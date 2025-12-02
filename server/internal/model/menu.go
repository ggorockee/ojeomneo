package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"gorm.io/gorm"
)

// MenuCategory 메뉴 카테고리
type MenuCategory string

const (
	MenuCategoryKorean   MenuCategory = "korean"   // 한식
	MenuCategoryChinese  MenuCategory = "chinese"  // 중식
	MenuCategoryJapanese MenuCategory = "japanese" // 일식
	MenuCategoryWestern  MenuCategory = "western"  // 양식
	MenuCategoryAsian    MenuCategory = "asian"    // 아시안
	MenuCategorySnack    MenuCategory = "snack"    // 분식
	MenuCategoryCafe     MenuCategory = "cafe"     // 카페/디저트
	MenuCategoryOther    MenuCategory = "other"    // 기타
)

// StringArray PostgreSQL text[] 타입을 위한 커스텀 타입
type StringArray []string

// Scan implements sql.Scanner
func (a *StringArray) Scan(value interface{}) error {
	if value == nil {
		*a = nil
		return nil
	}

	switch v := value.(type) {
	case []byte:
		return json.Unmarshal(v, a)
	case string:
		return json.Unmarshal([]byte(v), a)
	default:
		return errors.New("invalid type for StringArray")
	}
}

// Value implements driver.Valuer
func (a StringArray) Value() (driver.Value, error) {
	if a == nil {
		return nil, nil
	}
	return json.Marshal(a)
}

// Menu 메뉴 모델
type Menu struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	Name      string         `gorm:"size:100;not null;uniqueIndex" json:"name"`
	Category  MenuCategory   `gorm:"size:50;not null;index" json:"category"`
	ImageURL  string         `gorm:"type:text" json:"image_url,omitempty"`
	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`

	// 태그 (JSONB로 저장)
	EmotionTags   StringArray `gorm:"type:jsonb;default:'[]'" json:"emotion_tags"`
	SituationTags StringArray `gorm:"type:jsonb;default:'[]'" json:"situation_tags"`
	AttributeTags StringArray `gorm:"type:jsonb;default:'[]'" json:"attribute_tags"`

	IsActive bool `gorm:"default:true;not null" json:"is_active"`

	// 관계
	Recommendations []Recommendation `gorm:"foreignKey:MenuID" json:"recommendations,omitempty"`
}

// TableName GORM 테이블명 지정
func (Menu) TableName() string {
	return "menus"
}

// GetAllTags 모든 태그를 하나의 슬라이스로 반환
func (m *Menu) GetAllTags() []string {
	tags := make([]string, 0, len(m.EmotionTags)+len(m.SituationTags)+len(m.AttributeTags))
	tags = append(tags, m.EmotionTags...)
	tags = append(tags, m.SituationTags...)
	tags = append(tags, m.AttributeTags...)
	return tags
}

// MenuResponse API 응답용 구조체
type MenuResponse struct {
	ID            uint         `json:"id"`
	Name          string       `json:"name"`
	Category      MenuCategory `json:"category"`
	CategoryLabel string       `json:"category_label"`
	ImageURL      string       `json:"image_url,omitempty"`
	EmotionTags   []string     `json:"emotion_tags"`
	SituationTags []string     `json:"situation_tags"`
	AttributeTags []string     `json:"attribute_tags"`
}

// ToResponse Menu를 API 응답용 구조체로 변환
func (m *Menu) ToResponse() MenuResponse {
	return MenuResponse{
		ID:            m.ID,
		Name:          m.Name,
		Category:      m.Category,
		CategoryLabel: m.Category.Label(),
		ImageURL:      m.ImageURL,
		EmotionTags:   m.EmotionTags,
		SituationTags: m.SituationTags,
		AttributeTags: m.AttributeTags,
	}
}

// Label 카테고리 한글 라벨 반환
func (c MenuCategory) Label() string {
	labels := map[MenuCategory]string{
		MenuCategoryKorean:   "한식",
		MenuCategoryChinese:  "중식",
		MenuCategoryJapanese: "일식",
		MenuCategoryWestern:  "양식",
		MenuCategoryAsian:    "아시안",
		MenuCategorySnack:    "분식",
		MenuCategoryCafe:     "카페/디저트",
		MenuCategoryOther:    "기타",
	}
	if label, ok := labels[c]; ok {
		return label
	}
	return string(c)
}
