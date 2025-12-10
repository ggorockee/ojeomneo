package service

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/ggorockee/ojeomneo/server/internal/service/email"
	"github.com/ggorockee/ojeomneo/server/internal/telemetry"
	"github.com/ggorockee/ojeomneo/server/pkg/auth"
	"github.com/ggorockee/ojeomneo/server/pkg/sns"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// AuthService 인증 서비스
type AuthService struct {
	db           *gorm.DB
	cfg          *config.Config
	logger       *zap.Logger
	metrics      *telemetry.AuthMetrics
	emailService *email.SMTPService
}

// NewAuthService 새 인증 서비스 생성
func NewAuthService(db *gorm.DB, cfg *config.Config, logger *zap.Logger, metrics *telemetry.AuthMetrics) *AuthService {
	// SMTP 이메일 서비스 초기화
	var emailService *email.SMTPService
	if cfg.SMTPUsername != "" && cfg.SMTPPassword != "" {
		smtpConfig := &email.SMTPConfig{
			Host:     cfg.SMTPHost,
			Port:     cfg.SMTPPort,
			Username: cfg.SMTPUsername,
			Password: cfg.SMTPPassword,
			From:     cfg.SMTPFrom,
		}
		emailService = email.NewSMTPService(smtpConfig, logger)
		logger.Info("SMTP email service initialized successfully",
			zap.String("host", cfg.SMTPHost),
			zap.String("port", cfg.SMTPPort),
			zap.String("username", cfg.SMTPUsername),
			zap.String("from", cfg.SMTPFrom),
		)
	} else {
		logger.Warn("SMTP email service disabled: missing credentials",
			zap.Bool("has_username", cfg.SMTPUsername != ""),
			zap.Bool("has_password", cfg.SMTPPassword != ""),
		)
	}

	return &AuthService{
		db:           db,
		cfg:          cfg,
		logger:       logger,
		metrics:      metrics,
		emailService: emailService,
	}
}

// AuthResponse 인증 응답
type AuthResponse struct {
	AccessToken  string        `json:"access_token"`
	RefreshToken string        `json:"refresh_token"`
	TokenType    string        `json:"token_type"`
	User         *UserResponse `json:"user"`
}

// UserResponse 사용자 응답
type UserResponse struct {
	ID          uint      `json:"id"`
	Email       string    `json:"email"`
	IsActive    bool      `json:"is_active"`
	DateJoined  time.Time `json:"date_joined"`
	LoginMethod string    `json:"login_method"`
}

// SNSLoginRequest SNS 로그인 요청
type SNSLoginRequest struct {
	IDToken     string `json:"id_token"`     // Google (Firebase ID Token)
	AccessToken string `json:"access_token"` // Apple/Kakao
}

// SignupRequest 회원가입 요청
type SignupRequest struct {
	Email           string  `json:"email"`
	Password        string  `json:"password"`
	FirstName       *string `json:"first_name,omitempty"`
	LastName        *string `json:"last_name,omitempty"`
	VerificationToken *string `json:"verification_token,omitempty"`
}

// LoginRequest 이메일 로그인 요청
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// GuestLoginRequest 익명 로그인 요청
type GuestLoginRequest struct {
	DeviceID string `json:"device_id"` // 디바이스 고유 ID (UUID)
}

// GoogleLogin Google 로그인 처리 (Firebase ID Token 사용)
func (s *AuthService) GoogleLogin(idToken string) (*AuthResponse, error) {
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	s.logger.Debug("Starting Google login",
		zap.String("provider", "google"),
	)

	// Firebase ID Token 검증 (goroutine으로 비동기 처리)
	type verifyResult struct {
		user *sns.FirebaseUserInfo
		err  error
	}
	resultCh := make(chan verifyResult, 1)

	go func() {
		user, err := sns.VerifyFirebaseIDToken(ctx, idToken)
		resultCh <- verifyResult{user, err}
	}()

	// 검증 결과 대기
	result := <-resultCh
	verifyDuration := time.Since(start)

	if result.err != nil {
		s.logger.Warn("Google login token verification failed",
			zap.Error(result.err),
			zap.String("provider", "google"),
			zap.Duration("duration", verifyDuration),
		)
		// 메트릭 기록: 토큰 검증 실패
		if s.metrics != nil {
			s.metrics.RecordSNSLogin(ctx, "google", "token_invalid", float64(time.Since(start).Milliseconds()))
		}
		return nil, fmt.Errorf("firebase 토큰 검증에 실패했습니다: %w", result.err)
	}

	firebaseUser := result.user
	if firebaseUser.Email == "" {
		s.logger.Warn("Google login missing email",
			zap.String("provider", "google"),
			zap.String("user_id", firebaseUser.ID),
		)
		return nil, errors.New("이메일이 필요합니다")
	}

	s.logger.Debug("Google token verified",
		zap.String("provider", "google"),
		zap.String("email", firebaseUser.Email),
		zap.String("user_id", firebaseUser.ID),
		zap.Duration("verify_duration", verifyDuration),
	)

	response, err := s.handleSNSLogin(
		"google",
		firebaseUser.ID,
		firebaseUser.Email,
		firebaseUser.Name,
	)

	if err != nil {
		s.logger.Error("Google login failed",
			zap.Error(err),
			zap.String("provider", "google"),
			zap.String("email", firebaseUser.Email),
			zap.Duration("total_duration", time.Since(start)),
		)
		// 메트릭 기록: 로그인 실패
		if s.metrics != nil {
			s.metrics.RecordSNSLogin(ctx, "google", "failed", float64(time.Since(start).Milliseconds()))
		}
		return nil, err
	}

	s.logger.Info("Google login successful",
		zap.String("provider", "google"),
		zap.Uint("user_id", response.User.ID),
		zap.String("email", response.User.Email),
		zap.Duration("total_duration", time.Since(start)),
	)

	// 메트릭 기록: 로그인 성공
	if s.metrics != nil {
		s.metrics.RecordSNSLogin(ctx, "google", "success", float64(time.Since(start).Milliseconds()))
		s.metrics.RecordTokenIssued(ctx, "access")
		s.metrics.RecordTokenIssued(ctx, "refresh")
	}

	return response, nil
}

