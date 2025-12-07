package module

import (
	"context"
	"os"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/ggorockee/ojeomneo/server/internal/seed"
	"go.uber.org/fx"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// DatabaseModule 데이터베이스 모듈
func DatabaseModule() fx.Option {
	return fx.Options(
		fx.Provide(
			func(cfg *config.Config, logger *zap.Logger) (*gorm.DB, error) {
				db, err := config.ConnectDB(cfg)
				if err != nil {
					logger.Warn("Failed to connect to database",
						zap.Error(err),
						zap.String("host", cfg.DBHost),
						zap.String("database", cfg.DBName),
					)
					return nil, err
				}

				logger.Info("Database connected",
					zap.String("host", cfg.DBHost),
					zap.String("database", cfg.DBName),
				)

				return db, nil
			},
		),
		fx.Invoke(
			func(lc fx.Lifecycle, db *gorm.DB, logger *zap.Logger) {
				lc.Append(fx.Hook{
					OnStart: func(ctx context.Context) error {
						// AutoMigrate 실행
						logger.Info("Running database migrations...")
						models := []interface{}{
							&model.User{},
							&model.Menu{},
							&model.MenuImage{},
							&model.Sketch{},
							&model.Recommendation{},
							&model.AppVersion{},
						}

						if err := db.AutoMigrate(models...); err != nil {
							logger.Error("Failed to run migrations",
								zap.Error(err),
							)
							return err
						}

						logger.Info("Database migrations completed")

						// 시드 데이터 삽입 (SEED_DATA=true 일 때만)
						if os.Getenv("SEED_DATA") == "true" {
							logger.Info("Seeding menu data...")
							if err := seed.SeedMenus(db); err != nil {
								logger.Warn("Failed to seed menus",
									zap.Error(err),
								)
								// 시드 실패는 치명적이지 않음
							} else {
								logger.Info("Menu data seeded successfully")
							}
						}

						return nil
					},
					OnStop: func(ctx context.Context) error {
						sqlDB, err := db.DB()
						if err != nil {
							return err
						}
						return sqlDB.Close()
					},
				})
			},
		),
	)
}

