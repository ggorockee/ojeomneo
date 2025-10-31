# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Django 5.2.7 + Django Ninja 기반 REST API 백엔드 서버입니다.

## 개발 환경

- **Python**: 3.12+
- **Framework**: Django 5.2.7, Django Ninja 1.4.5
- **의존성 관리**: uv (pyproject.toml)
- **데이터베이스**: PostgreSQL (Docker)
- **서버**: Uvicorn (ASGI - 비동기 지원)
- **환경변수 관리**: python-dotenv (.env 파일)
- **Settings Module**: `settings.settings` (비표준 구조 - settings 디렉토리)
- **Timezone**: Asia/Seoul
- **언어**: ko-kr

## 주요 명령어

### 환경 설정
```bash
# 가상환경 활성화
source .venv/bin/activate

# 의존성 설치/동기화
uv sync                           # uv.lock 기반 설치
uv add <package>                  # 패키지 추가
uv pip list                       # 설치된 패키지 확인

# 환경변수 설정
cp .env.example .env              # .env 파일 생성
# .env 파일을 열어서 DATABASE 정보와 SECRET_KEY 수정
```

### 개발 서버
```bash
# ASGI 서버 (비동기 지원 - 권장)
uvicorn settings.asgi:application --reload   # 8000 포트, 자동 리로드

# Django 개발 서버 (동기 모드 - 개발용만)
python manage.py runserver                    # 8000 포트로 개발 서버 실행
python manage.py runserver 0.0.0.0:8000      # 외부 접근 가능하게 실행
```

### 데이터베이스
```bash
python manage.py makemigrations              # 마이그레이션 파일 생성
python manage.py migrate                     # 마이그레이션 적용
python manage.py showmigrations              # 마이그레이션 상태 확인
python manage.py dbshell                     # 데이터베이스 쉘 접속
```

### 테스트 데이터베이스 (PostgreSQL)
```bash
# test_database/ 디렉토리에서 실행
cd test_database
docker compose up -d                         # PostgreSQL 컨테이너 시작
docker compose down                          # PostgreSQL 컨테이너 중지
docker compose logs -f                       # 로그 확인

# 접속 정보
# Host: localhost:5432
# User: test
# Password: test1234
# Database: test
```

### 테스트
```bash
# 전체 테스트 실행
python manage.py test

# 특정 앱 테스트
python manage.py test tests.api

# 특정 테스트 케이스 실행
python manage.py test tests.api.v1.test_healthcheck

# 상세 출력으로 테스트 (권장)
python manage.py test --verbosity=2

# 테스트 커버리지 확인 (coverage 설치 필요)
coverage run --source='.' manage.py test
coverage report
```

### 유틸리티
```bash
python manage.py createsuperuser             # 관리자 계정 생성
python manage.py shell                       # Django 쉘 (ORM 테스트용)
python manage.py shell_plus                  # 향상된 쉘 (django-extensions 설치 필요)
python manage.py check                       # 프로젝트 설정 검증
```

## 아키텍처 특징

### Settings 구조
- Django 프로젝트 설정이 `settings/` 디렉토리에 위치 (표준 프로젝트명과 다름)
- `DJANGO_SETTINGS_MODULE`: `settings.settings`
- BASE_DIR는 settings 디렉토리의 부모 (프로젝트 루트)

### 데이터베이스 전략
- **현재 설정**: PostgreSQL (Docker) - 개발 및 테스트 환경
- **연결 정보**: `test@localhost:5432` (비밀번호: test1234)
- **의존성**: `psycopg2-binary` 설치됨
- 데이터베이스 연결 상태는 healthcheck API로 확인 가능

### API 구조
- **Django Ninja API**: v1 prefix 사용 (`/v1/`)
- **API 디렉토리 구조**:
  ```
  api/
  ├── __init__.py
  └── v1/
      ├── __init__.py
      ├── api.py           # v1 API 메인 라우터
      └── healthcheck.py   # 헬스체크 엔드포인트
  ```
- **엔드포인트**:
  - Health Check: `GET /v1/healthcheck` → 서버 및 데이터베이스 상태 확인
    ```json
    {
      "status": "ok",
      "message": "Server is running",
      "database": {
        "connected": true,
        "message": "Database connection successful: test@localhost:5432"
      }
    }
    ```
  - Admin: `/admin/`

### API 개발 패턴
- 새로운 엔드포인트는 `api/v1/` 디렉토리에 모듈별로 생성
- 각 모듈에서 `Router()` 생성 후 `api/v1/api.py`에 등록
- 예시:
  ```python
  # api/v1/restaurants.py
  from ninja import Router
  router = Router()

  @router.get("/restaurants")
  def list_restaurants(request):
      return {"restaurants": []}

  # api/v1/api.py에 등록
  from api.v1.restaurants import router as restaurants_router
  api.add_router("/restaurants", restaurants_router)
  ```

## 개발 시 주의사항

