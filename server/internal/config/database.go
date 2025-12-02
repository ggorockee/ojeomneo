package config

import (
	"fmt"

	"github.com/ggorockee/ojeomneo/server/internal/model"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// ConnectDB PostgreSQL 데이터베이스 연결
func ConnectDB(cfg *Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable TimeZone=Asia/Seoul",
		cfg.DBHost,
		cfg.DBPort,
		cfg.DBUser,
		cfg.DBPassword,
		cfg.DBName,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// 연결 풀 설정
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)

	// AutoMigrate - 테이블 자동 생성/업데이트
	if err := db.AutoMigrate(&model.User{}); err != nil {
		return nil, fmt.Errorf("failed to auto migrate: %w", err)
	}

	// email + login_method 복합 unique constraint 추가
	// GORM에서 복합 unique index는 수동으로 추가
	if err := db.Exec(`
		CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_email_login_method
		ON users (email, login_method)
	`).Error; err != nil {
		return nil, fmt.Errorf("failed to create unique index: %w", err)
	}

	return db, nil
}
