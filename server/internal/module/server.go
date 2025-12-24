package module

import (
	"context"
	"os"
	"time"

	"github.com/gofiber/contrib/otelfiber/v2"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	// "github.com/gofiber/fiber/v2/middleware/logger" // Zap JSON 로거 사용으로 비활성화
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/swagger"
	"github.com/ggorockee/ojeomneo/server/internal/config"
	"github.com/ggorockee/ojeomneo/server/internal/handler"
	"github.com/ggorockee/ojeomneo/server/internal/middleware"
	"github.com/ggorockee/ojeomneo/server/internal/telemetry"
	"go.uber.org/fx"
	"go.uber.org/zap"

	_ "github.com/ggorockee/ojeomneo/server/docs"
)

// ServerParams 서버 초기화 파라미터
type ServerParams struct {
	fx.In

	Config          *config.Config
	Logger          *zap.Logger
	HealthHandler   *handler.HealthHandler
	MenuHandler     *handler.MenuHandler
	SketchHandler   *handler.SketchHandler
	AppVersionHandler *handler.AppVersionHandler
	ImageHandler    *handler.ImageHandler
	AuthHandler     *handler.AuthHandler
	RedisConfig     RedisConfig
}

// ServerModule 서버 모듈
func ServerModule() fx.Option {
	return fx.Options(
		fx.Provide(
			func(params ServerParams) (*fiber.App, error) {
				// 에러 핸들러에 로거 주입
				handler.SetLogger(params.Logger)

				// Fiber 앱 생성
				app := fiber.New(fiber.Config{
					AppName:      "Ojeomneo API v1.0.0",
					ServerHeader: "Ojeomneo",
					ErrorHandler: handler.CustomErrorHandler,
					BodyLimit:    10 * 1024 * 1024, // 10MB
				})

				// 전역 미들웨어 설정
				app.Use(recover.New())

				// OpenTelemetry 트레이싱 미들웨어
				if params.Config.OTLPEndpoint != "" {
					app.Use(otelfiber.Middleware())
					params.Logger.Info("OpenTelemetry tracing middleware enabled")
				}

				// Zap 기반 로거 미들웨어 (비동기 처리)
				app.Use(func(c *fiber.Ctx) error {
					start := time.Now()
					err := c.Next()
					duration := time.Since(start)

					// Fiber context는 핸들러 종료 후 재사용되므로 goroutine에서 사용할 값들을 미리 캡처
					method := c.Method()
					path := c.Path()
					statusCode := c.Response().StatusCode()
					clientIP := c.IP()
					userAgent := c.Get("User-Agent")

					// 비동기로 로깅 (goroutine 사용)
					go func() {
						params.Logger.Info("HTTP Request",
							zap.String("method", method),
							zap.String("path", path),
							zap.Int("status", statusCode),
							zap.Duration("latency", duration),
							zap.String("ip", clientIP),
							zap.String("user_agent", userAgent),
						)
					}()

					return err
				})

				// Fiber 기본 로거 비활성화 - Zap JSON 로거만 사용 (Loki 파싱 일관성)
				// app.Use(logger.New(logger.Config{
				// 	Format:     "${time} | ${status} | ${latency} | ${ip} | ${method} | ${path}\n",
				// 	TimeFormat: "2006-01-02 15:04:05",
				// }))

				app.Use(cors.New(cors.Config{
					AllowOrigins: "*",
					AllowMethods: "GET,POST,PUT,DELETE,PATCH,OPTIONS",
					AllowHeaders: "Origin,Content-Type,Accept,Authorization",
				}))

				// /ojeomneo 그룹
				ojeomneo := app.Group("/ojeomneo")

				// Prometheus metrics 엔드포인트 (SigNoz scrape용)
				ojeomneo.Get("/metrics", middleware.PrometheusHandler())

				// API v1 라우터
				v1 := ojeomneo.Group("/v1")

				// Rate Limiting 미들웨어 (Redis 연결 시에만 활성화)
				if params.RedisConfig.RedisClient != nil {
					rateLimitCfg := middleware.DefaultRateLimitConfig()
					rateLimitCfg.RedisClient = params.RedisConfig.RedisClient
					v1.Use(middleware.RateLimiter(rateLimitCfg))
					params.Logger.Info("Rate Limiting middleware enabled")
				}

				// API 캐싱 미들웨어 (Redis 연결 시에만 활성화)
				if params.RedisConfig.RedisClient != nil {
					cacheCfg := middleware.DefaultCacheConfig()
					cacheCfg.RedisClient = params.RedisConfig.RedisClient
					v1.Use(middleware.Cache(cacheCfg))
					params.Logger.Info("API Cache middleware enabled")
				}

				// Prometheus 미들웨어
				v1.Use(middleware.PrometheusMiddleware())

				// Swagger 문서 - /ojeomneo/v1/docs (무조건 포함)
				v1.Get("/docs/*", swagger.New(swagger.Config{
					URL:          "/ojeomneo/v1/docs/doc.json",
					DeepLinking:  true,
					DocExpansion: "list",
					Title:        "Ojeomneo API Documentation",
				}))

				// Health Check 엔드포인트
				v1.Get("/healthcheck", params.HealthHandler.HealthCheck)
				v1.Get("/healthcheck/live", params.HealthHandler.LivenessCheck)
				v1.Get("/healthcheck/ready", params.HealthHandler.ReadinessCheck)

				// Auth 엔드포인트
				// 이메일 인증
				v1.Post("/auth/email/send-code", params.AuthHandler.SendEmailCode)
				v1.Post("/auth/email/verify-code", params.AuthHandler.VerifyEmailCode)
				// 회원가입/로그인
				v1.Post("/auth/signup", params.AuthHandler.Signup)
				v1.Post("/auth/login", params.AuthHandler.Login)
				v1.Post("/auth/refresh", params.AuthHandler.RefreshToken)
				// 비밀번호 재설정
				v1.Post("/auth/password/reset-request", params.AuthHandler.PasswordResetRequest)
				v1.Post("/auth/password/reset-verify", params.AuthHandler.PasswordResetVerify)
				v1.Post("/auth/password/reset-confirm", params.AuthHandler.PasswordResetConfirm)
				// 사용자 관리
				v1.Get("/auth/me", params.AuthHandler.GetMe)
				v1.Delete("/auth/me", params.AuthHandler.DeleteMe)
				// SNS 로그인
				v1.Post("/auth/google", params.AuthHandler.GoogleLogin)
				v1.Post("/auth/apple", params.AuthHandler.AppleLogin)
				v1.Post("/auth/kakao", params.AuthHandler.KakaoLogin)
				// 익명 로그인
				v1.Post("/auth/guest", params.AuthHandler.GuestLogin)

				// Menu 엔드포인트
				v1.Get("/menus", params.MenuHandler.List)
				v1.Get("/menus/categories", params.MenuHandler.GetCategories)
				v1.Get("/menus/:id", params.MenuHandler.GetByID)

				// Sketch 엔드포인트
				v1.Post("/sketch/analyze", params.SketchHandler.Analyze)
				v1.Get("/sketch/history", params.SketchHandler.GetHistory)
				v1.Get("/sketch/:id", params.SketchHandler.GetByID)

				// App 엔드포인트
				v1.Get("/app/version", params.AppVersionHandler.CheckVersion)

				// Image 엔드포인트
				v1.Post("/images/upload", params.ImageHandler.Upload)
				v1.Post("/images/upload-url", params.ImageHandler.UploadFromURL)
				v1.Delete("/images/:id", params.ImageHandler.Delete)

				return app, nil
			},
		),
		fx.Invoke(
			func(lc fx.Lifecycle, app *fiber.App, logger *zap.Logger) {
				lc.Append(fx.Hook{
					OnStart: func(ctx context.Context) error {
						// 비동기로 서버 시작 (goroutine 사용)
						go func() {
							port := os.Getenv("APP_PORT")
							if port == "" {
								port = "3000"
							}

							logger.Info("🚀 Server starting",
								zap.String("port", port),
								zap.String("env", os.Getenv("APP_ENV")),
							)
							logger.Info("📚 Swagger documentation",
								zap.String("url", "http://localhost:"+port+"/ojeomneo/v1/docs"),
							)
							logger.Info("📊 Metrics endpoint",
								zap.String("url", "http://localhost:"+port+"/ojeomneo/metrics"),
								zap.String("note", "internal only"),
							)
							logger.Info("🎨 Sketch API",
								zap.String("method", "POST"),
								zap.String("url", "http://localhost:"+port+"/ojeomneo/v1/sketch/analyze"),
							)
							logger.Info("🖼️ Image API",
								zap.String("method", "POST"),
								zap.String("url", "http://localhost:"+port+"/ojeomneo/v1/images/upload"),
							)

							if err := app.Listen(":" + port); err != nil {
								logger.Fatal("Failed to start server",
									zap.Error(err),
									zap.String("port", port),
								)
							}
						}()
						return nil
					},
					OnStop: func(ctx context.Context) error {
						logger.Info("Shutting down server...")
						return app.ShutdownWithContext(ctx)
					},
				})
			},
		),
	)
}

