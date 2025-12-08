# Ojeomneo 모니터링 설정 가이드

## 개요

Ojeomneo Server는 **OpenTelemetry**를 사용하여 **SigNoz**로 메트릭과 트레이스를 전송합니다.
관리자는 SigNoz 대시보드를 통해 시스템 상태를 실시간으로 모니터링할 수 있습니다.

---

## 📊 모니터링 항목

### 1. **APM (Application Performance Monitoring)**
- HTTP 요청률 (RPS)
- HTTP 응답 시간 (P50, P95, P99)
- HTTP 에러율 (4xx, 5xx)
- 엔드포인트별 성능 분석

### 2. **인증 (Authentication)**
- 로그인 시도 및 성공률 (이메일, Google, Apple, Kakao)
- SNS 제공자별 로그인 통계
- 토큰 발급 현황 (Access, Refresh)
- 이메일 인증/비밀번호 재설정 발송 통계
- 로그인 처리 시간

### 3. **데이터베이스**
- 활성/유휴 연결 수
- 쿼리 실행 시간 (P95)
- 연결 풀 사용률
- 테이블별 쿼리 성능

### 4. **Go Runtime**
- Heap 메모리 사용량
- Goroutine 개수
- GC (Garbage Collection) 일시정지 시간
- CPU 사용률

---

## 🏗️ 아키텍처

```
┌─────────────────┐
│  Ojeomneo Server │
│   (Go Fiber)     │
└────────┬─────────┘
         │ OpenTelemetry SDK
         │ (Metrics + Traces)
         ▼
┌─────────────────────────┐
│  SigNoz OTLP Collector  │
│  (signoz-otel-collector)│
└────────┬────────────────┘
         │
         ▼
┌─────────────────┐
│  SigNoz Query   │
│  Service        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SigNoz UI      │
│  (Dashboard)    │
└─────────────────┘
```

---

## ⚙️ 설정

### 환경변수

**Server (`server/.env`)**:
```bash
# OpenTelemetry 설정
OTEL_EXPORTER_OTLP_ENDPOINT=signoz-otel-collector.monitoring:4317

# 또는 Kubernetes ConfigMap에서
OTEL_EXPORTER_OTLP_ENDPOINT=signoz-otel-collector.signoz:4317
```

**Kubernetes ConfigMap** (`/home/woohaen88/infra/charts/helm/prod/ojeomneo/values.yaml`):
```yaml
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "signoz-otel-collector.monitoring:4317"
  - name: APP_ENV
    value: "production"
```

---

## 📈 메트릭 목록

### HTTP 메트릭
| 메트릭 이름 | 타입 | 설명 | 레이블 |
|------------|------|------|--------|
| `http.server.requests` | Counter | HTTP 요청 수 | `http.method`, `http.route`, `http.status_code` |
| `http.server.request.duration` | Histogram | HTTP 응답 시간 (ms) | `http.method`, `http.route` |

### 인증 메트릭
| 메트릭 이름 | 타입 | 설명 | 레이블 |
|------------|------|------|--------|
| `auth.login.total` | Counter | 로그인 시도 수 | `auth.method`, `auth.status` |
| `auth.login.duration` | Histogram | 로그인 처리 시간 (ms) | `auth.method` |
| `auth.sns.login.total` | Counter | SNS 로그인 시도 수 | `sns.provider`, `auth.status` |
| `auth.token.issued` | Counter | 토큰 발급 수 | `token.type` |
| `auth.verification.sent` | Counter | 이메일 인증 발송 수 | `email.status` |
| `auth.password_reset.sent` | Counter | 비밀번호 재설정 발송 수 | `email.status` |

### 데이터베이스 메트릭 (otelgorm 자동 수집)
| 메트릭 이름 | 타입 | 설명 | 레이블 |
|------------|------|------|--------|
| `db.client.connections.active` | Gauge | 활성 연결 수 | - |
| `db.client.connections.idle` | Gauge | 유휴 연결 수 | - |
| `db.client.connections.max` | Gauge | 최대 연결 수 | - |
| `db.client.operation.duration` | Histogram | 쿼리 실행 시간 (ms) | `db.operation`, `db.sql.table` |

### Go Runtime 메트릭 (OpenTelemetry 표준)
| 메트릭 이름 | 타입 | 설명 |
|------------|------|------|
| `go.memory.used` | Gauge | Heap 메모리 사용량 (bytes) |
| `go.memory.allocated` | Counter | 할당된 메모리 총량 (bytes) |
| `go.goroutine.count` | Gauge | 활성 Goroutine 개수 |
| `go.gc.pause_ns` | Histogram | GC 일시정지 시간 (ns) |

---

## 🎨 SigNoz 대시보드

### 대시보드 import

1. **대시보드 JSON 파일**: `/home/woohaen88/woohalabs/ojeomneo/signoz_ojeomneo_dashboard.json`
2. **SigNoz UI**로 이동
3. **Dashboards** → **Import Dashboard**
4. JSON 파일 업로드 또는 내용 붙여넣기
5. **Import** 클릭

