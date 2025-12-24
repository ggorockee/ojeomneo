package middleware

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/redis/go-redis/v9"
)

var (
	// 캐시 메트릭
	// TODO: path label이 동시 요청 시 Prometheus 중복 수집 문제 발생
	// 향후 label 없는 전체 counter로 변경 또는 aggregation 방식 개선 필요
	// cacheHits = promauto.NewCounterVec(
	// 	prometheus.CounterOpts{
	// 		Name: "ojeomneo_cache_hits_total",
	// 		Help: "Total number of cache hits",
	// 	},
	// 	[]string{"path"},
	// )

	// cacheMisses = promauto.NewCounterVec(
	// 	prometheus.CounterOpts{
	// 		Name: "ojeomneo_cache_misses_total",
	// 		Help: "Total number of cache misses",
	// 	},
	// 	[]string{"path"},
	// )

	cacheLatency = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "ojeomneo_cache_operation_duration_seconds",
			Help:    "Cache operation latency in seconds",
			Buckets: []float64{.001, .005, .01, .025, .05, .1},
		},
		[]string{"operation"}, // get, set
	)
)

// CacheConfig 캐시 설정
type CacheConfig struct {
	// 기본 TTL (기본: 5분)
	DefaultTTL time.Duration
	// 경로별 TTL 설정
	PathTTL map[string]time.Duration
	// 캐시 제외 경로
	SkipPaths []string
	// 캐시 가능한 HTTP 메서드 (기본: GET만)
	Methods []string
	// Redis 클라이언트
	RedisClient *redis.Client
	// 캐시 키 prefix
	KeyPrefix string
}

// CachedResponse 캐시된 응답
type CachedResponse struct {
	StatusCode  int               `json:"statusCode"`
	Body        []byte            `json:"body"`
	ContentType string            `json:"contentType"`
	Headers     map[string]string `json:"headers"`
	CachedAt    int64             `json:"cachedAt"`
}

// DefaultCacheConfig 기본 설정
func DefaultCacheConfig() CacheConfig {
	return CacheConfig{
		DefaultTTL: 5 * time.Minute,
		PathTTL: map[string]time.Duration{
			"/ojeomneo/v1/config":   30 * time.Minute, // 설정은 오래 캐시
			"/ojeomneo/v1/menu":     10 * time.Minute, // 메뉴 데이터
			"/ojeomneo/v1/category": 15 * time.Minute, // 카테고리
		},
		SkipPaths: []string{
			"/ojeomneo/v1/healthcheck",
			"/ojeomneo/v1/docs",
			"/ojeomneo/metrics",
		},
		Methods:   []string{"GET"},
		KeyPrefix: "cache:api",
	}
}

