package module

import (
	"context"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/pkg/sns"
	"go.uber.org/fx"
	"go.uber.org/zap"
)

// FirebaseModule Firebase 초기화 모듈
func FirebaseModule() fx.Option {
	return fx.Options(
		fx.Invoke(
			func(lc fx.Lifecycle, cfg *config.Config, logger *zap.Logger) {
				lc.Append(fx.Hook{
					OnStart: func(ctx context.Context) error {
						if cfg.FirebaseAdminSDKKey == "" {
							logger.Warn("Firebase Admin SDK key not configured, Google login will not work")
							return nil
						}

						// Firebase 초기화
						if err := sns.InitFirebase(cfg.FirebaseAdminSDKKey); err != nil {
							logger.Error("Failed to initialize Firebase Admin SDK",
								zap.Error(err),
							)
							return err
						}

						logger.Info("Firebase Admin SDK initialized successfully")
						return nil
					},
				})
			},
		),
	)
}

