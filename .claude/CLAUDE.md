# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Flutter 기반 크로스 플랫폼 모바일 애플리케이션입니다. Android, iOS, Web, Linux, macOS, Windows를 지원합니다.

## 개발 환경

- **SDK**: Dart ^3.9.2
- **Framework**: Flutter (stable channel 권장)
- **의존성 관리**: pubspec.yaml
- **Linting**: flutter_lints ^5.0.0

## 주요 명령어

### 의존성 관리
```bash
flutter pub get                    # 의존성 설치
flutter pub upgrade                # 의존성 업그레이드
flutter pub outdated              # 업데이트 가능한 패키지 확인
```

### 개발 및 실행
```bash
flutter run                        # 앱 실행 (기본 디바이스)
flutter run -d chrome             # Chrome에서 웹 실행
flutter run -d macos              # macOS에서 실행
flutter run --debug               # 디버그 모드 실행
flutter run --release             # 릴리스 모드 실행
```

### 코드 품질 검사
```bash
flutter analyze                    # 정적 분석 실행
dart format .                      # 코드 포맷팅
dart format --set-exit-if-changed . # 포맷 검사 (CI용)
```

### 테스트
```bash
flutter test                       # 모든 테스트 실행
flutter test test/widget_test.dart # 특정 테스트 파일 실행
flutter test --coverage           # 커버리지 포함 테스트
```

### 빌드
```bash
flutter build apk                  # Android APK 빌드
flutter build appbundle           # Android App Bundle 빌드
flutter build ios                 # iOS 빌드 (macOS 필요)
flutter build web                 # 웹 빌드
flutter build macos               # macOS 앱 빌드
flutter build linux               # Linux 앱 빌드
flutter build windows             # Windows 앱 빌드
```

### 클린업
```bash
flutter clean                      # 빌드 캐시 정리
flutter pub cache repair          # pub 캐시 복구
```

## 아키텍처 및 디렉토리 구조

### 핵심 디렉토리
- **lib/**: Dart 소스 코드
  - `main.dart`: 애플리케이션 진입점
- **test/**: 단위 테스트 및 위젯 테스트
- **android/**: Android 네이티브 코드 및 설정
- **ios/**: iOS 네이티브 코드 및 설정
- **web/**: 웹 플랫폼 설정 및 리소스
- **macos/**, **linux/**, **windows/**: 데스크톱 플랫폼 설정

### 코드 구성 원칙
- Flutter의 위젯 기반 아키텍처 사용
- `StatelessWidget`: 상태가 없는 불변 위젯
- `StatefulWidget`: 상태를 가지는 위젯 (`State` 클래스와 함께)
- Material Design 컴포넌트 사용 (`MaterialApp`, `Scaffold` 등)

## 개발 시 주의사항

### 코드 스타일
- `analysis_options.yaml`에 정의된 flutter_lints 규칙 준수
- `flutter analyze` 실행 시 경고 없이 통과해야 함
- `dart format`을 사용한 일관된 코드 포맷팅 유지

### Hot Reload 활용
- 코드 변경 시 `r` (hot reload) 또는 `R` (hot restart) 사용
- Hot reload는 상태를 유지하면서 UI 업데이트
- Hot restart는 앱을 완전히 재시작

### 플랫폼별 테스트
- 여러 플랫폼을 지원하므로 주요 변경사항은 각 플랫폼에서 검증 필요
- `flutter devices` 명령으로 사용 가능한 디바이스 확인

### 의존성 추가
- pubspec.yaml에 패키지 추가 후 `flutter pub get` 실행
- 버전 충돌 방지를 위해 `flutter pub outdated` 정기 확인
