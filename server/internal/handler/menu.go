package handler

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"go.uber.org/zap"

	"github.com/ggorockee/ojeomneo/server/internal/service"
)

// MenuHandler 메뉴 핸들러
type MenuHandler struct {
	menuService *service.MenuService
	logger      *zap.Logger
}

// NewMenuHandler 새 메뉴 핸들러 생성
func NewMenuHandler(menuService *service.MenuService, logger *zap.Logger) *MenuHandler {
	return &MenuHandler{
		menuService: menuService,
		logger:      logger,
	}
}

// List godoc
// @Summary 메뉴 목록 조회
// @Description 메뉴 목록을 조회합니다. 카테고리와 태그로 필터링할 수 있습니다.
// @Tags menu
// @Accept json
// @Produce json
// @Param category query string false "카테고리 필터 (korean, chinese, japanese, western, asian, snack, cafe, other)"
// @Param tag query string false "태그 필터"
// @Param page query int false "페이지 번호" default(1)
// @Param limit query int false "페이지당 개수" default(20)
// @Success 200 {object} map[string]interface{}
// @Router /menus [get]
func (h *MenuHandler) List(c *fiber.Ctx) error {
	start := time.Now()
	
	category := c.Query("category")
	tag := c.Query("tag")
	page := c.QueryInt("page", 1)
	limit := c.QueryInt("limit", 20)

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	menus, total, err := h.menuService.List(c.Context(), category, tag, page, limit)
	duration := time.Since(start)
	
	if err != nil {
		go func() {
			h.logger.Error("Menu list failed",
				zap.Error(err),
				zap.String("category", category),
				zap.String("tag", tag),
				zap.Int("page", page),
				zap.Duration("duration", duration),
			)
		}()
		
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	go func() {
		h.logger.Debug("Menu list completed",
			zap.String("category", category),
			zap.String("tag", tag),
			zap.Int("page", page),
			zap.Int("limit", limit),
			zap.Int64("total", total),
			zap.Int("count", len(menus)),
			zap.Duration("duration", duration),
		)
	}()

	// 응답 변환
	items := make([]map[string]interface{}, len(menus))
	for i, menu := range menus {
		items[i] = map[string]interface{}{
			"id":             menu.ID,
			"name":           menu.Name,
			"category":       menu.Category,
			"category_label": menu.Category.Label(),
			"image_url":      menu.ImageURL,
			"emotion_tags":   menu.EmotionTags,
			"situation_tags": menu.SituationTags,
			"attribute_tags": menu.AttributeTags,
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
// @Summary 메뉴 상세 조회
// @Description 메뉴 ID로 상세 정보를 조회합니다.
// @Tags menu
// @Accept json
// @Produce json
// @Param id path int true "메뉴 ID"
// @Success 200 {object} map[string]interface{}
// @Failure 404 {object} map[string]interface{}
// @Router /menus/{id} [get]
func (h *MenuHandler) GetByID(c *fiber.Ctx) error {
	id, err := c.ParamsInt("id")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid menu id",
		})
	}

	menu, err := h.menuService.GetByID(c.Context(), uint(id))
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"error":   "menu not found",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    menu.ToResponse(),
	})
}

// GetCategories godoc
// @Summary 카테고리 목록 조회
// @Description 사용 가능한 메뉴 카테고리 목록을 조회합니다.
// @Tags menu
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /menus/categories [get]
func (h *MenuHandler) GetCategories(c *fiber.Ctx) error {
	categories := h.menuService.GetCategories()

	return c.JSON(fiber.Map{
		"success": true,
		"data":    categories,
	})
}
