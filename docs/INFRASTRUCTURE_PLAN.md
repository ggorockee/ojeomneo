# 오점너 통합 인프라 기획서

## 개요

오점너 프로젝트의 전체 인프라 아키텍처와 컴포넌트 간 통신 방식, 구현 로드맵을 정의합니다.

---

## 1. 전체 아키텍처

### 1.1 컴포넌트 구성

| 컴포넌트 | 기술 스택 | 역할 | 포트 |
|----------|-----------|------|------|
| **Server** | Go Fiber v2 | REST API 서버 | 3000 |
| **Admin** | Django + Unfold | 백오피스 UI | 8000 |
| **Mobile** | Flutter | iOS/Android 앱 | - |
| **Database** | PostgreSQL 15 | 주 데이터 저장소 | 5432 |
| **Cache** | Redis 7 | 캐시, 세션, Pub/Sub | 6379 |
| **Metrics** | Prometheus | 메트릭 수집 | 9090 |
| **Dashboard** | Grafana | 시각화 | 3000 |

### 1.2 데이터 흐름

| 흐름 | 경로 | 프로토콜 |
|------|------|----------|
| 사용자 요청 | Mobile → Ingress → Server | HTTPS/REST |
| 관리자 접근 | Browser → Ingress → Admin | HTTPS/HTTP |
| API 데이터 | Server ↔ PostgreSQL | TCP/SQL |
| 캐시 조회 | Server ↔ Redis | TCP/RESP |
| 세션 저장 | Admin ↔ Redis | TCP/RESP |
| 메트릭 수집 | Prometheus → Server/Admin/Redis/PostgreSQL | HTTP/Scrape |
| 실시간 알림 | Server → Redis → Server (Pub/Sub) | TCP/RESP |

---

## 2. 컴포넌트 간 통신

### 2.1 Mobile ↔ Server

| 항목 | 내용 |
|------|------|
| 프로토콜 | HTTPS REST API |
| 인증 | JWT Bearer Token |
| 엔드포인트 | `/ojeomneo/v1/*` |
| 데이터 형식 | JSON |

**주요 API 그룹**

| 그룹 | 경로 | 용도 |
|------|------|------|
| Auth | `/auth/*` | 로그인, 토큰 갱신 |
| Users | `/users/*` | 사용자 정보 |
| Menus | `/menus/*` | 메뉴 조회 |
| Orders | `/orders/*` | 주문 생성/조회 |
| Config | `/config/*` | 앱 설정 (동적) |

### 2.2 Admin ↔ Server

| 항목 | 내용 |
|------|------|
| 통신 방식 | 직접 DB 접근 (읽기/쓰기) |
| 공유 리소스 | PostgreSQL, Redis |
| 조정 사항 | 스키마는 Server 소유, Admin은 `managed=False` |

### 2.3 Server ↔ Redis

| 용도 | 패턴 | 예시 |
|------|------|------|
| 캐싱 | GET/SET | 메뉴 목록 캐시 |
| Rate Limiting | INCR + EXPIRE | API 호출 제한 |
| 분산 락 | SETNX + EXPIRE | 결제 중복 방지 |
| Pub/Sub | PUBLISH/SUBSCRIBE | 주문 상태 변경 알림 |
| 토큰 관리 | SET + TTL | JWT 블랙리스트 |

### 2.4 Admin ↔ Redis

| 용도 | 패턴 | 설정 |
|------|------|------|
| 세션 저장 | Hash | `SESSION_ENGINE = 'django.contrib.sessions.backends.cache'` |
| 캐시 백엔드 | String/Hash | `CACHES['default']` |

### 2.5 Mobile ↔ Redis (간접)

| 시나리오 | 흐름 |
|----------|------|
| 실시간 주문 상태 | Mobile → Server (WebSocket/SSE) → Redis Pub/Sub |
| 캐시된 데이터 조회 | Mobile → Server → Redis Cache |

> **중요**: Mobile은 Redis에 직접 연결하지 않음. 모든 통신은 Server API를 통해 이루어짐.

---

## 3. 보안 아키텍처

### 3.1 네트워크 보안

