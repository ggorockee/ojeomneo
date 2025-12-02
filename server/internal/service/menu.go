package service

import (
	"context"
	"strings"

	"github.com/ggorockee/ojeomneo/server/internal/model"
	"gorm.io/gorm"
)

// MenuService 메뉴 서비스
type MenuService struct {
	db *gorm.DB
}

// NewMenuService 새 메뉴 서비스 생성
func NewMenuService(db *gorm.DB) *MenuService {
	return &MenuService{db: db}
}

// GetByID ID로 메뉴 조회
func (s *MenuService) GetByID(ctx context.Context, id uint) (*model.Menu, error) {
	var menu model.Menu
	if err := s.db.WithContext(ctx).First(&menu, id).Error; err != nil {
		return nil, err
	}
	return &menu, nil
}

// List 메뉴 목록 조회
func (s *MenuService) List(ctx context.Context, category string, tag string, page, limit int) ([]model.Menu, int64, error) {
	var menus []model.Menu
	var total int64

	query := s.db.WithContext(ctx).Model(&model.Menu{}).Where("is_active = ?", true)

	// 카테고리 필터
	if category != "" {
		query = query.Where("category = ?", category)
	}

	// 태그 필터 (JSONB 배열에서 검색)
	if tag != "" {
		query = query.Where(
			"emotion_tags @> ?::jsonb OR situation_tags @> ?::jsonb OR attribute_tags @> ?::jsonb",
			`["`+tag+`"]`, `["`+tag+`"]`, `["`+tag+`"]`,
		)
	}

	// 전체 개수 조회
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// 페이지네이션
	offset := (page - 1) * limit
	if err := query.Offset(offset).Limit(limit).Order("name ASC").Find(&menus).Error; err != nil {
		return nil, 0, err
	}

	return menus, total, nil
}

// FindByKeywords 키워드와 매칭되는 메뉴 검색
func (s *MenuService) FindByKeywords(ctx context.Context, keywords []string, limit int) ([]model.Menu, error) {
	var menus []model.Menu

	if len(keywords) == 0 {
		// 키워드가 없으면 랜덤 메뉴 반환
		if err := s.db.WithContext(ctx).
			Where("is_active = ?", true).
			Order("RANDOM()").
			Limit(limit).
			Find(&menus).Error; err != nil {
			return nil, err
		}
		return menus, nil
	}

	// 키워드 기반 태그 매칭
	// 유사어 매핑 적용
	mappedTags := s.mapKeywordsToTags(keywords)

	// 태그 매칭 쿼리 (OR 조건)
	query := s.db.WithContext(ctx).Model(&model.Menu{}).Where("is_active = ?", true)

	var conditions []string
	var args []interface{}

	for _, tag := range mappedTags {
		jsonTag := `["` + tag + `"]`
		conditions = append(conditions, "emotion_tags @> ?::jsonb OR situation_tags @> ?::jsonb OR attribute_tags @> ?::jsonb")
		args = append(args, jsonTag, jsonTag, jsonTag)
	}

	if len(conditions) > 0 {
		query = query.Where("("+strings.Join(conditions, " OR ")+")", args...)
	}

	if err := query.Order("RANDOM()").Limit(limit).Find(&menus).Error; err != nil {
		return nil, err
	}

	// 매칭된 메뉴가 없으면 랜덤 반환
	if len(menus) == 0 {
		if err := s.db.WithContext(ctx).
			Where("is_active = ?", true).
			Order("RANDOM()").
			Limit(limit).
			Find(&menus).Error; err != nil {
			return nil, err
		}
	}

	return menus, nil
}

// mapKeywordsToTags 키워드를 태그로 매핑
func (s *MenuService) mapKeywordsToTags(keywords []string) []string {
	// 키워드 → 태그 매핑 사전
	mapping := map[string][]string{
		// 감정/분위기 관련
		"따뜻함":  {"위로", "따뜻한", "국물"},
		"포근함":  {"위로", "따뜻한", "집밥"},
		"집밥":   {"위로", "한식", "집밥"},
		"시원함":  {"청량", "시원한", "면류"},
		"청량":   {"청량", "시원한"},
		"매콤함":  {"매운", "자극적"},
		"화끈":   {"매운", "자극적", "활력"},
		"달콤함":  {"달콤한", "보상", "디저트"},
		"보상":   {"보상", "달콤한", "특별한"},
		"피로":   {"위로", "따뜻한", "든든한"},
		"스트레스": {"매운", "자극적", "활력"},
		"행복":   {"보상", "달콤한", "특별한"},
		"우울":   {"위로", "따뜻한", "국물"},
		"활력":   {"활력", "든든한", "고기"},
		"가벼움":  {"가벼운", "샐러드", "건강"},
		"든든함":  {"든든한", "고기", "밥"},
	}

	tagSet := make(map[string]bool)

	for _, keyword := range keywords {
		// 직접 매핑
		if tags, ok := mapping[keyword]; ok {
			for _, tag := range tags {
				tagSet[tag] = true
			}
		}
		// 키워드 자체도 태그로 추가
		tagSet[keyword] = true
	}

	tags := make([]string, 0, len(tagSet))
	for tag := range tagSet {
		tags = append(tags, tag)
	}

	return tags
}

// Create 메뉴 생성
func (s *MenuService) Create(ctx context.Context, menu *model.Menu) error {
	return s.db.WithContext(ctx).Create(menu).Error
}

// Update 메뉴 수정
func (s *MenuService) Update(ctx context.Context, menu *model.Menu) error {
	return s.db.WithContext(ctx).Save(menu).Error
}

// Delete 메뉴 삭제 (soft delete)
func (s *MenuService) Delete(ctx context.Context, id uint) error {
	return s.db.WithContext(ctx).Delete(&model.Menu{}, id).Error
}

// GetCategories 모든 카테고리 목록 반환
func (s *MenuService) GetCategories() []map[string]string {
	categories := []model.MenuCategory{
		model.MenuCategoryKorean,
		model.MenuCategoryChinese,
		model.MenuCategoryJapanese,
		model.MenuCategoryWestern,
		model.MenuCategoryAsian,
		model.MenuCategorySnack,
		model.MenuCategoryCafe,
		model.MenuCategoryOther,
	}

	result := make([]map[string]string, len(categories))
	for i, cat := range categories {
		result[i] = map[string]string{
			"value": string(cat),
			"label": cat.Label(),
		}
	}

	return result
}
