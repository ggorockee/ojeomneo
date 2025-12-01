# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

오점너(Ojeomneo) 프로젝트는 멀티 컴포넌트 아키텍처로 구성된 풀스택 애플리케이션입니다.

## 프로젝트 구조

| 디렉토리 | 기술 스택 | 용도 |
|---------|----------|------|
| `admin/` | Django | Admin 전용 백오피스 |
| `mobile/` | Flutter | iOS/Android 모바일 앱 |
| `server/` | Go Fiber + GORM | Backend REST API |

## 배포 환경

- **Helm Chart 경로**: `/Users/woohyeon/ggorockee/infra/charts/helm/prod/ojeomneo`
- **배포 방식**: ArgoCD와 연동된 Helm Chart
- **인프라 구성**:
  - Server: Go Fiber v2 API (`ggorockee/ojeomneo-server-with-go`)
  - Database: PostgreSQL 15.15-alpine
  - Service Port: 3000
  - Health Check: `/ojeomneo/v1/healthcheck/live`, `/ojeomneo/v1/healthcheck/ready`
  - Metrics: Prometheus ServiceMonitor 활성화

---

## Admin (Django)

Admin 전용 백오피스로 관리자 기능만을 제공합니다.

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `python manage.py runserver` | 개발 서버 실행 |
| `python manage.py migrate` | DB 마이그레이션 적용 |
| `python manage.py makemigrations` | 마이그레이션 파일 생성 |
| `python manage.py createsuperuser` | 관리자 계정 생성 |

---

## Mobile (Flutter)

iOS/Android 크로스 플랫폼 모바일 애플리케이션입니다.

### 개발 환경

- **SDK**: Dart ^3.9.2
- **Framework**: Flutter (stable channel 권장)
- **Linting**: flutter_lints ^5.0.0

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `flutter pub get` | 의존성 설치 |
| `flutter run` | 앱 실행 (기본 디바이스) |
| `flutter run -d chrome` | Chrome에서 웹 실행 |
| `flutter analyze` | 정적 분석 실행 |
| `dart format .` | 코드 포맷팅 |
| `flutter test` | 테스트 실행 |
| `flutter build apk` | Android APK 빌드 |
| `flutter build ios` | iOS 빌드 |
| `flutter clean` | 빌드 캐시 정리 |

### 디렉토리 구조

- **lib/**: Dart 소스 코드 (`main.dart` 진입점)
- **test/**: 단위/위젯 테스트
- **android/**, **ios/**: 네이티브 플랫폼 설정

---

## Server (Go Fiber + GORM)

Backend REST API 서버입니다.

### 개발 환경

- **Framework**: Go Fiber v2
- **ORM**: GORM
- **API Prefix**: `/ojeomneo/v1`

### 주요 명령어

| 명령어 | 설명 |
|--------|------|
| `go mod download` | 의존성 다운로드 |
| `go run .` | 서버 실행 |
| `go build -o server .` | 바이너리 빌드 |
| `go test ./...` | 테스트 실행 |

### Health Check 엔드포인트

- **Liveness**: `GET /ojeomneo/v1/healthcheck/live`
- **Readiness**: `GET /ojeomneo/v1/healthcheck/ready` (DB 연결 확인)

---

## 개발 시 주의사항

### Git 워크플로우
- **main 브랜치 직접 푸시 금지**: 모든 작업은 feature 브랜치에서 진행
- **브랜치 네이밍**: `feature/{기능명}`, `fix/{버그명}`, `refactor/{대상}`
- **작업 흐름**: feature 브랜치 생성 → 개발 → feature 브랜치에 푸시

### Git Commit Convention
- **형식**: `<type>(<scope>): <subject>`
- **언어**: 한국어 커밋 메시지 사용

| Type | 설명 |
|------|------|
| feat | 새로운 기능 추가 |
| fix | 버그 수정 |
| docs | 문서 수정 |
| style | 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음) |
| refactor | 코드 리팩토링 |
| test | 테스트 코드 추가/수정 |
| chore | 빌드, 패키지 매니저 설정 등 |
| perf | 성능 개선 |
| ci | CI/CD 설정 변경 |

**예시**:
- `feat(admin): Django Admin 프로젝트 추가`
- `fix(server): 인증 토큰 만료 버그 수정`
- `refactor(mobile): 로그인 화면 컴포넌트 분리`

### 코드 스타일
- 각 프로젝트의 lint 규칙 준수 (Flutter: flutter_lints, Go: golangci-lint, Django: flake8/black)
- 커밋 전 정적 분석 통과 확인

### 환경 변수
- Server 환경 변수는 Kubernetes Secret으로 관리
  - `ojeomneo-db-credentials`: DB 접속 정보
  - `ojeomneo-api-credentials`: API 인증 정보
