package email

import (
	"bytes"
	"fmt"
	"html/template"
	"net/smtp"
	"strings"

	"go.uber.org/zap"
)

// SMTPConfig SMTP 설정
type SMTPConfig struct {
	Host     string
	Port     string
	Username string
	Password string
	From     string
}

// SMTPService SMTP 이메일 발송 서비스
type SMTPService struct {
	config *SMTPConfig
	logger *zap.Logger
}

// NewSMTPService 새 SMTP 서비스 생성
func NewSMTPService(config *SMTPConfig, logger *zap.Logger) *SMTPService {
	return &SMTPService{
		config: config,
		logger: logger,
	}
}

// EmailData 이메일 템플릿 데이터
type EmailData struct {
	Code    string
	Purpose string // "verification" 또는 "password_reset"
}

// SendVerificationCode 인증코드 발송 (회원가입용)
func (s *SMTPService) SendVerificationCode(to, code string) error {
	subject := "[오점너] 이메일 인증 코드"
	data := EmailData{
		Code:    code,
		Purpose: "verification",
	}

	body, err := s.renderTemplate(data)
	if err != nil {
		s.logger.Error("Failed to render email template",
			zap.Error(err),
			zap.String("to", to),
		)
		return fmt.Errorf("이메일 템플릿 생성 실패: %w", err)
	}

	return s.send(to, subject, body)
}

// SendPasswordResetCode 비밀번호 재설정 인증코드 발송
func (s *SMTPService) SendPasswordResetCode(to, code string) error {
	subject := "[오점너] 비밀번호 재설정 인증 코드"
	data := EmailData{
		Code:    code,
		Purpose: "password_reset",
	}

	body, err := s.renderTemplate(data)
	if err != nil {
		s.logger.Error("Failed to render password reset email template",
			zap.Error(err),
			zap.String("to", to),
		)
		return fmt.Errorf("이메일 템플릿 생성 실패: %w", err)
	}

	return s.send(to, subject, body)
}

// send 이메일 발송 (공통)
func (s *SMTPService) send(to, subject, body string) error {
	auth := smtp.PlainAuth("", s.config.Username, s.config.Password, s.config.Host)

	// MIME 헤더 설정
	headers := make(map[string]string)
	headers["From"] = s.config.From
	headers["To"] = to
	headers["Subject"] = subject
	headers["MIME-Version"] = "1.0"
	headers["Content-Type"] = "text/html; charset=UTF-8"

	// 메시지 구성
	var message strings.Builder
	for k, v := range headers {
		message.WriteString(fmt.Sprintf("%s: %s\r\n", k, v))
	}
	message.WriteString("\r\n")
	message.WriteString(body)

	// 이메일 발송
	addr := fmt.Sprintf("%s:%s", s.config.Host, s.config.Port)
	err := smtp.SendMail(addr, auth, s.config.From, []string{to}, []byte(message.String()))
	if err != nil {
		s.logger.Error("Failed to send email",
			zap.Error(err),
			zap.String("to", to),
			zap.String("host", s.config.Host),
			zap.String("port", s.config.Port),
		)
		return fmt.Errorf("이메일 발송 실패: %w", err)
	}

	s.logger.Info("Email sent successfully",
		zap.String("to", to),
		zap.String("subject", subject),
	)

	return nil
}

// renderTemplate HTML 템플릿 렌더링
func (s *SMTPService) renderTemplate(data EmailData) (string, error) {
	var tmplContent string

	if data.Purpose == "verification" {
		tmplContent = verificationEmailTemplate
	} else if data.Purpose == "password_reset" {
		tmplContent = passwordResetEmailTemplate
	} else {
		return "", fmt.Errorf("unknown email purpose: %s", data.Purpose)
	}

	tmpl, err := template.New("email").Parse(tmplContent)
	if err != nil {
		return "", fmt.Errorf("failed to parse template: %w", err)
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		return "", fmt.Errorf("failed to execute template: %w", err)
	}

	return buf.String(), nil
}

