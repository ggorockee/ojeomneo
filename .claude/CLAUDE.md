# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🚨 최우선 규칙 (CRITICAL RULES)

### ⚠️ Server-Admin 모델 동기화 (필수)

**Server와 Admin은 한 덩어리입니다.**

| 이벤트 | 필수 액션 |
|--------|-----------|
| Server 모델 **생성** | Admin에 `managed=False` 모델 추가 |
| Server 모델 **수정** | Admin 모델 필드 동기화 |
| Server 모델 **삭제** | Admin 모델도 삭제 |

> **중요**: Server에서 모델 변경 시 반드시 Admin도 함께 업데이트해야 합니다.

### 아키텍처 원칙

| 컴포넌트 | 역할 | 스키마 관리 |
|----------|------|-------------|
| **Server (Go)** | API 서버, 테이블 스키마 관리 | GORM AutoMigrate (스키마 소유자) |
| **Admin (Django)** | 백오피스 UI, 데이터 CRUD만 | `managed=False` (스키마 수정 금지) |
| **Mobile (Flutter)** | 클라이언트 앱, Server와 통신 | 하드코딩 금지, 설정은 Server에서 |

> **참고**: Mobile의 iOS Runner, Android manifest.xml 등 네이티브 설정 파일은 예외

### DB 마이그레이션 규칙

- **테이블 스키마 변경**: Server(Go GORM)에서만 수행
- **Django migrate/makemigrations**: Admin 전용 테이블(session 등)에만 사용
- **비즈니스 테이블**: Django에서 `managed=False`로 CRUD만 가능

### Git 워크플로우 (필수)

| 규칙 | 설명 |
|------|------|
| **main 직접 push 금지** | 모든 작업은 feature 브랜치에서 |
| **PR 머지 방식** | Squash and merge |
| **feature 브랜치** | 머지 후 삭제 |
| **push 시점** | 개발자가 요청하기 전까지 push 금지 |

### 🔴 코드 수정 시 필수 워크플로우 (자동 실행)

**코드 수정이 완료되면 반드시 아래 단계를 모두 수행해야 합니다:**

```
1. feature 브랜치 생성: git checkout -b {type}/{description}
2. 변경 파일 스테이징: git add {files}
3. 커밋: git commit -m "{type}({scope}): {message}"
4. 푸시: git push -u origin {branch}
5. PR 생성: gh pr create --title "{title}" --body "{body}"
6. PR 머지: gh pr merge {pr_number} --squash --delete-branch
7. main 최신화: git checkout main && git pull
```

**이 워크플로우는 다음 상황에서 자동 적용됩니다:**
- 버그 수정 (fix)
- 기능 추가 (feat)
- 리팩토링 (refactor)
- 문서 수정 (docs)
- 기타 모든 코드 변경

> ⚠️ **예외 없음**: 사용자가 "push해줘", "커밋해줘", "PR 만들어줘" 등을 요청하면 위 전체 워크플로우를 완료해야 합니다.

### 크로스 컴포넌트 작업 예시

Mobile 작업 중 Server API 수정이 필요한 경우:

1. Mobile 작업 내용 `git stash`
2. Server 디렉토리에서 feature 브랜치 생성
3. Server 코드 수정 → 커밋 → push → PR 생성
4. PR 승인 및 Squash merge → feature 브랜치 삭제
5. `git checkout main && git pull`
6. Mobile로 돌아와서 `git stash apply`
7. Mobile 작업 이어서 진행

### 하위 폴더 규칙

각 컴포넌트(`admin/`, `server/`, `mobile/`)에 `.claude/` 폴더가 있으면 해당 규칙을 우선 적용

---

## 프로젝트 개요

오점너(Ojeomneo) 프로젝트는 멀티 컴포넌트 아키텍처로 구성된 풀스택 애플리케이션입니다.

## 프로젝트 구조

| 디렉토리 | 기술 스택 | 용도 |
|---------|----------|------|
| `admin/` | Django + Unfold | Admin 전용 백오피스 |
| `mobile/` | Flutter | iOS/Android 모바일 앱 |
| `server/` | Go Fiber + GORM | Backend REST API |

## 배포 환경

