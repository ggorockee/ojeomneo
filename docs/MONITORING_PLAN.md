# Grafana/Prometheus 모니터링 계획서

## 개요

오점너 프로젝트의 관측 가능성(Observability)을 위한 모니터링 인프라 구축 계획입니다.

---

## 1. 현재 상태

### 1.1 구현된 기능

| 컴포넌트 | 상태 | 구현 내용 |
|----------|------|-----------|
| **Server (Go)** | ✅ 완료 | Prometheus 미들웨어 구현 |
| **ServiceMonitor** | ✅ 활성화 | Helm Chart에서 설정 |
| **메트릭 엔드포인트** | ✅ 활성화 | `/ojeomneo/metrics` (내부망 전용) |

### 1.2 현재 수집 중인 메트릭

| 메트릭 이름 | 유형 | 설명 |
|-------------|------|------|
| `ojeomneo_http_requests_total` | Counter | HTTP 요청 총 수 (method, path, status) |
| `ojeomneo_http_request_duration_seconds` | Histogram | 요청 처리 시간 (method, path) |
| `ojeomneo_http_active_connections` | Gauge | 활성 연결 수 |
| `ojeomneo_http_request_size_bytes` | Summary | 요청 크기 (method, path) |
| `ojeomneo_http_response_size_bytes` | Summary | 응답 크기 (method, path) |

---

## 2. 목표 아키텍처

### 2.1 메트릭 수집 구성

| 수집 대상 | Exporter | 메트릭 경로 |
|-----------|----------|-------------|
| Server (Go) | 내장 | `/ojeomneo/metrics` |
| Admin (Django) | django-prometheus | `/metrics` |
| PostgreSQL | postgres_exporter | `:9187/metrics` |
| Redis | redis_exporter | `:9121/metrics` |
| Kubernetes | kube-state-metrics | - |

### 2.2 데이터 흐름

| 단계 | 구성요소 | 역할 |
|------|----------|------|
| 1 | Exporter | 메트릭 노출 |
| 2 | ServiceMonitor | 스크랩 대상 정의 |
| 3 | Prometheus | 메트릭 수집 및 저장 |
| 4 | Grafana | 시각화 및 알림 |
| 5 | AlertManager | 알림 전송 |

---

## 3. 메트릭 설계

### 3.1 비즈니스 메트릭 (추가 예정)

| 메트릭 | 유형 | 설명 | 레이블 |
|--------|------|------|--------|
| `ojeomneo_orders_total` | Counter | 주문 총 수 | status, payment_method |
| `ojeomneo_order_amount_total` | Counter | 주문 금액 합계 | payment_method |
| `ojeomneo_users_active` | Gauge | 활성 사용자 수 | - |
| `ojeomneo_menu_views_total` | Counter | 메뉴 조회 수 | category_id |

### 3.2 시스템 메트릭 (Exporter별)

#### PostgreSQL 메트릭

| 메트릭 | 설명 | 중요도 |
|--------|------|--------|
| `pg_stat_activity_count` | 활성 연결 수 | 높음 |
| `pg_database_size_bytes` | DB 크기 | 중간 |
| `pg_stat_bgwriter_*` | 백그라운드 작업 통계 | 중간 |
| `pg_locks_count` | 락 수 | 높음 |
| `pg_replication_lag` | 복제 지연 | 높음 |

#### Redis 메트릭

| 메트릭 | 설명 | 중요도 |
|--------|------|--------|
| `redis_connected_clients` | 연결 클라이언트 수 | 높음 |
| `redis_used_memory_bytes` | 메모리 사용량 | 높음 |
| `redis_commands_processed_total` | 명령 처리 수 | 중간 |
| `redis_keyspace_hits_total` | 캐시 히트 | 높음 |
| `redis_keyspace_misses_total` | 캐시 미스 | 높음 |

---

## 4. Grafana 대시보드 설계

### 4.1 대시보드 구성

