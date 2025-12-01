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

// LivenessResponse Liveness 체크 응답
// @Description Kubernetes liveness/startup probe용 간단한 응답
type LivenessResponse struct {
	Status  string `json:"status" example:"ok"`
	Service string `json:"service" example:"woohalabs-api"`
}

// ReadinessResponse Readiness 체크 응답
// @Description Kubernetes readiness probe용 응답
type ReadinessResponse struct {
	Status   string `json:"status" example:"ok"`
	Ready    bool   `json:"ready" example:"true"`
	Database bool   `json:"database" example:"true"`
}

// DatabaseStatus 데이터베이스 상태
// @Description 데이터베이스 연결 상태
type DatabaseStatus struct {
	Connected bool   `json:"connected" example:"true"`
	LatencyMs int64  `json:"latency_ms" example:"5"`
	Message   string `json:"message,omitempty" example:"Database connection successful"`
}

// LivenessCheck godoc
// @Summary Liveness 체크 (Kubernetes startup/liveness probe용)
// @Description 서버가 살아있는지 확인 (DB 연결 무관)
// @Tags Health
// @Accept json
// @Produce json
// @Success 200 {object} LivenessResponse "서버 정상 가동 중"
// @Router /healthcheck/live [get]
func (h *HealthHandler) LivenessCheck(c *fiber.Ctx) error {
	return c.JSON(LivenessResponse{
		Status:  "ok",
		Service: "woohalabs-api",
	})
}

// ReadinessCheck godoc
// @Summary Readiness 체크 (Kubernetes readiness probe용)
// @Description 서버가 트래픽을 받을 준비가 됐는지 확인 (DB 연결 포함)
// @Tags Health
// @Accept json
// @Produce json
// @Success 200 {object} ReadinessResponse "트래픽 수신 준비 완료"
// @Failure 503 {object} ReadinessResponse "트래픽 수신 불가 (DB 연결 실패)"
// @Router /healthcheck/ready [get]
func (h *HealthHandler) ReadinessCheck(c *fiber.Ctx) error {
	response := ReadinessResponse{
		Status: "ok",
		Ready:  true,
	}

	// DB 연결 체크
	if h.db == nil {
		response.Status = "not_ready"
		response.Ready = false
		response.Database = false
		return c.Status(fiber.StatusServiceUnavailable).JSON(response)
	}

	sqlDB, err := h.db.DB()
	if err != nil {
		response.Status = "not_ready"
		response.Ready = false
		response.Database = false
		return c.Status(fiber.StatusServiceUnavailable).JSON(response)
	}

	if err = sqlDB.Ping(); err != nil {
		response.Status = "not_ready"
		response.Ready = false
		response.Database = false
		return c.Status(fiber.StatusServiceUnavailable).JSON(response)
	}

	response.Database = true
	return c.JSON(response)
}

// HealthCheck godoc
// @Summary 서버 상세 헬스체크
// @Description 서버 및 데이터베이스 상태 상세 확인 (모니터링/디버깅용)
// @Tags Health
// @Accept json
// @Produce json
// @Success 200 {object} HealthResponse "상태 정보 반환 (DB 연결 실패해도 200)"
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
		// 모니터링용이므로 항상 200 반환 (상태 정보만 제공)
		return c.JSON(response)
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
		return c.JSON(response)
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
		return c.JSON(response)
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
