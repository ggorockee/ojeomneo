# 새로운 Phase 순서 (UI 우선 개발)

> 📱 **화면을 먼저 만들고, 로직과 API는 나중에!**

## 🎯 변경 이유

- 화면이 동작하는 것을 먼저 확인
- Mock 데이터로 UI/UX 테스트
- 환경변수와 API 설정은 화면 완성 후

## 📋 새로운 Phase 순서

### Phase 1: 프로젝트 기본 설정 (1-2시간)
**목표**: Flutter 프로젝트 기본 환경 구성

- [ ] Flutter SDK 및 의존성 설치
  - riverpod, hive, dio, naver_map, geolocator, lottie
- [ ] 폴더 구조 생성
  - lib/core, lib/presentation, lib/domain, lib/data
- [ ] Git 저장소 초기화
- [ ] ⚠️ **환경변수(.env) 설정 제외** → Phase 7로 이동

---

### Phase 2: Core 레이어 (2-3시간)
**목표**: 테마, 상수, 유틸리티 구현

- [ ] 테마 설정 (global.css 기반)
  - AppColors, AppTextStyles, AppTheme
- [ ] 상수 정의
  - 거리 옵션 [100m, 500m, 1000m, 2000m]
  - 친근한 메시지
- [ ] 유틸리티
  - Logger, Validators, DateFormatter
- [ ] 에러 처리 구조
- [ ] ⚠️ **환경설정(Config) 제외** → Phase 7로 이동

---

### Phase 3: Presentation - 홈/지도 화면 (4-6시간)
**목표**: UI 먼저 구현 (Mock 데이터 사용)

- [ ] Mock 데이터 생성
  ```dart
  // lib/presentation/mock/mock_data.dart
  final mockRestaurants = [
    Restaurant(name: '맛있는국수', category: '한식', distance: 250),
    Restaurant(name: '피자천국', category: '양식', distance: 380),
  ];
  
  final mockWeather = Weather(temp: 18, condition: '맑음');
  ```

- [ ] 홈 화면
  - AppBar (타이틀, 알림, 설정)
  - 날씨 카드 (Material Icons 사용)
  - 슬롯머신 버튼
  - 지도 보기 버튼
  - 방문 기록 버튼
  - BottomNavigationBar

- [ ] 지도 화면
  - Naver Map 통합
  - Mock 마커 표시
  - 거리 선택 드롭다운
  - 하단 슬라이드업 패널
  - 식당 리스트 (Mock 데이터)

- [ ] 라우팅 설정
  - `/home`, `/map`, `/slot-machine`, `/history`

---

### Phase 4: Presentation - 슬롯머신/히스토리 화면 (4-6시간)
**목표**: 나머지 UI 구현 (Mock 데이터 사용)

- [ ] 슬롯머신 화면
  - 거리 선택
  - Lottie 애니메이션 (또는 Flutter 애니메이션)
  - Mock 추천 결과 표시
  - Material Icons 사용

- [ ] 방문 기록 화면
  - Mock 통계 데이터
  - Mock 방문 리스트
  - 방문 기록 지도 뷰

- [ ] 인증 화면 (선택사항)
  - 스플래시
  - 온보딩
  - 로그인/회원가입 선택

- [ ] 설정 화면
  - 프로필 (Mock)
  - 추천 설정
  - 알림 설정

**✅ 이 시점에서 UI가 완전히 동작!**

---

### Phase 5: Domain 레이어 (3-4시간)
**목표**: 비즈니스 로직 구현

- [ ] 엔티티 정의
  - Restaurant, Weather, VisitHistory

- [ ] Repository 인터페이스
  - RestaurantRepository
  - WeatherRepository
  - LocationRepository
  - VisitHistoryRepository

- [ ] Use Cases
  - GetNearbyRestaurants
  - GetRecommendation (날씨/거리/랜덤 로직)
  - GetCurrentWeather
  - AddVisitHistory
  - GetVisitStatistics

- [ ] 추천 로직 설계
  - 날씨 기반 (더운날→냉면, 추운날→국밥, 비→파전)
  - 거리 기반 (가까운 순)
  - 랜덤

---

