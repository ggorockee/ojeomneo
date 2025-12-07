# Uber-fx DI Framework 및 Zap Logging 도입 검토

## 개요

현재 Ojeomneo 서버는 수동 의존성 주입과 표준 `log` 패키지를 사용하고 있습니다. 이 문서는 Uber-fx DI Framework와 Zap 로깅 라이브러리 도입에 대한 검토 결과를 정리합니다.

---

## 1. 현재 상태 분석

### 1.1 현재 의존성 주입 방식

**현재 구조 (`server/cmd/api/main.go`):**
```go
// 수동으로 모든 의존성 생성
cfg := config.Load()
db, _ := config.ConnectDB(cfg)
rdb, _ := config.ConnectRedis(cfg)
llmClient := llm.NewClient(...)
menuService := service.NewMenuService(db)
sketchService := service.NewSketchService(db, llmClient, menuService)
authService := service.NewAuthService(db, cfg)
// ... 핸들러 초기화
```

**문제점:**
- 의존성 생성 순서를 수동으로 관리해야 함
- 테스트 시 Mock 객체 주입이 어려움
- 생명주기 관리가 명시적이지 않음
- 코드 중복 (각 서비스마다 동일한 패턴 반복)

### 1.2 현재 로깅 방식

**현재 구조:**
- 표준 `log` 패키지 사용
- 단순 텍스트 로깅
- 로그 레벨 구분 없음
- 구조화된 로그 없음
- 성능 최적화 없음

**문제점:**
- 로그 레벨 제어 불가 (Debug, Info, Warn, Error)
- 구조화된 로그 없음 (JSON 형식 불가)
- 성능 최적화 없음 (문자열 포맷팅 오버헤드)
- 로그 필터링/검색 어려움
- 프로덕션 환경에서 로그 분석 어려움

---

## 2. Uber-fx DI Framework 검토

### 2.1 Uber-fx란?

Uber에서 개발한 Go용 의존성 주입 프레임워크로, 다음 기능을 제공합니다:

- **의존성 주입**: 자동으로 의존성 해결 및 주입
- **생명주기 관리**: 초기화/종료 순서 자동 관리
- **모듈화**: 기능별로 모듈 분리 가능
- **테스트 용이성**: Mock 객체 주입 쉬움

### 2.2 장점

1. **코드 간소화**
   - 의존성 생성 코드가 크게 줄어듦
   - 생성 순서 자동 관리

2. **테스트 용이성**
   - Mock 객체 주입이 쉬움
   - 테스트용 모듈 교체 가능

3. **모듈화**
   - 기능별로 모듈 분리
   - 재사용 가능한 컴포넌트

4. **생명주기 관리**
   - 초기화/종료 순서 자동 관리
   - Graceful shutdown 지원

5. **타입 안전성**
   - 컴파일 타임에 의존성 검증
   - 런타임 에러 감소

### 2.3 단점

1. **학습 곡선**
   - 새로운 개념 학습 필요
   - 초기 설정 복잡도 증가

2. **오버헤드**
   - 작은 프로젝트에서는 과도할 수 있음
   - 리플렉션 사용으로 인한 약간의 성능 오버헤드

3. **디버깅 복잡도**
   - 의존성 해결 과정이 숨겨져 있어 디버깅 어려울 수 있음

### 2.4 도입 시 예상 구조

```go
// server/internal/module/database.go
func NewDatabaseModule(cfg *config.Config) fx.Option {
    return fx.Options(
        fx.Provide(func() (*gorm.DB, error) {
            return config.ConnectDB(cfg)
        }),
        fx.Invoke(func(db *gorm.DB) error {
            // AutoMigrate 등 초기화 작업
            return db.AutoMigrate(...)
        }),
    )
}

// server/internal/module/service.go
func NewServiceModule() fx.Option {
    return fx.Options(
        fx.Provide(
            service.NewMenuService,
            service.NewSketchService,
            service.NewAuthService,
        ),
    )
}

// server/cmd/api/main.go
func main() {
    fx.New(
        fx.Provide(config.Load),
        NewDatabaseModule,
        NewRedisModule,
        NewLLMModule,
        NewServiceModule,
        NewHandlerModule,
        fx.Invoke(StartServer),
    ).Run()
}
```

### 2.5 도입 권장 여부

**✅ 권장합니다**

**이유:**
- 프로젝트가 이미 복잡한 의존성 구조를 가지고 있음
- 향후 확장 시 모듈화가 유리함
- 테스트 코드 작성이 쉬워짐
- 생명주기 관리가 명확해짐

---

## 3. Zap Logging 검토

### 3.1 Zap이란?

Uber에서 개발한 고성능 구조화 로깅 라이브러리입니다.

**주요 특징:**
- **고성능**: Zero-allocation JSON 로깅
- **구조화된 로그**: JSON 형식 지원
- **로그 레벨**: Debug, Info, Warn, Error, Fatal, Panic
- **컨텍스트 필드**: 구조화된 필드 추가 가능
- **성능 최적화**: 문자열 포맷팅 오버헤드 최소화

### 3.2 장점

1. **성능**
   - Zero-allocation JSON 로깅
   - 문자열 포맷팅 오버헤드 최소화
   - 프로덕션 환경에 최적화

2. **구조화된 로그**
   ```go
   logger.Info("User logged in",
       zap.String("user_id", userID),
       zap.String("email", email),
       zap.Duration("latency", duration),
   )
   ```