- **Helm Chart 경로**: `/home/woohaen88/infra/charts/helm/prod/ojeomneo`
- **배포 방식**: ArgoCD와 연동된 Helm Chart
- **인프라 구성**:
  - Server: Go Fiber v2 API (`ggorockee/ojeomneo-server-with-go`)
  - Database: PostgreSQL 15.15-alpine
  - Service Port: 3000
  - Health Check: `/ojeomneo/v1/healthcheck/live`, `/ojeomneo/v1/healthcheck/ready`
  - Metrics: Prometheus ServiceMonitor 활성화

## 테스트 환경

- **test_database**: 운영 DB와 동일 구조
- 서버 재시작 시 꺼져 있을 수 있음 → 수동으로 켜서 사용

---

## Admin (Django)

Admin 전용 백오피스로 관리자 기능만을 제공합니다.

### 핵심 원칙

- 테이블 스키마 수정 금지 (`managed=False`)
- 데이터 CRUD만 수행
- Admin 전용 테이블(session 등)만 migrate 가능

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `uv run python manage.py runserver` | 개발 서버 실행 |
| `uv run python manage.py migrate` | Admin 전용 테이블 마이그레이션 |
| `uv run python manage.py createsuperuser` | 관리자 계정 생성 |

---

## Mobile (Flutter)

iOS/Android 크로스 플랫폼 모바일 애플리케이션입니다.

### 핵심 원칙

- 하드코딩 최소화
- 환경설정, 상수 등은 Server API에서 가져오기
- Server와 통신하여 동적으로 설정 로드

### 개발 환경

- **SDK**: Dart ^3.9.2
- **Framework**: Flutter (stable channel 권장)
- **Linting**: flutter_lints ^5.0.0

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `flutter pub get` | 의존성 설치 |
| `flutter run` | 앱 실행 (기본 디바이스) |
| `flutter analyze` | 정적 분석 실행 |
| `dart format .` | 코드 포맷팅 |
| `flutter test` | 테스트 실행 |

---

## Server (Go Fiber + GORM)

Backend REST API 서버입니다.

### 핵심 원칙

- 테이블 스키마의 단일 소유자 (GORM AutoMigrate)
- 속도와 안정성 우선
- **비동기 처리 우선**
- 스키마 변경 시 Django Admin 모델도 동기화 필요

### TDD 규칙

- 테스트 코드 작성 필수
- **개발자가 승인한 테스트는 수정 금지**
- 그 외 테스트는 필요 시 수정 가능

### 개발 환경

- **Framework**: Go Fiber v2
- **ORM**: GORM
- **API Prefix**: `/ojeomneo/v1`

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `go mod download` | 의존성 다운로드 |
| `go run ./cmd/server` | 서버 실행 |
| `go build -o server ./cmd/server` | 바이너리 빌드 |
| `go test ./...` | 테스트 실행 |

### Health Check 엔드포인트

- **Liveness**: `GET /ojeomneo/v1/healthcheck/live`
- **Readiness**: `GET /ojeomneo/v1/healthcheck/ready` (DB 연결 확인)

---

## Git Commit Convention

- **형식**: `<type>(<scope>): <subject>`
- **언어**: 한국어 커밋 메시지 사용

| Type | 설명 |
|------|------|
| feat | 새로운 기능 추가 |
| fix | 버그 수정 |
| docs | 문서 수정 |
| style | 코드 포맷팅 (코드 변경 없음) |
| refactor | 코드 리팩토링 |
| test | 테스트 코드 추가/수정 |
| chore | 빌드, 패키지 매니저 설정 등 |
| perf | 성능 개선 |
| ci | CI/CD 설정 변경 |

### 브랜치 네이밍

- `feature/{기능명}` - 새 기능
- `fix/{버그명}` - 버그 수정
- `docs/{대상}` - 문서 수정
- `refactor/{대상}` - 리팩토링

---

## 환경 변수

Server 환경 변수는 Kubernetes Secret으로 관리:
- `ojeomneo-db-credentials`: DB 접속 정보
- `ojeomneo-api-credentials`: API 인증 정보
- `ojeomneo-admin-credentials`: ADMIN 인증 정보