### Settings Module Path
- `DJANGO_SETTINGS_MODULE`이 `settings.settings`로 설정됨 (manage.py:9)
- 환경 변수나 다른 설정에서 참조 시 이 경로 사용

### Django Ninja 통합
- Django Ninja v1 API가 `/v1/` prefix로 설정됨
- 새로운 API 엔드포인트 추가 시 `api/v1/` 디렉토리에 모듈 생성
- Auto-generated API docs: `http://localhost:8000/v1/docs` (개발 중 확인 가능)

### 환경변수 관리 (.env)
- **라이브러리**: python-dotenv
- **환경변수 파일**: `.env` (gitignore에 추가됨)
- **예제 파일**: `.env.example` (버전 관리에 포함)
- **로딩**: `settings.py`에서 자동 로드됨

**환경변수 목록**:
```bash
# Django Settings
SECRET_KEY=your-secret-key-here
DEBUG=True

# Database Configuration
DB_ENGINE=django.db.backends.postgresql
DB_NAME=your_database_name
DB_USER=your_database_user
DB_PASSWORD=your_database_password
DB_HOST=localhost
DB_PORT=5432
```

**초기 설정**:
```bash
# 1. .env.example을 복사하여 .env 생성
cp .env.example .env

# 2. .env 파일을 열어 실제 값으로 변경
vim .env

# 3. 설정 확인
python manage.py check
```

**주의사항**:
- `.env` 파일은 **절대 커밋하지 말 것** (.gitignore에 포함됨)
- 프로덕션 환경에서는 환경변수를 시스템 레벨에서 주입
- SECRET_KEY는 반드시 강력한 랜덤 키로 변경 필요

### 가상환경
- `.venv/` 사용 중 - 항상 활성화된 상태에서 작업
- `.gitignore`에 제외되어 있음

### 커스텀 User 모델
- **인증 방식**: Email + Password (username 대신 email 사용)
- **모델 위치**: `accounts.User`
- **설정**: `AUTH_USER_MODEL = 'accounts.User'`
- **필수 필드**: email (unique)
- **추가 필드**: is_staff, is_active, created_at, updated_at
- **관리**: Django Admin에서 email 기반 사용자 관리

### CoreModel 기본 모델
- **위치**: `core/models/base.py`
- **제공 필드**:
  - `created_at`: 생성 시간 (auto_now_add=True)
  - `updated_at`: 수정 시간 (auto_now=True)
- **사용법**: 모든 모델은 CoreModel을 상속
  ```python
  from core.models import CoreModel

  class MyModel(CoreModel):
      # 자동으로 created_at, updated_at 필드 포함
      name = models.CharField(max_length=100)
  ```

### 컬러 로깅 시스템
- **라이브러리**: colorlog
- **로그 레벨별 색상**:
  - 🟢 INFO: 초록색 (정상 동작)
  - 🟡 WARNING: 노란색 (경고)
  - 🔴 ERROR: 빨간색 (에러)
  - 🔴⬜ CRITICAL: 빨간색 배경 (치명적 오류)
  - 🔵 DEBUG: 청록색 (디버그)
- 데이터베이스 연결 상태는 자동으로 로그에 색상으로 표시됨

## 테스트 주도 개발 (TDD)

### 테스트 구조
```
tests/
├── __init__.py
├── test_env_config.py         # 환경변수 설정 테스트
├── test_database_async.py     # Database utility async 테스트
└── api/
    ├── __init__.py
    └── v1/
        ├── __init__.py
        ├── test_healthcheck.py        # healthcheck API 동기 테스트
        └── test_healthcheck_async.py  # healthcheck API 비동기 테스트
```

### TDD 워크플로우
1. **테스트 작성**: 기능 구현 전 테스트 케이스 먼저 작성
2. **테스트 실행**: `python manage.py test --verbosity=2`
3. **구현**: 테스트를 통과하도록 코드 작성
4. **리팩토링**: 테스트 통과 상태를 유지하며 코드 개선

### 테스트 작성 가이드
- 각 API 엔드포인트는 최소 5가지 테스트 필요:
  1. 엔드포인트 존재 여부
  2. HTTP 상태 코드 확인
  3. 응답 형식 검증
  4. 응답 구조 검증
  5. 비즈니스 로직 검증
- Mock을 활용한 실패 시나리오 테스트 포함

### 구현된 테스트
- **환경변수 설정**: 10개 테스트 (100% 통과)
  - `tests/test_env_config.py`
  - SECRET_KEY, DEBUG, DATABASE 설정 로딩 검증
  - .env 파일 존재 확인, python-dotenv 패키지 확인
  - 환경변수 fallback 메커니즘 테스트
- **Healthcheck API (동기)**: 11개 테스트 (100% 통과)
  - `tests/api/v1/test_healthcheck.py`
- **Healthcheck API (비동기)**: 7개 테스트 (100% 통과)
  - `tests/api/v1/test_healthcheck_async.py`
  - AsyncClient를 사용한 async endpoint 테스트
