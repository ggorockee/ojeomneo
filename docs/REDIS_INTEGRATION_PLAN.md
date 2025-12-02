# Redis 통합 계획서

## 개요

Redis를 오점너 프로젝트 초기부터 도입하여 성능, 확장성, 실시간 기능의 기반을 마련합니다.

---

## 1. Redis 활용 영역

### 1.1 컴포넌트별 활용 목적

| 컴포넌트 | 활용 목적 | 우선순위 |
|----------|-----------|----------|
| **Server (Go)** | API 응답 캐싱, Rate Limiting, 분산 락, Pub/Sub | 높음 |
| **Admin (Django)** | 세션 저장소, 캐시 백엔드 | 중간 |
| **Mobile (Flutter)** | 직접 연결 안함 (Server API 통해 간접 활용) | - |

### 1.2 상세 활용 시나리오

#### Server (Go Fiber)

| 기능 | 설명 | 데이터 구조 |
|------|------|-------------|
| **API 캐싱** | 자주 조회되는 데이터 캐싱 (메뉴, 설정 등) | String, Hash |
| **Rate Limiting** | IP/사용자 기반 요청 제한 | Sorted Set |
| **분산 락** | 동시 요청 제어 (결제, 재고 등) | String (SETNX) |
| **실시간 알림** | 주문 상태 변경 Pub/Sub | Pub/Sub Channel |
| **세션/토큰** | JWT 블랙리스트, Refresh Token 저장 | String, Set |

#### Admin (Django)

| 기능 | 설명 | 설정 |
|------|------|------|
| **세션 저장소** | Django 세션을 Redis에 저장 | django-redis |
| **캐시 백엔드** | 쿼리 결과, 템플릿 캐싱 | CACHES 설정 |

---

## 2. 아키텍처 설계

### 2.1 네트워크 토폴로지

| 구성요소 | 연결 방식 | 비고 |
|----------|-----------|------|
| Server ↔ Redis | 직접 연결 (TCP) | go-redis 클라이언트 |
| Admin ↔ Redis | 직접 연결 (TCP) | django-redis |
| Mobile ↔ Server | REST API | Redis에 직접 연결 안함 |
| Prometheus ↔ Redis | redis_exporter | 메트릭 수집용 |

### 2.2 Redis 인스턴스 구성

> **배포 방식**: Helm Chart (Bitnami Redis v24.0.0)로 infra 차트에 추가

| 환경 | 구성 | 메모리 |
|------|------|--------|
| 프로덕션 | Sentinel 또는 Cluster | 512Mi~1Gi |

**Helm 저장소 추가**:
- `helm repo add bitnami https://charts.bitnami.com/bitnami`
- Chart 버전: `24.0.0`

---

## 3. 데이터 설계

### 3.1 키 네이밍 컨벤션

| 패턴 | 용도 | 예시 |
|------|------|------|
| `cache:{entity}:{id}` | 엔티티 캐시 | `cache:menu:123` |
| `session:{session_id}` | 세션 데이터 | `session:abc123def` |
| `ratelimit:{type}:{key}` | Rate Limit | `ratelimit:api:192.168.1.1` |
| `lock:{resource}:{id}` | 분산 락 | `lock:order:456` |
| `pubsub:{channel}` | Pub/Sub 채널 | `pubsub:order_status` |
| `token:blacklist:{jti}` | JWT 블랙리스트 | `token:blacklist:xyz789` |

### 3.2 TTL 정책

| 데이터 유형 | TTL | 이유 |
|-------------|-----|------|
| API 캐시 | 5분 ~ 1시간 | 데이터 신선도 유지 |
| 세션 | 24시간 | 사용자 경험 |
| Rate Limit | 1분 ~ 1시간 | 윈도우 기반 제한 |
| 분산 락 | 30초 | 데드락 방지 |
| JWT 블랙리스트 | 토큰 만료시간과 동일 | 메모리 효율 |

---

## 4. 구현 계획

### 4.1 Phase 1: 기반 구축

> **우선순위**: Helm으로 Redis 설치/배포 → K8s ServiceMonitor로 메트릭 연결

- [ ] Helm Chart에 Redis 추가 (Infra) - Bitnami Redis Chart 활용
- [ ] Redis Secret 생성 (ojeomneo-redis-credentials)
- [ ] Redis 환경변수 설정 (Server/Admin) - Secret으로 관리
- [ ] go-redis 클라이언트 통합 (Server) - 연결 풀 설정
- [ ] django-redis 설정 (Admin) - CACHES, SESSION_ENGINE 설정
- [ ] ServiceMonitor 연결 확인

