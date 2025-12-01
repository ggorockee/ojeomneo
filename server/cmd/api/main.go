package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/swagger"
	"github.com/joho/godotenv"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/handler"
	"github.com/ggorockee/ojeomneo/server/internal/middleware"

	_ "github.com/ggorockee/ojeomneo/server/docs"
)

// @title Woohalabs API
// @version 1.0.0
// @description Go Fiber v2 기반 REST API 서버
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.email support@woohalabs.com

// @license.name Apache 2.0
// @license.url http://www.apache.org/licenses/LICENSE-2.0.html

// @host api.woohalabs.com
// @BasePath /woohalabs/v1

// @schemes https http
func main() {
	// .env 파일 로드
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// 설정 로드
	cfg := config.Load()

	// 데이터베이스 연결
	db, err := config.ConnectDB(cfg)
	if err != nil {
		log.Printf("Warning: Failed to connect to database: %v", err)
		log.Println("Server will start without database connection")
	}

	// Fiber 앱 생성
	app := fiber.New(fiber.Config{
		AppName:      "Woohalabs API v1.0.0",
		ServerHeader: "Woohalabs",
		ErrorHandler: handler.CustomErrorHandler,
	})

	// 전역 미들웨어 설정
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format:     "${time} | ${status} | ${latency} | ${ip} | ${method} | ${path}\n",
		TimeFormat: "2006-01-02 15:04:05",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,PATCH,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	// ============================================
	// /woohalabs 그룹 (Ingress에서 전달받는 prefix)
	// Swagger 정적 파일 로딩 문제 방지를 위해 Fiber에서 전체 경로 처리
	// ============================================
	woohalabs := app.Group("/woohalabs")

	// Prometheus 메트릭 (내부망 접근 제한)
	woohalabs.Get("/metrics", middleware.InternalOnly(), middleware.PrometheusHandler())

	// API v1 라우터
	v1 := woohalabs.Group("/v1")

	// Prometheus 미들웨어 (API 요청만 측정)
	v1.Use(middleware.PrometheusMiddleware())

	// Swagger 문서 - /woohalabs/v1/docs
	v1.Get("/docs/*", swagger.New(swagger.Config{
		URL:          "/woohalabs/v1/docs/doc.json",
		DeepLinking:  true,
		DocExpansion: "list",
		Title:        "Woohalabs API Documentation",
	}))

	// 핸들러 등록
	healthHandler := handler.NewHealthHandler(db)

	// Health Check 엔드포인트
	// /woohalabs/v1/healthcheck - 상세 상태 (모니터링용, 항상 200)
	// /woohalabs/v1/healthcheck/live - Kubernetes startup/liveness probe용 (항상 200)
	// /woohalabs/v1/healthcheck/ready - Kubernetes readiness probe용 (DB 연결 시 200)
	v1.Get("/healthcheck", healthHandler.HealthCheck)
	v1.Get("/healthcheck/live", healthHandler.LivenessCheck)
	v1.Get("/healthcheck/ready", healthHandler.ReadinessCheck)

	// 서버 시작
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📚 Swagger: http://localhost:%s/woohalabs/v1/docs", port)
	log.Printf("📊 Metrics: http://localhost:%s/woohalabs/metrics (internal only)", port)

	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
