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

	RedisHost     string
	RedisPort     string
	RedisPassword string

	// OpenAI 설정
	OpenAIAPIKey string
	OpenAIModel  string
}

// Load 환경변수에서 설정 로드
// Kubernetes Secret 키 이름에 맞춰 POSTGRES_*, REDIS_* 형식 사용
func Load() *Config {
	return &Config{
		AppEnv:  getEnv("APP_ENV", "development"),
		AppPort: getEnv("APP_PORT", "3000"),

		DBHost:     getEnv("POSTGRES_SERVER", "localhost"),
		DBPort:     getEnv("POSTGRES_PORT", "5432"),
		DBName:     getEnv("POSTGRES_DB", "ojeomneo"),
		DBUser:     getEnv("POSTGRES_USER", "ojeomneo"),
		DBPassword: getEnv("POSTGRES_PASSWORD", ""),

		RedisHost:     getEnv("REDIS_HOST", "localhost"),
		RedisPort:     getEnv("REDIS_PORT", "6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),

		OpenAIAPIKey: getEnv("OPENAI_API_KEY", ""),
		OpenAIModel:  getEnv("OPENAI_MODEL", "gpt-4o-mini"),
	}
}

// getEnv 환경변수 조회 (기본값 지원)
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