### 4.2 Phase 2: 핵심 기능

- [ ] Rate Limiting 미들웨어 (Server) - IP 기반 요청 제한
- [ ] API 캐싱 레이어 (Server) - 인터셉터 패턴
- [ ] Django 세션 마이그레이션 (Admin) - DB → Redis

### 4.3 Phase 3: 고급 기능 (필요 시)

- [ ] Pub/Sub 실시간 알림 (Server) - 주문 상태 변경 알림
- [ ] 분산 락 구현 (Server) - Redlock 알고리즘

> **참고**: Celery 브로커는 현재 스코프에서 제외 (향후 비동기 작업 필요 시 재검토)

---

## 5. 보안 고려사항

| 항목 | 조치 |
|------|------|
| **인증** | Redis AUTH 활성화 (requirepass) |
| **네트워크** | Kubernetes 내부 네트워크만 허용 |
| **암호화** | TLS 연결 (프로덕션) |
| **접근 제어** | NetworkPolicy로 Pod 간 통신 제한 |
| **비밀번호 관리** | Kubernetes Secret 사용 |

---

## 6. 모니터링

### 6.1 주요 메트릭

| 메트릭 | 설명 | 임계값 |
|--------|------|--------|
| `redis_connected_clients` | 연결된 클라이언트 수 | 경고: 100 이상 |
| `redis_used_memory_bytes` | 사용 중인 메모리 | 경고: 80% 이상 |
| `redis_commands_processed_total` | 처리된 명령 수 | 모니터링용 |
| `redis_keyspace_hits_total` | 캐시 히트 수 | 히트율 계산용 |
| `redis_keyspace_misses_total` | 캐시 미스 수 | 히트율 계산용 |

### 6.2 Grafana 대시보드

| 패널 | 표시 내용 |
|------|-----------|
| 연결 상태 | 연결 클라이언트 수 추이 |
| 메모리 사용량 | 메모리 사용량 및 단편화율 |
| 명령 처리량 | 초당 명령 처리 수 |
| 캐시 히트율 | 히트/(히트+미스) 비율 |
| 지연 시간 | 명령 응답 시간 분포 |

---

## 7. Helm Chart 설정 (예정)

### 7.1 values.yaml 추가 항목

| 설정 | 값 | 설명 |
|------|-----|------|
| `redis.enabled` | true | Redis 활성화 |
| `redis.architecture` | standalone | 초기 구성 |
| `redis.auth.enabled` | true | 인증 활성화 |
| `redis.auth.existingSecret` | ojeomneo-redis-credentials | 비밀번호 Secret |
| `redis.master.persistence.size` | 1Gi | 영구 저장소 크기 |
| `redis.metrics.enabled` | true | Prometheus 메트릭 활성화 |

### 7.2 Secret 키 명세 (ojeomneo-redis-credentials)

| 키 | 설명 | 예시 값 |
|----|------|---------|
| `redis-password` | Redis AUTH 비밀번호 | `your-secure-password` |

> **생성 예시**: `kubectl create secret generic ojeomneo-redis-credentials --from-literal=redis-password=your-secure-password`

---

## 8. 마이그레이션 전략

### 8.1 Django 세션 마이그레이션

- [ ] django-redis 패키지 설치 (롤백: 패키지 제거)
- [ ] CACHES에 Redis 백엔드 추가 (롤백: 설정 원복)
- [ ] SESSION_ENGINE을 캐시로 변경 (롤백: 설정 원복)
- [ ] 기존 DB 세션 테이블 정리

### 8.2 점진적 캐싱 도입

- [ ] 설정/상수 데이터 - Cache-Aside (긴 TTL)
- [ ] 메뉴/카테고리 - Cache-Aside (중간 TTL)
- [ ] 사용자 프로필 - Write-Through
- [ ] 검색 결과 - Cache-Aside (짧은 TTL)

---

## 9. 예상 리소스

> **참고**: 개발 환경 없이 프로덕션만 운영. 스토리지 여유 충분.

| 항목 | 프로덕션 환경 |
|------|---------------|
| CPU | 200m |
| Memory | 512Mi |
| Storage | 5Gi |

> 현재 클러스터 리소스 확인이 필요하면 `kubectl top` 명령으로 확인 가능

---

## 10. 성공 지표

| 지표 | 목표 |
|------|------|
| 캐시 히트율 | 80% 이상 |
| API 응답 시간 단축 | 30% 이상 |
| DB 쿼리 감소 | 40% 이상 |
| 세션 조회 지연 | 1ms 이하 |