| 계층 | 보안 조치 |
|------|-----------|
| Ingress | TLS 종료, WAF (향후) |
| Pod 간 | NetworkPolicy로 통신 제한 |
| DB/Redis | 내부망 전용, 인증 필수 |
| Metrics | InternalOnly 미들웨어 |

### 3.2 NetworkPolicy 정책

| 출발지 | 목적지 | 허용 |
|--------|--------|------|
| Ingress | Server, Admin | ✅ |
| Server | PostgreSQL, Redis | ✅ |
| Admin | PostgreSQL, Redis | ✅ |
| Prometheus | 모든 컴포넌트 (/metrics) | ✅ |
| Mobile | Server만 (Ingress 통해) | ✅ |

### 3.3 Secret 관리

| Secret 이름 | 용도 | 사용 컴포넌트 |
|-------------|------|---------------|
| `ojeomneo-db-credentials` | DB 인증 정보 | Server, Admin, postgres_exporter |
| `ojeomneo-api-credentials` | API 인증 키 | Server |
| `ojeomneo-admin-credentials` | Admin 설정 | Admin |
| `ojeomneo-redis-credentials` | Redis 비밀번호 | Server, Admin, redis_exporter |

---

## 4. 고가용성 (HA) 설계

### 4.1 현재 구성 (초기)

| 컴포넌트 | 복제 수 | HA 수준 |
|----------|---------|---------|
| Server | 1 | 낮음 |
| Admin | 1 | 낮음 |
| PostgreSQL | 1 | 낮음 |
| Redis | 1 (Standalone) | 낮음 |

### 4.2 프로덕션 목표 구성

| 컴포넌트 | 복제 수 | HA 전략 |
|----------|---------|---------|
| Server | 2+ | HPA, PDB |
| Admin | 2 | PDB |
| PostgreSQL | 1 Primary + 1 Replica | Streaming Replication |
| Redis | 3 (Sentinel) | 자동 Failover |

### 4.3 단계별 전환

| 단계 | 작업 | 트리거 조건 |
|------|------|-------------|
| 1 | HPA 활성화 (Server) | CPU > 80% |
| 2 | Server 복제 수 증가 | 트래픽 증가 |
| 3 | Redis Sentinel 전환 | 가용성 요구사항 |
| 4 | PostgreSQL 복제 | 읽기 트래픽 분산 필요 |

---

## 5. 구현 로드맵

### 5.1 Phase 1: 기반 인프라

- [ ] Redis Helm Chart 추가 (DevOps)
- [ ] Server Redis 클라이언트 통합 (Backend)
- [ ] Admin django-redis 설정 (Backend)
- [ ] Prometheus Stack 설치 (DevOps)
- [ ] 기본 Grafana 대시보드 (DevOps)

### 5.2 Phase 2: 핵심 기능

- [ ] API 캐싱 구현 (Backend)
- [ ] Rate Limiting 미들웨어 (Backend)
- [ ] Django 세션 Redis 마이그레이션 (Backend)
- [ ] postgres_exporter 설치 (DevOps)
- [ ] API Performance 대시보드 (DevOps)

### 5.3 Phase 3: 고급 기능

- [ ] Pub/Sub 실시간 알림 (Backend)
- [ ] 분산 락 구현 (Backend)
- [ ] 알림 규칙 설정 (DevOps)
- [ ] Slack 알림 연동 (DevOps)
- [ ] 비즈니스 메트릭 추가 (Backend)

### 5.4 Phase 4: 최적화

- [ ] HPA 설정 (DevOps)
- [ ] Redis Sentinel 전환 (DevOps)
- [ ] PostgreSQL 복제 (DevOps)
- [ ] 로그 통합 - Loki (DevOps)
- [ ] 분산 추적 - Tempo (DevOps)

---

## 6. Helm Chart 변경 사항

### 6.1 새로 추가할 종속성

| Chart | 버전 | 용도 |
|-------|------|------|
| bitnami/redis | 18.x | Redis 캐시 |
| prometheus-community/kube-prometheus-stack | 55.x | 모니터링 |

### 6.2 values.yaml 추가 섹션

#### Redis 설정

| 키 | 값 | 설명 |
|----|-----|------|
| `redis.enabled` | true | Redis 활성화 |
| `redis.architecture` | standalone | 초기 아키텍처 |
| `redis.auth.existingSecret` | ojeomneo-redis-credentials | 비밀번호 |
| `redis.master.persistence.size` | 1Gi | 저장소 크기 |
| `redis.metrics.enabled` | true | 메트릭 활성화 |

