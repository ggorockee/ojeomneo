package handler

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"go.uber.org/zap"

	"github.com/ggorockee/ojeomneo/server/internal/service"
	"github.com/ggorockee/ojeomneo/server/pkg/auth"
)

// SendEmailCodeRequest 이메일 인증코드 발송 요청
type SendEmailCodeRequest struct {
	Email string `json:"email"`
}

// SendEmailCode godoc
// @Summary 이메일 인증코드 발송
// @Tags auth
// @Accept json
// @Produce json
// @Param request body SendEmailCodeRequest true "이메일"
// @Success 200 {object} map[string]string
// @Router /auth/email/send-code [post]
func (h *AuthHandler) SendEmailCode(c *fiber.Ctx) error {
	var req SendEmailCodeRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("SendEmailCode request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email is required",
		})
	}

	if err := h.authService.SendEmailCode(req.Email); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "인증코드가 발송되었습니다",
	})
}

// VerifyEmailCodeRequest 이메일 인증코드 확인 요청
type VerifyEmailCodeRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

// VerifyEmailCodeResponse 이메일 인증코드 확인 응답
type VerifyEmailCodeResponse struct {
	Verified          bool   `json:"verified"`
	VerificationToken string `json:"verification_token,omitempty"`
}

// VerifyEmailCode godoc
// @Summary 이메일 인증코드 확인
// @Tags auth
// @Accept json
// @Produce json
// @Param request body VerifyEmailCodeRequest true "이메일과 인증코드"
// @Success 200 {object} VerifyEmailCodeResponse
// @Router /auth/email/verify-code [post]
func (h *AuthHandler) VerifyEmailCode(c *fiber.Ctx) error {
	var req VerifyEmailCodeRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("VerifyEmailCode request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" || req.Code == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email and code are required",
		})
	}

	verified, token, err := h.authService.VerifyEmailCode(req.Email, req.Code)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(VerifyEmailCodeResponse{
		Verified:          verified,
		VerificationToken: token,
	})
}

// SignupRequest 회원가입 요청
type SignupRequest struct {
	Email            string  `json:"email"`
	Password         string  `json:"password"`
	FirstName        *string `json:"first_name,omitempty"`
	LastName         *string `json:"last_name,omitempty"`
	VerificationToken *string `json:"verification_token,omitempty"`
}

// Signup godoc
// @Summary 회원가입
// @Tags auth
// @Accept json
// @Produce json
// @Param request body SignupRequest true "회원가입 정보"
// @Success 201 {object} service.AuthResponse
// @Router /auth/signup [post]
func (h *AuthHandler) Signup(c *fiber.Ctx) error {
	var req SignupRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("Signup request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email and password are required",
		})
	}

	serviceReq := &service.SignupRequest{
		Email:            req.Email,
		Password:         req.Password,
		FirstName:        req.FirstName,
		LastName:         req.LastName,
		VerificationToken: req.VerificationToken,
	}

	response, err := h.authService.Signup(serviceReq)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    response,
	})
}

// LoginRequest 이메일 로그인 요청
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// Login godoc
// @Summary 이메일 로그인
// @Tags auth
// @Accept json
// @Produce json
// @Param request body LoginRequest true "로그인 정보"
// @Success 200 {object} service.AuthResponse
// @Router /auth/login [post]
func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("Login request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email and password are required",
		})
	}

	serviceReq := &service.LoginRequest{
		Email:    req.Email,
		Password: req.Password,
	}

	response, err := h.authService.EmailLogin(serviceReq)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    response,
	})
}

// RefreshTokenRequest Refresh Token 요청
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// RefreshToken godoc
// @Summary 토큰 갱신
// @Tags auth
// @Accept json
// @Produce json
// @Param request body RefreshTokenRequest true "Refresh Token"
// @Success 200 {object} service.AuthResponse
// @Router /auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	var req RefreshTokenRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("RefreshToken request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.RefreshToken == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "refresh_token is required",
		})
	}

	response, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    response,
	})
}

// PasswordResetRequest 비밀번호 재설정 요청
type PasswordResetRequest struct {
	Email string `json:"email"`
}

