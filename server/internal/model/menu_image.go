package model

import (
	"time"

	"gorm.io/gorm"
)

// MenuImage 메뉴 이미지 모델
type MenuImage struct {
	ID        uint           `gorm:"primaryKey" json:"id"`
	MenuID    uint           `gorm:"not null;index" json:"menu_id"`
	ImageID   string         `gorm:"size:255;not null" json:"image_id"`          // Cloudflare 이미지 ID
	ImageURL  string         `gorm:"type:text;not null" json:"image_url"`        // 퍼블릭 URL
	IsPrimary bool           `gorm:"default:false;not null" json:"is_primary"`   // 대표 이미지 여부
	SortOrder int            `gorm:"default:0;not null" json:"sort_order"`       // 정렬 순서
	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`

	// 관계
	Menu Menu `gorm:"foreignKey:MenuID" json:"menu,omitempty"`
}

// TableName GORM 테이블명 지정
func (MenuImage) TableName() string {
	return "menu_images"
}

// MenuImageResponse API 응답용 구조체
type MenuImageResponse struct {
	ID           uint   `json:"id"`
	MenuID       uint   `json:"menu_id"`
	ImageID      string `json:"image_id"`
	ImageURL     string `json:"image_url"`
	ThumbnailURL string `json:"thumbnail_url,omitempty"`
	IsPrimary    bool   `json:"is_primary"`
	SortOrder    int    `json:"sort_order"`
}

// ToResponse MenuImage를 API 응답용 구조체로 변환
func (m *MenuImage) ToResponse(accountHash string) MenuImageResponse {
	thumbnailURL := ""
	if accountHash != "" && m.ImageID != "" {
		thumbnailURL = "https://imagedelivery.net/" + accountHash + "/" + m.ImageID + "/thumbnail"
	}

	return MenuImageResponse{
		ID:           m.ID,
		MenuID:       m.MenuID,
		ImageID:      m.ImageID,
		ImageURL:     m.ImageURL,
		ThumbnailURL: thumbnailURL,
		IsPrimary:    m.IsPrimary,
		SortOrder:    m.SortOrder,
	}
}
