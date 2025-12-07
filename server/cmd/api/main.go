package main

import (
	"context"

	"github.com/joho/godotenv"
	"go.uber.org/fx"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/module"
	"github.com/ggorockee/ojeomneo/server/pkg/logger"

	_ "github.com/ggorockee/ojeomneo/server/docs"
)

// @title Ojeomneo API
// @version 1.0.1
// @description Go Fiber v2 기반 REST API 서버 - 스케치 기반 메뉴 추천
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.email support@woohalabs.com

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host api.woohalabs.com
// @BasePath /ojeomneo/v1

// @schemes https http
func main() {
	// .env 파일 로드 (없어도 계속 진행)
	_ = godotenv.Load()

	// Uber-fx를 통한 의존성 주입 및 애플리케이션 초기화
	fx.New(
		// Config 제공
		fx.Provide(config.Load),

		// Logger 초기화
		fx.Provide(logger.NewLogger),

		// 데이터베이스 모듈
		module.DatabaseModule(),

		// Redis 모듈 (선택적)
		module.RedisModule(),

		// Redis 설정 제공
		fx.Provide(module.RedisConfigProvider),

		// OpenTelemetry 모듈
		module.TelemetryModule(),

		// Firebase 초기화 모듈
		module.FirebaseModule(),

		// 서비스 모듈
		module.ServiceModule(),
		module.RedisServiceModule(),

		// 핸들러 모듈
		module.HandlerModule(),

		// 서버 모듈 (Swagger 포함)
		module.ServerModule(),

		// 종료 시 로거 동기화
		fx.Invoke(func(lc fx.Lifecycle) {
			lc.Append(fx.Hook{
				OnStop: func(ctx context.Context) error {
					return logger.Sync()
				},
			})
		}),
	).Run()
}
