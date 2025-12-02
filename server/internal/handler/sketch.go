package handler

import (
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"

	"github.com/ggorockee/ojeomneo/server/internal/service"
)

// SketchHandler 스케치 핸들러
type SketchHandler struct {
	sketchService *service.SketchService
}

// NewSketchHandler 새 스케치 핸들러 생성
func NewSketchHandler(sketchService *service.SketchService) *SketchHandler {
	return &SketchHandler{
		sketchService: sketchService,
	}
}

// AnalyzeRequest 스케치 분석 요청 DTO
type AnalyzeRequest struct {
	Text     string `form:"text"`
	DeviceID string `form:"device_id"`
}

// Analyze godoc
// @Summary 스케치 분석 및 메뉴 추천
// @Description 스케치 이미지를 분석하여 감정/분위기를 파악하고 어울리는 메뉴를 추천합니다
// @Tags sketch
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "스케치 이미지 (PNG/JPEG, max 5MB)"
// @Param text formData string false "추가 텍스트 입력"
// @Param device_id formData string true "디바이스 식별자"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /sketch/analyze [post]
func (h *SketchHandler) Analyze(c *fiber.Ctx) error {
	// 디바이스 ID 확인
	deviceID := c.FormValue("device_id")
	if deviceID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "device_id is required",
		})
	}

	// 이미지 파일 확인
	file, err := c.FormFile("image")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "image file is required",
		})
	}

	// 파일 크기 확인 (5MB)
	if file.Size > 5*1024*1024 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "image file too large (max 5MB)",
		})
	}

	// 파일 열기
	f, err := file.Open()
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to read image file",
		})
	}
	defer f.Close()

	// 이미지 데이터 읽기
	imageData := make([]byte, file.Size)
	if _, err := f.Read(imageData); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to read image data",
		})
	}

	// 분석 요청
	req := &service.AnalyzeRequest{
		ImageData: imageData,
		InputText: c.FormValue("text"),
		DeviceID:  deviceID,
	}

	result, err := h.sketchService.Analyze(c.Context(), req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

// HistoryQuery 히스토리 조회 쿼리 파라미터
type HistoryQuery struct {
	Page  int `query:"page"`
	Limit int `query:"limit"`
}

// GetHistory godoc
// @Summary 스케치 히스토리 조회
// @Description 디바이스별 스케치 분석 히스토리를 조회합니다
// @Tags sketch
// @Accept json
// @Produce json
// @Param device_id query string true "디바이스 식별자"
// @Param page query int false "페이지 번호" default(1)
// @Param limit query int false "페이지당 개수" default(10)
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Router /sketch/history [get]
func (h *SketchHandler) GetHistory(c *fiber.Ctx) error {
	deviceID := c.Query("device_id")
	if deviceID == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "device_id is required",
		})
	}

	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 10)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 50 {
		limit = 10
	}

	sketches, total, err := h.sketchService.GetHistory(c.Context(), deviceID, page, limit)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items": sketches,
			"pagination": fiber.Map{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"total_page": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// GetByID godoc
// @Summary 스케치 상세 조회
// @Description 스케치 ID로 상세 정보를 조회합니다
// @Tags sketch
// @Accept json
// @Produce json
// @Param id path string true "스케치 UUID"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /sketch/{id} [get]
func (h *SketchHandler) GetByID(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid sketch id",
		})
	}

	sketch, err := h.sketchService.GetByID(c.Context(), id)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"error":   "sketch not found",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    sketch,
	})
}