// TelemetryModule OpenTelemetry 모듈 (Metrics 포함)
func TelemetryModule() fx.Option {
	return fx.Options(
		// OpenTelemetry Providers 제공
		fx.Provide(
			func(lc fx.Lifecycle, cfg *config.Config, logger *zap.Logger) (*telemetry.Providers, error) {
				if cfg.OTLPEndpoint == "" {
					logger.Info("OpenTelemetry disabled (no OTLP endpoint configured)")
					return nil, nil
				}

				providers, err := telemetry.InitTelemetry(telemetry.Config{
					ServiceName:    "ojeomneo-server",
					ServiceVersion: "1.0.0",
					Environment:    cfg.AppEnv,
					OTLPEndpoint:   cfg.OTLPEndpoint,
				})
				if err != nil {
					logger.Warn("Failed to initialize OpenTelemetry",
						zap.Error(err),
						zap.String("endpoint", cfg.OTLPEndpoint),
					)
					return nil, nil // 선택적이므로 실패해도 계속 진행
				}

				// 종료 시 정리
				lc.Append(fx.Hook{
					OnStop: func(ctx context.Context) error {
						return providers.Shutdown(ctx)
					},
				})

				logger.Info("OpenTelemetry initialized",
					zap.String("endpoint", cfg.OTLPEndpoint),
					zap.String("service", "ojeomneo-server"),
				)

				return providers, nil
			},
		),
		// AuthMetrics 제공
		fx.Provide(
			func(providers *telemetry.Providers, logger *zap.Logger) (*telemetry.AuthMetrics, error) {
				if providers == nil || providers.MeterProvider == nil {
					return nil, nil
				}

				authMetrics, err := telemetry.RegisterAuthMetrics(providers.MeterProvider)
				if err != nil {
					logger.Warn("Failed to register auth metrics", zap.Error(err))
					return nil, nil
				}

				logger.Info("Auth metrics registered")
				return authMetrics, nil
			},
		),
		// HTTP Metrics 제공
		fx.Provide(
			func(providers *telemetry.Providers, logger *zap.Logger) (*telemetry.HTTPMetrics, error) {
				if providers == nil || providers.MeterProvider == nil {
					return nil, nil
				}

				requestCounter, latencyHistogram, err := telemetry.RegisterHTTPMetrics(providers.MeterProvider)
				if err != nil {
					logger.Warn("Failed to register HTTP metrics", zap.Error(err))
					return nil, nil
				}

				logger.Info("HTTP metrics registered")
				return &telemetry.HTTPMetrics{
					RequestCounter:   requestCounter,
					LatencyHistogram: latencyHistogram,
				}, nil
			},
		),
	)
}
