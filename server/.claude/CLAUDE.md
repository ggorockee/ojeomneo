# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Go Fiber v2 (API) + Django (Admin) 하이브리드 아키텍처 백엔드 서버입니다.

## 아키텍처 (필수)

### 역할 분리
| 컴포넌트 | 역할 | 기술 스택 |
|----------|------|-----------|
| Go API | REST API 서버 | Go Fiber v2, GORM |
| Django Admin | 관리자 패널 | Django, Django Unfold |
| PostgreSQL | 데이터베이스 | Docker |

### URL 구조 (매우 중요)
- **Base Domain**: `api.woohalabs.com`
- **Service Prefix**: 모든 요청은 `/woohalabs`로 시작
- **API 버전**: `/v1` 사용

| 경로 | 설명 |
|------|------|
| `/woohalabs/v1/*` | API 엔드포인트 |
| `/woohalabs/v1/docs` | Swagger 문서 (필수) |
| `/woohalabs/v1/healthcheck` | 헬스체크 |
| `/woohalabs/metrics` | Prometheus 메트릭 |
| `/admin/` | Django Admin |

## 개발 환경

### Go API
- **Go**: 1.21+
- **Framework**: Fiber v2
- **ORM**: GORM
- **문서화**: Swagger (swaggo)
- **메트릭**: Prometheus client

### Django Admin
- **Python**: 3.12+
- **Framework**: Django 5.x
- **Admin UI**: Django Unfold
- **의존성 관리**: uv

### 공통
- **데이터베이스**: PostgreSQL (Docker)
- **환경변수 관리**: .env 파일
- **Timezone**: Asia/Seoul

## Observability (모니터링)

### Prometheus 메트릭
- **엔드포인트**: `/woohalabs/metrics`
- **필수 메트릭**:
  - HTTP 요청 수 (method, path, status)
  - HTTP 요청 지연시간 (histogram)
  - 활성 연결 수
  - DB 연결 풀 상태

### Grafana 연동
- Prometheus 데이터소스 연결
- 대시보드 JSON 템플릿 제공 예정

## 주요 명령어

### Go API
```bash
# 개발 서버 실행
go run cmd/api/main.go

# 빌드
go build -o bin/api cmd/api/main.go

# 테스트
go test ./...

# Swagger 문서 생성
swag init -g cmd/api/main.go
```

### Django Admin
```bash
# 가상환경 활성화
source .venv/bin/activate

# 의존성 설치
uv sync

# 개발 서버 실행
python manage.py runserver

# 마이그레이션
python manage.py makemigrations
python manage.py migrate

# 관리자 계정 생성
python manage.py createsuperuser
```

### 데이터베이스 (Docker)
```bash
cd test_database
docker compose up -d      # PostgreSQL 시작
docker compose down       # PostgreSQL 중지
docker compose logs -f    # 로그 확인
```

## 프로젝트 구조 (예정)

```
server/
├── .claude/
│   └── CLAUDE.md              # 프로젝트 문서
├── .env                       # 환경변수 (gitignore)
├── .env.example               # 환경변수 예제
├── .gitignore
│
├── cmd/                       # Go 진입점
│   └── api/
│       └── main.go
│
├── internal/                  # Go 내부 패키지
│   ├── config/                # 설정 로더
│   ├── handler/               # HTTP 핸들러
│   ├── middleware/            # 미들웨어
│   ├── model/                 # GORM 모델
│   ├── repository/            # 데이터 접근 계층
│   └── service/               # 비즈니스 로직
│
├── pkg/                       # Go 공개 패키지
│   └── metrics/               # Prometheus 메트릭
│
├── docs/                      # Swagger 문서 (자동 생성)
│
├── admin/                     # Django Admin 프로젝트
│   ├── manage.py
│   ├── config/                # Django 설정
│   └── accounts/              # 사용자 관리
│
└── test_database/
    └── docker-compose.yml     # PostgreSQL
```

## 환경변수

```bash
# 서버 설정
APP_ENV=development
APP_PORT=8080

# 데이터베이스
DB_HOST=localhost
DB_PORT=5432
DB_NAME=woohalabs
DB_USER=test
DB_PASSWORD=test1234

# Django
DJANGO_SECRET_KEY=your-secret-key
DJANGO_DEBUG=True
```

## 개발 시 주의사항

### Go API 개발
- 모든 API는 `/woohalabs/v1/` prefix 사용
- Swagger 어노테이션 필수 작성
- 에러 응답 형식 통일
- 메트릭 수집 미들웨어 적용

### Django Admin 개발
- Go API와 동일한 DB 스키마 공유
- GORM 모델과 Django 모델 동기화 필요
- Admin 전용 기능만 구현

### 데이터베이스
- 스키마 변경은 Django 마이그레이션으로 관리
- Go GORM은 AutoMigrate 사용 금지 (Django 마이그레이션과 충돌 방지)

## API 응답 형식

### 성공 응답
```json
{
  "success": true,
  "data": { ... },
  "message": "요청 성공"
}
```

### 에러 응답 (Naver 스타일)
사용자용 메시지와 개발자용 메시지를 분리하여 제공합니다.

```json
{
  "success": false,
  "error": {
    "code": "INVALID_INPUT",
    "message": "입력 정보를 다시 확인해 주세요.",
    "detail": "email 필드가 유효하지 않습니다: 이메일 형식이 올바르지 않습니다."
  }
}
```

### 에러 메시지 가이드라인 (필수)

#### 원칙
1. **사용자 메시지 (message)**: 한글로 친절하게 작성, 기술 용어 지양
2. **개발자 메시지 (detail)**: 디버깅에 필요한 상세 정보 포함
3. **에러 코드 (code)**: 영문 대문자 + 언더스코어

#### 사용자 메시지 작성 규칙
- 존댓말 사용 ("~해 주세요", "~입니다")
- 해결 방법 제시
- 기술 용어 대신 일상 용어 사용

#### 에러 코드 및 메시지 예시
| 코드 | 사용자 메시지 | 개발자 메시지 |
|------|---------------|---------------|
| INVALID_INPUT | 입력 정보를 다시 확인해 주세요. | {필드명} 필드가 유효하지 않습니다: {상세 사유} |
| NOT_FOUND | 요청하신 정보를 찾을 수 없습니다. | {리소스} ID {id}를 찾을 수 없습니다. |
| UNAUTHORIZED | 로그인이 필요한 서비스입니다. | 인증 토큰이 없거나 만료되었습니다. |
| FORBIDDEN | 접근 권한이 없습니다. | 사용자 {user_id}가 리소스 {resource}에 접근 권한이 없습니다. |
| INTERNAL_ERROR | 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해 주세요. | {상세 에러 메시지} |
| DB_ERROR | 서비스 연결에 문제가 발생했습니다. | 데이터베이스 쿼리 실패: {SQL 에러} |
| RATE_LIMIT | 요청이 너무 많습니다. 잠시 후 다시 시도해 주세요. | Rate limit exceeded: {limit}/min |

#### 환경별 detail 노출
- **개발 환경 (APP_ENV=development)**: detail 항상 포함
- **운영 환경 (APP_ENV=production)**: detail 제외 (보안)

## 헬스체크 응답

```json
{
  "status": "ok",
  "service": "woohalabs-api",
  "version": "1.0.0",
  "database": {
    "connected": true,
    "latency_ms": 5
  }
}
```
