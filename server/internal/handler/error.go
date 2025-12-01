package handler

import (
	"os"

	"github.com/gofiber/fiber/v2"
)

// ErrorResponse 에러 응답 구조체 (Naver 스타일)
type ErrorResponse struct {
	Success bool      `json:"success"`
	Error   ErrorInfo `json:"error"`
}

// ErrorInfo 에러 상세 정보
// message: 사용자용 (한글, 친절하게)
// detail: 개발자용 (디버깅 정보, production에서는 숨김)
type ErrorInfo struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Detail  string `json:"detail,omitempty"`
}

// 에러 코드별 사용자 메시지 (Naver 스타일)
var userMessages = map[string]string{
	"INVALID_INPUT":      "입력 정보를 다시 확인해 주세요.",
	"NOT_FOUND":          "요청하신 정보를 찾을 수 없습니다.",
	"UNAUTHORIZED":       "로그인이 필요한 서비스입니다.",
	"FORBIDDEN":          "접근 권한이 없습니다.",
	"METHOD_NOT_ALLOWED": "지원하지 않는 요청 방식입니다.",
	"INTERNAL_ERROR":     "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.",
	"DB_ERROR":           "서비스 연결에 문제가 발생했습니다.",
	"RATE_LIMIT":         "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.",
	"BAD_REQUEST":        "요청 형식이 올바르지 않습니다.",
	"CONFLICT":           "이미 존재하는 정보입니다.",
	"VALIDATION_ERROR":   "입력값이 올바르지 않습니다.",
}

// getUserMessage 에러 코드에 해당하는 사용자 메시지 반환
func getUserMessage(code string) string {
	if msg, ok := userMessages[code]; ok {
		return msg
	}
	return "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요."
}

// isProduction 운영 환경인지 확인
func isProduction() bool {
	return os.Getenv("APP_ENV") == "production"
}

// CustomErrorHandler Fiber 커스텀 에러 핸들러
func CustomErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	errorCode := "INTERNAL_ERROR"
	detail := err.Error()

	// Fiber 에러인 경우 상태 코드 추출
	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
		detail = e.Message

		switch code {
		case fiber.StatusNotFound:
			errorCode = "NOT_FOUND"
		case fiber.StatusBadRequest:
			errorCode = "BAD_REQUEST"
		case fiber.StatusUnauthorized:
			errorCode = "UNAUTHORIZED"
		case fiber.StatusForbidden:
			errorCode = "FORBIDDEN"
		case fiber.StatusMethodNotAllowed:
			errorCode = "METHOD_NOT_ALLOWED"
		case fiber.StatusConflict:
			errorCode = "CONFLICT"
		case fiber.StatusTooManyRequests:
			errorCode = "RATE_LIMIT"
		}
	}

	response := ErrorResponse{
		Success: false,
		Error: ErrorInfo{
			Code:    errorCode,
			Message: getUserMessage(errorCode),
		},
	}

	// 개발 환경에서만 detail 포함
	if !isProduction() {
		response.Error.Detail = detail
	}

	return c.Status(code).JSON(response)
}

// NewError 에러 응답 생성 헬퍼
func NewError(c *fiber.Ctx, status int, code, detail string) error {
	response := ErrorResponse{
		Success: false,
		Error: ErrorInfo{
			Code:    code,
			Message: getUserMessage(code),
		},
	}

	// 개발 환경에서만 detail 포함
	if !isProduction() {
		response.Error.Detail = detail
	}

	return c.Status(status).JSON(response)
}

// NewValidationError 검증 에러 응답 생성
func NewValidationError(c *fiber.Ctx, field, reason string) error {
	detail := field + " 필드가 유효하지 않습니다: " + reason
	return NewError(c, fiber.StatusBadRequest, "VALIDATION_ERROR", detail)
}

// NewNotFoundError 리소스 없음 에러 응답 생성
func NewNotFoundError(c *fiber.Ctx, resource, id string) error {
	detail := resource + " ID " + id + "를 찾을 수 없습니다."
	return NewError(c, fiber.StatusNotFound, "NOT_FOUND", detail)
}

// NewUnauthorizedError 인증 에러 응답 생성
func NewUnauthorizedError(c *fiber.Ctx, reason string) error {
	return NewError(c, fiber.StatusUnauthorized, "UNAUTHORIZED", reason)
}

// NewForbiddenError 권한 에러 응답 생성
func NewForbiddenError(c *fiber.Ctx, reason string) error {
	return NewError(c, fiber.StatusForbidden, "FORBIDDEN", reason)
}

// NewInternalError 내부 에러 응답 생성
func NewInternalError(c *fiber.Ctx, detail string) error {
	return NewError(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", detail)
}

// NewDBError 데이터베이스 에러 응답 생성
func NewDBError(c *fiber.Ctx, detail string) error {
	return NewError(c, fiber.StatusInternalServerError, "DB_ERROR", "데이터베이스 쿼리 실패: "+detail)
}
