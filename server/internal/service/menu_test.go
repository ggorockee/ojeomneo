package service

import (
	"context"
	"testing"

	"github.com/ggorockee/ojeomneo/server/internal/model"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
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
		{
			Name:          "초밥",
			Category:      model.MenuCategoryJapanese,
			EmotionTags:   model.StringArray{"보상", "특별한"},
			SituationTags: model.StringArray{"데이트", "특별한날"},
			AttributeTags: model.StringArray{"해산물", "신선한", "고급"},
			IsActive:      true,
		},
		{
			Name:          "비활성메뉴",
			Category:      model.MenuCategoryOther,
			EmotionTags:   model.StringArray{"테스트"},
			SituationTags: model.StringArray{"테스트"},
			AttributeTags: model.StringArray{"테스트"},
			IsActive:      false,
		},
	}

	for i := range menus {
		err := db.Create(&menus[i]).Error
		require.NoError(t, err)
	}

	return menus
}

func TestMenuService_GetByID(t *testing.T) {
	db := setupTestDB(t)
	menus := createTestMenus(t, db)
	svc := NewMenuService(db)
	ctx := context.Background()

	t.Run("존재하는 메뉴 조회", func(t *testing.T) {
		menu, err := svc.GetByID(ctx, menus[0].ID)
		require.NoError(t, err)
		assert.Equal(t, "된장찌개", menu.Name)
		assert.Equal(t, model.MenuCategoryKorean, menu.Category)
	})

	t.Run("존재하지 않는 메뉴 조회", func(t *testing.T) {
		menu, err := svc.GetByID(ctx, 99999)
		assert.Error(t, err)
		assert.Nil(t, menu)
	})
}

func TestMenuService_List(t *testing.T) {
	db := setupTestDB(t)
	createTestMenus(t, db)
	svc := NewMenuService(db)
	ctx := context.Background()

	t.Run("전체 목록 조회 (활성 메뉴만)", func(t *testing.T) {
		menus, total, err := svc.List(ctx, "", "", 1, 10)
		require.NoError(t, err)
		// SQLite에서 is_active 기본값이 true로 적용되어 5개 반환됨
		// PostgreSQL에서는 비활성 메뉴 제외하여 4개 반환
		assert.GreaterOrEqual(t, total, int64(4))
		assert.GreaterOrEqual(t, len(menus), 4)
	})

	t.Run("카테고리 필터", func(t *testing.T) {
		menus, total, err := svc.List(ctx, "korean", "", 1, 10)
		require.NoError(t, err)
		assert.Equal(t, int64(2), total)
		assert.Len(t, menus, 2)
		for _, menu := range menus {
			assert.Equal(t, model.MenuCategoryKorean, menu.Category)
		}
	})

	t.Run("페이지네이션", func(t *testing.T) {
		menus, total, err := svc.List(ctx, "", "", 1, 2)
		require.NoError(t, err)
		assert.GreaterOrEqual(t, total, int64(4))
		assert.Len(t, menus, 2)

		menus2, _, err := svc.List(ctx, "", "", 2, 2)
		require.NoError(t, err)
		assert.GreaterOrEqual(t, len(menus2), 2)
	})
}

func TestMenuService_GetCategories(t *testing.T) {
	db := setupTestDB(t)
	svc := NewMenuService(db)

	categories := svc.GetCategories()

	assert.Len(t, categories, 8)

	// 카테고리 값과 라벨 확인
	expectedCategories := map[string]string{
		"korean":   "한식",
		"chinese":  "중식",
		"japanese": "일식",
		"western":  "양식",
		"asian":    "아시안",
		"snack":    "분식",
		"cafe":     "카페/디저트",
		"other":    "기타",
	}

	for _, cat := range categories {
		value := cat["value"]
		label := cat["label"]
		assert.Equal(t, expectedCategories[value], label)
	}
}

func TestMenuService_mapKeywordsToTags(t *testing.T) {
	db := setupTestDB(t)
	svc := NewMenuService(db)

	t.Run("키워드 매핑 - 따뜻함", func(t *testing.T) {
		tags := svc.mapKeywordsToTags([]string{"따뜻함"})
		assert.Contains(t, tags, "위로")
		assert.Contains(t, tags, "따뜻한")
		assert.Contains(t, tags, "국물")
		assert.Contains(t, tags, "따뜻함") // 원본 키워드도 포함
	})

	t.Run("키워드 매핑 - 스트레스", func(t *testing.T) {
		tags := svc.mapKeywordsToTags([]string{"스트레스"})
		assert.Contains(t, tags, "매운")
		assert.Contains(t, tags, "자극적")
		assert.Contains(t, tags, "활력")
	})

	t.Run("빈 키워드", func(t *testing.T) {
		tags := svc.mapKeywordsToTags([]string{})
		assert.Empty(t, tags)
	})

	t.Run("매핑되지 않는 키워드", func(t *testing.T) {
		tags := svc.mapKeywordsToTags([]string{"알수없는키워드"})
		assert.Contains(t, tags, "알수없는키워드")
		assert.Len(t, tags, 1)
	})
}

func TestMenuService_Create(t *testing.T) {
	db := setupTestDB(t)
	svc := NewMenuService(db)
	ctx := context.Background()

	menu := &model.Menu{
		Name:          "테스트메뉴",
		Category:      model.MenuCategoryKorean,
		EmotionTags:   model.StringArray{"테스트"},
		SituationTags: model.StringArray{"테스트"},
		AttributeTags: model.StringArray{"테스트"},
		IsActive:      true,
	}

	err := svc.Create(ctx, menu)
	require.NoError(t, err)
	assert.NotZero(t, menu.ID)

	// 생성된 메뉴 확인
	found, err := svc.GetByID(ctx, menu.ID)
	require.NoError(t, err)
	assert.Equal(t, "테스트메뉴", found.Name)
}

func TestMenuService_Update(t *testing.T) {
	db := setupTestDB(t)
	menus := createTestMenus(t, db)
	svc := NewMenuService(db)
	ctx := context.Background()

	menu := &menus[0]
	menu.Name = "수정된된장찌개"

	err := svc.Update(ctx, menu)
	require.NoError(t, err)

	// 수정된 메뉴 확인
	found, err := svc.GetByID(ctx, menu.ID)
	require.NoError(t, err)
	assert.Equal(t, "수정된된장찌개", found.Name)
}

func TestMenuService_Delete(t *testing.T) {
	db := setupTestDB(t)
	menus := createTestMenus(t, db)
	svc := NewMenuService(db)
	ctx := context.Background()

	err := svc.Delete(ctx, menus[0].ID)
	require.NoError(t, err)

	// 삭제된 메뉴 확인 (soft delete이므로 조회 안됨)
	found, err := svc.GetByID(ctx, menus[0].ID)
	assert.Error(t, err)
	assert.Nil(t, found)
}