3. **로그 레벨 제어**
   - 개발: Debug 레벨
   - 프로덕션: Info 레벨 이상

4. **통합 용이성**
   - ELK, Datadog, CloudWatch 등과 쉽게 통합
   - JSON 형식으로 파싱 용이

5. **Fiber 통합**
   - `zapadapter`를 통해 Fiber 로거와 통합 가능

### 3.3 단점

1. **API 복잡도**
   - 표준 `log` 패키지보다 API가 복잡함
   - 학습 곡선 존재

2. **의존성 추가**
   - 추가 라이브러리 필요

### 3.4 도입 시 예상 구조

```go
// server/pkg/logger/logger.go
package logger

import (
    "go.uber.org/zap"
    "go.uber.org/zap/zapcore"
)

func NewLogger(env string) (*zap.Logger, error) {
    var config zap.Config
    
    if env == "production" {
        config = zap.NewProductionConfig()
    } else {
        config = zap.NewDevelopmentConfig()
    }
    
    return config.Build()
}

// 사용 예시
logger.Info("Server started",
    zap.String("port", port),
    zap.String("env", env),
)
logger.Error("Database connection failed",
    zap.Error(err),
    zap.String("host", host),
)
```

### 3.5 도입 권장 여부

**✅ 강력히 권장합니다**

**이유:**
- 프로덕션 환경에서 로그 분석이 필수적
- 구조화된 로그로 디버깅 효율 향상
- 성능 최적화로 오버헤드 최소화
- 모니터링 도구와의 통합 용이

---

## 4. 통합 도입 계획

### 4.1 단계별 마이그레이션 계획

#### Phase 1: Zap 로깅 도입 (우선순위 높음)
1. `go.uber.org/zap` 패키지 추가
2. `server/pkg/logger` 패키지 생성
3. 전역 로거 초기화
4. `main.go`에서 표준 `log` → `zap` 교체
5. 핸들러/서비스에서 로깅 교체

**예상 작업 시간:** 2-3시간

#### Phase 2: Uber-fx DI 도입
1. `go.uber.org/fx` 패키지 추가
2. 모듈 구조 설계
3. `server/internal/module` 패키지 생성
4. 각 컴포넌트를 모듈로 변환
5. `main.go` 리팩토링

**예상 작업 시간:** 4-6시간

### 4.2 마이그레이션 시 주의사항

1. **점진적 도입**
   - 한 번에 모든 코드를 변경하지 않음
   - 핵심 부분부터 시작

2. **하위 호환성**
   - 기존 코드와 병행 사용 가능
   - 점진적으로 교체

3. **테스트**
   - 각 단계마다 테스트 수행
   - 기존 기능 동작 확인

---

## 5. 예상 효과

### 5.1 코드 품질 향상

**Before:**
```go
log.Printf("Warning: Failed to connect to database: %v", err)
```

**After:**
```go
logger.Warn("Failed to connect to database",
    zap.Error(err),
    zap.String("host", cfg.DBHost),
    zap.String("database", cfg.DBName),
)
```

### 5.2 의존성 관리 개선

**Before:**
```go
db, _ := config.ConnectDB(cfg)
menuService := service.NewMenuService(db)
sketchService := service.NewSketchService(db, llmClient, menuService)
```

**After:**
```go
fx.New(
    fx.Provide(config.ConnectDB),
    fx.Provide(service.NewMenuService),
    fx.Provide(service.NewSketchService),
    // 의존성 자동 해결
)
```

### 5.3 테스트 용이성

**Before:**
```go
// 테스트마다 수동으로 Mock 객체 생성
db := &MockDB{}
service := service.NewMenuService(db)
```

**After:**
```go
// 테스트용 모듈로 교체
fx.New(
    fx.Provide(func() *gorm.DB { return mockDB }),
    fx.Provide(service.NewMenuService),
)
```

---

## 6. 결론 및 권장사항

### 6.1 최종 권장사항

1. **Zap 로깅: 즉시 도입 권장** ⭐⭐⭐⭐⭐
   - 프로덕션 환경에서 필수적
   - 성능 및 디버깅 효율 향상
   - 작업 시간 대비 효과 큼

2. **Uber-fx DI: 단기 내 도입 권장** ⭐⭐⭐⭐
   - 코드 품질 향상
   - 테스트 용이성 증가
   - 향후 확장성 고려

### 6.2 우선순위

1. **1순위: Zap 로깅 도입**
   - 즉시 시작 가능
   - 빠른 효과

2. **2순위: Uber-fx DI 도입**
   - Zap 도입 후 진행
   - 점진적 마이그레이션

### 6.3 예상 작업 시간

- **Zap 로깅:** 2-3시간
- **Uber-fx DI:** 4-6시간
- **총 예상 시간:** 6-9시간

---

## 7. 참고 자료

- [Uber-fx 공식 문서](https://github.com/uber-go/fx)
- [Zap 공식 문서](https://github.com/uber-go/zap)
- [Fiber Zap Adapter](https://github.com/gofiber/fiber/tree/master/middleware/logger)

---

## 8. 다음 단계

1. 이 문서 검토 및 승인
2. Zap 로깅 도입 시작
3. Uber-fx DI 도입 시작
4. 테스트 및 검증
5. 문서화 업데이트

