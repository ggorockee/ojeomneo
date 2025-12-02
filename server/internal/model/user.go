package model

import (
	"time"

	"gorm.io/gorm"
)

// LoginMethod 로그인 방식
type LoginMethod string

const (
	LoginMethodEmail  LoginMethod = "email"
	LoginMethodKakao  LoginMethod = "kakao"
	LoginMethodGoogle LoginMethod = "google"
	LoginMethodApple  LoginMethod = "apple"
)

// User 사용자 모델
// Django AbstractUser와 호환되는 필드 구조
type User struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	Password    string         `gorm:"size:128;not null" json:"-"`
	LastLogin   *time.Time     `gorm:"" json:"last_login,omitempty"`
	IsSuperuser bool           `gorm:"default:false;not null" json:"is_superuser"`
	Username    string         `gorm:"size:150;uniqueIndex;not null" json:"username"`
	FirstName   string         `gorm:"size:150;not null;default:''" json:"first_name"`
	LastName    string         `gorm:"size:150;not null;default:''" json:"last_name"`
	Email       string         `gorm:"size:254;not null;index:idx_email_login_method" json:"email"`
	IsStaff     bool           `gorm:"default:false;not null" json:"is_staff"`
	IsActive    bool           `gorm:"default:true;not null" json:"is_active"`
	DateJoined  time.Time      `gorm:"autoCreateTime;not null" json:"date_joined"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at,omitempty"`

	// SNS 로그인 지원 필드
	LoginMethod LoginMethod `gorm:"size:20;not null;default:'email';index:idx_email_login_method" json:"login_method"`
	SocialID    string      `gorm:"size:255;not null;default:''" json:"social_id,omitempty"`
}

// TableName GORM 테이블명 지정
func (User) TableName() string {
	return "users"
}

// BeforeCreate 생성 전 훅
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.LoginMethod == "" {
		u.LoginMethod = LoginMethodEmail
	}
	return nil
}

// IsSocialUser SNS 로그인 사용자 여부
func (u *User) IsSocialUser() bool {
	return u.LoginMethod != LoginMethodEmail
}