// Cache Redis 기반 API 캐싱 미들웨어
func Cache(config ...CacheConfig) fiber.Handler {
	cfg := DefaultCacheConfig()
	if len(config) > 0 {
		cfg = config[0]
	}

	return func(c *fiber.Ctx) error {
		// Redis 클라이언트가 없으면 통과
		if cfg.RedisClient == nil {
			return c.Next()
		}

		// 캐시 가능한 메서드인지 확인
		method := c.Method()
		methodAllowed := false
		for _, m := range cfg.Methods {
			if m == method {
				methodAllowed = true
				break
			}
		}
		if !methodAllowed {
			return c.Next()
		}

		// 제외 경로 체크
		path := c.Path()
		for _, skipPath := range cfg.SkipPaths {
			if strings.HasPrefix(path, skipPath) {
				return c.Next()
			}
		}

		// Cache-Control: no-cache 헤더 체크
		if c.Get("Cache-Control") == "no-cache" {
			return c.Next()
		}

		// 캐시 키 생성 (경로 + 쿼리스트링)
		cacheKey := generateCacheKey(cfg.KeyPrefix, path, c.Request().URI().QueryString())

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		// 캐시 조회
		start := time.Now()
		cached, err := cfg.RedisClient.Get(ctx, cacheKey).Bytes()
		cacheLatency.WithLabelValues("get").Observe(time.Since(start).Seconds())

		if err == nil && len(cached) > 0 {
			// 캐시 히트
			var response CachedResponse
			if err := json.Unmarshal(cached, &response); err == nil {
				// TODO: path label이 동시 요청 시 Prometheus 중복 수집 문제 발생 가능
				// 일단 path label 제거하고 전체 count만 추적
				// cacheHits.WithLabelValues(path).Inc()

				// 캐시된 헤더 설정
				for key, value := range response.Headers {
					c.Set(key, value)
				}
				c.Set("X-Cache", "HIT")
				c.Set("X-Cache-Age", fmt.Sprintf("%d", time.Now().Unix()-response.CachedAt))
				c.Set("Content-Type", response.ContentType)

				return c.Status(response.StatusCode).Send(response.Body)
			}
		}

		// 캐시 미스 - 다음 핸들러 실행
		// TODO: path label이 동시 요청 시 Prometheus 중복 수집 문제 발생 가능
		// cacheMisses.WithLabelValues(path).Inc()

		err = c.Next()
		if err != nil {
			return err
		}

		// 성공 응답만 캐시 (2xx)
		statusCode := c.Response().StatusCode()
		if statusCode < 200 || statusCode >= 300 {
			return nil
		}

		// 응답 캐시
		ttl := cfg.DefaultTTL
		for pathPrefix, pathTTL := range cfg.PathTTL {
			if strings.HasPrefix(path, pathPrefix) {
				ttl = pathTTL
				break
			}
		}

		response := CachedResponse{
			StatusCode:  statusCode,
			Body:        c.Response().Body(),
			ContentType: string(c.Response().Header.ContentType()),
			Headers:     make(map[string]string),
			CachedAt:    time.Now().Unix(),
		}

		// 캐시할 헤더 복사
		headersToCache := []string{"Content-Encoding", "Vary"}
		for _, h := range headersToCache {
			if v := string(c.Response().Header.Peek(h)); v != "" {
				response.Headers[h] = v
			}
		}

		// 캐시 저장
		if data, err := json.Marshal(response); err == nil {
			start := time.Now()
			cfg.RedisClient.Set(ctx, cacheKey, data, ttl)
			cacheLatency.WithLabelValues("set").Observe(time.Since(start).Seconds())
		}

		c.Set("X-Cache", "MISS")

		return nil
	}
}

// generateCacheKey 캐시 키 생성
func generateCacheKey(prefix, path string, query []byte) string {
	hash := sha256.New()
	hash.Write([]byte(path))
	hash.Write(query)
	return fmt.Sprintf("%s:%s", prefix, hex.EncodeToString(hash.Sum(nil))[:16])
}

// CacheInvalidator 캐시 무효화 헬퍼
type CacheInvalidator struct {
	client    *redis.Client
	keyPrefix string
}

// NewCacheInvalidator 캐시 무효화 헬퍼 생성
func NewCacheInvalidator(client *redis.Client, keyPrefix string) *CacheInvalidator {
	return &CacheInvalidator{
		client:    client,
		keyPrefix: keyPrefix,
	}
}

// InvalidatePattern 패턴 기반 캐시 무효화
func (ci *CacheInvalidator) InvalidatePattern(ctx context.Context, pattern string) error {
	if ci.client == nil {
		return nil
	}

	fullPattern := fmt.Sprintf("%s:%s*", ci.keyPrefix, pattern)
	iter := ci.client.Scan(ctx, 0, fullPattern, 100).Iterator()

	var keys []string
	for iter.Next(ctx) {
		keys = append(keys, iter.Val())
	}

	if len(keys) > 0 {
		return ci.client.Del(ctx, keys...).Err()
	}

	return iter.Err()
}
