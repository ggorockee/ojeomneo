package module

import (
	"context"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/redis/go-redis/v9"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// RedisModule Redis 모듈 (선택적)
func RedisModule() fx.Option {
	return fx.Options(
		fx.Provide(
			func(cfg *config.Config, logger *zap.Logger) (*redis.Client, error) {
				rdb, err := config.ConnectRedis(cfg)
				if err != nil {
					logger.Warn("Failed to connect to redis",
						zap.Error(err),
						zap.String("host", cfg.RedisHost),
						zap.String("port", cfg.RedisPort),
					)
					// Redis는 선택적이므로 nil 반환
					return nil, nil
				}

				logger.Info("Redis connection established",
					zap.String("host", cfg.RedisHost),
					zap.String("port", cfg.RedisPort),
				)

				return rdb, nil
			},
		),
		fx.Invoke(
			func(lc fx.Lifecycle, rdb *redis.Client, logger *zap.Logger) {
				if rdb == nil {
					return
				}

				lc.Append(fx.Hook{
					OnStart: func(ctx context.Context) error {
						// 연결 테스트
						return rdb.Ping(ctx).Err()
					},
					OnStop: func(ctx context.Context) error {
						logger.Info("Closing Redis connection")
						return rdb.Close()
					},
				})
			},
		),
	)
}