// AppleLogin Apple 로그인 처리
func (s *AuthService) AppleLogin(identityToken string) (*AuthResponse, error) {
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	s.logger.Debug("Starting Apple login",
		zap.String("provider", "apple"),
	)

	// Apple Identity Token 검증 (goroutine으로 비동기 처리)
	type verifyResult struct {
		user *sns.AppleUserInfo
		err  error
	}
	resultCh := make(chan verifyResult, 1)

	go func() {
		user, err := sns.VerifyAppleToken(ctx, identityToken, s.cfg.AppleClientID)
		resultCh <- verifyResult{user, err}
	}()

	// 검증 결과 대기
	result := <-resultCh
	verifyDuration := time.Since(start)

	if result.err != nil {
		s.logger.Warn("Apple login token verification failed",
			zap.Error(result.err),
			zap.String("provider", "apple"),
			zap.Duration("duration", verifyDuration),
		)
		return nil, fmt.Errorf("apple 토큰 검증에 실패했습니다: %w", result.err)
	}

	appleUser := result.user
	// Apple 로그인은 첫 로그인 시에만 이메일이 제공되고, 이후 로그인에서는 이메일이 없을 수 있음
	// social_id(sub)로 사용자를 찾을 수 있으므로 이메일이 없어도 처리 가능

	s.logger.Debug("Apple token verified",
		zap.String("provider", "apple"),
		zap.String("email", appleUser.Email),
		zap.String("user_id", appleUser.ID),
		zap.Duration("verify_duration", verifyDuration),
	)

	response, err := s.handleSNSLogin(
		"apple",
		appleUser.ID,
		appleUser.Email, // 빈 문자열일 수 있음
		appleUser.Name,
	)

	if err != nil {
		s.logger.Error("Apple login failed",
			zap.Error(err),
			zap.String("provider", "apple"),
			zap.String("email", appleUser.Email),
			zap.Duration("total_duration", time.Since(start)),
		)
		return nil, err
	}

	s.logger.Info("Apple login successful",
		zap.String("provider", "apple"),
		zap.Uint("user_id", response.User.ID),
		zap.String("email", response.User.Email),
		zap.Duration("total_duration", time.Since(start)),
	)

	return response, nil
}

// KakaoLogin Kakao 로그인 처리
func (s *AuthService) KakaoLogin(accessToken string) (*AuthResponse, error) {
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	s.logger.Debug("Starting Kakao login",
		zap.String("provider", "kakao"),
	)

	// Kakao Access Token 검증 (goroutine으로 비동기 처리)
	type verifyResult struct {
		user *sns.KakaoUserInfo
		err  error
	}
	resultCh := make(chan verifyResult, 1)

	go func() {
		user, err := sns.VerifyKakaoToken(ctx, accessToken)
		resultCh <- verifyResult{user, err}
	}()

	// 검증 결과 대기
	result := <-resultCh
	verifyDuration := time.Since(start)

	if result.err != nil {
		s.logger.Warn("Kakao login token verification failed",
			zap.Error(result.err),
			zap.String("provider", "kakao"),
			zap.Duration("duration", verifyDuration),
		)
		return nil, fmt.Errorf("kakao 토큰 검증에 실패했습니다: %w", result.err)
	}

	kakaoUser := result.user
	if kakaoUser.Email == "" {
		s.logger.Warn("Kakao login missing email",
			zap.String("provider", "kakao"),
			zap.String("user_id", kakaoUser.ID),
		)
		return nil, errors.New("이메일 제공 동의가 필요합니다")
	}

	s.logger.Debug("Kakao token verified",
		zap.String("provider", "kakao"),
		zap.String("email", kakaoUser.Email),
		zap.String("user_id", kakaoUser.ID),
		zap.Duration("verify_duration", verifyDuration),
	)

	response, err := s.handleSNSLogin(
		"kakao",
		kakaoUser.ID,
		kakaoUser.Email,
		kakaoUser.Name,
	)

	if err != nil {
		s.logger.Error("Kakao login failed",
			zap.Error(err),
			zap.String("provider", "kakao"),
			zap.String("email", kakaoUser.Email),
			zap.Duration("total_duration", time.Since(start)),
		)
		return nil, err
	}

	s.logger.Info("Kakao login successful",
		zap.String("provider", "kakao"),
		zap.Uint("user_id", response.User.ID),
		zap.String("email", response.User.Email),
		zap.Duration("total_duration", time.Since(start)),
	)

	return response, nil
}

