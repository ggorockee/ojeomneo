package middleware

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/redis/go-redis/v9"
)

var (
	// Rate Limit 메트릭
	rateLimitTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "ojeomneo_ratelimit_requests_total",
			Help: "Total number of rate limited requests",
		},
		[]string{"status"}, // allowed, limited
	)

	rateLimitRemaining = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "ojeomneo_ratelimit_remaining",
			Help: "Remaining requests in current window",
		},
		[]string{"ip"},
	)
)

// RateLimitConfig Rate Limiting 설정
type RateLimitConfig struct {
	// 윈도우 시간 (기본: 1분)
	Window time.Duration
	// 윈도우 내 최대 요청 수 (기본: 100)
	Max int
	// Rate Limit 초과 시 응답 메시지
	Message string
	// 제외할 경로 (healthcheck 등)
	SkipPaths []string
	// Redis 클라이언트
	RedisClient *redis.Client
}

// DefaultRateLimitConfig 기본 설정
func DefaultRateLimitConfig() RateLimitConfig {
	return RateLimitConfig{
		Window:  1 * time.Minute,
		Max:     100,
		Message: "Too many requests. Please try again later.",
		SkipPaths: []string{
			"/ojeomneo/v1/healthcheck",
			"/ojeomneo/v1/healthcheck/live",
			"/ojeomneo/v1/healthcheck/ready",
			"/ojeomneo/v1/docs",
			"/ojeomneo/metrics",
		},
	}
}

// RateLimiter Redis 기반 Rate Limiting 미들웨어
// Sliding Window Log 알고리즘 사용
func RateLimiter(config ...RateLimitConfig) fiber.Handler {
	cfg := DefaultRateLimitConfig()
	if len(config) > 0 {
		cfg = config[0]
	}

	return func(c *fiber.Ctx) error {
		// Redis 클라이언트가 없으면 통과
		if cfg.RedisClient == nil {
			return c.Next()
		}

		// 제외 경로 체크
		path := c.Path()
		for _, skipPath := range cfg.SkipPaths {
			if len(path) >= len(skipPath) && path[:len(skipPath)] == skipPath {
				return c.Next()
			}
		}

		// 클라이언트 IP 추출
		clientIP := c.IP()
		if realIP := c.Get("X-Real-IP"); realIP != "" {
			clientIP = realIP
		}
		if forwardedFor := c.Get("X-Forwarded-For"); forwardedFor != "" {
			clientIP = forwardedFor
		}

		// Rate Limit 키
		key := fmt.Sprintf("ratelimit:api:%s", clientIP)
		now := time.Now()
		windowStart := now.Add(-cfg.Window)

		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()

		// Sliding Window Log 알고리즘
		// 1. 윈도우 밖의 오래된 요청 제거
		// 2. 현재 요청 추가
		// 3. 윈도우 내 요청 수 확인
		pipe := cfg.RedisClient.Pipeline()

		// 윈도우 밖 요청 제거
		pipe.ZRemRangeByScore(ctx, key, "0", strconv.FormatInt(windowStart.UnixNano(), 10))

		// 현재 요청 추가
		pipe.ZAdd(ctx, key, redis.Z{
			Score:  float64(now.UnixNano()),
			Member: fmt.Sprintf("%d", now.UnixNano()),
		})

		// 현재 윈도우 내 요청 수 조회
		countCmd := pipe.ZCard(ctx, key)

		// TTL 설정 (윈도우 시간 + 여유)
		pipe.Expire(ctx, key, cfg.Window+time.Minute)

		// 파이프라인 실행
		_, err := pipe.Exec(ctx)
		if err != nil {
			// Redis 오류 시 통과 (fail-open)
			return c.Next()
		}

		count := countCmd.Val()
		remaining := int64(cfg.Max) - count

		// Rate Limit 헤더 설정
		c.Set("X-RateLimit-Limit", strconv.Itoa(cfg.Max))
		c.Set("X-RateLimit-Remaining", strconv.FormatInt(max(0, remaining), 10))
		c.Set("X-RateLimit-Reset", strconv.FormatInt(now.Add(cfg.Window).Unix(), 10))

		// 메트릭 업데이트
		// TODO: IP label이 동시 요청 시 Prometheus 중복 수집 문제 발생
		// rateLimitRemaining.WithLabelValues(clientIP).Set(float64(max(0, remaining)))

		// Rate Limit 초과 체크
		if count > int64(cfg.Max) {
			rateLimitTotal.WithLabelValues("limited").Inc()

			retryAfter := int(cfg.Window.Seconds())
			c.Set("Retry-After", strconv.Itoa(retryAfter))

			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"success": false,
				"error": fiber.Map{
					"code":       "RATE_LIMIT_EXCEEDED",
					"message":    cfg.Message,
					"retryAfter": retryAfter,
				},
			})
		}

		rateLimitTotal.WithLabelValues("allowed").Inc()
		return c.Next()
	}
}
