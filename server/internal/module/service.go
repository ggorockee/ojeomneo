package module

import (
	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/service"
	"github.com/ggorockee/ojeomneo/server/internal/service/cloudflare"
	"github.com/ggorockee/ojeomneo/server/internal/service/llm"
	"github.com/ggorockee/ojeomneo/server/internal/telemetry"
	"go.uber.org/fx"
	"go.uber.org/zap"
	"gorm.io/gorm"

	"github.com/redis/go-redis/v9"
)

// ServiceModule 서비스 모듈
func ServiceModule() fx.Option {
	return fx.Options(
		// LLM 클라이언트
		fx.Provide(
			func(cfg *config.Config, logger *zap.Logger) *llm.Client {
				client := llm.NewClient(cfg.GeminiAPIKey, cfg.GeminiModel)
				if client.IsAvailable() {
					logger.Info("Gemini client initialized",
						zap.String("model", cfg.GeminiModel),
					)
				} else {
					logger.Warn("Gemini API key not configured, using mock responses")
				}
				return client
			},
		),
		// Cloudflare Images 클라이언트
		fx.Provide(
			func(cfg *config.Config, logger *zap.Logger) *cloudflare.ImagesClient {
				client := cloudflare.NewImagesClient(
					cfg.CloudflareAccountID,
					cfg.CloudflareAccountHash,
					cfg.CloudflareAPIKey,
				)
				if client.IsAvailable() {
					logger.Info("Cloudflare Images client initialized")
				} else {
					logger.Warn("Cloudflare Images not configured, image upload disabled")
				}
				return client
			},
		),
		// 서비스들 (의존성 자동 해결)
		fx.Provide(
			func(db *gorm.DB, logger *zap.Logger) *service.MenuService {
				return service.NewMenuService(db, logger)
			},
			func(db *gorm.DB, llmClient *llm.Client, menuService *service.MenuService, logger *zap.Logger) *service.SketchService {
				return service.NewSketchService(db, llmClient, menuService, logger)
			},
			func(db *gorm.DB, cfg *config.Config, logger *zap.Logger, metrics *telemetry.AuthMetrics) *service.AuthService {
				return service.NewAuthService(db, cfg, logger, metrics)
			},
		),
	)
}

// RedisServiceModule Redis 의존 서비스 모듈 (선택적)
func RedisServiceModule() fx.Option {
	return fx.Options(
		fx.Invoke(
			// Rate Limiting 및 Cache 미들웨어는 핸들러 모듈에서 처리
			func(rdb *redis.Client, logger *zap.Logger) {
				if rdb != nil {
					logger.Info("Redis services available")
				}
			},
		),
	)
}

