package module

import (
	"context"
	"os"
	"time"

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

				// Register database metrics plugin for Prometheus monitoring
				// Tracks: query duration, query count, errors, slow queries (>1s)
				// Labels: operation (SELECT/INSERT/UPDATE/DELETE), table, status
				if err := db.Use(&DBMetricsPlugin{}); err != nil {
					logger.Warn("Failed to register database metrics plugin", zap.Error(err))
				} else {
					logger.Info("Database metrics plugin registered")
				}

				// Configure connection pool
				sqlDB, err := db.DB()
				if err == nil {
					sqlDB.SetMaxOpenConns(25)
					sqlDB.SetMaxIdleConns(5)
					sqlDB.SetConnMaxLifetime(300)
					logger.Info("Database connection pool configured")
				}

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

						// Start connection pool metrics collector (background goroutine)
						// Collects every 30 seconds: pool size, idle connections, in-use connections
						// Enables real-time monitoring of database connection pool health
						go StartConnectionPoolMetricsCollector(ctx, db, 30*time.Second)
						logger.Info("Database connection pool metrics collector started")

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