### 대시보드 구성

| 패널 | 설명 |
|------|------|
| 📊 HTTP 요청률 (RPS) | 초당 HTTP 요청 수 (메서드, 경로, 상태코드별) |
| ⏱️ HTTP 응답 시간 (P95) | 95 백분위수 응답 시간 |
| ❌ HTTP 에러율 | 5xx 응답 비율 |
| 🔐 로그인 시도 (총계) | 로그인 방식별 시도 횟수 |
| ✅ 로그인 성공률 | 로그인 성공 비율 (방식별) |
| 📱 SNS 로그인 분포 | SNS 제공자별 로그인 통계 (Pie Chart) |
| 🎫 토큰 발급 현황 | Access/Refresh 토큰 발급 추이 |
| 💾 DB 활성 연결 수 | 데이터베이스 활성 연결 |
| 💤 DB 유휴 연결 수 | 데이터베이스 유휴 연결 |
| ⚡ DB 쿼리 성능 (P95) | 쿼리 실행 시간 (테이블별) |
| 🧠 Go Heap 메모리 | Go 힙 메모리 사용량 |
| 🔀 Goroutine 수 | 활성 Goroutine 개수 |
| 🗑️ GC 일시정지 시간 | GC 일시정지 시간 |
| 🕐 로그인 처리 시간 | 로그인 처리 시간 (P95) |
| 📧 이메일 인증 발송 | 이메일 인증 발송 통계 |
| 🔑 비밀번호 재설정 이메일 | 비밀번호 재설정 발송 통계 |

---

## 🔍 주요 메트릭 쿼리 예시

### 1. HTTP 에러율 계산
```promql
rate(http_server_requests_total{http_status_code>=500}[5m])
/
rate(http_server_requests_total[5m])
* 100
```

### 2. 로그인 성공률 계산
```promql
rate(auth_login_total{auth_status="success"}[5m])
/
rate(auth_login_total[5m])
* 100
```

### 3. SNS 제공자별 로그인 비율
```promql
sum(auth_sns_login_total) by (sns_provider)
```

### 4. DB 연결 풀 사용률
```promql
db_client_connections_active
/
db_client_connections_max
* 100
```

---

## 🚨 알림 설정 권장사항

### HTTP 에러율 알림
```yaml
alert: HighHTTPErrorRate
expr: |
  rate(http_server_requests_total{http_status_code>=500}[5m])
  / rate(http_server_requests_total[5m])
  * 100 > 5
for: 5m
labels:
  severity: warning
annotations:
  summary: "HTTP 5xx 에러율이 5% 초과"
```

### 로그인 실패율 알림
```yaml
alert: HighLoginFailureRate
expr: |
  rate(auth_login_total{auth_status="failed"}[5m])
  / rate(auth_login_total[5m])
  * 100 > 20
for: 5m
labels:
  severity: warning
annotations:
  summary: "로그인 실패율이 20% 초과"
```

### DB 연결 풀 고갈 알림
```yaml
alert: DBConnectionPoolExhausted
expr: |
  db_client_connections_active
  / db_client_connections_max
  * 100 > 90
for: 5m
labels:
  severity: critical
annotations:
  summary: "DB 연결 풀 사용률이 90% 초과"
```

---

## 🧪 테스트

### 메트릭 수집 확인

1. **서버 시작 후 로그 확인**:
   ```
   OpenTelemetry initialized (endpoint: signoz-otel-collector.signoz:4317, service: ojeomneo-server)
   Auth metrics registered
   HTTP metrics registered
   Go runtime metrics started (OpenTelemetry standard)
   ```

2. **SigNoz UI에서 메트릭 확인**:
   - **Metrics Explorer** → `auth.login.total` 검색
   - **Metrics Explorer** → `http.server.requests` 검색
   - **Metrics Explorer** → `go.memory.used` 검색

3. **테스트 요청 보내기**:
   ```bash
   # HTTP 요청
   curl https://api.woohalabs.com/ojeomneo/v1/healthcheck/live

   # 로그인 요청
   curl -X POST https://api.woohalabs.com/ojeomneo/v1/auth/email/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password"}'
   ```

---

## 📝 참고 자료

- [OpenTelemetry Go SDK](https://opentelemetry.io/docs/instrumentation/go/)
- [SigNoz Documentation](https://signoz.io/docs/)
- [GORM OpenTelemetry Plugin](https://github.com/uptrace/opentelemetry-go-extra)
- [Fiber OpenTelemetry Middleware](https://docs.gofiber.io/contrib/otelfiber/)

---

## 최종 업데이트

- **날짜**: 2025년 1월
- **상태**: 모니터링 시스템 구현 완료 ✅
- **커버리지**: APM, 인증, DB, Runtime 메트릭 100%
- **다음 작업**: SigNoz 대시보드 import 및 알림 설정