### Phase 6: Data 레이어 (4-5시간)
**목표**: Repository 구현체 및 로컬 DB

- [ ] 로컬 데이터 소스
  - Hive 초기화
  - VisitHistory 저장/조회
  - Restaurant 캐싱

- [ ] DTO 모델
  - RestaurantDTO
  - WeatherDTO
  - VisitHistoryDTO
  - toEntity(), fromEntity()

- [ ] Repository 구현체
  - Mock API 대신 로컬 데이터 우선
  - RestaurantRepositoryImpl
  - WeatherRepositoryImpl (Mock)
  - LocationRepositoryImpl (Geolocator)
  - VisitHistoryRepositoryImpl (Hive)

- [ ] Riverpod Provider 연결
  - Mock 데이터 → 실제 Repository로 교체

**✅ 이 시점에서 로컬 데이터로 앱 완전 동작!**

---

### Phase 7: 환경변수 & API 연동 (3-4시간)
**목표**: 실제 API 연동

- [ ] 환경변수 설정
  - `.env.dev` 생성
    ```
    API_BASE_URL=https://api.example.com
    NAVER_MAP_CLIENT_ID=your_client_id
    WEATHER_API_KEY=your_api_key
    LOG_LEVEL=debug
    ```
  - `.env.prod` 생성
  - flutter_dotenv 설정

- [ ] API 데이터 소스
  - Dio 클라이언트 설정
  - RestaurantAPI (Retrofit)
  - WeatherAPI (OpenWeatherMap)
  - Interceptor (로깅, 에러처리)

- [ ] Repository 업데이트
  - Mock → 실제 API 호출
  - 캐싱 전략 적용
  - 에러 처리

- [ ] Naver Map API 키 적용

**✅ 완전한 앱 완성!**

---

### Phase 8: 테스트 & 배포 (4-6시간)
**목표**: 품질 보증 및 배포 준비

- [ ] 단위 테스트
  - Domain Use Cases
  - Repository

- [ ] 위젯 테스트
  - 주요 화면

- [ ] 통합 테스트
  - 화면 플로우

- [ ] 코드 품질
  - flutter analyze
  - dart format

- [ ] 빌드 설정
  - Android (APK, AAB)
  - iOS (IPA)

- [ ] 배포 준비
  - Google Play Console
  - App Store Connect

---

## 📊 Phase 비교

| 기존 Phase | 새로운 Phase | 변경 사항 |
|-----------|-------------|----------|
| Phase 1: 초기 설정 (환경변수 포함) | Phase 1: 기본 설정 | 환경변수 제거 |
| Phase 2: Core | Phase 2: Core | 환경설정 제거 |
| Phase 3: Domain | Phase 3: Presentation (홈/지도) | UI 먼저 |
| Phase 4: Data | Phase 4: Presentation (슬롯머신/히스토리) | UI 먼저 |
| Phase 5: Presentation (홈/지도) | Phase 5: Domain | 순서 변경 |
| Phase 6: Presentation (슬롯머신/히스토리) | Phase 6: Data | 순서 변경 |
| Phase 7: 테스트/배포 | Phase 7: 환경변수 & API | 새로 추가 |
| - | Phase 8: 테스트/배포 | 기존 Phase 7 |

---

## 🎯 장점

1. **빠른 피드백**
   - UI를 먼저 보고 수정 가능
   - 사용자 경험 먼저 검증

2. **단계별 동작 확인**
   - Phase 4 완료 시: UI 완전 동작 (Mock)
   - Phase 6 완료 시: 로컬 데이터로 동작
   - Phase 7 완료 시: 실제 API 연동

3. **유연한 개발**
   - API 지연되어도 개발 진행 가능
   - UI/UX 먼저 완성

4. **환경변수 나중에**
   - API 키가 없어도 시작 가능
   - 화면 완성 후 한번에 설정

---

## 🚀 개발 시작하기

```bash
# Phase 1부터 시작
cat docs/phases_new/phase1-basic-setup.md

# 각 Phase 완료 시 확인
flutter run
flutter analyze
```

---

**다음 단계**: Phase 문서들을 새로운 순서로 재작성
