# 프로젝트 개발 히스토리

## 프로젝트 개요

Django 기반 비동기 웹 애플리케이션 서버

- **프레임워크**: Django 5.2.7
- **API**: Django Ninja (비동기)
- **데이터베이스**: PostgreSQL
- **서버**: Uvicorn (ASGI)
- **인증**: 이메일 기반 커스텀 User 모델
- **관리자**: Django Unfold (모던 UI)
- **테스트**: 56개 테스트 (100% 통과)

---

## 개발 순서 및 주요 작업

### 1. 테스트 데이터베이스 Docker Compose 설정 (PR #3)

**브랜치**: `feature/test-database-setup`

**작업 내용**:
- PostgreSQL 15 Docker Compose 설정 추가
- 로컬 개발 환경을 위한 데이터베이스 컨테이너 구성

**파일 변경**:
- `docker-compose.yml` 생성
  - PostgreSQL 15 이미지 사용
  - DB 이름: test
  - 사용자: test / test1234
  - 포트: 5432:5432
  - 볼륨 마운트: `./test_database:/var/lib/postgresql/data`

**실행 방법**:
```bash
docker-compose up -d
docker-compose down
```

---

### 2. PostgreSQL + TDD 기반 개발 환경 구축 (PR #5)

**브랜치**: `feature/postgresql-tdd-setup`

**작업 내용**:
- PostgreSQL 데이터베이스 연동
- 비동기 데이터베이스 유틸리티 함수 구현
- TDD 기반 테스트 작성

**파일 변경**:
- `settings/settings.py`: PostgreSQL DATABASE 설정
- `core/database.py`: 비동기 DB 헬퍼 함수
  - `get_db_connection()`: 비동기 DB 연결
  - `execute_query()`: 비동기 쿼리 실행
- `core/tests/test_database_async.py`: 데이터베이스 테스트 (6개)

**의존성 추가**:
- `psycopg2-binary>=2.9.11`

**테스트**:
```bash
python manage.py test core.tests.test_database_async
```

---

### 3. 이메일 기반 커스텀 User 모델 구현 (PR #6)

**브랜치**: `feature/custom-user-model`

**작업 내용**:
- Django 기본 username 대신 email을 주요 식별자로 사용
- UserManager 구현
- Admin 인터페이스 통합

**파일 변경**:
- `accounts/models.py`: User 모델 구현
  - `email`: 주요 식별자 (unique)
  - `is_active`, `is_staff`, `is_superuser`: 권한 플래그
  - `date_joined`: 가입 일시
- `accounts/admin.py`: User Admin 설정
- `accounts/tests/test_models.py`: User 모델 테스트 (6개)
- `settings/settings.py`: `AUTH_USER_MODEL = 'accounts.User'`

**마이그레이션**:
```bash
python manage.py makemigrations
python manage.py migrate
```

**슈퍼유저 생성**:
```bash
python manage.py createsuperuser
```

---

### 4. 비동기 헬스체크 API 엔드포인트 구현 (PR #4)

**브랜치**: `feature/api-healthcheck`

**작업 내용**:
- Django Ninja를 활용한 비동기 API 구현
- 헬스체크 및 데이터베이스 연결 확인 API

**파일 변경**:
- `api/urls.py`: API 라우터 설정
- `api/v1/healthcheck.py`: 헬스체크 API 구현
  - `GET /api/v1/healthcheck/`: 기본 헬스체크
  - `GET /api/v1/healthcheck/db/`: DB 연결 확인
- `settings/urls.py`: API 라우터 연결
- `api/tests/v1/test_healthcheck*.py`: API 테스트 (16개)

**API 엔드포인트**:
```
GET /api/v1/healthcheck/
Response: {"status": "ok", "timestamp": "..."}

GET /api/v1/healthcheck/db/
Response: {"status": "ok", "database": "connected", "timestamp": "..."}
```

**테스트**:
```bash
python manage.py test api.tests.v1
```

---

### 5. ASGI 기반 비동기 API 구현 완료 (PR #7)

**브랜치**: `feature/async-api-implementation`

**작업 내용**:
- Uvicorn ASGI 서버 설정
- 비동기 API 최적화

**파일 변경**:
- `pyproject.toml`: uvicorn 의존성 추가
- 비동기 API 엔드포인트 최적화

