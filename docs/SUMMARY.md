# 오점너 프로젝트 요약 문서

## 프로젝트 개요

**오점너 (오늘 점심 뭐 먹을래?)**는 점심 메뉴 선택의 어려움을 해결하는 Flutter 기반 모바일 애플리케이션입니다.

| 항목 | 내용 |
|------|------|
| 프레임워크 | Flutter 3.19+ / Dart 3.3+ |
| 아키텍처 | Clean Architecture |
| 상태 관리 | Riverpod 2.4+ |
| 데이터베이스 | Hive (NoSQL), Drift (SQL) |
| 주요 기능 | 슬롯머신 추천, 지도 보기, 방문 기록, 날씨 연동 |

### 핵심 기능

- **슬롯머신 추천**: 날씨/거리/랜덤 기반으로 식당 추천
- **지도 보기**: Naver Maps로 주변 식당 확인 (100m/500m/1000m 범위)
- **방문 기록**: 방문한 식당 기록 및 통계 대시보드
- **날씨 연동**: 날씨에 맞는 메뉴 추천

### UI/UX 특징

카카오, 배달의 민족 스타일의 친근한 톤으로 모든 메시지 제공
- "오늘 점심 뭐 먹을래? 🍽️"
- "두근두근... 어디가 나올까?"
- "배고프면 일도 안 되지! 빨리 골라볼까?"

## 기술 스택

### 핵심 프레임워크

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.19+ | 크로스 플랫폼 UI 프레임워크 |
| Dart | 3.3+ | 프로그래밍 언어 |
| Riverpod | 2.4+ | 상태 관리 (컴파일 타임 안전성) |
| Hive | 2.2+ | 빠른 로컬 NoSQL 데이터베이스 |
| Drift | 2.14+ | 로컬 SQL 데이터베이스 |
| Dio | 5.4+ | HTTP 클라이언트 |
| Retrofit | 4.1+ | 타입 안전 API 인터페이스 |

### 주요 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| Naver Maps Flutter Plugin | 지도 표시 및 마커 관리 |
| Geolocator | 위치 정보 조회 및 권한 관리 |
| Lottie | 슬롯머신 애니메이션 |
| flutter_dotenv | 환경 변수 관리 |

## 아키텍처 개요

### Clean Architecture 레이어 구조

```
┌─────────────────────────────────┐
│   Presentation Layer (UI)       │  ← Riverpod Providers, Pages, Widgets
│  - 상태 관리 (Riverpod)         │
│  - UI 렌더링                    │
└────────────┬────────────────────┘
             │ Uses
┌────────────▼────────────────────┐
│   Domain Layer (Business)       │  ← Use Cases, Entities, Repository 인터페이스
│  - 비즈니스 로직                 │
│  - 플랫폼 독립적                 │
└────────────┬────────────────────┘
             │ Implements
┌────────────▼────────────────────┐
│   Data Layer (Data Sources)     │  ← API, Local DB, Repository 구현체
│  - API 통신 (Retrofit)          │
│  - 로컬 DB (Hive/Drift)         │
│  - DTO ↔ Entity 변환            │
└─────────────────────────────────┘
```

### 폴더 구조

```
lib/
├── main.dart                      # 앱 진입점
├── app.dart                       # MaterialApp 설정
├── core/                          # 공통 기능
│   ├── constants/                # 상수, 친근한 메시지
│   ├── theme/                    # 컬러, 텍스트 스타일, 테마
│   ├── utils/                    # 로거, 검증, 포맷터, Extensions
│   ├── errors/                   # Failures, Exceptions
│   └── config/                   # 환경 변수, 앱 설정
├── data/                          # Data Layer
│   ├── datasources/
│   │   ├── remote/               # Retrofit API
│   │   └── local/                # Hive/Drift
│   ├── models/                   # DTOs (JSON ↔ Entity)
│   └── repositories/             # Repository 구현체
├── domain/                        # Domain Layer
│   ├── entities/                 # 비즈니스 모델
│   ├── repositories/             # Repository 인터페이스
│   └── usecases/                 # Use Cases
└── presentation/                  # Presentation Layer
    ├── pages/                    # 화면 (Home, Map, SlotMachine, History)
    ├── widgets/                  # 재사용 컴포넌트
    └── providers/                # Riverpod Providers
```

