package model

import (
	"time"

	"github.com/google/uuid"
)

// Recommendation 추천 모델
type Recommendation struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	SketchID  uuid.UUID `gorm:"type:uuid;not null;index" json:"sketch_id"`
	MenuID    uint      `gorm:"not null;index" json:"menu_id"`
	Reason    string    `gorm:"type:text;not null" json:"reason"`
	Rank      int       `gorm:"not null;default:1" json:"rank"`
	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`

	// 관계
	Sketch *Sketch `gorm:"foreignKey:SketchID" json:"sketch,omitempty"`
	Menu   *Menu   `gorm:"foreignKey:MenuID" json:"menu,omitempty"`
}

// TableName GORM 테이블명 지정
func (Recommendation) TableName() string {
	return "recommendations"
}

// RecommendationResponse API 응답용 구조체
type RecommendationResponse struct {
	ID       uint   `json:"id"`
	MenuID   uint   `json:"menu_id"`
	MenuName string `json:"menu_name"`
	Reason   string `json:"reason"`
	Rank     int    `json:"rank"`
}

// ToResponse Recommendation을 API 응답용 구조체로 변환
func (r *Recommendation) ToResponse() RecommendationResponse {
	resp := RecommendationResponse{
		ID:     r.ID,
		MenuID: r.MenuID,
		Reason: r.Reason,
		Rank:   r.Rank,
	}
	if r.Menu != nil {
		resp.MenuName = r.Menu.Name
	}
	return resp
}