**의존성 추가**:
- `uvicorn>=0.38.0`

**서버 실행**:
```bash
# 개발 서버
uvicorn settings.asgi:application --reload

# 프로덕션 서버
uvicorn settings.asgi:application --host 0.0.0.0 --port 8000
```

**테스트**:
- 46개 테스트 모두 통과

---

### 6. 환경 변수 기반 설정 관리 시스템 구현 (PR #8)

**브랜치**: `feature/env-config-management`

**작업 내용**:
- python-dotenv를 활용한 환경 변수 관리
- .env 파일을 통한 설정 주입
- 프로덕션 배포 준비

**파일 변경**:
- `pyproject.toml`: python-dotenv 의존성 추가
- `.env`: 환경 변수 파일 (gitignore)
- `.env.example`: 환경 변수 템플릿 (버전 관리)
- `settings/settings.py`: 환경 변수 로딩
  - `load_dotenv(BASE_DIR / '.env')`
  - SECRET_KEY, DEBUG, ALLOWED_HOSTS 환경 변수화
  - DATABASE 설정 환경 변수화
- `.gitignore`: .env, .env.local 추가
- `settings/tests/test_env_config.py`: 환경 변수 테스트 (10개)

**의존성 추가**:
- `python-dotenv>=1.2.1`

**환경 변수 설정**:
```bash
# .env 파일 예시
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

DB_ENGINE=django.db.backends.postgresql
DB_NAME=test
DB_USER=test
DB_PASSWORD=test1234
DB_HOST=localhost
DB_PORT=5432
```

**테스트**:
```bash
python manage.py test settings.tests.test_env_config
```

---

### 7. Django 권장 구조로 테스트 재구성 (PR #9)

**브랜치**: `feature/test-structure-reorganization`

**작업 내용**:
- 중앙 집중식 `tests/` 폴더에서 앱별 `tests/` 구조로 변경
- Django 권장 테스트 구조 적용

**테스트 파일 이동**:
```
tests/test_accounts.py → accounts/tests/test_models.py
tests/test_database_async.py → core/tests/test_database_async.py
tests/test_env_config.py → settings/tests/test_env_config.py
tests/api/v1/test_healthcheck*.py → api/tests/v1/test_healthcheck*.py
```

**디렉토리 구조**:
```
server/
├── accounts/
│   └── tests/
│       ├── __init__.py
│       └── test_models.py
├── api/
│   └── tests/
│       ├── __init__.py
│       └── v1/
│           ├── __init__.py
│           ├── test_healthcheck.py
│           └── test_healthcheck_db.py
├── core/
│   └── tests/
│       ├── __init__.py
│       └── test_database_async.py
└── settings/
    └── tests/
        ├── __init__.py
        └── test_env_config.py
```

**테스트 실행**:
```bash
# 전체 테스트
python manage.py test

# 앱별 테스트
python manage.py test accounts.tests
python manage.py test api.tests
python manage.py test core.tests
python manage.py test settings.tests
```

---

### 8. Django Unfold 모던 어드민 UI 구현 (PR #10)

**브랜치**: `feature/django-unfold-admin`

**작업 내용**:
- django-unfold를 활용한 현대적인 관리자 UI
- 정적 파일 수집 및 배포 준비

**파일 변경**:
- `pyproject.toml`: django-unfold 의존성 추가
- `settings/settings.py`:
  - INSTALLED_APPS에 'unfold' 추가 (**admin 앞에 배치 필수**)
  - STATIC_ROOT 설정
  - UNFOLD 설정 추가
- `.gitignore`: staticfiles/, static/ 추가
- `settings/tests/test_admin_config.py`: Admin 설정 테스트 (10개)

**의존성 추가**:
- `django-unfold>=0.69.0`

**설정**:
```python
# settings/settings.py
INSTALLED_APPS = [
    'unfold',  # admin 앞에 위치 필수!
    'django.contrib.admin',
    # ...
]

UNFOLD = {
    "SITE_TITLE": "오점너 관리자",
    "SITE_HEADER": "오점너 (오늘 점심 뭐 먹을래?)",
    "SITE_FAVICON": "/static/favicon.ico",
}

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
```

**정적 파일 수집**:
```bash
python manage.py collectstatic --noinput
# 153개 파일 수집됨
```

