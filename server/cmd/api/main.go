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
// @version 1.0
// @description Go Fiber v2 기반 REST API 서버
// @host api.woohalabs.com
// @BasePath /woohalabs/v1
func main() {
	// .env 파일 로드
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found")
	}

	// 설정 로드
	cfg := config.Load()

	// 데이터베이스 연결
	db, err := config.ConnectDB(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Fiber 앱 생성
	app := fiber.New(fiber.Config{
		AppName: "Woohalabs API v1.0.0",
	})

	// 미들웨어 설정
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New())

	// Prometheus 메트릭 미들웨어
	app.Use(middleware.PrometheusMiddleware())

	// 메트릭 엔드포인트
	app.Get("/woohalabs/metrics", middleware.PrometheusHandler())

	// API v1 라우터
	v1 := app.Group("/woohalabs/v1")

	// Swagger 문서
	v1.Get("/docs/*", swagger.HandlerDefault)

	// 핸들러 등록
	healthHandler := handler.NewHealthHandler(db)
	v1.Get("/healthcheck", healthHandler.HealthCheck)

	// 서버 시작
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
