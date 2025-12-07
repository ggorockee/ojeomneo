package config

import (
	"os"
	"strconv"
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

	// Gemini 설정
	GeminiAPIKey string
	GeminiModel  string

	// OpenTelemetry 설정
	OTLPEndpoint string

	// Cloudflare Images 설정
	CloudflareAccountID   string
	CloudflareAccountHash string
	CloudflareAPIKey      string

	// Firebase Admin SDK 설정 (Google 로그인 토큰 검증용)
	FirebaseAdminSDKKey string

	// JWT 설정
	JWTSecretKey              string
	JWTAccessTokenExpireMin   int
	JWTRefreshTokenExpireDays int

	// SNS Login 설정
	AppleClientID  string
	AppleTeamID    string
	AppleKeyID     string
	KakaoRestAPIKey string
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

		GeminiAPIKey: getEnv("GEMINI_API_KEY", ""),
		GeminiModel:  getEnv("GEMINI_MODEL", "gemini-1.5-flash"),

		OTLPEndpoint: getEnv("OTEL_EXPORTER_OTLP_ENDPOINT", ""),

		CloudflareAccountID:   getEnv("CLOUDFLARE_ACCOUNT_ID", ""),
		CloudflareAccountHash: getEnv("CLOUDFLARE_ACCOUNT_HASH", ""),
		CloudflareAPIKey:      getEnv("CLOUDFLARE_API_KEY", ""),

		FirebaseAdminSDKKey: getEnv("FIREBASE_ADMIN_SDK_KEY", ""),

		JWTSecretKey:              getEnv("JWT_SECRET_KEY", ""),
		JWTAccessTokenExpireMin:   getEnvAsInt("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", 15),
		JWTRefreshTokenExpireDays: getEnvAsInt("JWT_REFRESH_TOKEN_EXPIRE_DAYS", 7),

		AppleClientID:   getEnv("APPLE_CLIENT_ID", ""),
		AppleTeamID:     getEnv("APPLE_TEAM_ID", ""),
		AppleKeyID:      getEnv("APPLE_KEY_ID", ""),
		KakaoRestAPIKey: getEnv("KAKAO_REST_API_KEY", ""),
	}
}

// getEnv 환경변수 조회 (기본값 지원)
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt 환경변수를 정수로 조회 (기본값 지원)
func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}
