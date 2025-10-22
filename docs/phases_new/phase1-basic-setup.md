# Phase 1: 프로젝트 기본 설정

> 🎯 **목표**: Flutter 프로젝트 기본 환경 구성 (의존성 설치 및 폴더 구조)

## 📋 작업 목록

### 1.1 Flutter 환경 확인
- [ ] Flutter SDK 버전 확인 (3.19+)
  ```bash
  flutter --version
  ```
- [ ] Dart SDK 버전 확인 (3.3+)
  ```bash
  dart --version
  ```
- [ ] 개발 환경 검증
  ```bash
  flutter doctor
  ```

### 1.2 의존성 추가
- [ ] `pubspec.yaml` 의존성 추가
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    
    # 상태 관리
    flutter_riverpod: ^2.4.0
    riverpod_annotation: ^2.4.0
    
    # 로컬 DB
    hive: ^2.2.0
    hive_flutter: ^1.1.0
    
    # HTTP 클라이언트
    dio: ^5.4.0
    
    # 지도
    flutter_naver_map: ^1.0.0
    
    # 위치
    geolocator: ^10.1.0
    permission_handler: ^11.0.0
    
    # 애니메이션
    lottie: ^3.0.0
    
    # UI
    cupertino_icons: ^1.0.8
  
  dev_dependencies:
    flutter_test:
      sdk: flutter
    flutter_lints: ^5.0.0
    riverpod_generator: ^2.4.0
    build_runner: ^2.4.0
    hive_generator: ^2.0.0
  ```

- [ ] 의존성 설치
  ```bash
  flutter pub get
  ```

### 1.3 폴더 구조 생성
- [ ] Core 디렉토리
  ```bash
  mkdir -p lib/core/constants
  mkdir -p lib/core/theme
  mkdir -p lib/core/utils
  mkdir -p lib/core/errors
  ```

- [ ] Presentation 디렉토리
  ```bash
  mkdir -p lib/presentation/pages/home
  mkdir -p lib/presentation/pages/map
  mkdir -p lib/presentation/pages/slot_machine
  mkdir -p lib/presentation/pages/history
  mkdir -p lib/presentation/pages/settings
  mkdir -p lib/presentation/widgets
  mkdir -p lib/presentation/providers
  mkdir -p lib/presentation/routes
  mkdir -p lib/presentation/mock
  ```

- [ ] Domain 디렉토리 (Phase 5에서 사용)
  ```bash
  mkdir -p lib/domain/entities
  mkdir -p lib/domain/repositories
  mkdir -p lib/domain/usecases
  ```

- [ ] Data 디렉토리 (Phase 6에서 사용)
  ```bash
  mkdir -p lib/data/datasources/local
  mkdir -p lib/data/datasources/remote
  mkdir -p lib/data/models
  mkdir -p lib/data/repositories
  ```

### 1.4 Git 설정
- [ ] `.gitignore` 업데이트
  ```gitignore
  # Flutter
  *.g.dart
  *.freezed.dart
  
  # 환경변수 (Phase 7에서 추가)
  .env*
  !.env.example
  
  # IDE
  .vscode/
  .idea/
  
  # 빌드
  build/
  .dart_tool/
  ```

- [ ] Git 저장소 초기화 (선택사항)
  ```bash
  git init
  git add .
  git commit -m "chore: 프로젝트 초기 설정"
  ```

### 1.5 기본 파일 생성
- [ ] `lib/main.dart` 기본 구조
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }
  
  class MyApp extends StatelessWidget {
    const MyApp({super.key});
  
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: '오점너',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF8844),
          ),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: Text('오점너 - 오늘 점심은 너야!'),
          ),
        ),
      );
    }
  }
  ```

- [ ] 앱 실행 테스트
  ```bash
  flutter run
  ```

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `pubspec.yaml` | 프로젝트 의존성 정의 |
| `lib/main.dart` | 앱 진입점 |
| `.gitignore` | Git 제외 파일 목록 |

## 🎯 완료 조건

- ✅ 모든 의존성 패키지 설치 완료
- ✅ Clean Architecture 폴더 구조 생성 완료
- ✅ 기본 앱이 실행됨 (빈 화면)
- ✅ `flutter analyze` 경고 없음

## ⚠️ 주의사항

- **환경변수 설정은 하지 않음** → Phase 7에서 진행
- **API 설정은 하지 않음** → Phase 7에서 진행
- 이 Phase는 기본 구조만 세팅하는 단계

## 🚀 다음 단계

Phase 2: Core 레이어 구현으로 이동