#### Server 환경변수 추가

| 키 | 값 | 용도 |
|----|-----|------|
| `REDIS_HOST` | ojeomneo-redis-master | Redis 호스트 |
| `REDIS_PORT` | 6379 | Redis 포트 |

#### Admin 환경변수 추가

| 키 | 값 | 용도 |
|----|-----|------|
| `REDIS_URL` | redis://... | Django 캐시 URL |
| `CACHE_BACKEND` | django_redis | 캐시 백엔드 |

---

## 7. 환경별 구성

### 7.1 개발 환경

| 컴포넌트 | 구성 | 리소스 |
|----------|------|--------|
| Server | 1 replica | 100m CPU, 128Mi |
| Admin | 1 replica | 100m CPU, 128Mi |
| PostgreSQL | Standalone | 100m CPU, 256Mi |
| Redis | Standalone | 50m CPU, 128Mi |
| Monitoring | 최소 구성 | 총 200m CPU, 512Mi |

### 7.2 프로덕션 환경

| 컴포넌트 | 구성 | 리소스 |
|----------|------|--------|
| Server | 2+ replicas (HPA) | 500m CPU, 512Mi |
| Admin | 2 replicas | 500m CPU, 256Mi |
| PostgreSQL | Primary + Replica | 1 CPU, 2Gi |
| Redis | Sentinel (3 nodes) | 200m CPU, 512Mi |
| Monitoring | 전체 구성 | 총 500m CPU, 1Gi |

---

## 8. 운영 가이드

### 8.1 헬스체크 엔드포인트

| 컴포넌트 | Liveness | Readiness |
|----------|----------|-----------|
| Server | `/ojeomneo/v1/healthcheck/live` | `/ojeomneo/v1/healthcheck/ready` |
| Admin | `/ojeomneo/v1/healthcheck/live/` | `/ojeomneo/v1/healthcheck/ready/` |
| PostgreSQL | `pg_isready` | `pg_isready` |
| Redis | `PING` | `PING` |

### 8.2 주요 모니터링 지표

| 지표 | 정상 범위 | 경고 임계값 |
|------|-----------|-------------|
| API 응답 시간 (P95) | < 500ms | > 1s |
| 에러율 | < 1% | > 5% |
| DB 연결 수 | < 50 | > 80 |
| Redis 메모리 | < 70% | > 80% |
| 캐시 히트율 | > 80% | < 70% |

### 8.3 장애 대응 절차

| 상황 | 대응 |
|------|------|
| Server Pod 다운 | HPA가 자동 복구 / 수동 스케일링 |
| Redis 연결 실패 | Fallback to DB (캐시 미스 처리) |
| DB 연결 실패 | 서비스 중단 알림 → DB 복구 우선 |
| 높은 에러율 | 로그 분석 → 롤백 또는 핫픽스 |

---

## 9. 비용 예측

### 9.1 GCP/AWS 기준 월간 예상 비용

| 리소스 | 사양 | 예상 비용 (월) |
|--------|------|----------------|
| Server (2 pods) | 0.5 vCPU, 512Mi | $30~50 |
| Admin (1 pod) | 0.5 vCPU, 256Mi | $15~25 |
| PostgreSQL | 1 vCPU, 2Gi, 20Gi SSD | $50~80 |
| Redis | 0.2 vCPU, 512Mi | $15~25 |
| 모니터링 스택 | 0.5 vCPU, 1Gi, 20Gi | $40~60 |
| **총계** | - | **$150~240** |

---

## 10. 문서 연결

| 문서 | 경로 | 내용 |
|------|------|------|
| Redis 통합 계획 | `docs/REDIS_INTEGRATION_PLAN.md` | Redis 상세 활용 방안 |
| 모니터링 계획 | `docs/MONITORING_PLAN.md` | Grafana/Prometheus 상세 |
| Admin 배포 계획 | `docs/DEPLOY_ADMIN_PLAN.md` | Admin 배포 가이드 |
| 프로젝트 규칙 | `.claude/CLAUDE.md` | 개발 규칙 및 가이드 |
