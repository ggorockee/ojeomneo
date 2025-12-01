package handler

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// HealthHandler 헬스체크 핸들러
type HealthHandler struct {
	db *gorm.DB
}

// NewHealthHandler HealthHandler 생성자
func NewHealthHandler(db *gorm.DB) *HealthHandler {
	return &HealthHandler{db: db}
}

// HealthResponse 헬스체크 응답 구조체
// @Description 서버 헬스체크 응답
type HealthResponse struct {
	Status   string         `json:"status" example:"ok"`
	Service  string         `json:"service" example:"woohalabs-api"`
	Version  string         `json:"version" example:"1.0.0"`
	Database DatabaseStatus `json:"database"`
}

// DatabaseStatus 데이터베이스 상태
// @Description 데이터베이스 연결 상태
type DatabaseStatus struct {
	Connected bool   `json:"connected" example:"true"`
	LatencyMs int64  `json:"latency_ms" example:"5"`
	Message   string `json:"message,omitempty" example:"Database connection successful"`
}

// HealthCheck godoc
// @Summary 서버 헬스체크
// @Description 서버 및 데이터베이스 상태 확인
// @Tags Health
// @Accept json
// @Produce json
// @Success 200 {object} HealthResponse "서버 정상"
// @Failure 503 {object} HealthResponse "서버 비정상 (DB 연결 실패)"
// @Router /healthcheck [get]
func (h *HealthHandler) HealthCheck(c *fiber.Ctx) error {
	response := HealthResponse{
		Service: "woohalabs-api",
		Version: "1.0.0",
	}

	// DB가 nil인 경우 (연결 실패 상태로 시작된 경우)
	if h.db == nil {
		response.Status = "degraded"
		response.Database = DatabaseStatus{
			Connected: false,
			LatencyMs: 0,
			Message:   "Database not configured",
		}
		return c.Status(fiber.StatusServiceUnavailable).JSON(response)
	}

	// DB 연결 체크 및 레이턴시 측정
	start := time.Now()
	sqlDB, err := h.db.DB()

	if err != nil {
		response.Status = "degraded"
		response.Database = DatabaseStatus{
			Connected: false,
			LatencyMs: 0,
			Message:   "Failed to get database connection",
		}
		return c.Status(fiber.StatusServiceUnavailable).JSON(response)
	}

	// Ping 테스트
	err = sqlDB.Ping()
	latency := time.Since(start).Milliseconds()

	if err != nil {
		response.Status = "degraded"
		response.Database = DatabaseStatus{
			Connected: false,
			LatencyMs: latency,
			Message:   "Database ping failed: " + err.Error(),
		}
		return c.Status(fiber.StatusServiceUnavailable).JSON(response)
	}

	// 정상 응답
	response.Status = "ok"
	response.Database = DatabaseStatus{
		Connected: true,
		LatencyMs: latency,
		Message:   "Database connection successful",
	}

	return c.JSON(response)
}