## 개발 계획 (7 Phases)

### Phase 1: 프로젝트 초기 설정 ⬜

**목표**: Flutter 프로젝트 기본 환경 구성 및 Clean Architecture 폴더 구조 세팅

**주요 작업**:
- Flutter/Dart SDK 버전 확인 (3.19+/3.3+)
- pubspec.yaml 의존성 추가 (Riverpod, Hive, Dio, Retrofit 등)
- 환경 변수 설정 (.env.dev, .env.prod)
- Clean Architecture 폴더 구조 생성 (core, data, domain, presentation)
- Git 설정 및 초기 커밋

**완료 조건**: 모든 의존성 설치, 환경 변수 파일 생성, 폴더 구조 완료

---

### Phase 2: Core 레이어 구현 ⬜

**목표**: 공통 기능, 상수, 테마, 유틸리티 구현

**주요 작업**:
- 환경 설정 (EnvConfig, AppConfig)
- 상수 정의 (앱 상수, API 상수, 스토리지 키)
- 테마 설정 (컬러 팔레트, 텍스트 스타일, Light/Dark Theme)
- 에러 처리 (Failures, Exceptions)
- 유틸리티 (Logger, Validators, DateFormatter, Extensions)
- 친근한 메시지 상수 정의

**테마 컬러**:
- Primary Yellow: #FFD500
- Secondary Orange: #FF8A00
- Secondary Red: #FF5A5A (에러)
- Secondary Green: #00C896 (성공)
- Secondary Blue: #5B9FED (정보)

**완료 조건**: 환경 설정, 테마 시스템, 에러 처리, 유틸리티, 친근한 메시지 완료

---

### Phase 3: Domain 레이어 구현 ⬜

**목표**: 비즈니스 로직, 엔티티, Repository 인터페이스 정의

**주요 작업**:
- 엔티티 정의 (Restaurant, Weather, VisitHistory, RecommendationStrategy)
- Repository 인터페이스 정의
  - RestaurantRepository: 식당 조회/검색
  - WeatherRepository: 날씨 조회
  - LocationRepository: 위치 정보/권한
  - VisitHistoryRepository: 방문 기록 CRUD/통계
- Use Cases 구현
  - GetNearbyRestaurants: 거리 기반 식당 조회
  - GetRecommendation: 날씨/거리/랜덤 추천 알고리즘
  - GetCurrentWeather: 날씨 정보 조회
  - AddVisitHistory: 방문 기록 추가
  - GetVisitStatistics: 방문 통계 조회
- 추천 로직 설계 (날씨별, 거리별, 랜덤)

**추천 규칙**:
- 날씨 기반: 더운 날씨(28°C+) → 시원한 음식, 추운 날씨(10°C-) → 따뜻한 음식, 비 → 파전/수제비
- 거리 기반: 100m/500m/1000m 범위별 우선순위
- 랜덤: 완전 랜덤, 미방문 우선

**완료 조건**: 모든 엔티티, Repository 인터페이스, Use Cases, 추천 로직 완료

---

### Phase 4: Data 레이어 구현 ⬜

**목표**: API 통신, 로컬 DB, Repository 구현체 개발

**주요 작업**:
- API 데이터 소스 (Remote)
  - RestaurantApi: Retrofit 인터페이스 (GET restaurants, search)
  - WeatherApi: OpenWeatherMap API 연동
  - DioClient: Dio 인스턴스, Interceptor (로깅, 에러)
- 로컬 데이터 소스 (Local)
  - HiveDatabase: Hive 초기화, Box 등록, TypeAdapter
  - VisitHistoryLocal: 방문 기록 CRUD, 통계 계산
  - RestaurantCache: 식당 정보 캐싱 (1시간 유효)
- DTO 모델 (RestaurantDTO, WeatherDTO, VisitHistoryDTO)
  - JSON 직렬화/역직렬화
  - toEntity() / fromEntity() 변환
