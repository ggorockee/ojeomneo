package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/ggorockee/ojeomneo/server/pkg/auth"
	"github.com/ggorockee/ojeomneo/server/pkg/sns"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// AuthService 인증 서비스
type AuthService struct {
	db     *gorm.DB
	cfg    *config.Config
	logger *zap.Logger
}

// NewAuthService 새 인증 서비스 생성
func NewAuthService(db *gorm.DB, cfg *config.Config, logger *zap.Logger) *AuthService {
	return &AuthService{
		db:     db,
		cfg:    cfg,
		logger: logger,
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
		firebaseUser.ProfileImage,
	)

	if err != nil {
		s.logger.Error("Google login failed",
			zap.Error(err),
			zap.String("provider", "google"),
			zap.String("email", firebaseUser.Email),
			zap.Duration("total_duration", time.Since(start)),
		)
		return nil, err
	}

	s.logger.Info("Google login successful",
		zap.String("provider", "google"),
		zap.Uint("user_id", response.User.ID),
		zap.String("email", response.User.Email),
		zap.Duration("total_duration", time.Since(start)),
	)

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
		appleUser.ProfileImage,
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
		kakaoUser.ProfileImage,
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
func (s *AuthService) handleSNSLogin(provider, socialID, email, name, profileImage string) (*AuthResponse, error) {
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