**관리자 접속**:
```
http://localhost:8000/admin/
```

**테스트**:
```bash
python manage.py test settings.tests.test_admin_config
```

---

## 현재 프로젝트 상태

### 디렉토리 구조
```
server/
├── accounts/                    # 사용자 인증 앱
│   ├── migrations/
│   ├── tests/
│   │   ├── __init__.py
│   │   └── test_models.py      (6 tests)
│   ├── __init__.py
│   ├── admin.py
│   ├── apps.py
│   ├── models.py               # 커스텀 User 모델
│   └── views.py
├── api/                         # API 앱
│   ├── tests/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── test_healthcheck.py     (8 tests)
│   │       └── test_healthcheck_db.py  (8 tests)
│   ├── v1/
│   │   ├── __init__.py
│   │   └── healthcheck.py      # 헬스체크 API
│   ├── __init__.py
│   ├── apps.py
│   └── urls.py                 # API 라우터
├── core/                        # 핵심 유틸리티
│   ├── tests/
│   │   ├── __init__.py
│   │   └── test_database_async.py  (6 tests)
│   ├── __init__.py
│   ├── apps.py
│   └── database.py             # 비동기 DB 헬퍼
├── settings/                    # 설정 앱
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_env_config.py      (10 tests)
│   │   └── test_admin_config.py    (10 tests)
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py             # Django 설정
│   ├── urls.py
│   └── wsgi.py
├── docs/                        # 프로젝트 문서
│   └── PROJECT_HISTORY.md      # 이 파일
├── .env                         # 환경 변수 (gitignore)
├── .env.example                 # 환경 변수 템플릿
├── .gitignore
├── docker-compose.yml           # PostgreSQL 컨테이너
├── manage.py
├── pyproject.toml              # 의존성 관리
└── uv.lock
```

### 의존성 목록
```toml
[project]
dependencies = [
    "colorlog>=6.10.1",          # 컬러 로깅
    "django>=5.2.7",             # Django 프레임워크
    "django-ninja>=1.4.5",       # 비동기 API
    "django-unfold>=0.69.0",     # 모던 Admin UI
    "psycopg2-binary>=2.9.11",   # PostgreSQL 드라이버
    "python-dotenv>=1.2.1",      # 환경 변수 관리
    "uvicorn>=0.38.0",           # ASGI 서버
]
```

### 테스트 현황
```
총 56개 테스트, 100% 통과

accounts.tests.test_models:           6 tests
api.tests.v1.test_healthcheck:        8 tests
api.tests.v1.test_healthcheck_db:     8 tests
core.tests.test_database_async:       6 tests
settings.tests.test_env_config:      10 tests
settings.tests.test_admin_config:    10 tests
settings.tests.test_admin_access:     8 tests
```

---

## 주요 명령어

### 개발 서버 실행
```bash
# ASGI 서버 (권장)
uvicorn settings.asgi:application --reload

# Django 개발 서버
python manage.py runserver
```

### 데이터베이스
```bash
# Docker Compose로 PostgreSQL 시작
docker-compose up -d

# 마이그레이션
python manage.py makemigrations
python manage.py migrate

# PostgreSQL 중지
docker-compose down
```

### 테스트
```bash
# 전체 테스트
python manage.py test

# 앱별 테스트
python manage.py test accounts
python manage.py test api
python manage.py test core
python manage.py test settings

# 특정 테스트 파일
python manage.py test accounts.tests.test_models
```

### 정적 파일
```bash
# 정적 파일 수집 (배포 전)
python manage.py collectstatic --noinput
```

### 관리자
```bash
# 슈퍼유저 생성
python manage.py createsuperuser
# Email: admin@example.com
# Password: (입력)
```

---

## API 엔드포인트

### 헬스체크 API

#### 기본 헬스체크
```http
GET /api/v1/healthcheck/

Response 200 OK:
{
    "status": "ok",
    "timestamp": "2025-10-31T12:34:56.789Z"
}
```

#### 데이터베이스 헬스체크
```http
GET /api/v1/healthcheck/db/

Response 200 OK:
{
    "status": "ok",
    "database": "connected",
    "timestamp": "2025-10-31T12:34:56.789Z"
}

Response 500 Internal Server Error (DB 연결 실패):
{
    "status": "error",
    "database": "disconnected",
    "error": "connection failed",
    "timestamp": "2025-10-31T12:34:56.789Z"
}
```

