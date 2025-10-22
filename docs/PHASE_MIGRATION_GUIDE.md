# Phase 순서 변경 가이드

> 📱 **UI를 먼저 만들고, API는 나중에!**

## 🔄 변경 사항

### 기존 순서
```
Phase 1: 프로젝트 초기 설정 (환경변수 포함)
Phase 2: Core 레이어
Phase 3: Domain 레이어  
Phase 4: Data 레이어
Phase 5: Presentation (홈/지도)
Phase 6: Presentation (슬롯머신/히스토리)
Phase 7: 테스트 및 배포
```

### 새로운 순서
```
Phase 1: 기본 설정 (의존성만)
Phase 2: Core 레이어 (환경변수 제외)
Phase 3: Presentation (홈/지도) + Mock 데이터 ← UI 먼저!
Phase 4: Presentation (슬롯머신/히스토리) + Mock 데이터 ← UI 먼저!
Phase 5: Domain 레이어
Phase 6: Data 레이어
Phase 7: 환경변수 & API 연동 ← 새로 추가!
Phase 8: 테스트 및 배포
```

## 📁 문서 위치

| 새로운 Phase | 문서 위치 | 기반 문서 |
|------------|-----------|----------|
| Phase 1 | `docs/phases_new/phase1-basic-setup.md` | 기존 Phase 1 (환경변수 제거) |
| Phase 2 | `docs/phases_new/phase2-core-layer.md` | 기존 Phase 2 (환경설정 제거) |
| Phase 3 | `docs/phases/phase5-presentation-home-map.md` | 기존 Phase 5 (Mock 데이터 추가 필요) |
| Phase 4 | `docs/phases/phase6-presentation-slot-history.md` | 기존 Phase 6 (Mock 데이터 추가 필요) |
| Phase 5 | `docs/phases/phase3-domain-layer.md` | 기존 Phase 3 |
| Phase 6 | `docs/phases/phase4-data-layer.md` | 기존 Phase 4 |
| Phase 7 | 새로 작성 필요 | 환경변수 & API 연동 |
| Phase 8 | `docs/phases/phase7-testing-deployment.md` | 기존 Phase 7 |

## 🎯 핵심 변경 포인트

### Phase 1 (기본 설정)
- ✅ 의존성 설치
- ✅ 폴더 구조 생성
- ❌ **.env 파일 생성 제거** → Phase 7로 이동
- ❌ **환경변수 설정 제거** → Phase 7로 이동

### Phase 2 (Core 레이어)
- ✅ 테마 설정
- ✅ 상수 정의
- ✅ 유틸리티
- ❌ **lib/core/config/ 제거** → Phase 7로 이동
- ❌ **EnvConfig 제거** → Phase 7로 이동

### Phase 3, 4 (Presentation - UI 먼저!)
**새로 추가할 내용:**

1. **Mock 데이터 생성**
   ```dart
   // lib/presentation/mock/mock_data.dart
   
   class MockData {
     static final restaurants = [
       Restaurant(
         id: '1',
         name: '맛있는국수',
         category: '한식',
         distance: 250,
         rating: 4.5,
         reviewCount: 128,
       ),
       Restaurant(
         id: '2',
         name: '피자천국',
         category: '양식',
         distance: 380,
         rating: 4.3,
         reviewCount: 95,
       ),
       // ... 더 많은 Mock 데이터
     ];
     
     static final weather = Weather(
       temperature: 18,
       condition: '맑음',
       humidity: 60,
     );
     
     static final visitHistory = [
       VisitHistory(
         id: '1',
         restaurantId: '1',
         visitedAt: DateTime.now().subtract(Duration(days: 0)),
       ),
       // ...
     ];
   }
   ```

2. **Mock Provider 사용**
   ```dart
   // lib/presentation/providers/restaurant_provider.dart
   
   import 'package:riverpod_annotation/riverpod_annotation.dart';
   import '../mock/mock_data.dart';
   
   @riverpod
   class RestaurantList extends _$RestaurantList {
     @override
     List<Restaurant> build() {
       return MockData.restaurants;  // Mock 데이터 사용
     }
     
     void filterByDistance(int distance) {
       state = MockData.restaurants
           .where((r) => r.distance <= distance)
           .toList();
     }
   }
   ```

3. **UI 먼저 완성**
   - 모든 화면을 Mock 데이터로 구현
   - 실제 동작하는 것처럼 보이게
   - Phase 7에서 실제 API로 교체

### Phase 5, 6 (Domain & Data)
- 기존 Phase 3, 4와 동일
- UI가 완성되어 있어서 테스트하기 쉬움

### Phase 7 (새로 추가: 환경변수 & API 연동)
**작성 필요 내용:**

1. **환경변수 설정**
   ```bash
   # .env.dev
   API_BASE_URL=https://api.example.com
   NAVER_MAP_CLIENT_ID=your_dev_key
   WEATHER_API_KEY=your_dev_key
   LOG_LEVEL=debug
   
   # .env.prod
   API_BASE_URL=https://api.production.com
   NAVER_MAP_CLIENT_ID=your_prod_key
   WEATHER_API_KEY=your_prod_key
   LOG_LEVEL=error
   ```

2. **Config 클래스**
   ```dart
   // lib/core/config/env_config.dart
   
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   class EnvConfig {
     static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
     static String get naverMapClientId => dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
     static String get weatherApiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
     static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'error';
   }
   ```