// handleSNSLogin 공통 SNS 로그인 로직 (goroutine으로 최적화)
// profileImage는 현재 User 모델에 필드가 없어 사용하지 않음
func (s *AuthService) handleSNSLogin(provider, socialID, email, name string) (*AuthResponse, error) {
	start := time.Now()

	// 이메일 정규화
	email = normalizeEmail(email)

	var user *model.User
	var isNewUser bool

	// DB 트랜잭션에서 사용자 생성/조회
	txErr := s.db.Transaction(func(tx *gorm.DB) error {
		// 기존 사용자 찾기: login_method + social_id 조합 (social_id가 고유함)
		// Apple 로그인의 경우 이메일이 없을 수 있으므로 social_id로 먼저 찾음
		var existingUser model.User
		err := tx.Where("login_method = ? AND social_id = ?", provider, socialID).
			First(&existingUser).Error

		if err == nil {
			// 기존 사용자 발견
			user = &existingUser
			isNewUser = false

			s.logger.Debug("Existing user found for SNS login",
				zap.String("provider", provider),
				zap.Uint("user_id", user.ID),
				zap.String("email", user.Email),
				zap.String("social_id", socialID),
			)

			// 업데이트 필드 준비
			updateFields := map[string]interface{}{
				"last_login": time.Now(),
			}

			// 이메일이 제공되었고 기존 사용자의 이메일이 비어있으면 업데이트
			if email != "" && existingUser.Email == "" {
				updateFields["email"] = email
			}

			if name != "" && existingUser.FirstName == "" {
				// name을 first_name과 last_name으로 분리
				nameParts := strings.SplitN(name, " ", 2)
				if len(nameParts) == 2 {
					updateFields["first_name"] = nameParts[0]
					updateFields["last_name"] = nameParts[1]
				} else {
					updateFields["first_name"] = name
				}
			}

			if err := tx.Model(user).Updates(updateFields).Error; err != nil {
				return fmt.Errorf("failed to update user: %w", err)
			}

			return nil
		}

		// 새로운 사용자 생성
		isNewUser = true

		// username 생성: 이메일이 있으면 이메일 기반, 없으면 social_id 기반
		var username string
		if email != "" {
			username = fmt.Sprintf("%s_%s", strings.ReplaceAll(email, "@", "_at_"), provider)
		} else {
			// Apple 로그인처럼 이메일이 없을 경우 social_id 기반 username 생성
			username = fmt.Sprintf("%s_%s", provider, socialID)
		}

		// name을 first_name과 last_name으로 분리
		firstName := name
		lastName := ""
		if name != "" {
			nameParts := strings.SplitN(name, " ", 2)
			if len(nameParts) == 2 {
				firstName = nameParts[0]
				lastName = nameParts[1]
			}
		}

		// Apple 로그인의 경우 이메일이 없을 수 있지만, User 모델의 email은 not null
		// 따라서 이메일이 없을 때는 placeholder 이메일 생성
		userEmail := email
		if userEmail == "" {
			// Apple 로그인처럼 이메일이 없을 경우 placeholder 이메일 생성
			userEmail = fmt.Sprintf("%s_%s@placeholder.local", provider, socialID)
			s.logger.Warn("Creating user without email, using placeholder",
				zap.String("provider", provider),
				zap.String("social_id", socialID),
				zap.String("placeholder_email", userEmail),
			)
		}

		user = &model.User{
			Username:    username,
			Email:       userEmail,
			LoginMethod: model.LoginMethod(provider),
			SocialID:    socialID,
			FirstName:   firstName,
			LastName:    lastName,
			Password:    "", // SNS 로그인은 비밀번호 없음
			IsActive:    true,
		}

		if err := tx.Create(user).Error; err != nil {
			return fmt.Errorf("failed to create user: %w", err)
		}

		s.logger.Info("New user created for SNS login",
			zap.String("provider", provider),
			zap.Uint("user_id", user.ID),
			zap.String("email", email),
		)

		return nil
	})

	if txErr != nil {
		s.logger.Error("SNS login transaction failed",
			zap.Error(txErr),
			zap.String("provider", provider),
			zap.String("email", email),
		)
		return nil, txErr
	}

	dbDuration := time.Since(start)

	// JWT 토큰 발급 (goroutine 사용)
	type tokenResult struct {
		accessToken  string
		refreshToken string
		err          error
	}
	tokenCh := make(chan tokenResult, 1)

	go func() {
		accessToken, refreshToken, err := auth.GenerateTokenPair(
			user.ID,
			s.cfg.JWTSecretKey,
			s.cfg.JWTAccessTokenExpireMin,
			s.cfg.JWTRefreshTokenExpireDays,
		)
		tokenCh <- tokenResult{accessToken, refreshToken, err}
	}()

	tokenRes := <-tokenCh
	if tokenRes.err != nil {
		s.logger.Error("JWT token generation failed",
			zap.Error(tokenRes.err),
			zap.String("provider", provider),
			zap.Uint("user_id", user.ID),
		)
		return nil, fmt.Errorf("failed to generate tokens: %w", tokenRes.err)
	}

	s.logger.Debug("SNS login completed",
		zap.String("provider", provider),
		zap.Uint("user_id", user.ID),
		zap.String("email", email),
		zap.Bool("is_new_user", isNewUser),
		zap.Duration("db_duration", dbDuration),
		zap.Duration("total_duration", time.Since(start)),
	)

	return &AuthResponse{
		AccessToken:  tokenRes.accessToken,
		RefreshToken: tokenRes.refreshToken,
		TokenType:    "bearer",
		User: &UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			IsActive:    user.IsActive,
			DateJoined:  user.DateJoined,
			LoginMethod: string(user.LoginMethod),
		},
	}, nil
}

