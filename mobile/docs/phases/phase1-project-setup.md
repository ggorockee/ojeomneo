# Phase 1: 프로젝트 초기 설정

> 🎯 **목표**: Flutter 프로젝트 기본 환경 구성 및 Clean Architecture 폴더 구조 세팅

## 📋 작업 목록

### 1.1 프로젝트 환경 설정
- [ ] Flutter SDK 버전 확인 (3.19+)
- [ ] Dart SDK 버전 확인 (3.3+)
- [ ] pubspec.yaml 의존성 추가
  - [ ] riverpod: ^2.4.0
  - [ ] flutter_riverpod: ^2.4.0
  - [ ] hive: ^2.2.0
  - [ ] hive_flutter: ^1.1.0
  - [ ] drift: ^2.14.0
  - [ ] dio: ^5.4.0
  - [ ] retrofit: ^4.1.0
  - [ ] naver_map_plugin: latest
  - [ ] geolocator: ^10.1.0
  - [ ] flutter_dotenv: ^5.1.0
  - [ ] lottie: ^3.0.0
- [ ] `flutter pub get` 실행

### 1.2 환경 변수 설정
- [ ] `.env.dev` 파일 생성 (개발 환경)
  - [ ] API_BASE_URL 설정
  - [ ] NAVER_MAP_CLIENT_ID 설정
  - [ ] LOG_LEVEL=debug 설정
- [ ] `.env.prod` 파일 생성 (운영 환경)
  - [ ] API_BASE_URL 설정
  - [ ] NAVER_MAP_CLIENT_ID 설정
  - [ ] LOG_LEVEL=error 설정
- [ ] `.gitignore`에 `.env*` 추가

### 1.3 폴더 구조 생성
- [ ] `lib/core/` 디렉토리 생성
  - [ ] `lib/core/constants/` 생성
  - [ ] `lib/core/theme/` 생성
  - [ ] `lib/core/utils/` 생성
  - [ ] `lib/core/errors/` 생성
  - [ ] `lib/core/config/` 생성
- [ ] `lib/data/` 디렉토리 생성
  - [ ] `lib/data/datasources/remote/` 생성
  - [ ] `lib/data/datasources/local/` 생성
  - [ ] `lib/data/models/` 생성
  - [ ] `lib/data/repositories/` 생성
- [ ] `lib/domain/` 디렉토리 생성
  - [ ] `lib/domain/entities/` 생성
  - [ ] `lib/domain/repositories/` 생성
  - [ ] `lib/domain/usecases/` 생성
- [ ] `lib/presentation/` 디렉토리 생성
  - [ ] `lib/presentation/pages/` 생성
  - [ ] `lib/presentation/widgets/` 생성
  - [ ] `lib/presentation/providers/` 생성

### 1.4 Git 설정
- [ ] `.gitignore` 파일 업데이트
  - [ ] `*.env` 추가
  - [ ] `.env*` 추가
  - [ ] `*.g.dart` 임시 제외 (코드 생성 파일)
- [ ] 초기 커밋 생성

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `pubspec.yaml` | 프로젝트 의존성 정의 |
| `.env.dev` | 개발 환경 변수 |
| `.env.prod` | 운영 환경 변수 |
| `.gitignore` | Git 제외 파일 목록 |

## 🎯 완료 조건

- ✅ 모든 의존성 패키지 설치 완료
- ✅ 환경 변수 파일 생성 완료
- ✅ Clean Architecture 폴더 구조 생성 완료
- ✅ Git 저장소 초기화 완료

## 🚀 다음 단계

Phase 2: Core 레이어 구현으로 이동