- Repository 구현체
  - API 호출, 캐싱, 에러 처리
  - Exception → Failure 변환
- 코드 생성 (build_runner)

**에러 매핑**:
- DioException → ServerFailure
- SocketException → NetworkFailure
- HiveError → CacheFailure
- LocationServiceDisabledException → LocationFailure

**완료 조건**: API/로컬 데이터 소스, DTO, Repository 구현체, 코드 생성 완료

---

### Phase 5: Presentation 레이어 (홈/지도) ⬜

**목표**: 홈 화면과 지도 화면 UI 구현

**주요 작업**:
- Riverpod Providers 설정
  - LocationProvider: 현재 위치, 권한 상태
  - WeatherProvider: 날씨 정보
  - RestaurantProvider: 식당 목록, 거리 필터
- 홈 화면 (HomePage)
  - AppBar, 날씨 카드, 슬롯머신 버튼, 지도 보기 버튼, 방문 기록 버튼
- 홈 화면 위젯
  - WeatherCard: 날씨 정보, 그라데이션 배경
  - ActionButton: 재사용 가능한 액션 버튼
- 지도 화면 (MapPage)
  - Naver Map, 현재 위치 마커, 식당 마커
  - 거리 선택 드롭다운 (100m/500m/1000m)
  - 하단 슬라이드업 패널 (식당 리스트)
- 지도 화면 위젯
  - DistanceDropdown: 거리 선택
  - RestaurantListItem: 식당 정보 카드
  - SlideUpPanel: 드래그 가능한 패널
- 라우팅 설정 (AppRoutes, AppRouter)
- 앱 진입점 수정 (app.dart, main.dart)

**완료 조건**: Riverpod Providers, 홈 화면, 지도 화면, 라우팅 완료

---

### Phase 6: Presentation 레이어 (슬롯머신/히스토리) ⬜

**목표**: 슬롯머신 추천 화면과 방문 기록 화면 구현

**주요 작업**:
- 슬롯머신 Providers
  - RecommendationProvider: 추천 전략, 결과, 애니메이션 상태
- 슬롯머신 화면 (SlotMachinePage)
  - 추천 전략 선택 버튼 (날씨/거리/랜덤)
  - Lottie 애니메이션 영역
  - 추천 시작 버튼 ("돌려돌려 돌림판! 🎰")
  - 추천 결과 카드 (식당 정보, 추천 이유)
- 슬롯머신 위젯
  - StrategySelector: 전략 선택
  - SlotMachineAnimation: Lottie 애니메이션 래퍼
  - RecommendationCard: 추천 결과 카드
- Lottie 애니메이션 통합 (slot_machine.json, loading.json)
- 방문 기록 Providers
  - VisitHistoryProvider: 방문 기록 목록, 통계, CRUD 액션
- 방문 기록 화면 (HistoryPage)
  - 통계 대시보드 (총 방문, 좋아하는 카테고리)
  - 방문 기록 리스트 (날짜별 그룹핑)
  - 빈 상태 UI ("아직 방문 기록이 없어요 😊")
- 방문 기록 위젯
  - StatisticsCard: 통계 정보 카드
  - VisitHistoryItem: 방문 기록 아이템 (스와이프 삭제)
  - EmptyState: 빈 상태 UI
- 친근한 메시지 통합

**완료 조건**: 슬롯머신 화면, Lottie 애니메이션, 방문 기록 화면, 통계 대시보드 완료

---

### Phase 7: 테스트 및 배포 ⬜

**목표**: 품질 보증, 테스트 작성, 빌드 및 배포 준비

**주요 작업**:
- 단위 테스트 (Unit Tests)
  - Domain 레이어: Use Cases 로직 테스트
  - Data 레이어: Repository, DTO 테스트
- 위젯 테스트 (Widget Tests)
  - HomePage, WeatherCard, RestaurantListItem 테스트
- 통합 테스트 (Integration Tests)
  - 앱 시작, 슬롯머신 플로우, 지도 플로우, 방문 기록 플로우
- 코드 품질 검사
  - flutter analyze 실행, 린트 규칙 준수
  - dart format 실행, 코드 스타일 일관성