// normalizeEmail 이메일 주소 정규화
func normalizeEmail(email string) string {
	if email == "" {
		return ""
	}
	parts := strings.SplitN(email, "@", 2)
	if len(parts) == 2 {
		return parts[0] + "@" + strings.ToLower(parts[1])
	}
	return strings.ToLower(email)
}

// SendEmailCode 이메일 인증코드 발송
func (s *AuthService) SendEmailCode(email string) error {
	// 이메일 정규화
	email = normalizeEmail(email)

	// 6자리 인증코드 생성
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	// 기존 인증코드 삭제
	s.db.Where("email = ?", email).Delete(&model.EmailVerification{})

	// 새 인증 레코드 생성
	verification := model.EmailVerification{
		Email:     email,
		Code:      code,
		ExpiresAt: time.Now().Add(10 * time.Minute),
		SendCount: 1,
		LastSentAt: func() *time.Time {
			now := time.Now()
			return &now
		}(),
	}

	if err := s.db.Create(&verification).Error; err != nil {
		s.logger.Error("Failed to create email verification",
			zap.Error(err),
			zap.String("email", email),
		)
		return fmt.Errorf("인증코드 생성에 실패했습니다: %w", err)
	}

	// 실제 이메일 발송
	if s.emailService != nil {
		if err := s.emailService.SendVerificationCode(email, code); err != nil {
			s.logger.Error("Failed to send verification email",
				zap.Error(err),
				zap.String("email", email),
			)
			// 이메일 발송 실패해도 코드는 저장되었으므로 성공 반환 (개발 환경 대응)
			fmt.Printf("[개발용] 이메일 발송 실패, 인증코드: %s -> %s\n", email, code)
		} else {
			s.logger.Info("Email verification code sent",
				zap.String("email", email),
			)
		}
	} else {
		// SMTP 서비스가 없으면 개발용 콘솔 출력
		s.logger.Info("Email verification code generated (SMTP disabled)",
			zap.String("email", email),
			zap.String("code", code),
		)
		fmt.Printf("[개발용] 이메일 인증코드: %s -> %s\n", email, code)
	}

	return nil
}

// VerifyEmailCode 이메일 인증코드 확인
func (s *AuthService) VerifyEmailCode(email, code string) (bool, string, error) {
	// 이메일 정규화
	email = normalizeEmail(email)

	var verification model.EmailVerification
	err := s.db.Where("email = ? AND code = ? AND expires_at > ?", email, code, time.Now()).
		First(&verification).Error

	if err != nil {
		// 실패 횟수 증가
		var existingVerification model.EmailVerification
		if err := s.db.Where("email = ?", email).First(&existingVerification).Error; err == nil {
			s.db.Model(&existingVerification).Update("attempts", gorm.Expr("attempts + 1"))
		}

		s.logger.Warn("Email verification code invalid or expired",
			zap.String("email", email),
			zap.Error(err),
		)
		return false, "", errors.New("인증코드가 유효하지 않거나 만료되었습니다")
	}

	// 인증 성공 처리
	verification.IsVerified = true
	verification.Attempts = 0

	// VerificationToken 생성 (회원가입 시 사용)
	token := fmt.Sprintf("%s_%d_%d", email, time.Now().Unix(), rand.Intn(10000))
	verification.VerificationToken = &token

	if err := s.db.Save(&verification).Error; err != nil {
		s.logger.Error("Failed to update email verification",
			zap.Error(err),
			zap.String("email", email),
		)
		return false, "", fmt.Errorf("인증 처리에 실패했습니다: %w", err)
	}

	s.logger.Info("Email verification successful",
		zap.String("email", email),
	)

	return true, token, nil
}

