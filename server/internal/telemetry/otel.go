package telemetry

import (
	"context"
	"log"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

// Config OpenTelemetry 설정
type Config struct {
	ServiceName    string
	ServiceVersion string
	Environment    string
	OTLPEndpoint   string // SigNoz OTLP endpoint (예: signoz-otel-collector.signoz:4317)
}

// InitTracer OpenTelemetry tracer 초기화
func InitTracer(cfg Config) (func(context.Context) error, error) {
	ctx := context.Background()

	// OTLP gRPC exporter 생성
	exporter, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithEndpoint(cfg.OTLPEndpoint),
		otlptracegrpc.WithInsecure(), // 클러스터 내부 통신이므로 TLS 불필요
	)
	if err != nil {
		return nil, err
	}

	// 리소스 정보 설정
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceName(cfg.ServiceName),
			semconv.ServiceVersion(cfg.ServiceVersion),
			semconv.DeploymentEnvironment(cfg.Environment),
		),
	)
	if err != nil {
		return nil, err
	}

	// TracerProvider 생성
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(sdktrace.AlwaysSample()), // 모든 요청 샘플링 (프로덕션에서는 조정 필요)
	)

	// 전역 TracerProvider 설정
	otel.SetTracerProvider(tp)

	// Context propagation 설정 (분산 트레이싱용)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	log.Printf("OpenTelemetry initialized (endpoint: %s, service: %s)", cfg.OTLPEndpoint, cfg.ServiceName)

	// shutdown 함수 반환
	return tp.Shutdown, nil
}
