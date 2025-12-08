package telemetry

import (
	"context"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
)

// HTTPMetrics HTTP 요청 관련 메트릭
type HTTPMetrics struct {
	RequestCounter   metric.Int64Counter     // HTTP 요청 수
	LatencyHistogram metric.Float64Histogram // HTTP 응답 시간
}

// AuthMetrics 인증 관련 메트릭
type AuthMetrics struct {
	LoginCounter       metric.Int64Counter   // 로그인 시도 카운터
	LoginDuration      metric.Float64Histogram // 로그인 처리 시간
	TokenIssued        metric.Int64Counter   // 토큰 발급 카운터
	SNSLoginCounter    metric.Int64Counter   // SNS 로그인 카운터
	VerificationSent   metric.Int64Counter   // 이메일 인증 발송 카운터
	PasswordResetSent  metric.Int64Counter   // 비밀번호 재설정 발송 카운터
}

// RegisterAuthMetrics 인증 메트릭 등록
func RegisterAuthMetrics(mp *sdkmetric.MeterProvider) (*AuthMetrics, error) {
	meter := mp.Meter("auth.server",
		metric.WithInstrumentationVersion("1.0.0"),
	)

	// 로그인 시도 카운터
	loginCounter, err := meter.Int64Counter(
		"auth.login.total",
		metric.WithDescription("Total number of login attempts"),
		metric.WithUnit("{login}"),
	)
	if err != nil {
		return nil, err
	}

	// 로그인 처리 시간
	loginDuration, err := meter.Float64Histogram(
		"auth.login.duration",
		metric.WithDescription("Login processing duration"),
		metric.WithUnit("ms"),
	)
	if err != nil {
		return nil, err
	}

	// 토큰 발급 카운터
	tokenIssued, err := meter.Int64Counter(
		"auth.token.issued",
		metric.WithDescription("Total number of tokens issued"),
		metric.WithUnit("{token}"),
	)
	if err != nil {
		return nil, err
	}

	// SNS 로그인 카운터
	snsLoginCounter, err := meter.Int64Counter(
		"auth.sns.login.total",
		metric.WithDescription("Total number of SNS login attempts"),
		metric.WithUnit("{login}"),
	)
	if err != nil {
		return nil, err
	}

	// 이메일 인증 발송 카운터
	verificationSent, err := meter.Int64Counter(
		"auth.verification.sent",
		metric.WithDescription("Total number of verification emails sent"),
		metric.WithUnit("{email}"),
	)
	if err != nil {
		return nil, err
	}

	// 비밀번호 재설정 발송 카운터
	passwordResetSent, err := meter.Int64Counter(
		"auth.password_reset.sent",
		metric.WithDescription("Total number of password reset emails sent"),
		metric.WithUnit("{email}"),
	)
	if err != nil {
		return nil, err
	}

	return &AuthMetrics{
		LoginCounter:      loginCounter,
		LoginDuration:     loginDuration,
		TokenIssued:       tokenIssued,
		SNSLoginCounter:   snsLoginCounter,
		VerificationSent:  verificationSent,
		PasswordResetSent: passwordResetSent,
	}, nil
}

// RecordLogin 로그인 시도 기록
func (m *AuthMetrics) RecordLogin(ctx context.Context, method, status string, durationMs float64) {
	attrs := metric.WithAttributes(
		attribute.String("auth.method", method),      // "email", "google", "apple", "kakao"
		attribute.String("auth.status", status),      // "success", "failed"
	)
	m.LoginCounter.Add(ctx, 1, attrs)
	m.LoginDuration.Record(ctx, durationMs, metric.WithAttributes(
		attribute.String("auth.method", method),
	))
}

// RecordSNSLogin SNS 로그인 기록
func (m *AuthMetrics) RecordSNSLogin(ctx context.Context, provider, status string, durationMs float64) {
	attrs := metric.WithAttributes(
		attribute.String("sns.provider", provider),   // "google", "apple", "kakao"
		attribute.String("auth.status", status),      // "success", "failed", "token_invalid"
	)
	m.SNSLoginCounter.Add(ctx, 1, attrs)
	m.LoginDuration.Record(ctx, durationMs, metric.WithAttributes(
		attribute.String("auth.method", provider),
	))
}

// RecordTokenIssued 토큰 발급 기록
func (m *AuthMetrics) RecordTokenIssued(ctx context.Context, tokenType string) {
	m.TokenIssued.Add(ctx, 1, metric.WithAttributes(
		attribute.String("token.type", tokenType), // "access", "refresh"
	))
}

// RecordVerificationSent 이메일 인증 발송 기록
func (m *AuthMetrics) RecordVerificationSent(ctx context.Context, status string) {
	m.VerificationSent.Add(ctx, 1, metric.WithAttributes(
		attribute.String("email.status", status), // "success", "failed"
	))
}

// RecordPasswordResetSent 비밀번호 재설정 발송 기록
func (m *AuthMetrics) RecordPasswordResetSent(ctx context.Context, status string) {
	m.PasswordResetSent.Add(ctx, 1, metric.WithAttributes(
		attribute.String("email.status", status), // "success", "failed"
	))
}

// DBMetrics 데이터베이스 관련 메트릭
type DBMetrics struct {
	ConnectionsActive metric.Int64ObservableGauge // 활성 연결 수
	ConnectionsIdle   metric.Int64ObservableGauge // 유휴 연결 수
	ConnectionsMax    metric.Int64ObservableGauge // 최대 연결 수
}

// RegisterDBMetrics DB 메트릭 등록
// 참고: GORM의 otelgorm 플러그인이 이미 쿼리 성능 메트릭을 자동 수집합니다.
// 이 함수는 연결 풀 상태를 추가로 모니터링합니다.
func RegisterDBMetrics(mp *sdkmetric.MeterProvider) (*DBMetrics, error) {
	meter := mp.Meter("db.server",
		metric.WithInstrumentationVersion("1.0.0"),
	)

	// 활성 연결 수
	connectionsActive, err := meter.Int64ObservableGauge(
		"db.client.connections.active",
		metric.WithDescription("Number of active database connections"),
		metric.WithUnit("{connection}"),
	)
	if err != nil {
		return nil, err
	}

	// 유휴 연결 수
	connectionsIdle, err := meter.Int64ObservableGauge(
		"db.client.connections.idle",
		metric.WithDescription("Number of idle database connections"),
		metric.WithUnit("{connection}"),
	)
	if err != nil {
		return nil, err
	}

	// 최대 연결 수
	connectionsMax, err := meter.Int64ObservableGauge(
		"db.client.connections.max",
		metric.WithDescription("Maximum number of database connections"),
		metric.WithUnit("{connection}"),
	)
	if err != nil {
		return nil, err
	}

	return &DBMetrics{
		ConnectionsActive: connectionsActive,
		ConnectionsIdle:   connectionsIdle,
		ConnectionsMax:    connectionsMax,
	}, nil
}