- **Database Utility (비동기)**: 4개 테스트 (100% 통과)
  - `tests/test_database_async.py`
  - sync_to_async wrapper 검증
- **Custom User Model**: 14개 테스트 (100% 통과)
  - `tests/test_accounts.py`
  - User 생성, Superuser 생성, Email 정규화, 필드 검증 등

**전체 테스트**: 46개 (100% 통과)

## 프로젝트 구조

```
server/
├── .claude/
│   └── CLAUDE.md          # 프로젝트 문서
├── .env                   # 환경변수 파일 (gitignore)
├── .env.example           # 환경변수 예제 파일
├── .gitignore             # Git 제외 파일 (.env 포함)
├── accounts/              # 사용자 인증 앱
│   ├── managers.py        # Custom UserManager
│   ├── models.py          # Custom User Model (email 인증)
│   ├── admin.py           # Admin 패널 설정
│   └── migrations/
├── api/
│   └── v1/
│       ├── api.py         # v1 API 라우터
│       └── healthcheck.py # DB 연결 체크 포함 healthcheck
├── core/
│   ├── models/
│   │   └── base.py        # CoreModel (created_at, updated_at)
│   └── utils/
│       └── database.py    # DB 연결 체크 유틸리티 (sync/async)
├── settings/
│   ├── settings.py        # 환경변수 기반 설정 (dotenv)
│   └── urls.py
├── tests/
│   ├── test_accounts.py        # User Model 테스트
│   ├── test_env_config.py      # 환경변수 설정 테스트
│   ├── test_database_async.py  # Database utility async 테스트
│   └── api/
│       └── v1/
│           ├── test_healthcheck.py       # Healthcheck 동기 테스트
│           └── test_healthcheck_async.py # Healthcheck 비동기 테스트
└── test_database/
    └── docker-compose.yml # PostgreSQL 컨테이너
```

## 비동기 (Async) 아키텍처

### 핵심 원칙
- **Auth 제외 모든 API는 async/await 사용**
- Django Ninja의 async 지원 활용
- `sync_to_async`로 동기 Django ORM 래핑

### ASGI 설정
- **ASGI 애플리케이션**: `settings/asgi.py`
- **실행 명령**: `uvicorn settings.asgi:application --reload`
- **포트**: 8000 (기본값)

### Async Database Utils
**위치**: `core/utils/database.py`

```python
from asgiref.sync import sync_to_async
from django.db import connection

def check_database_connection() -> tuple[bool, str]:
    """동기 방식 DB 연결 체크"""
    try:
        connection.ensure_connection()
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return True, "Database connection successful"
    except Exception as e:
        return False, f"Database connection failed: {str(e)}"

async def check_database_connection_async() -> tuple[bool, str]:
    """비동기 방식 DB 연결 체크 (sync_to_async 래퍼)"""
    return await sync_to_async(check_database_connection)()
```

### Async API 예제
**위치**: `api/v1/healthcheck.py`

```python
from ninja import Router
from core.utils.database import check_database_connection_async

router = Router()

@router.get("/healthcheck", tags=["Health"])
async def healthcheck(request):
    """비동기 헬스체크 엔드포인트"""
    db_connected, db_message = await check_database_connection_async()

    return {
        "status": "ok" if db_connected else "degraded",
        "message": "Server is running",
        "database": {
            "connected": db_connected,
            "message": db_message
        }
    }
```

### Async 테스트 작성
**위치**: `tests/api/v1/test_healthcheck_async.py`

```python
from django.test import TestCase
from django.test.client import AsyncClient
import json

class HealthCheckAsyncAPITestCase(TestCase):
    """비동기 healthcheck 엔드포인트 테스트"""

    def setUp(self):
        """AsyncClient 설정"""
        self.client = AsyncClient()
        self.healthcheck_url = '/v1/healthcheck'

    async def test_healthcheck_returns_200_async(self):
        """비동기로 healthcheck가 200 반환하는지 테스트"""
        response = await self.client.get(self.healthcheck_url)
        self.assertEqual(response.status_code, 200)

    async def test_healthcheck_response_structure_async(self):
        """비동기 healthcheck 응답 구조 검증"""
        response = await self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertIn('status', data)
        self.assertIn('message', data)
        self.assertIn('database', data)
```

### Async 개발 가이드라인

1. **API 엔드포인트**
   - 모든 새 엔드포인트는 `async def`로 정의
   - Auth 관련 엔드포인트만 예외 (동기 허용)

2. **Database 작업**
   - Django ORM은 기본적으로 동기
   - `sync_to_async`로 래핑하여 async context에서 사용
   - 예: `await sync_to_async(User.objects.get)(id=user_id)`

3. **테스트**
   - 비동기 뷰는 `AsyncClient` 사용
   - 테스트 메서드는 `async def`로 정의
   - 동기/비동기 테스트 모두 작성 권장

4. **성능**
   - Async는 I/O bound 작업에서 성능 향상
   - CPU bound 작업은 큰 이점 없음
   - Database 쿼리, 외부 API 호출 등에 적합
```
