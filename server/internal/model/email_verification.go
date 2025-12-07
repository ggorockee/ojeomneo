package model

import (
	"time"

	"gorm.io/gorm"
)

// EmailVerification 이메일 인증 모델
type EmailVerification struct {
	ID                uint       `gorm:"primaryKey" json:"id"`
	Email             string     `gorm:"size:255;not null;index:idx_email_verification_email" json:"email"`
	Code              string     `gorm:"size:10;not null" json:"-"`
	VerificationToken *string    `gorm:"size:255;uniqueIndex:idx_email_verification_token" json:"-"`
	IsVerified        bool       `gorm:"default:false;not null" json:"is_verified"`
	ExpiresAt         time.Time  `gorm:"not null;index:idx_email_verification_expires" json:"expires_at"`
	SendCount         int        `gorm:"default:1;not null" json:"send_count"`
	LastSentAt        *time.Time `gorm:"" json:"last_sent_at,omitempty"`
	Attempts          int        `gorm:"default:0;not null" json:"attempts"`
	CreatedAt         time.Time  `gorm:"autoCreateTime;not null" json:"created_at"`
	UpdatedAt         time.Time  `gorm:"autoUpdateTime;not null" json:"updated_at"`
}

// TableName GORM 테이블명 지정
func (EmailVerification) TableName() string {
	return "email_verifications"
}

// IsExpired 만료 여부 확인
func (e *EmailVerification) IsExpired() bool {
	return time.Now().After(e.ExpiresAt)
}

// CanResend 재발송 가능 여부 확인 (60초 쿨다운)
func (e *EmailVerification) CanResend() bool {
	if e.LastSentAt == nil {
		return true
	}
	return time.Since(*e.LastSentAt) >= 60*time.Second
}

