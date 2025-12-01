# Django Admin 배포 계획

Django Admin을 Kubernetes 환경에 배포하기 위한 단계별 계획입니다.

## 현재 상태

| 항목 | 상태 |
|------|------|
| Admin 소스코드 | `admin/` 디렉토리에 완성 |
| Dockerfile | 작성 완료 (Python 3.12, Gunicorn, Port 8000) |
| Server Helm Chart | 배포 완료 (`charts/server/`) |
| Database Helm Chart | 배포 완료 (`charts/database/`) |
| Admin Helm Chart | 미생성 |

## 배포 작업 체크리스트

### Phase 1: Docker 이미지 준비

- [x] Docker 이미지 빌드 및 테스트
  - 이미지명: `ggorockee/ojeomneo-admin`
  - 태그: `20251202-61476fa`, `latest`
- [x] Docker Hub에 이미지 푸시
- [x] 이미지 정상 동작 확인 (로컬 테스트)
  - `/admin/` → 302 (로그인 리다이렉트)
  - `/admin/login/` → 200 OK

### Phase 2: Kubernetes Secret 설정

- [x] `ojeomneo-admin-credentials` Secret 생성 완료
  - namespace: `ojeomneo`
  - 주입 방식: `envFrom.secretRef` (Secret의 모든 키를 환경변수로 자동 주입)
- [x] 기존 `ojeomneo-db-credentials` Secret 재사용
  - 주입 방식: `envFrom.secretRef`

> **서비스 도메인**: `admin.woohalabs.com` (Ingress path: `/ojeomneo` 또는 루트)

### Phase 3: Helm Subchart 생성

- [x] `charts/admin/` 디렉토리 구조 생성
  ```
  charts/admin/
  ├── Chart.yaml
  ├── values.yaml
  ├── .helmignore
  └── templates/
      ├── _helpers.tpl
      ├── deployment.yaml
      ├── service.yaml
      ├── serviceaccount.yaml
      └── configmap.yaml
  ```
- [x] `Chart.yaml` 작성
- [x] `values.yaml` 작성
  - image: `ggorockee/ojeomneo-admin`
  - port: 8000
  - replicas: 1
  - revisionHistoryLimit: 1
  - resources 설정
  - health check: `/admin/login/`
- [x] `_helpers.tpl` 템플릿 헬퍼 작성
- [x] `deployment.yaml` 작성
  - 환경변수: `envFrom`으로 Secret 전체 주입
    - `ojeomneo-admin-credentials`
    - `ojeomneo-db-credentials`
  - Probe 설정 (liveness, readiness, startup)
- [x] `service.yaml` 작성 (ClusterIP, port 8000)
- [x] `serviceaccount.yaml` 작성
- [x] `configmap.yaml` 작성 (DJANGO_DEBUG=False)

### Phase 4: 상위 Chart 연동

- [x] `ojeomneo/Chart.yaml`에 admin dependency 추가
- [x] `ojeomneo/values.yaml`에 admin 설정 추가
  - image.tag: `20251202-61476fa`
  - revisionHistoryLimit: 1
  - secrets: `ojeomneo-admin-credentials`, `ojeomneo-db-credentials`
- [x] `helm dependency update` 실행 완료

### Phase 5: 배포 및 검증

- [ ] Helm dependency update 실행
- [ ] ArgoCD Sync 또는 수동 배포
- [ ] Pod 정상 기동 확인
- [ ] Service 연결 확인
- [ ] Django Admin 페이지 접속 테스트 (`/admin/`)
- [ ] DB 연결 확인 (마이그레이션 상태)

### Phase 6: 추가 설정 (Optional)

- [ ] Ingress 설정 (외부 접근 필요시)
- [ ] HPA (Horizontal Pod Autoscaler) 설정
- [ ] PodDisruptionBudget 설정
- [ ] NetworkPolicy 설정

---

## 참고 정보

### 기존 Server 설정 참조

| 항목 | Server | Admin (예정) |
|------|--------|--------------|
| Image | `ggorockee/ojeomneo-server-with-go` | `ggorockee/ojeomneo-admin` |
| Port | 3000 | 8000 |
| Health Check | `/ojeomneo/v1/healthcheck/live` | `/admin/` 또는 커스텀 |
| Secrets | `ojeomneo-db-credentials`, `ojeomneo-api-credentials` | `ojeomneo-db-credentials`, `ojeomneo-admin-credentials` |

### 환경변수 매핑

**주입 방식**: `envFrom.secretRef` (Secret의 모든 키를 환경변수로 자동 주입)

| Secret | 포함 키 |
|--------|---------|
| `ojeomneo-admin-credentials` | DJANGO_SECRET_KEY, DJANGO_ALLOWED_HOSTS, DJANGO_CSRF_TRUSTED_ORIGINS 등 |
| `ojeomneo-db-credentials` | POSTGRES_SERVER, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD |

**ConfigMap**: DJANGO_DEBUG=False 등 비민감 설정

### Helm Chart 경로

```
/Users/woohyeon/ggorockee/infra/charts/helm/prod/ojeomneo/
├── Chart.yaml
├── values.yaml
└── charts/
    ├── server/      # Go Fiber API (완료)
    ├── database/    # PostgreSQL (완료)
    └── admin/       # Django Admin (예정)
```

---

## 작업 기록

| 날짜 | 작업 내용 | 담당 |
|------|----------|------|
| 2024-12-02 | 배포 계획 문서 작성 | - |
| | | |
