# Phase 3: Domain 레이어 구현

> 🎯 **목표**: 비즈니스 로직, 엔티티, Repository 인터페이스 정의

## 📋 작업 목록

### 3.1 엔티티 정의 (Entities)
- [ ] `lib/domain/entities/restaurant.dart` 생성
  - [ ] id (String)
  - [ ] name (String)
  - [ ] category (String)
  - [ ] address (String)
  - [ ] latitude (double)
  - [ ] longitude (double)
  - [ ] distance (double?)
  - [ ] rating (double?)
  - [ ] imageUrl (String?)
  - [ ] isVisited (bool)
- [ ] `lib/domain/entities/weather.dart` 생성
  - [ ] temperature (double)
  - [ ] condition (WeatherCondition enum)
  - [ ] description (String)
  - [ ] humidity (int)
- [ ] `lib/domain/entities/visit_history.dart` 생성
  - [ ] id (String)
  - [ ] restaurantId (String)
  - [ ] visitDate (DateTime)
  - [ ] rating (int?)
  - [ ] memo (String?)
- [ ] `lib/domain/entities/recommendation_strategy.dart` 생성
  - [ ] strategyType (enum: weather, distance, random)
  - [ ] reason (String)

### 3.2 Repository 인터페이스 정의
- [ ] `lib/domain/repositories/restaurant_repository.dart` 생성
  - [ ] `Future<List<Restaurant>> getNearbyRestaurants(double lat, double lng, double distance)`
  - [ ] `Future<Restaurant> getRestaurantById(String id)`
  - [ ] `Future<List<Restaurant>> searchRestaurants(String query)`
- [ ] `lib/domain/repositories/weather_repository.dart` 생성
  - [ ] `Future<Weather> getCurrentWeather(double lat, double lng)`
- [ ] `lib/domain/repositories/location_repository.dart` 생성
  - [ ] `Future<Position> getCurrentPosition()`
  - [ ] `Future<bool> checkLocationPermission()`
  - [ ] `Future<bool> requestLocationPermission()`
- [ ] `lib/domain/repositories/visit_history_repository.dart` 생성
  - [ ] `Future<List<VisitHistory>> getVisitHistory()`
  - [ ] `Future<void> addVisitHistory(VisitHistory history)`
  - [ ] `Future<void> deleteVisitHistory(String id)`
  - [ ] `Future<Map<String, int>> getVisitStatistics()`

### 3.3 Use Cases 구현
- [ ] `lib/domain/usecases/get_nearby_restaurants.dart` 생성
  - [ ] 거리 기반 식당 목록 조회
  - [ ] 파라미터: latitude, longitude, distance
  - [ ] 반환: `List<Restaurant>`
- [ ] `lib/domain/usecases/get_recommendation.dart` 생성
  - [ ] 추천 알고리즘 실행
  - [ ] 날씨 기반 추천 로직
  - [ ] 거리 기반 추천 로직
  - [ ] 랜덤 추천 로직
  - [ ] 반환: `Restaurant` + 추천 이유
- [ ] `lib/domain/usecases/get_current_weather.dart` 생성
  - [ ] 현재 날씨 정보 조회
  - [ ] 파라미터: latitude, longitude
  - [ ] 반환: `Weather`
- [ ] `lib/domain/usecases/add_visit_history.dart` 생성
  - [ ] 방문 기록 추가
  - [ ] 파라미터: `VisitHistory`
  - [ ] 반환: `void`
- [ ] `lib/domain/usecases/get_visit_statistics.dart` 생성
  - [ ] 방문 통계 조회
  - [ ] 총 방문 횟수
  - [ ] 가장 많이 방문한 카테고리
  - [ ] 반환: `Map<String, dynamic>`

### 3.4 추천 로직 설계
- [ ] 날씨 기반 추천 규칙 정의
  - [ ] 더운 날씨 (28°C+): 시원한 음식 (냉면, 샐러드)
  - [ ] 추운 날씨 (10°C-): 따뜻한 음식 (국밥, 찌개)
  - [ ] 비 오는 날: 파전, 수제비
  - [ ] 일반 날씨: 다양한 선택
- [ ] 거리 기반 추천 규칙
  - [ ] 100m: 매우 가까운 곳 우선
  - [ ] 500m: 균형잡힌 선택
  - [ ] 1000m: 다양한 옵션
- [ ] 랜덤 추천 로직
  - [ ] 완전 랜덤 선택
  - [ ] 방문하지 않은 곳 우선

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `lib/domain/entities/restaurant.dart` | 식당 엔티티 |
| `lib/domain/repositories/restaurant_repository.dart` | 식당 Repository 인터페이스 |
| `lib/domain/usecases/get_recommendation.dart` | 추천 Use Case |

## 🎯 완료 조건

- ✅ 모든 엔티티 정의 완료
- ✅ Repository 인터페이스 정의 완료
- ✅ Use Cases 구현 완료
- ✅ 추천 로직 설계 완료

## 🚀 다음 단계

Phase 4: Data 레이어 구현으로 이동