---

## Git 브랜치 전략

### Feature 브랜치 순서
모든 feature 브랜치는 순차적으로 main에 merge되었습니다:

1. `feature/test-database-setup` (PR #3) ✅ Merged
2. `feature/postgresql-tdd-setup` (PR #5) ✅ Merged
3. `feature/custom-user-model` (PR #6) ✅ Merged
4. `feature/api-healthcheck` (PR #4) ✅ Merged
5. `feature/async-api-implementation` (PR #7) ✅ Merged
6. `feature/env-config-management` (PR #8) ✅ Merged
7. `feature/test-structure-reorganization` (PR #9) ✅ Merged
8. `feature/django-unfold-admin` (PR #10) ✅ Merged

### Merge 전략
- **Squash and Merge**: 각 feature 브랜치를 하나의 커밋으로 압축하여 main에 병합

---

## 환경 변수 설정

### .env 파일 설정 (로컬 개발)
```bash
# Django Settings
SECRET_KEY=django-insecure-2%+bir$!^a-qf$8dq%du$^y8od)lcwl7x)^*@(yz@0jm)&i3k0
DEBUG=True
ALLOWED_HOSTS=

# Database Configuration
DB_ENGINE=django.db.backends.postgresql
DB_NAME=test
DB_USER=test
DB_PASSWORD=test1234
DB_HOST=localhost
DB_PORT=5432
```

### 프로덕션 환경 변수 설정
```bash
# Django Settings
SECRET_KEY=<강력한-랜덤-시크릿-키>
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

# Database Configuration
DB_ENGINE=django.db.backends.postgresql
DB_NAME=production_db
DB_USER=production_user
DB_PASSWORD=<강력한-비밀번호>
DB_HOST=db.production.com
DB_PORT=5432
```

---

## 배포 준비 사항

### 1. 환경 변수 설정
- `.env` 파일 또는 시스템 환경 변수로 설정
- `SECRET_KEY`: 강력한 랜덤 키 생성
- `DEBUG=False`: 프로덕션에서 필수
- `ALLOWED_HOSTS`: 도메인 설정

### 2. 정적 파일 수집
```bash
python manage.py collectstatic --noinput
```

### 3. 데이터베이스 마이그레이션
```bash
python manage.py migrate
```

### 4. ASGI 서버 실행
```bash
uvicorn settings.asgi:application --host 0.0.0.0 --port 8000 --workers 4
```

### 5. Docker 배포 (권장)
- PostgreSQL: Docker Compose 또는 관리형 DB 서비스
- Django 앱: Docker 이미지 빌드
- 정적 파일: STATIC_ROOT에서 제공 또는 CDN 사용

---

## 다음 단계 권장 사항

### 기능 추가
1. **사용자 인증 API**
   - 회원가입 API
   - 로그인/로그아웃 API
   - JWT 토큰 인증

2. **맛집 데이터 모델**
   - Restaurant 모델 설계
   - 카테고리, 위치 정보
   - 평점 및 리뷰 시스템

3. **검색 API**
   - 맛집 검색 API
   - 필터링 (카테고리, 위치, 평점)
   - 페이지네이션

### 인프라 개선
1. **Docker 이미지**
   - Dockerfile 작성
   - Multi-stage 빌드
   - Docker Compose 전체 스택

2. **CI/CD**
   - GitHub Actions 설정
   - 자동 테스트 실행
   - 자동 배포

3. **모니터링**
   - 로깅 시스템
   - 에러 추적 (Sentry)
   - 성능 모니터링

### 보안 강화
1. **CORS 설정**
   - django-cors-headers 추가
   - 허용 도메인 설정

2. **Rate Limiting**
   - API 요청 제한
   - DDoS 방어

3. **보안 헤더**
   - SECURE_SSL_REDIRECT
   - SECURE_HSTS_SECONDS
   - X_FRAME_OPTIONS

---

## 참고 문서

- [Django 공식 문서](https://docs.djangoproject.com/)
- [Django Ninja 문서](https://django-ninja.rest-framework.com/)
- [Django Unfold 문서](https://unfoldadmin.com/)
- [Uvicorn 문서](https://www.uvicorn.org/)
- [PostgreSQL 문서](https://www.postgresql.org/docs/)
