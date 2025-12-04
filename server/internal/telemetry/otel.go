package telemetry

import (
	"context"
	"log"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/runtime"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/metric"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
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

// Providers OpenTelemetry providers
type Providers struct {
	TracerProvider *sdktrace.TracerProvider
	MeterProvider  *sdkmetric.MeterProvider
}

// Shutdown 모든 providers 종료
func (p *Providers) Shutdown(ctx context.Context) error {
	var errs []error
	if p.TracerProvider != nil {
		if err := p.TracerProvider.Shutdown(ctx); err != nil {
			errs = append(errs, err)
		}
	}
	if p.MeterProvider != nil {
		if err := p.MeterProvider.Shutdown(ctx); err != nil {
			errs = append(errs, err)
		}
	}
	if len(errs) > 0 {
		return errs[0]
	}
	return nil
}

// InitTelemetry OpenTelemetry tracer와 meter 초기화
func InitTelemetry(cfg Config) (*Providers, error) {
	ctx := context.Background()

	// 리소스 정보 설정 (Trace와 Metrics 공통)
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

	providers := &Providers{}

	// Trace Exporter 설정
	traceExporter, err := otlptracegrpc.New(ctx,
		otlptracegrpc.WithEndpoint(cfg.OTLPEndpoint),
		otlptracegrpc.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	// TracerProvider 생성
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(traceExporter),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
	)
	providers.TracerProvider = tp
	otel.SetTracerProvider(tp)

	// Context propagation 설정
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	// Metrics Exporter 설정
	metricExporter, err := otlpmetricgrpc.New(ctx,
		otlpmetricgrpc.WithEndpoint(cfg.OTLPEndpoint),
		otlpmetricgrpc.WithInsecure(),
	)
	if err != nil {
		return nil, err
	}

	// MeterProvider 생성 (15초마다 메트릭 전송)
	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
		sdkmetric.WithReader(sdkmetric.NewPeriodicReader(metricExporter,
			sdkmetric.WithInterval(15*time.Second),
		)),
	)
	providers.MeterProvider = mp
	otel.SetMeterProvider(mp)

	// 공식 Go Runtime Metrics 시작 (OpenTelemetry 표준 메트릭 이름 사용)
	// 메트릭: go.memory.used, go.memory.allocated, go.goroutine.count, go.gc.* 등
	if err := runtime.Start(
		runtime.WithMinimumReadMemStatsInterval(time.Second),
	); err != nil {
		log.Printf("Warning: Failed to start runtime metrics: %v", err)
	} else {
		log.Println("Go runtime metrics started (OpenTelemetry standard)")
	}

	log.Printf("OpenTelemetry initialized (endpoint: %s, service: %s) - Traces and Metrics enabled", cfg.OTLPEndpoint, cfg.ServiceName)

	return providers, nil
}

// InitTracer OpenTelemetry tracer 초기화 (하위 호환성 유지)
// Deprecated: Use InitTelemetry instead
func InitTracer(cfg Config) (func(context.Context) error, error) {
	providers, err := InitTelemetry(cfg)
	if err != nil {
		return nil, err
	}
	return providers.Shutdown, nil
}

// RegisterHTTPMetrics HTTP 요청 메트릭 등록
func RegisterHTTPMetrics(mp *sdkmetric.MeterProvider) (metric.Int64Counter, metric.Float64Histogram, error) {
	meter := mp.Meter("http.server",
		metric.WithInstrumentationVersion("1.0.0"),
	)

	// HTTP 요청 수
	requestCounter, err := meter.Int64Counter(
		"http.server.requests",
		metric.WithDescription("Total number of HTTP requests"),
		metric.WithUnit("{request}"),
	)
	if err != nil {
		return nil, nil, err
	}

	// HTTP 응답 시간
	latencyHistogram, err := meter.Float64Histogram(
		"http.server.request.duration",
		metric.WithDescription("HTTP request duration"),
		metric.WithUnit("ms"),
	)
	if err != nil {
		return nil, nil, err
	}

	return requestCounter, latencyHistogram, nil
}

// RecordHTTPRequest HTTP 요청 메트릭 기록 헬퍼
func RecordHTTPRequest(ctx context.Context, counter metric.Int64Counter, histogram metric.Float64Histogram, method, path string, statusCode int, durationMs float64) {
	attrs := metric.WithAttributes(
		attribute.String("http.method", method),
		attribute.String("http.route", path),
		attribute.Int("http.status_code", statusCode),
	)
	counter.Add(ctx, 1, attrs)
	histogram.Record(ctx, durationMs, attrs)
}