// verificationEmailTemplate 회원가입 인증코드 이메일 템플릿
const verificationEmailTemplate = `
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오점너 이메일 인증</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Apple SD Gothic Neo', sans-serif; background-color: #f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- 헤더 -->
                    <tr>
                        <td style="padding: 40px 40px 20px 40px; text-align: center;">
                            <h1 style="margin: 0; color: #1A1C1E; font-size: 28px; font-weight: 700;">오점너</h1>
                            <p style="margin: 8px 0 0 0; color: #6B7280; font-size: 14px;">AI 기반 메뉴 추천 서비스</p>
                        </td>
                    </tr>

                    <!-- 본문 -->
                    <tr>
                        <td style="padding: 20px 40px;">
                            <h2 style="margin: 0 0 16px 0; color: #1A1C1E; font-size: 20px; font-weight: 600;">이메일 인증</h2>
                            <p style="margin: 0 0 24px 0; color: #4B5563; font-size: 16px; line-height: 1.6;">
                                오점너 회원가입을 위해 아래 인증코드를 입력해 주세요.
                            </p>

                            <!-- 인증코드 박스 -->
                            <div style="background-color: #F3F4F6; border-radius: 8px; padding: 24px; text-align: center; margin-bottom: 24px;">
                                <p style="margin: 0 0 8px 0; color: #6B7280; font-size: 14px; font-weight: 500;">인증코드</p>
                                <p style="margin: 0; color: #1A1C1E; font-size: 32px; font-weight: 700; letter-spacing: 4px; font-family: 'Courier New', monospace;">{{.Code}}</p>
                            </div>

                            <p style="margin: 0 0 8px 0; color: #6B7280; font-size: 14px; line-height: 1.6;">
                                • 인증코드는 발송 시점부터 <strong style="color: #1A1C1E;">10분간</strong> 유효합니다.<br>
                                • 본인이 요청하지 않은 경우, 이 이메일을 무시하셔도 됩니다.
                            </p>
                        </td>
                    </tr>

                    <!-- 푸터 -->
                    <tr>
                        <td style="padding: 20px 40px 40px 40px; border-top: 1px solid #E5E7EB;">
                            <p style="margin: 0; color: #9CA3AF; font-size: 12px; text-align: center;">
                                © 2025 오점너. All rights reserved.<br>
                                본 메일은 발신 전용이며, 회신되지 않습니다.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
`

// passwordResetEmailTemplate 비밀번호 재설정 인증코드 이메일 템플릿
const passwordResetEmailTemplate = `
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>오점너 비밀번호 재설정</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Apple SD Gothic Neo', sans-serif; background-color: #f5f5f5;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                    <!-- 헤더 -->
                    <tr>
                        <td style="padding: 40px 40px 20px 40px; text-align: center;">
                            <h1 style="margin: 0; color: #1A1C1E; font-size: 28px; font-weight: 700;">오점너</h1>
                            <p style="margin: 8px 0 0 0; color: #6B7280; font-size: 14px;">AI 기반 메뉴 추천 서비스</p>
                        </td>
                    </tr>

                    <!-- 본문 -->
                    <tr>
                        <td style="padding: 20px 40px;">
                            <h2 style="margin: 0 0 16px 0; color: #1A1C1E; font-size: 20px; font-weight: 600;">비밀번호 재설정</h2>
                            <p style="margin: 0 0 24px 0; color: #4B5563; font-size: 16px; line-height: 1.6;">
                                비밀번호 재설정을 위해 아래 인증코드를 입력해 주세요.
                            </p>

                            <!-- 인증코드 박스 -->
                            <div style="background-color: #FEF3C7; border-radius: 8px; padding: 24px; text-align: center; margin-bottom: 24px; border: 2px solid #F59E0B;">
                                <p style="margin: 0 0 8px 0; color: #92400E; font-size: 14px; font-weight: 500;">인증코드</p>
                                <p style="margin: 0; color: #92400E; font-size: 32px; font-weight: 700; letter-spacing: 4px; font-family: 'Courier New', monospace;">{{.Code}}</p>
                            </div>

                            <p style="margin: 0 0 8px 0; color: #6B7280; font-size: 14px; line-height: 1.6;">
                                • 인증코드는 발송 시점부터 <strong style="color: #1A1C1E;">60분간</strong> 유효합니다.<br>
                                • 본인이 요청하지 않은 경우, 즉시 비밀번호를 변경하시기 바랍니다.
                            </p>

                            <div style="background-color: #FEF2F2; border-radius: 8px; padding: 16px; margin-top: 16px; border-left: 4px solid #EF4444;">
                                <p style="margin: 0; color: #991B1B; font-size: 13px; font-weight: 500;">
                                    ⚠️ 보안 안내<br>
                                    <span style="font-weight: 400;">타인에게 인증코드를 공유하지 마세요. 오점너는 인증코드를 묻지 않습니다.</span>
                                </p>
                            </div>
                        </td>
                    </tr>

                    <!-- 푸터 -->
                    <tr>
                        <td style="padding: 20px 40px 40px 40px; border-top: 1px solid #E5E7EB;">
                            <p style="margin: 0; color: #9CA3AF; font-size: 12px; text-align: center;">
                                © 2025 오점너. All rights reserved.<br>
                                본 메일은 발신 전용이며, 회신되지 않습니다.
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
`
