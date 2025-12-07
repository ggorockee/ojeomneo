package handler

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"go.uber.org/zap"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/service"
)

// AuthHandler 인증 핸들러
type AuthHandler struct {
	authService *service.AuthService
	cfg         *config.Config
	logger      *zap.Logger
}

// NewAuthHandler 새 인증 핸들러 생성
func NewAuthHandler(authService *service.AuthService, cfg *config.Config, logger *zap.Logger) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		cfg:         cfg,
		logger:      logger,
	}
}

// GoogleLoginRequest Google 로그인 요청 DTO
type GoogleLoginRequest struct {
	IDToken string `json:"id_token"`
}

// GoogleLogin godoc
// @Summary Google 로그인 (Firebase ID Token 사용)
// @Description Firebase ID Token을 검증하고 사용자를 인증합니다
// @Tags auth
// @Accept json
// @Produce json
// @Param request body GoogleLoginRequest true "Google 로그인 요청"
// @Success 200 {object} service.AuthResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /auth/google [post]
func (h *AuthHandler) GoogleLogin(c *fiber.Ctx) error {
	start := time.Now()

	var req GoogleLoginRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("Google login request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
			zap.String("user_agent", c.Get("User-Agent")),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.IDToken == "" {
		h.logger.Warn("Google login missing token",
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "id_token is required",
		})
	}

	result, err := h.authService.GoogleLogin(req.IDToken)
	duration := time.Since(start)

	if err != nil {
		// 비동기로 로깅 (goroutine 사용)
		go func() {
			h.logger.Warn("Google login failed",
				zap.Error(err),
				zap.String("provider", "google"),
				zap.String("ip", c.IP()),
				zap.String("user_agent", c.Get("User-Agent")),
				zap.Duration("duration", duration),
			)
		}()

		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	// 비동기로 성공 로깅 (goroutine 사용)
	go func() {
		h.logger.Info("Google login successful",
			zap.String("provider", "google"),
			zap.Uint("user_id", result.User.ID),
			zap.String("email", result.User.Email),
			zap.String("ip", c.IP()),
			zap.Duration("duration", duration),
		)
	}()

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

// AppleLoginRequest Apple 로그인 요청 DTO
type AppleLoginRequest struct {
	IdentityToken string `json:"identity_token"`
}

// AppleLogin godoc
// @Summary Apple 로그인
// @Description Apple Identity Token을 검증하고 사용자를 인증합니다
// @Tags auth
// @Accept json
// @Produce json
// @Param request body AppleLoginRequest true "Apple 로그인 요청"
// @Success 200 {object} service.AuthResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /auth/apple [post]
func (h *AuthHandler) AppleLogin(c *fiber.Ctx) error {
	start := time.Now()

	var req AppleLoginRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("Apple login request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.IdentityToken == "" {
		h.logger.Warn("Apple login missing token",
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "identity_token is required",
		})
	}

	result, err := h.authService.AppleLogin(req.IdentityToken)
	duration := time.Since(start)

	if err != nil {
		go func() {
			h.logger.Warn("Apple login failed",
				zap.Error(err),
				zap.String("provider", "apple"),
				zap.String("ip", c.IP()),
				zap.Duration("duration", duration),
			)
		}()

		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	go func() {
		h.logger.Info("Apple login successful",
			zap.String("provider", "apple"),
			zap.Uint("user_id", result.User.ID),
			zap.String("email", result.User.Email),
			zap.String("ip", c.IP()),
			zap.Duration("duration", duration),
		)
	}()

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

// KakaoLoginRequest Kakao 로그인 요청 DTO
type KakaoLoginRequest struct {
	AccessToken string `json:"access_token"`
}

// KakaoLogin godoc
// @Summary Kakao 로그인
// @Description Kakao Access Token을 검증하고 사용자를 인증합니다
// @Tags auth
// @Accept json
// @Produce json
// @Param request body KakaoLoginRequest true "Kakao 로그인 요청"
// @Success 200 {object} service.AuthResponse
// @Failure 400 {object} map[string]interface{}
// @Failure 401 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /auth/kakao [post]
func (h *AuthHandler) KakaoLogin(c *fiber.Ctx) error {
	start := time.Now()

	var req KakaoLoginRequest
	if err := c.BodyParser(&req); err != nil {
		h.logger.Warn("Kakao login request parse failed",
			zap.Error(err),
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid request body",
		})
	}

	if req.AccessToken == "" {
		h.logger.Warn("Kakao login missing token",
			zap.String("ip", c.IP()),
		)
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "access_token is required",
		})
	}

	result, err := h.authService.KakaoLogin(req.AccessToken)
	duration := time.Since(start)

	if err != nil {
		go func() {
			h.logger.Warn("Kakao login failed",
				zap.Error(err),
				zap.String("provider", "kakao"),
				zap.String("ip", c.IP()),
				zap.Duration("duration", duration),
			)
		}()

		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	go func() {
		h.logger.Info("Kakao login successful",
			zap.String("provider", "kakao"),
			zap.Uint("user_id", result.User.ID),
			zap.String("email", result.User.Email),
			zap.String("ip", c.IP()),
			zap.Duration("duration", duration),
		)
	}()

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}
