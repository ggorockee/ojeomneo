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
type HealthResponse struct {
	Status   string         `json:"status"`
	Service  string         `json:"service"`
	Version  string         `json:"version"`
	Database DatabaseStatus `json:"database"`
}

// DatabaseStatus 데이터베이스 상태
type DatabaseStatus struct {
	Connected bool  `json:"connected"`
	LatencyMs int64 `json:"latency_ms"`
}

// HealthCheck 헬스체크 엔드포인트
// @Summary 서버 헬스체크
// @Description 서버 및 데이터베이스 상태 확인
// @Tags Health
// @Accept json
// @Produce json
// @Success 200 {object} HealthResponse
// @Router /healthcheck [get]
func (h *HealthHandler) HealthCheck(c *fiber.Ctx) error {
	// DB 연결 체크 및 레이턴시 측정
	start := time.Now()
	sqlDB, err := h.db.DB()

	var dbStatus DatabaseStatus
	if err != nil {
		dbStatus = DatabaseStatus{Connected: false, LatencyMs: 0}
	} else {
		err = sqlDB.Ping()
		latency := time.Since(start).Milliseconds()
		dbStatus = DatabaseStatus{
			Connected: err == nil,
			LatencyMs: latency,
		}
	}

	status := "ok"
	if !dbStatus.Connected {
		status = "degraded"
	}

	return c.JSON(HealthResponse{
		Status:   status,
		Service:  "woohalabs-api",
		Version:  "1.0.0",
		Database: dbStatus,
	})
}
