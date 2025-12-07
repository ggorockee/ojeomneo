package module

import (
	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/handler"
	"github.com/ggorockee/ojeomneo/server/internal/service"
	"github.com/ggorockee/ojeomneo/server/internal/service/cloudflare"
	"go.uber.org/fx"
	"go.uber.org/zap"
	"gorm.io/gorm"

	"github.com/redis/go-redis/v9"
)

// HandlerModule 핸들러 모듈
func HandlerModule() fx.Option {
	return fx.Options(
		fx.Provide(
			func(db *gorm.DB, logger *zap.Logger) *handler.HealthHandler {
				return handler.NewHealthHandler(db, logger)
			},
			func(menuService *service.MenuService, logger *zap.Logger) *handler.MenuHandler {
				return handler.NewMenuHandler(menuService, logger)
			},
			func(sketchService *service.SketchService, logger *zap.Logger) *handler.SketchHandler {
				return handler.NewSketchHandler(sketchService, logger)
			},
			func(db *gorm.DB, logger *zap.Logger) *handler.AppVersionHandler {
				return handler.NewAppVersionHandler(db, logger)
			},
			func(cfImages *cloudflare.ImagesClient, logger *zap.Logger) *handler.ImageHandler {
				return handler.NewImageHandler(cfImages, logger)
			},
			func(authService *service.AuthService, cfg *config.Config, logger *zap.Logger) *handler.AuthHandler {
				return handler.NewAuthHandler(authService, cfg, logger)
			},
		),
	)
}

// RedisConfig Redis 설정 (미들웨어용)
type RedisConfig struct {
	RedisClient *redis.Client
}

// RedisConfigProvider Redis 설정 제공자
func RedisConfigProvider(rdb *redis.Client) RedisConfig {
	return RedisConfig{
		RedisClient: rdb,
	}
}

