package handler

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"

	"github.com/ggorockee/ojeomneo/server/internal/model"
)

// AppVersionHandler 앱 버전 핸들러
type AppVersionHandler struct {
	db *gorm.DB
}

// NewAppVersionHandler AppVersionHandler 생성자
func NewAppVersionHandler(db *gorm.DB) *AppVersionHandler {
	return &AppVersionHandler{db: db}
}

// CheckVersion godoc
// @Summary 앱 버전 확인
// @Description 앱 버전을 확인하고 강제 업데이트 여부를 반환합니다
// @Tags App
// @Accept json
// @Produce json
// @Param platform query string true "플랫폼 (ios/android)"
// @Param current_version query string true "현재 앱 버전 (예: 1.0.0)"
// @Success 200 {object} map[string]interface{} "버전 정보"
// @Failure 400 {object} map[string]interface{} "잘못된 요청"
// @Failure 404 {object} map[string]interface{} "버전 정보 없음"
// @Router /app/version [get]
func (h *AppVersionHandler) CheckVersion(c *fiber.Ctx) error {
	platform := c.Query("platform")
	currentVersion := c.Query("current_version")

	// 필수 파라미터 검증
	if platform == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "platform is required",
		})
	}

	if currentVersion == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "current_version is required",
		})
	}

	// 플랫폼 검증
	if platform != "ios" && platform != "android" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "platform must be ios or android",
		})
	}

	// DB에서 버전 정보 조회
	var appVersion model.AppVersion
	result := h.db.Where("platform = ? AND is_active = ?", platform, true).First(&appVersion)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"success": false,
				"error":   "version info not found for platform: " + platform,
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "failed to get version info",
		})
	}

	// 버전 비교하여 강제 업데이트 여부 결정
	forceUpdate := false
	if appVersion.ForceUpdate && compareVersions(currentVersion, appVersion.MinVersion) < 0 {
		forceUpdate = true
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"force_update":   forceUpdate,
			"latest_version": appVersion.LatestVersion,
			"min_version":    appVersion.MinVersion,
			"store_url":      appVersion.StoreURL,
			"update_message": appVersion.UpdateMessage,
		},
	})
}

// compareVersions 버전 비교 (Semantic Versioning)
// 반환값: -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
func compareVersions(v1, v2 string) int {
	parts1 := parseVersion(v1)
	parts2 := parseVersion(v2)

	// 비교할 최대 길이
	maxLen := len(parts1)
	if len(parts2) > maxLen {
		maxLen = len(parts2)
	}

	for i := 0; i < maxLen; i++ {
		var p1, p2 int
		if i < len(parts1) {
			p1 = parts1[i]
		}
		if i < len(parts2) {
			p2 = parts2[i]
		}

		if p1 < p2 {
			return -1
		}
		if p1 > p2 {
			return 1
		}
	}

	return 0
}

// parseVersion 버전 문자열을 정수 슬라이스로 파싱
func parseVersion(version string) []int {
	parts := strings.Split(version, ".")
	result := make([]int, len(parts))

	for i, part := range parts {
		num, err := strconv.Atoi(part)
		if err != nil {
			result[i] = 0
		} else {
			result[i] = num
		}
	}

	return result
}
