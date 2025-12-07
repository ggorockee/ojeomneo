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

	// 응답 변환: Menu의 image_url이 제대로 포함되도록 처리
	items := make([]fiber.Map, len(sketches))
	for i, sketch := range sketches {
		// recommendations 변환
		recommendations := make([]fiber.Map, len(sketch.Recommendations))
		for j, rec := range sketch.Recommendations {
			recMap := fiber.Map{
				"id":         rec.ID,
				"sketch_id":  rec.SketchID,
				"menu_id":    rec.MenuID,
				"reason":     rec.Reason,
				"rank":       rec.Rank,
				"created_at": rec.CreatedAt,
			}
			// Menu가 있으면 image_url 포함하여 추가
			if rec.Menu != nil {
				recMap["menu"] = fiber.Map{
					"id":             rec.Menu.ID,
					"name":           rec.Menu.Name,
					"category":       rec.Menu.Category,
					"image_url":      rec.Menu.ImageURL,
					"emotion_tags":   rec.Menu.EmotionTags,
					"situation_tags": rec.Menu.SituationTags,
					"attribute_tags": rec.Menu.AttributeTags,
				}
			}
			recommendations[j] = recMap
		}

		items[i] = fiber.Map{
			"id":              sketch.ID,
			"device_id":       sketch.DeviceID,
			"image_path":      sketch.ImagePath,
			"input_text":      sketch.InputText,
			"created_at":      sketch.CreatedAt,
			"analysis_result": sketch.AnalysisResult,
			"recommendations": recommendations,
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items": items,
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
