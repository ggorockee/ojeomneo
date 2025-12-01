package config

import (
	"os"
)

// Config 애플리케이션 설정
type Config struct {
	AppEnv  string
	AppPort string

	DBHost     string
	DBPort     string
	DBName     string
	DBUser     string
	DBPassword string
}

// Load 환경변수에서 설정 로드
func Load() *Config {
	return &Config{
		AppEnv:  getEnv("APP_ENV", "development"),
		AppPort: getEnv("APP_PORT", "8080"),

		DBHost:     getEnv("DB_HOST", "localhost"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBName:     getEnv("DB_NAME", "woohalabs"),
		DBUser:     getEnv("DB_USER", "test"),
		DBPassword: getEnv("DB_PASSWORD", "test1234"),
	}
}

// getEnv 환경변수 조회 (기본값 지원)
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