3. **Mock → 실제 API 교체**
   ```dart
   // Before (Mock)
   @override
   List<Restaurant> build() {
     return MockData.restaurants;
   }
   
   // After (실제 API)
   @override
   Future<List<Restaurant>> build() async {
     final repository = ref.read(restaurantRepositoryProvider);
     return repository.getNearbyRestaurants(
       lat: currentLat,
       lng: currentLng,
       distance: currentDistance,
     );
   }
   ```

### Phase 8 (테스트 및 배포)
- 기존 Phase 7과 동일

## 🚀 개발 시작 방법

### 방법 1: 새로운 순서로 시작 (권장)

```bash
# Phase 1-2는 새 문서 사용
cat docs/phases_new/phase1-basic-setup.md
cat docs/phases_new/phase2-core-layer.md

# Phase 3-4는 기존 문서 + Mock 데이터 추가
# (Mock 데이터 부분만 추가하면 됨)
cat docs/phases/phase5-presentation-home-map.md
cat docs/phases/phase6-presentation-slot-history.md

# Phase 5-6은 기존 문서 그대로
cat docs/phases/phase3-domain-layer.md
cat docs/phases/phase4-data-layer.md

# Phase 7은 새로 작성 필요
# (환경변수 + API 연동)

# Phase 8은 기존 문서 그대로
cat docs/phases/phase7-testing-deployment.md
```

### 방법 2: Mock 데이터 예시 확인

```dart
// lib/presentation/mock/mock_data.dart 생성

class MockData {
  // 식당 Mock 데이터
  static final restaurants = [
    Restaurant(
      id: '1',
      name: '맛있는국수',
      category: '한식',
      address: '서울시 강남구',
      latitude: 37.1234,
      longitude: 127.5678,
      distance: 250,
      rating: 4.5,
      reviewCount: 128,
      imageUrl: null,
      isVisited: false,
    ),
    Restaurant(
      id: '2',
      name: '피자천국',
      category: '양식',
      address: '서울시 강남구',
      latitude: 37.1235,
      longitude: 127.5679,
      distance: 380,
      rating: 4.3,
      reviewCount: 95,
      imageUrl: null,
      isVisited: false,
    ),
    Restaurant(
      id: '3',
      name: '초밥마을',
      category: '일식',
      address: '서울시 강남구',
      latitude: 37.1236,
      longitude: 127.5680,
      distance: 520,
      rating: 4.7,
      reviewCount: 156,
      imageUrl: null,
      isVisited: true,
    ),
    // 더 많은 데이터 추가...
  ];
  
  // 날씨 Mock 데이터
  static final weather = Weather(
    temperature: 18,
    condition: WeatherCondition.sunny,
    description: '맑음',
    humidity: 60,
  );
  
  // 방문 기록 Mock 데이터
  static final visitHistory = [
    VisitHistory(
      id: '1',
      restaurantId: '1',
      visitDate: DateTime.now(),
      rating: null,
      memo: null,
    ),
    VisitHistory(
      id: '2',
      restaurantId: '3',
      visitDate: DateTime.now().subtract(Duration(days: 1)),
      rating: null,
      memo: null,
    ),
    // 더 많은 기록...
  ];
}
```

## ✅ Phase별 완료 체크리스트

### ✅ Phase 1 완료 시
- [ ] `flutter run` 실행됨
- [ ] 기본 화면 표시됨
- [ ] 환경변수 설정 안 함 (나중에!)

### ✅ Phase 2 완료 시
- [ ] 테마 적용 확인
- [ ] 색상 시스템 동작
- [ ] 환경설정 없음 (나중에!)

### ✅ Phase 3-4 완료 시 (중요!)
- [ ] 모든 화면 표시됨
- [ ] Mock 데이터로 동작함
- [ ] 버튼 클릭 시 화면 전환됨
- [ ] Material Icons만 사용 (Emoji 없음)
- [ ] **이 시점에서 앱이 완전히 동작!** ⭐

### ✅ Phase 5-6 완료 시
- [ ] 비즈니스 로직 구현
- [ ] Repository 구현
- [ ] Mock 데이터 → 로컬 DB 연동

### ✅ Phase 7 완료 시
- [ ] .env 파일 생성
- [ ] API 연동 완료
- [ ] Mock 데이터 → 실제 API 교체
- [ ] **완전한 앱 완성!** 🎉

### ✅ Phase 8 완료 시
- [ ] 테스트 통과
- [ ] 빌드 성공
- [ ] 배포 준비 완료

## 🎯 장점 요약

1. **빠른 피드백**
   - Phase 3-4 완료 시 이미 동작하는 앱
   - UI/UX 먼저 검증 가능

2. **유연한 개발**
   - API 없어도 개발 진행 가능
   - 환경변수 나중에 설정

3. **명확한 단계**
   - Phase 3-4: UI 완성
   - Phase 5-6: 로직 완성
   - Phase 7: API 연동
   - Phase 8: 배포

## 📞 도움말

문제가 생기면:
1. `docs/UI_DESIGN_RULES.md` - UI 규칙 확인
2. `docs/SCREEN_FLOW.md` - 화면 구현 예시
3. `.claude/DESIGN_ASCII.md` - 원본 디자인

---

**다음**: Phase 1부터 시작!
```bash
cat docs/phases_new/phase1-basic-setup.md
```