// PasswordResetRequestHandler godoc
// @Summary 비밀번호 재설정 요청 (인증코드 발송)
// @Tags auth
// @Accept json
// @Produce json
// @Param request body PasswordResetRequest true "이메일"
// @Success 200 {object} map[string]string
// @Router /auth/password/reset-request [post]
func (h *AuthHandler) PasswordResetRequest(c *fiber.Ctx) error {
	var req PasswordResetRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("PasswordResetRequest parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email is required",
		})
	}

	// 보안상 이유로 실패해도 성공 메시지 반환
	if err := h.authService.PasswordResetRequest(req.Email); err != nil {
		h.logger.Warn("PasswordResetRequest failed",
			zap.Error(err),
			zap.String("email", req.Email),
		)
		// 에러를 반환하지 않고 성공 메시지만 반환
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "인증코드가 발송되었습니다",
	})
}

// PasswordResetVerifyRequest 비밀번호 재설정 인증코드 확인 요청
type PasswordResetVerifyRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

// PasswordResetVerifyResponse 비밀번호 재설정 인증코드 확인 응답
type PasswordResetVerifyResponse struct {
	ResetToken string `json:"reset_token"`
}

// PasswordResetVerify godoc
// @Summary 비밀번호 재설정 인증코드 확인
// @Tags auth
// @Accept json
// @Produce json
// @Param request body PasswordResetVerifyRequest true "이메일과 인증코드"
// @Success 200 {object} PasswordResetVerifyResponse
// @Router /auth/password/reset-verify [post]
func (h *AuthHandler) PasswordResetVerify(c *fiber.Ctx) error {
	var req PasswordResetVerifyRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("PasswordResetVerify parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" || req.Code == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email and code are required",
		})
	}

	resetToken, err := h.authService.PasswordResetVerify(req.Email, req.Code)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(PasswordResetVerifyResponse{
		ResetToken: resetToken,
	})
}

// PasswordResetConfirmRequest 비밀번호 재설정 확정 요청
type PasswordResetConfirmRequest struct {
	Email       string `json:"email"`
	ResetToken  string `json:"reset_token"`
	NewPassword string `json:"new_password"`
}

// PasswordResetConfirm godoc
// @Summary 비밀번호 재설정 확정 (새 비밀번호 설정)
// @Tags auth
// @Accept json
// @Produce json
// @Param request body PasswordResetConfirmRequest true "이메일, Reset Token, 새 비밀번호"
// @Success 200 {object} map[string]string
// @Router /auth/password/reset-confirm [post]
func (h *AuthHandler) PasswordResetConfirm(c *fiber.Ctx) error {
	var req PasswordResetConfirmRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("PasswordResetConfirm parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.Email == "" || req.ResetToken == "" || req.NewPassword == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "email, reset_token and new_password are required",
		})
	}

	if err := h.authService.PasswordResetConfirm(req.Email, req.ResetToken, req.NewPassword); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "비밀번호가 성공적으로 변경되었습니다",
	})
}

// GetMe godoc
// @Summary 현재 사용자 정보 조회
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{}
// @Router /auth/me [get]
func (h *AuthHandler) GetMe(c *fiber.Ctx) error {
	// Authorization 헤더에서 토큰 추출
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "로그인이 필요합니다",
		})
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "잘못된 인증 형식입니다",
		})
	}

	token := parts[1]
	claims, err := auth.ValidateAccessToken(token, h.cfg.JWTSecretKey)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "로그인이 만료되었습니다. 다시 로그인해 주세요",
		})
	}

	user, err := h.authService.GetMe(claims.UserID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"error":   "사용자를 찾을 수 없습니다",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    user,
	})
}

// DeleteMe godoc
// @Summary 회원 탈퇴
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]string
// @Router /auth/me [delete]
func (h *AuthHandler) DeleteMe(c *fiber.Ctx) error {
	// Authorization 헤더에서 토큰 추출
	authHeader := c.Get("Authorization")
	if authHeader == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "로그인이 필요합니다",
		})
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "잘못된 인증 형식입니다",
		})
	}

	token := parts[1]
	claims, err := auth.ValidateAccessToken(token, h.cfg.JWTSecretKey)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "로그인이 만료되었습니다. 다시 로그인해 주세요",
		})
	}

	if err := h.authService.DeleteMe(claims.UserID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "회원 탈퇴 처리 중 오류가 발생했습니다",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "회원 탈퇴가 완료되었습니다",
	})
}

