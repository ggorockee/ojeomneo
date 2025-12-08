package logger

import (
	"os"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var globalLogger *zap.Logger

// InitLogger 로거 초기화
func InitLogger(env string) (*zap.Logger, error) {
	var config zap.Config

	if env == "production" {
		config = zap.NewProductionConfig()
		config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
		config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
	} else {
		config = zap.NewDevelopmentConfig()
		config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
		config.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
	}

	// JSON 출력 (프로덕션) 또는 콘솔 출력 (개발)
	if env == "production" {
		config.Encoding = "json"
	} else {
		config.Encoding = "console"
	}

	logger, err := config.Build(
		zap.AddCaller(),
		zap.AddStacktrace(zapcore.ErrorLevel),
	)
	if err != nil {
		return nil, err
	}

	globalLogger = logger
	return logger, nil
}

// GetLogger 전역 로거 반환
func GetLogger() *zap.Logger {
	if globalLogger == nil {
		// 기본 로거 (fallback)
		logger, _ := zap.NewDevelopment()
		return logger
	}
	return globalLogger
}

// Sync 로거 버퍼 플러시 (Graceful shutdown 시 호출)
func Sync() error {
	if globalLogger != nil {
		return globalLogger.Sync()
	}
	return nil
}

// NewLogger 환경변수에서 로거 생성 (Uber-fx용)
func NewLogger() (*zap.Logger, error) {
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "development"
	}
	return InitLogger(env)
}

