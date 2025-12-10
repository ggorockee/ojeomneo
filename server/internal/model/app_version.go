package model

import (
	"time"
)

// Platform 플랫폼 타입
type Platform string

const (
	PlatformIOS     Platform = "ios"
	PlatformAndroid Platform = "android"
)

// AppVersion 앱 버전 관리 모델
type AppVersion struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	Platform      Platform  `gorm:"size:20;not null;uniqueIndex" json:"platform"`
	MinVersion    string    `gorm:"size:20;not null" json:"min_version"`
	LatestVersion string    `gorm:"size:20;not null" json:"latest_version"`
	ForceUpdate   bool      `gorm:"default:false;not null" json:"force_update"`
	StoreURL      string    `gorm:"type:text" json:"store_url"`
	UpdateMessage string    `gorm:"type:text" json:"update_message"`
	IsActive      bool      `gorm:"default:true;not null" json:"is_active"`
	UpdatedAt     time.Time `gorm:"autoUpdateTime" json:"updated_at"`
	UpdatedBy     *uint     `gorm:"index" json:"updated_by,omitempty"`
}

// TableName GORM 테이블명 지정
func (AppVersion) TableName() string {
	return "app_versions"
}

// AppVersionRequest 버전 체크 요청
type AppVersionRequest struct {
	Platform       string `query:"platform" validate:"required,oneof=ios android"`
	CurrentVersion string `query:"current_version" validate:"required"`
}

// AppVersionResponse 버전 체크 응답
type AppVersionResponse struct {
	NeedsUpdate   bool   `json:"needs_update"`   // 업데이트 필요 여부
	ForceUpdate   bool   `json:"force_update"`   // 강제 업데이트 여부
	LatestVersion string `json:"latest_version"` // 최신 버전
	MinVersion    string `json:"min_version"`    // 최소 지원 버전
	StoreURL      string `json:"store_url"`      // 앱 스토어 URL
	UpdateMessage string `json:"update_message"` // 업데이트 메시지
}

// ToResponse AppVersion을 API 응답용 구조체로 변환
func (a *AppVersion) ToResponse() AppVersionResponse {
	return AppVersionResponse{
		ForceUpdate:   a.ForceUpdate,
		LatestVersion: a.LatestVersion,
		MinVersion:    a.MinVersion,
		StoreURL:      a.StoreURL,
		UpdateMessage: a.UpdateMessage,
	}
}

// Label 플랫폼 한글 라벨 반환
func (p Platform) Label() string {
	labels := map[Platform]string{
		PlatformIOS:     "iOS",
		PlatformAndroid: "Android",
	}
	if label, ok := labels[p]; ok {
		return label
	}
	return string(p)
}