// Signup 회원가입
func (s *AuthService) Signup(req *SignupRequest) (*AuthResponse, error) {
	// 이메일 정규화
	email := normalizeEmail(req.Email)

	// 이메일 인증 확인
	var verification model.EmailVerification
	var verificationErr error

	if req.VerificationToken != nil && *req.VerificationToken != "" {
		// VerificationToken으로 확인
		verificationErr = s.db.Where("email = ? AND verification_token = ? AND is_verified = ?",
			email, *req.VerificationToken, true).First(&verification).Error
	} else {
		// IsVerified로 확인 (하위 호환성)
		verificationErr = s.db.Where("email = ? AND is_verified = ?",
			email, true).First(&verification).Error
	}

	if verificationErr != nil {
		s.logger.Warn("Signup failed: email not verified",
			zap.String("email", email),
			zap.Error(verificationErr),
		)
		return nil, errors.New("이메일 인증이 완료되지 않았습니다")
	}

	// 기존 사용자 확인
	var existingUser model.User
	if err := s.db.Where("email = ? AND login_method = ?", email, "email").
		First(&existingUser).Error; err == nil {
		s.logger.Warn("Signup failed: user already exists",
			zap.String("email", email),
			zap.Uint("user_id", existingUser.ID),
		)
		return nil, errors.New("이미 가입된 이메일입니다")
	}

	// 비밀번호 해싱
	hashedPassword, err := auth.HashPassword(req.Password)
	if err != nil {
		s.logger.Error("Failed to hash password",
			zap.Error(err),
			zap.String("email", email),
		)
		return nil, fmt.Errorf("비밀번호 처리에 실패했습니다: %w", err)
	}

	// 이름 처리
	firstName := ""
	lastName := ""
	if req.FirstName != nil {
		firstName = *req.FirstName
	}
	if req.LastName != nil {
		lastName = *req.LastName
	}

	// Username 생성: email_at_email 형식
	username := fmt.Sprintf("%s_email", strings.ReplaceAll(email, "@", "_at_"))

	// 사용자 생성
	user := model.User{
		Username:    username,
		Email:       email,
		Password:    hashedPassword,
		LoginMethod: model.LoginMethodEmail,
		FirstName:   firstName,
		LastName:    lastName,
		IsActive:    true,
	}

	if err := s.db.Create(&user).Error; err != nil {
		s.logger.Error("Failed to create user",
			zap.Error(err),
			zap.String("email", email),
		)
		return nil, fmt.Errorf("회원가입에 실패했습니다: %w", err)
	}

	// JWT 토큰 발급
	accessToken, refreshToken, err := auth.GenerateTokenPair(
		user.ID,
		s.cfg.JWTSecretKey,
		s.cfg.JWTAccessTokenExpireMin,
		s.cfg.JWTRefreshTokenExpireDays,
	)
	if err != nil {
		s.logger.Error("Failed to generate tokens",
			zap.Error(err),
			zap.Uint("user_id", user.ID),
		)
		return nil, fmt.Errorf("토큰 생성에 실패했습니다: %w", err)
	}

	s.logger.Info("User signup successful",
		zap.Uint("user_id", user.ID),
		zap.String("email", email),
	)

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "bearer",
		User: &UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			IsActive:    user.IsActive,
			DateJoined:  user.DateJoined,
			LoginMethod: string(user.LoginMethod),
		},
	}, nil
}

// EmailLogin 이메일 로그인
func (s *AuthService) EmailLogin(req *LoginRequest) (*AuthResponse, error) {
	start := time.Now()

	// 이메일 정규화
	email := normalizeEmail(req.Email)

	s.logger.Debug("Starting email login",
		zap.String("email", email),
	)

	// 사용자 조회
	var user model.User
	if err := s.db.Where("email = ? AND login_method = ?", email, "email").
		First(&user).Error; err != nil {
		s.logger.Warn("Email login failed: user not found",
			zap.String("email", email),
			zap.Error(err),
		)
		return nil, errors.New("이메일 또는 비밀번호가 올바르지 않습니다")
	}

	// 비밀번호 확인
	if !auth.CheckPassword(req.Password, user.Password) {
		s.logger.Warn("Email login failed: invalid password",
			zap.String("email", email),
			zap.Uint("user_id", user.ID),
		)
		return nil, errors.New("이메일 또는 비밀번호가 올바르지 않습니다")
	}

	// 사용자 활성화 확인
	if !user.IsActive {
		s.logger.Warn("Email login failed: user inactive",
			zap.String("email", email),
			zap.Uint("user_id", user.ID),
		)
		return nil, errors.New("비활성화된 계정입니다")
	}

	// 마지막 로그인 시간 업데이트
	now := time.Now()
	user.LastLogin = &now
	if err := s.db.Save(&user).Error; err != nil {
		s.logger.Warn("Failed to update last login",
			zap.Error(err),
			zap.Uint("user_id", user.ID),
		)
		// 로그인은 계속 진행
	}

	// JWT 토큰 발급
	accessToken, refreshToken, err := auth.GenerateTokenPair(
		user.ID,
		s.cfg.JWTSecretKey,
		s.cfg.JWTAccessTokenExpireMin,
		s.cfg.JWTRefreshTokenExpireDays,
	)
	if err != nil {
		s.logger.Error("Failed to generate tokens",
			zap.Error(err),
			zap.Uint("user_id", user.ID),
		)
		return nil, fmt.Errorf("토큰 생성에 실패했습니다: %w", err)
	}

	s.logger.Info("Email login successful",
		zap.Uint("user_id", user.ID),
		zap.String("email", email),
		zap.Duration("duration", time.Since(start)),
	)

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "bearer",
		User: &UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			IsActive:    user.IsActive,
			DateJoined:  user.DateJoined,
			LoginMethod: string(user.LoginMethod),
		},
	}, nil
}

