package main

import (
	"context"
	"log"
	"os"

	"github.com/gofiber/contrib/otelfiber/v2"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/swagger"
	"github.com/joho/godotenv"

	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/handler"
	"github.com/ggorockee/ojeomneo/server/internal/middleware"
	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/ggorockee/ojeomneo/server/internal/seed"
	"github.com/ggorockee/ojeomneo/server/internal/service"
	"github.com/ggorockee/ojeomneo/server/internal/service/llm"
	"github.com/ggorockee/ojeomneo/server/internal/telemetry"

	_ "github.com/ggorockee/ojeomneo/server/docs"
)

// @title Ojeomneo API
// @version 1.0.0
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
	// .env 파일 로드
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using environment variables")
	}

	// 설정 로드
	cfg := config.Load()

	// OpenTelemetry 초기화 (OTLP endpoint가 설정된 경우에만)
	if cfg.OTLPEndpoint != "" {
		shutdown, err := telemetry.InitTracer(telemetry.Config{
			ServiceName:    "ojeomneo-server",
			ServiceVersion: "1.0.0",
			Environment:    cfg.AppEnv,
			OTLPEndpoint:   cfg.OTLPEndpoint,
		})
		if err != nil {
			log.Printf("Warning: Failed to initialize OpenTelemetry: %v", err)
		} else {
			defer shutdown(context.Background())
		}
	}

	// 데이터베이스 연결
	db, err := config.ConnectDB(cfg)
	if err != nil {
		log.Printf("Warning: Failed to connect to database: %v", err)
		log.Println("Server will start without database connection")
	}

	// AutoMigrate (스키마 동기화)
	if db != nil {
		log.Println("Running database migrations...")
		if err := db.AutoMigrate(
			&model.User{},
			&model.Menu{},
			&model.Sketch{},
			&model.Recommendation{},
			&model.AppVersion{},
		); err != nil {
			log.Printf("Warning: Failed to run migrations: %v", err)
		} else {
			log.Println("Database migrations completed")
		}

		// 메뉴 시드 데이터 삽입 (SEED_DATA=true 일 때만)
		if os.Getenv("SEED_DATA") == "true" {
			log.Println("Seeding menu data...")
			if err := seed.SeedMenus(db); err != nil {
				log.Printf("Warning: Failed to seed menus: %v", err)
			}
		}
	}

	// Redis 연결
	rdb, err := config.ConnectRedis(cfg)
	if err != nil {
		log.Printf("Warning: Failed to connect to redis: %v", err)
		log.Println("Server will start without redis connection")
	} else {
		log.Println("Redis connection established")
		defer rdb.Close()
	}

	// LLM 클라이언트 초기화 (Gemini)
	llmClient := llm.NewClient(cfg.GeminiAPIKey, cfg.GeminiModel)
	if llmClient.IsAvailable() {
		log.Printf("Gemini client initialized (model: %s)", cfg.GeminiModel)
	} else {
		log.Println("Warning: Gemini API key not configured, using mock responses")
	}

	// 서비스 초기화
	menuService := service.NewMenuService(db)
	sketchService := service.NewSketchService(db, llmClient, menuService)

	// Fiber 앱 생성
	app := fiber.New(fiber.Config{
		AppName:      "Ojeomneo API v1.0.0",
		ServerHeader: "Ojeomneo",
		ErrorHandler: handler.CustomErrorHandler,
		BodyLimit:    10 * 1024 * 1024, // 10MB (스케치 이미지 업로드용)
	})

	// 전역 미들웨어 설정
	app.Use(recover.New())

	// OpenTelemetry 트레이싱 미들웨어 (OTLP endpoint가 설정된 경우에만)
	if cfg.OTLPEndpoint != "" {
		app.Use(otelfiber.Middleware())
		log.Println("OpenTelemetry tracing middleware enabled")
	}

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
	// /ojeomneo 그룹 (Ingress에서 전달받는 prefix)
	// Swagger 정적 파일 로딩 문제 방지를 위해 Fiber에서 전체 경로 처리
	// ============================================
	ojeomneo := app.Group("/ojeomneo")

	// Prometheus 메트릭 (내부망 접근 제한)
	ojeomneo.Get("/metrics", middleware.InternalOnly(), middleware.PrometheusHandler())

	// API v1 라우터
	v1 := ojeomneo.Group("/v1")

	// Rate Limiting 미들웨어 (Redis 연결 시에만 활성화)
	if rdb != nil {
		rateLimitCfg := middleware.DefaultRateLimitConfig()
		rateLimitCfg.RedisClient = rdb
		v1.Use(middleware.RateLimiter(rateLimitCfg))
		log.Println("Rate Limiting middleware enabled")
	}

	// API 캐싱 미들웨어 (Redis 연결 시에만 활성화)
	if rdb != nil {
		cacheCfg := middleware.DefaultCacheConfig()
		cacheCfg.RedisClient = rdb
		v1.Use(middleware.Cache(cacheCfg))
		log.Println("API Cache middleware enabled")
	}

	// Prometheus 미들웨어 (API 요청만 측정)
	v1.Use(middleware.PrometheusMiddleware())

	// Swagger 문서 - /ojeomneo/v1/docs
	v1.Get("/docs/*", swagger.New(swagger.Config{
		URL:          "/ojeomneo/v1/docs/doc.json",
		DeepLinking:  true,
		DocExpansion: "list",
		Title:        "Ojeomneo API Documentation",
	}))

	// 핸들러 초기화
	healthHandler := handler.NewHealthHandler(db)
	menuHandler := handler.NewMenuHandler(menuService)
	sketchHandler := handler.NewSketchHandler(sketchService)
	appVersionHandler := handler.NewAppVersionHandler(db)

	// Health Check 엔드포인트
	// /ojeomneo/v1/healthcheck - 상세 상태 (모니터링용, 항상 200)
	// /ojeomneo/v1/healthcheck/live - Kubernetes startup/liveness probe용 (항상 200)
	// /ojeomneo/v1/healthcheck/ready - Kubernetes readiness probe용 (DB 연결 시 200)
	v1.Get("/healthcheck", healthHandler.HealthCheck)
	v1.Get("/healthcheck/live", healthHandler.LivenessCheck)
	v1.Get("/healthcheck/ready", healthHandler.ReadinessCheck)

	// Menu 엔드포인트
	v1.Get("/menus", menuHandler.List)
	v1.Get("/menus/categories", menuHandler.GetCategories)
	v1.Get("/menus/:id", menuHandler.GetByID)

	// Sketch 엔드포인트
	v1.Post("/sketch/analyze", sketchHandler.Analyze)
	v1.Get("/sketch/history", sketchHandler.GetHistory)
	v1.Get("/sketch/:id", sketchHandler.GetByID)

	// App 엔드포인트
	v1.Get("/app/version", appVersionHandler.CheckVersion)

	// 서버 시작
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "3000"
	}

	log.Printf("🚀 Server starting on port %s", port)
	log.Printf("📚 Swagger: http://localhost:%s/ojeomneo/v1/docs", port)
	log.Printf("📊 Metrics: http://localhost:%s/ojeomneo/metrics (internal only)", port)
	log.Printf("🎨 Sketch API: POST http://localhost:%s/ojeomneo/v1/sketch/analyze", port)

	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