| 대시보드 | 대상 | 주요 패널 |
|----------|------|-----------|
| **Overview** | 전체 | 서비스 상태, 에러율, 응답 시간 |
| **API Performance** | Server | 엔드포인트별 성능, 처리량 |
| **Database** | PostgreSQL | 연결, 쿼리 성능, 디스크 사용량 |
| **Cache** | Redis | 히트율, 메모리, 연결 |
| **Business** | 전체 | 주문, 사용자, 매출 |

### 4.2 Overview 대시보드 패널

| 패널 | 시각화 | 쿼리 |
|------|--------|------|
| 서비스 상태 | Stat | 각 서비스 UP/DOWN |
| 요청 처리량 | Graph | rate(http_requests_total[5m]) |
| 에러율 | Gauge | rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) |
| P95 응답 시간 | Graph | histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) |
| 활성 연결 | Stat | http_active_connections |

### 4.3 API Performance 대시보드 패널

| 패널 | 시각화 | 내용 |
|------|--------|------|
| Top 10 엔드포인트 (처리량) | Table | 가장 많이 호출되는 API |
| Top 10 엔드포인트 (지연) | Table | 가장 느린 API |
| 엔드포인트별 응답 시간 분포 | Heatmap | 시간대별 응답 시간 |
| 상태 코드 분포 | Pie | 200/4xx/5xx 비율 |
| 요청/응답 크기 | Graph | 평균 요청/응답 크기 추이 |

### 4.4 Database 대시보드 패널

| 패널 | 시각화 | 내용 |
|------|--------|------|
| 연결 풀 상태 | Gauge | 활성/유휴/최대 연결 |
| 쿼리 성능 | Graph | 쿼리 실행 시간 분포 |
| 디스크 사용량 | Graph | 테이블별 크기 추이 |
| 슬로우 쿼리 | Table | 1초 이상 쿼리 목록 |
| 락 대기 | Graph | 락 대기 시간 |

### 4.5 Cache 대시보드 패널

| 패널 | 시각화 | 내용 |
|------|--------|------|
| 캐시 히트율 | Gauge | hits / (hits + misses) |
| 메모리 사용률 | Gauge | used_memory / maxmemory |
| 연결 수 추이 | Graph | 클라이언트 연결 수 |
| 명령 처리량 | Graph | 초당 명령 수 |
| 키 공간 통계 | Table | DB별 키 수, 만료 키 수 |

---

## 5. 알림 설정

### 5.1 알림 규칙

| 알림 이름 | 조건 | 심각도 | 알림 대상 |
|-----------|------|--------|-----------|
| HighErrorRate | 에러율 > 5% (5분) | Critical | Slack, Email |
| HighLatency | P95 > 2s (5분) | Warning | Slack |
| PodDown | 파드 0개 (1분) | Critical | Slack, Email, PagerDuty |
| HighMemory | 메모리 > 80% | Warning | Slack |
| DBConnectionExhausted | 연결 > 90% | Critical | Slack, Email |
| RedisCacheHitLow | 히트율 < 70% | Warning | Slack |
| RedisMemoryHigh | 메모리 > 80% | Warning | Slack |

### 5.2 알림 채널