// RefreshToken Refresh Token으로 새 토큰 발급
func (s *AuthService) RefreshToken(refreshTokenString string) (*AuthResponse, error) {
	// Refresh Token 검증
	claims, err := auth.ValidateRefreshToken(refreshTokenString, s.cfg.JWTSecretKey)
	if err != nil {
		s.logger.Warn("Refresh token validation failed",
			zap.Error(err),
		)
		return nil, errors.New("유효하지 않은 토큰입니다")
	}

	// 사용자 조회
	var user model.User
	if err := s.db.First(&user, claims.UserID).Error; err != nil {
		s.logger.Warn("Refresh token failed: user not found",
			zap.Uint("user_id", claims.UserID),
			zap.Error(err),
		)
		return nil, errors.New("사용자를 찾을 수 없습니다")
	}

	// 사용자 활성화 확인
	if !user.IsActive {
		s.logger.Warn("Refresh token failed: user inactive",
			zap.Uint("user_id", user.ID),
		)
		return nil, errors.New("비활성화된 계정입니다")
	}

	// 새 토큰 발급
	accessToken, newRefreshToken, err := auth.GenerateTokenPair(
		user.ID,
		s.cfg.JWTSecretKey,
		s.cfg.JWTAccessTokenExpireMin,
		s.cfg.JWTRefreshTokenExpireDays,
	)
	if err != nil {
		s.logger.Error("Failed to generate new tokens",
			zap.Error(err),
			zap.Uint("user_id", user.ID),
		)
		return nil, fmt.Errorf("토큰 생성에 실패했습니다: %w", err)
	}

	s.logger.Debug("Token refreshed successfully",
		zap.Uint("user_id", user.ID),
	)

	return &AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		TokenType:    "bearer",
		User: &UserResponse{
			ID:          user.ID,
			Email:       user.Email,
			IsActive:    user.IsActive,
			DateJoined:  user.DateJoined,
			LoginMethod: string(user.LoginMethod),
		},
	}, nil
}

// PasswordResetRequest 비밀번호 재설정 요청 (인증코드 발송)
func (s *AuthService) PasswordResetRequest(email string) error {
	// 이메일 정규화
	email = normalizeEmail(email)

	// 이메일 로그인 사용자 확인
	var user model.User
	if err := s.db.Where("email = ? AND login_method = ?", email, "email").
		First(&user).Error; err != nil {
		s.logger.Warn("Password reset requested for non-existent email",
			zap.String("email", email),
		)
		return fmt.Errorf("등록되지 않은 이메일입니다")
	}

	// 6자리 인증코드 생성
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	// 기존 인증코드 삭제
	s.db.Where("email = ?", email).Delete(&model.EmailVerification{})

	// 새 인증 레코드 생성 (비밀번호 재설정용)
	verification := model.EmailVerification{
		Email:     email,
		Code:      code,
		ExpiresAt: time.Now().Add(60 * time.Minute), // 비밀번호 재설정은 60분 유효
		SendCount: 1,
		LastSentAt: func() *time.Time {
			now := time.Now()
			return &now
		}(),
	}

	if err := s.db.Create(&verification).Error; err != nil {
		s.logger.Error("Failed to create password reset verification",
			zap.Error(err),
			zap.String("email", email),
		)
		return fmt.Errorf("인증코드 생성에 실패했습니다: %w", err)
	}

	// 실제 이메일 발송
	if s.emailService != nil {
		if err := s.emailService.SendPasswordResetCode(email, code); err != nil {
			s.logger.Error("Failed to send password reset email",
				zap.Error(err),
				zap.String("email", email),
			)
			// 이메일 발송 실패해도 코드는 저장되었으므로 성공 반환 (개발 환경 대응)
			fmt.Printf("[개발용] 이메일 발송 실패, 비밀번호 재설정 인증코드: %s -> %s\n", email, code)
		} else {
			s.logger.Info("Password reset code sent",
				zap.String("email", email),
			)
		}
	} else {
		// SMTP 서비스가 없으면 개발용 콘솔 출력
		s.logger.Info("Password reset code generated (SMTP disabled)",
			zap.String("email", email),
			zap.String("code", code),
		)
		fmt.Printf("[개발용] 비밀번호 재설정 인증코드: %s -> %s\n", email, code)
	}

	return nil
}

