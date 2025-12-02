package model

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// AnalysisMood 분석된 분위기
type AnalysisMood string

const (
	MoodBright AnalysisMood = "bright" // 밝음
	MoodCalm   AnalysisMood = "calm"   // 차분함
	MoodDark   AnalysisMood = "dark"   // 어두움
)

// Sketch 스케치 모델
type Sketch struct {
	ID        uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	DeviceID  string         `gorm:"size:255;not null;index" json:"device_id"`
	UserID    *uint          `gorm:"index" json:"user_id,omitempty"`
	ImagePath string         `gorm:"type:text;not null" json:"image_path"`
	InputText string         `gorm:"type:text" json:"input_text,omitempty"`
	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`

	// LLM 분석 결과 (JSONB)
	AnalysisResult datatypes.JSON `gorm:"type:jsonb" json:"analysis_result,omitempty"`

	// 관계
	User            *User            `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Recommendations []Recommendation `gorm:"foreignKey:SketchID" json:"recommendations,omitempty"`
}

// TableName GORM 테이블명 지정
func (Sketch) TableName() string {
	return "sketches"
}

// BeforeCreate UUID 자동 생성
func (s *Sketch) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

// AnalysisResultData 분석 결과 구조체
type AnalysisResultData struct {
	Emotion  string       `json:"emotion"`
	Keywords []string     `json:"keywords"`
	Mood     AnalysisMood `json:"mood"`
}

// GetAnalysisResult JSON을 구조체로 파싱
func (s *Sketch) GetAnalysisResult() (*AnalysisResultData, error) {
	if s.AnalysisResult == nil {
		return nil, nil
	}

	var result AnalysisResultData
	if err := s.AnalysisResult.UnmarshalJSON([]byte(s.AnalysisResult)); err != nil {
		return nil, err
	}
	return &result, nil
}

// SketchResponse API 응답용 구조체
type SketchResponse struct {
	ID             uuid.UUID           `json:"sketch_id"`
	Analysis       *AnalysisResultData `json:"analysis,omitempty"`
	Recommendation *RecommendationSet  `json:"recommendation,omitempty"`
	CreatedAt      time.Time           `json:"created_at"`
}

// RecommendationSet 추천 결과 세트
type RecommendationSet struct {
	Primary      *MenuRecommendation  `json:"primary"`
	Alternatives []MenuRecommendation `json:"alternatives,omitempty"`
}

// MenuRecommendation 개별 메뉴 추천
type MenuRecommendation struct {
	MenuID   uint         `json:"menu_id"`
	Name     string       `json:"name"`
	Category MenuCategory `json:"category"`
	ImageURL string       `json:"image_url,omitempty"`
	Reason   string       `json:"reason"`
	Tags     []string     `json:"tags,omitempty"`
}
