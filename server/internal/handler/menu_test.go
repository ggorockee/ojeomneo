package handler

import (
	"encoding/json"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/ggorockee/ojeomneo/server/internal/service"
)

// setupTestDB 테스트용 SQLite DB 생성
func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	require.NoError(t, err)

	// 테이블 마이그레이션 (Menu와 MenuImage 모두 필요)
	err = db.AutoMigrate(&model.Menu{}, &model.MenuImage{})
	require.NoError(t, err)

	return db
}

// createTestMenus 테스트용 메뉴 데이터 생성
func createTestMenus(t *testing.T, db *gorm.DB) []model.Menu {
	menus := []model.Menu{
		{
			Name:          "된장찌개",
			Category:      model.MenuCategoryKorean,
			EmotionTags:   model.StringArray{"위로", "평온"},
			SituationTags: model.StringArray{"혼밥", "집밥"},
			AttributeTags: model.StringArray{"따뜻한", "국물", "든든한"},
			IsActive:      true,
		},
		{
			Name:          "김치찌개",
			Category:      model.MenuCategoryKorean,
			EmotionTags:   model.StringArray{"활력", "스트레스해소"},
			SituationTags: model.StringArray{"혼밥", "회식"},
			AttributeTags: model.StringArray{"따뜻한", "매운", "국물"},
			IsActive:      true,
		},
		{
			Name:          "짜장면",
			Category:      model.MenuCategoryChinese,
			EmotionTags:   model.StringArray{"위로", "향수"},
			SituationTags: model.StringArray{"혼밥", "배달"},
			AttributeTags: model.StringArray{"면류", "달콤한", "든든한"},
			IsActive:      true,
		},
	}

	for i := range menus {
		err := db.Create(&menus[i]).Error
		require.NoError(t, err)
	}

	return menus
}

// setupApp 테스트용 Fiber 앱 생성
func setupApp(t *testing.T) (*fiber.App, *gorm.DB) {
	db := setupTestDB(t)
	createTestMenus(t, db)

	logger := zap.NewNop()
	menuService := service.NewMenuService(db, logger)
	menuHandler := NewMenuHandler(menuService, logger)

	app := fiber.New()
	app.Get("/menus", menuHandler.List)
	app.Get("/menus/categories", menuHandler.GetCategories)
	app.Get("/menus/:id", menuHandler.GetByID)

	return app, db
}

func TestMenuHandler_List(t *testing.T) {
	app, _ := setupApp(t)

	t.Run("전체 목록 조회", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/menus", nil)
		resp, err := app.Test(req)
		require.NoError(t, err)
		assert.Equal(t, fiber.StatusOK, resp.StatusCode)

		var result map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&result)
		require.NoError(t, err)

		assert.True(t, result["success"].(bool))
		data := result["data"].(map[string]interface{})
		items := data["items"].([]interface{})
		assert.Len(t, items, 3)
	})

	t.Run("카테고리 필터", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/menus?category=korean", nil)
		resp, err := app.Test(req)
		require.NoError(t, err)
		assert.Equal(t, fiber.StatusOK, resp.StatusCode)

		var result map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&result)
		require.NoError(t, err)

		data := result["data"].(map[string]interface{})
		items := data["items"].([]interface{})
		assert.Len(t, items, 2)
	})

	t.Run("페이지네이션", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/menus?page=1&limit=2", nil)
		resp, err := app.Test(req)
		require.NoError(t, err)
		assert.Equal(t, fiber.StatusOK, resp.StatusCode)

		var result map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&result)
		require.NoError(t, err)

		data := result["data"].(map[string]interface{})
		items := data["items"].([]interface{})
		pagination := data["pagination"].(map[string]interface{})

		assert.Len(t, items, 2)
		assert.Equal(t, float64(3), pagination["total"])
		assert.Equal(t, float64(1), pagination["page"])
		assert.Equal(t, float64(2), pagination["limit"])
	})
}

func TestMenuHandler_GetByID(t *testing.T) {
	app, db := setupApp(t)

	// 첫 번째 메뉴 ID 조회
	var menu model.Menu
	db.First(&menu)

	t.Run("존재하는 메뉴 조회", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/menus/1", nil)
		resp, err := app.Test(req)
		require.NoError(t, err)
		assert.Equal(t, fiber.StatusOK, resp.StatusCode)

		var result map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&result)
		require.NoError(t, err)

		assert.True(t, result["success"].(bool))
		data := result["data"].(map[string]interface{})
		assert.Equal(t, "된장찌개", data["name"])
	})

	t.Run("존재하지 않는 메뉴 조회", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/menus/99999", nil)
		resp, err := app.Test(req)
		require.NoError(t, err)
		assert.Equal(t, fiber.StatusNotFound, resp.StatusCode)

		var result map[string]interface{}
		err = json.NewDecoder(resp.Body).Decode(&result)
		require.NoError(t, err)

		assert.False(t, result["success"].(bool))
	})

	t.Run("잘못된 ID 형식", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/menus/invalid", nil)
		resp, err := app.Test(req)
		require.NoError(t, err)
		assert.Equal(t, fiber.StatusBadRequest, resp.StatusCode)
	})
}

func TestMenuHandler_GetCategories(t *testing.T) {
	app, _ := setupApp(t)

	req := httptest.NewRequest("GET", "/menus/categories", nil)
	resp, err := app.Test(req)
	require.NoError(t, err)
	assert.Equal(t, fiber.StatusOK, resp.StatusCode)

	var result map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(t, err)

	assert.True(t, result["success"].(bool))
	data := result["data"].([]interface{})
	assert.Len(t, data, 8)

	// 첫 번째 카테고리 확인
	firstCat := data[0].(map[string]interface{})
	assert.Contains(t, firstCat, "value")
	assert.Contains(t, firstCat, "label")
}