// PasswordResetVerify 비밀번호 재설정 인증코드 확인
func (s *AuthService) PasswordResetVerify(email, code string) (string, error) {
	// 이메일 정규화
	email = normalizeEmail(email)

	var verification model.EmailVerification
	err := s.db.Where("email = ? AND code = ? AND expires_at > ?", email, code, time.Now()).
		First(&verification).Error

	if err != nil {
		// 실패 횟수 증가
		var existingVerification model.EmailVerification
		if err := s.db.Where("email = ?", email).First(&existingVerification).Error; err == nil {
			s.db.Model(&existingVerification).Update("attempts", gorm.Expr("attempts + 1"))

			// 5회 이상 실패 시 에러
			if existingVerification.Attempts >= 5 {
				s.logger.Warn("Password reset verification attempts exceeded",
					zap.String("email", email),
					zap.Int("attempts", existingVerification.Attempts),
				)
				return "", errors.New("인증 시도 횟수를 초과했습니다. 다시 요청해주세요")
			}
		}

		s.logger.Warn("Password reset verification code invalid or expired",
			zap.String("email", email),
			zap.Error(err),
		)
		return "", errors.New("인증코드가 유효하지 않거나 만료되었습니다")
	}

	// Reset Token 생성
	resetToken := fmt.Sprintf("reset_%s_%d_%d", email, time.Now().Unix(), rand.Intn(10000))
	verification.VerificationToken = &resetToken
	verification.IsVerified = true
	verification.Attempts = 0

	if err := s.db.Save(&verification).Error; err != nil {
		s.logger.Error("Failed to update password reset verification",
			zap.Error(err),
			zap.String("email", email),
		)
		return "", fmt.Errorf("인증 처리에 실패했습니다: %w", err)
	}

	s.logger.Info("Password reset verification successful",
		zap.String("email", email),
	)

	return resetToken, nil
}

// PasswordResetConfirm 비밀번호 재설정 확정 (새 비밀번호 설정)
func (s *AuthService) PasswordResetConfirm(email, resetToken, newPassword string) error {
	// 이메일 정규화
	email = normalizeEmail(email)

	// Reset Token 확인
	var verification model.EmailVerification
	if err := s.db.Where("email = ? AND verification_token = ? AND is_verified = ?",
		email, resetToken, true).First(&verification).Error; err != nil {
		s.logger.Warn("Password reset confirm failed: invalid token",
			zap.String("email", email),
			zap.Error(err),
		)
		return errors.New("유효하지 않은 재설정 토큰입니다")
	}

	// 사용자 조회
	var user model.User
	if err := s.db.Where("email = ? AND login_method = ?", email, "email").
		First(&user).Error; err != nil {
		s.logger.Warn("Password reset confirm failed: user not found",
			zap.String("email", email),
			zap.Error(err),
		)
		return errors.New("사용자를 찾을 수 없습니다")
	}

	// 새 비밀번호 해싱
	hashedPassword, err := auth.HashPassword(newPassword)
	if err != nil {
		s.logger.Error("Failed to hash new password",
			zap.Error(err),
			zap.String("email", email),
		)
		return fmt.Errorf("비밀번호 처리에 실패했습니다: %w", err)
	}

	// 비밀번호 업데이트
	user.Password = hashedPassword
	if err := s.db.Save(&user).Error; err != nil {
		s.logger.Error("Failed to update password",
			zap.Error(err),
			zap.String("email", email),
			zap.Uint("user_id", user.ID),
		)
		return fmt.Errorf("비밀번호 변경에 실패했습니다: %w", err)
	}

	// 인증 레코드 삭제 (보안상 재사용 방지)
	s.db.Delete(&verification)

	s.logger.Info("Password reset successful",
		zap.String("email", email),
		zap.Uint("user_id", user.ID),
	)

	return nil
}

// GetMe 현재 사용자 정보 조회
func (s *AuthService) GetMe(userID uint) (*model.User, error) {
	var user model.User
	if err := s.db.First(&user, userID).Error; err != nil {
		s.logger.Warn("GetMe failed: user not found",
			zap.Uint("user_id", userID),
			zap.Error(err),
		)
		return nil, errors.New("사용자를 찾을 수 없습니다")
	}

	return &user, nil
}

// DeleteMe 회원 탈퇴 (Soft Delete) - 탈퇴 사유 선택 가능
func (s *AuthService) DeleteMe(userID uint, reason *string) error {
	start := time.Now()

	s.logger.Info("Starting account deletion",
		zap.Uint("user_id", userID),
		zap.Bool("has_reason", reason != nil),
	)

	var user model.User
	if err := s.db.First(&user, userID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			s.logger.Warn("DeleteMe failed: user not found",
				zap.Uint("user_id", userID),
				zap.Error(err),
			)
			return errors.New("사용자를 찾을 수 없습니다")
		}
		return fmt.Errorf("사용자 조회 실패: %w", err)
	}

	// 익명 사용자는 탈퇴 불가 (자동 삭제 대상)
	if user.IsGuest {
		return errors.New("익명 사용자는 회원 탈퇴를 할 수 없습니다")
	}

	// 탈퇴 사유 로깅 (선택사항)
	if reason != nil && *reason != "" {
		s.logger.Info("Account deletion reason provided",
			zap.Uint("user_id", userID),
			zap.String("reason", *reason),
		)
	}

	// Soft Delete (GORM의 DeletedAt 사용)
	if err := s.db.Delete(&user).Error; err != nil {
		s.logger.Error("Failed to delete user",
			zap.Error(err),
			zap.Uint("user_id", userID),
		)
		return fmt.Errorf("회원 탈퇴 처리에 실패했습니다: %w", err)
	}

	s.logger.Info("User deleted successfully",
		zap.Uint("user_id", userID),
		zap.String("email", user.Email),
		zap.String("login_method", string(user.LoginMethod)),
		zap.Duration("duration", time.Since(start)),
	)

	return nil
}