- 성능 최적화
  - 이미지 압축, 캐싱, lazy loading
  - API 요청 최적화, Debouncing/Throttling
  - 애니메이션 최적화 (60fps)
- 빌드 설정
  - Android: build.gradle, 앱 아이콘, 권한 설정
  - iOS: Info.plist, 앱 아이콘, Bundle Identifier
- 릴리스 빌드
  - Android: APK/AAB 빌드 (<50MB 권장)
  - iOS: Archive/IPA 생성
- 배포 준비
  - Google Play Console: 스크린샷, 앱 설명, 개인정보 처리방침
  - App Store Connect: 스크린샷, 앱 설명, 개인정보 처리방침
- 문서화
  - README.md 업데이트, API 문서, 개발 가이드
- 모니터링 설정
  - Firebase Crashlytics: 에러 추적
  - Firebase Analytics: 주요 이벤트 추적

**완료 조건**: 모든 테스트 통과, 코드 품질 검사, 릴리스 빌드, 배포 준비, 문서화 완료

---

## 주요 화면

| 화면 | 설명 |
|------|------|
| **홈 화면** | 날씨 카드, 슬롯머신 버튼, 지도 보기, 방문 기록 버튼 |
| **지도 화면** | Naver Maps, 거리 드롭다운, 식당 마커, 하단 슬라이드업 리스트 |
| **슬롯머신 화면** | 추천 전략 선택, Lottie 애니메이션, 추천 결과 카드 |
| **방문 기록 화면** | 통계 대시보드, 방문 기록 리스트, 빈 상태 UI |

## 주요 마일스톤

| 마일스톤 | Phase | 핵심 산출물 |
|---------|-------|-------------|
| **환경 구성** | Phase 1 | Clean Architecture 폴더 구조, 의존성 설치 |
| **공통 기반** | Phase 2 | 테마 시스템, 에러 처리, 유틸리티 |
| **비즈니스 로직** | Phase 3 | 엔티티, Repository 인터페이스, Use Cases, 추천 알고리즘 |
| **데이터 계층** | Phase 4 | API 연동, 로컬 DB, Repository 구현체 |
| **UI 기본** | Phase 5 | 홈 화면, 지도 화면, Riverpod Providers |
| **UI 완성** | Phase 6 | 슬롯머신 화면, 방문 기록 화면, Lottie 애니메이션 |
| **품질 보증** | Phase 7 | 테스트, 최적화, 릴리스 빌드, 배포 |

## 디자인 시스템

### 컬러 팔레트

| 컬러 | Hex Code | 용도 |
|------|----------|------|
| Primary Yellow | #FFD500 | 메인 컬러, 브랜드 아이덴티티 |
| Secondary Orange | #FF8A00 | 포인트 컬러, 강조 |
| Secondary Red | #FF5A5A | 에러, 경고 |
| Secondary Green | #00C896 | 성공 메시지 |
| Secondary Blue | #5B9FED | 정보 표시 |

### 타이포그래피

- Font Family: Apple SD Gothic Neo, Pretendard, Noto Sans KR
- Font Sizes: 12px ~ 40px
- Font Weights: Regular (400) ~ Bold (700)

### 컴포넌트 스타일

- 버튼: 둥근 모서리 (16px), 그림자 효과
- 카드: 흰색 배경, 그림자, 둥근 모서리
- 입력 필드: 회색 배경, focus 시 노란색 테두리

## 시작하기

### 요구 사항

- Flutter SDK 3.19 이상
- Dart SDK 3.3 이상
- Android Studio / Xcode (플랫폼별)

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행 (개발 모드)
flutter run

# 릴리스 빌드
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

### 환경 변수 설정

.env.dev 및 .env.prod 파일 생성:

```env
API_BASE_URL=https://api.example.com
NAVER_MAP_CLIENT_ID=your_client_id
LOG_LEVEL=debug
```

## 향후 개선 사항

- 사용자 리뷰 및 평점 기능
- 소셜 공유 기능
- 친구와 함께 추천받기
- 식당 즐겨찾기 기능
- 푸시 알림 (점심시간 알림)

---

**Made with ❤️ by Woohalabs Team**