| 채널 | 용도 | 설정 |
|------|------|------|
| Slack (#ojeomneo-alerts) | 실시간 알림 | Webhook URL |
| Email | 중요 알림 백업 | 운영팀 메일링 리스트 |
| PagerDuty | 심각한 장애 | On-call 로테이션 (향후) |

---

## 6. 구현 계획

### 6.1 Phase 1: 기반 구축

- [ ] Prometheus Stack 설치 - kube-prometheus-stack Helm Chart
- [ ] Grafana 초기 설정 - 데이터 소스, 기본 대시보드
- [ ] ServiceMonitor 검증 - Server 메트릭 수집 확인

### 6.2 Phase 2: Exporter 추가

- [ ] postgres_exporter 설치 - Helm Chart로 배포
- [ ] redis_exporter 설치 - Redis Chart에 포함
- [ ] django-prometheus 통합 - Admin 앱에 미들웨어 추가

### 6.3 Phase 3: 대시보드 구축

- [ ] Overview 대시보드 - 전체 서비스 상태
- [ ] API Performance 대시보드 - Server 성능 분석
- [ ] Database 대시보드 - PostgreSQL 모니터링
- [ ] Cache 대시보드 - Redis 모니터링

### 6.4 Phase 4: 알림 설정

- [ ] AlertManager 설정 - 알림 라우팅 규칙
- [ ] PrometheusRule 생성 - 알림 조건 정의
- [ ] Slack 연동 - Webhook 설정
- [ ] 런북 작성 - 알림별 대응 가이드

---

## 7. Helm Chart 설정

### 7.1 values.yaml 추가 항목 (예정)

#### postgres_exporter

| 설정 | 값 | 설명 |
|------|-----|------|
| `postgresExporter.enabled` | true | Exporter 활성화 |
| `postgresExporter.serviceMonitor.enabled` | true | ServiceMonitor 생성 |
| `postgresExporter.config.datasource.existingSecret` | ojeomneo-db-credentials | DB 인증 정보 |

#### redis_exporter

| 설정 | 값 | 설명 |
|------|-----|------|
| `redis.metrics.enabled` | true | 메트릭 활성화 |
| `redis.metrics.serviceMonitor.enabled` | true | ServiceMonitor 생성 |

---

## 8. SLI/SLO 정의

### 8.1 가용성 (Availability)

| SLI | 측정 방법 | SLO |
|-----|-----------|-----|
| 서비스 가용성 | 성공 요청 / 전체 요청 | 99.9% |
| API 가용성 | 200 응답 / 전체 요청 | 99.5% |

### 8.2 지연 시간 (Latency)

| SLI | 측정 방법 | SLO |
|-----|-----------|-----|
| P50 응답 시간 | 중앙값 | < 100ms |
| P95 응답 시간 | 95 백분위 | < 500ms |
| P99 응답 시간 | 99 백분위 | < 2s |

### 8.3 처리량 (Throughput)

| SLI | 측정 방법 | SLO |
|-----|-----------|-----|
| 최대 RPS | 초당 요청 수 | > 100 RPS |
| 에러율 | 5xx / 전체 | < 1% |

---

## 9. 로그 통합 (향후 계획)

### 9.1 로깅 스택

| 구성요소 | 역할 |
|----------|------|
| Fluent Bit | 로그 수집 (DaemonSet) |
| Loki | 로그 저장소 |
| Grafana | 로그 시각화 |

### 9.2 로그 레이블

| 레이블 | 값 예시 | 용도 |
|--------|---------|------|
| app | ojeomneo-server | 애플리케이션 구분 |
| namespace | ojeomneo | 네임스페이스 구분 |
| pod | server-xxx-yyy | 파드 식별 |
| level | info, warn, error | 로그 레벨 필터링 |

---

## 10. 트레이싱 (향후 계획)

### 10.1 분산 추적 스택

| 구성요소 | 역할 |
|----------|------|
| OpenTelemetry | 추적 수집 |
| Jaeger / Tempo | 추적 저장 및 조회 |
| Grafana | 추적 시각화 |

### 10.2 추적 대상

| 컴포넌트 | 계측 방법 |
|----------|-----------|
| Server (Go) | otel-go SDK |
| Admin (Django) | opentelemetry-python |
| PostgreSQL | DB 쿼리 스팬 |
| Redis | 캐시 명령 스팬 |

---

## 11. 예상 리소스

| 구성요소 | CPU | Memory | Storage |
|----------|-----|--------|---------|
| Prometheus | 200m | 512Mi | 10Gi |
| Grafana | 100m | 256Mi | 1Gi |
| AlertManager | 50m | 64Mi | - |
| postgres_exporter | 50m | 64Mi | - |
| redis_exporter | 50m | 64Mi | - |

---

## 12. 성공 지표

| 지표 | 목표 |
|------|------|
| 메트릭 수집 지연 | < 30초 |
| 대시보드 로딩 시간 | < 3초 |
| 알림 발송 지연 | < 1분 |
| 거짓 양성 알림 비율 | < 5% |
| 장애 탐지 시간 (MTTD) | < 5분 |