// GuestLogin 익명 로그인 처리 (디바이스 ID 기반)
// 로그인하지 않고 둘러보기 기능 지원
func (s *AuthService) GuestLogin(deviceID string) (*AuthResponse, error) {
	start := time.Now()
	ctx := context.Background()

	s.logger.Debug("Starting guest login",
		zap.String("device_id", deviceID),
	)

	// 디바이스 ID로 기존 익명 사용자 조회
	var existingUser model.User
	err := s.db.Where("device_id = ? AND is_guest = ?", deviceID, true).First(&existingUser).Error

	if err == nil {
		// 기존 익명 사용자 존재: 토큰만 새로 발급
		s.logger.Debug("Existing guest user found",
			zap.Uint("user_id", existingUser.ID),
			zap.String("device_id", deviceID),
		)

		// 토큰 생성
		guestToken, err := auth.GenerateGuestToken(existingUser.ID, s.cfg.JWTSecretKey, 7) // 7일 만료
		if err != nil {
			s.logger.Error("Failed to generate guest token",
				zap.Error(err),
				zap.Uint("user_id", existingUser.ID),
			)
			if s.metrics != nil {
				s.metrics.RecordGuestLogin(ctx, "failed")
			}
			return nil, fmt.Errorf("토큰 생성에 실패했습니다: %w", err)
		}

		// 메트릭 기록
		if s.metrics != nil {
			s.metrics.RecordGuestLogin(ctx, "success")
			s.metrics.RecordTokenIssued(ctx, "guest")
		}

		s.logger.Info("Guest login successful (existing user)",
			zap.Uint("user_id", existingUser.ID),
			zap.String("device_id", deviceID),
			zap.Duration("duration", time.Since(start)),
		)

		return &AuthResponse{
			AccessToken:  guestToken,
			RefreshToken: "", // 익명 사용자는 refresh token 없음
			TokenType:    "Bearer",
			User: &UserResponse{
				ID:          existingUser.ID,
				Email:       existingUser.Email,
				IsActive:    existingUser.IsActive,
				DateJoined:  existingUser.DateJoined,
				LoginMethod: string(existingUser.LoginMethod),
			},
		}, nil
	}

	if err != gorm.ErrRecordNotFound {
		// DB 조회 실패 (레코드 없음 제외)
		s.logger.Error("Failed to query guest user",
			zap.Error(err),
			zap.String("device_id", deviceID),
		)
		if s.metrics != nil {
			s.metrics.RecordGuestLogin(ctx, "failed")
		}
		return nil, fmt.Errorf("사용자 조회에 실패했습니다: %w", err)
	}

	// 새 익명 사용자 생성
	s.logger.Debug("Creating new guest user",
		zap.String("device_id", deviceID),
	)

	// 익명 사용자용 임시 이메일 및 username 생성
	guestEmail := fmt.Sprintf("guest_%s@ojeomneo.local", generateRandomString(8))
	guestUsername := fmt.Sprintf("guest_%s", generateRandomString(8))

	newUser := model.User{
		Email:       guestEmail,
		Username:    guestUsername,
		Password:    generateRandomString(32), // 임의의 비밀번호 (로그인 불가)
		IsGuest:     true,
		DeviceID:    &deviceID,
		IsActive:    true,
		LoginMethod: "guest",
		FirstName:   "게스트",
		LastName:    "사용자",
	}

	// 사용자 생성
	if err := s.db.Create(&newUser).Error; err != nil {
		s.logger.Error("Failed to create guest user",
			zap.Error(err),
			zap.String("device_id", deviceID),
		)
		if s.metrics != nil {
			s.metrics.RecordGuestLogin(ctx, "failed")
		}
		return nil, fmt.Errorf("익명 사용자 생성에 실패했습니다: %w", err)
	}

	// 토큰 생성
	guestToken, err := auth.GenerateGuestToken(newUser.ID, s.cfg.JWTSecretKey, 7) // 7일 만료
	if err != nil {
		s.logger.Error("Failed to generate guest token",
			zap.Error(err),
			zap.Uint("user_id", newUser.ID),
		)
		if s.metrics != nil {
			s.metrics.RecordGuestLogin(ctx, "failed")
		}
		return nil, fmt.Errorf("토큰 생성에 실패했습니다: %w", err)
	}

	// 메트릭 기록
	if s.metrics != nil {
		s.metrics.RecordGuestLogin(ctx, "success")
		s.metrics.RecordTokenIssued(ctx, "guest")
	}

	s.logger.Info("Guest login successful (new user)",
		zap.Uint("user_id", newUser.ID),
		zap.String("device_id", deviceID),
		zap.Duration("duration", time.Since(start)),
	)

	return &AuthResponse{
		AccessToken:  guestToken,
		RefreshToken: "", // 익명 사용자는 refresh token 없음
		TokenType:    "Bearer",
		User: &UserResponse{
			ID:          newUser.ID,
			Email:       newUser.Email,
			IsActive:    newUser.IsActive,
			DateJoined:  newUser.DateJoined,
			LoginMethod: string(newUser.LoginMethod),
		},
	}, nil
}

// generateRandomString 랜덤 문자열 생성 (익명 사용자용)
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}
