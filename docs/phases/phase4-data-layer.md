# Phase 4: Data 레이어 구현

> 🎯 **목표**: API 통신, 로컬 DB, Repository 구현체 개발

## 📋 작업 목록

### 4.1 API 데이터 소스 (Remote)
- [ ] `lib/data/datasources/remote/restaurant_api.dart` 생성
  - [ ] Retrofit 인터페이스 정의
  - [ ] `@GET("/restaurants")` - 식당 목록 조회
  - [ ] `@GET("/restaurants/{id}")` - 식당 상세 조회
  - [ ] `@GET("/restaurants/search")` - 식당 검색
- [ ] `lib/data/datasources/remote/weather_api.dart` 생성
  - [ ] OpenWeatherMap API 연동
  - [ ] `@GET("/weather")` - 현재 날씨 조회
  - [ ] API 키 환경 변수에서 로드
- [ ] `lib/data/datasources/remote/dio_client.dart` 생성
  - [ ] Dio 인스턴스 생성
  - [ ] BaseUrl 설정
  - [ ] Timeout 설정
  - [ ] Interceptor 추가 (로깅, 에러 처리)

### 4.2 로컬 데이터 소스 (Local)
- [ ] `lib/data/datasources/local/hive_database.dart` 생성
  - [ ] Hive 초기화
  - [ ] Box 등록 (restaurants, visit_history)
  - [ ] TypeAdapter 생성
- [ ] `lib/data/datasources/local/visit_history_local.dart` 생성
  - [ ] 방문 기록 저장
  - [ ] 방문 기록 조회
  - [ ] 방문 기록 삭제
  - [ ] 방문 통계 계산
- [ ] `lib/data/datasources/local/restaurant_cache.dart` 생성
  - [ ] 식당 정보 캐싱
  - [ ] 캐시 유효 기간 설정 (1시간)
  - [ ] 캐시 무효화

### 4.3 DTO (Data Transfer Objects) 모델
- [ ] `lib/data/models/restaurant_dto.dart` 생성
  - [ ] JSON 직렬화/역직렬화
  - [ ] `fromJson()` 메서드
  - [ ] `toJson()` 메서드
  - [ ] `toEntity()` 메서드 (DTO → Entity)
  - [ ] `fromEntity()` 메서드 (Entity → DTO)
- [ ] `lib/data/models/weather_dto.dart` 생성
  - [ ] JSON 직렬화/역직렬화
  - [ ] `toEntity()` 메서드
- [ ] `lib/data/models/visit_history_dto.dart` 생성
  - [ ] Hive TypeAdapter 생성
  - [ ] `toEntity()` 메서드
  - [ ] `fromEntity()` 메서드

### 4.4 Repository 구현체
- [ ] `lib/data/repositories/restaurant_repository_impl.dart` 생성
  - [ ] `RestaurantRepository` 인터페이스 구현
  - [ ] API 호출 로직
  - [ ] 캐싱 로직
  - [ ] 에러 처리 (try-catch)
  - [ ] Exception → Failure 변환
- [ ] `lib/data/repositories/weather_repository_impl.dart` 생성
  - [ ] `WeatherRepository` 인터페이스 구현
  - [ ] OpenWeatherMap API 호출
  - [ ] 에러 처리
- [ ] `lib/data/repositories/location_repository_impl.dart` 생성
  - [ ] `LocationRepository` 인터페이스 구현
  - [ ] Geolocator 패키지 사용
  - [ ] 위치 권한 요청 로직
  - [ ] 현재 위치 조회
- [ ] `lib/data/repositories/visit_history_repository_impl.dart` 생성
  - [ ] `VisitHistoryRepository` 인터페이스 구현
  - [ ] Hive 기반 CRUD 작업
  - [ ] 통계 계산 로직

### 4.5 코드 생성
- [ ] `build_runner` 실행
  - [ ] Retrofit 코드 생성
  - [ ] Hive TypeAdapter 생성
  - [ ] `flutter pub run build_runner build --delete-conflicting-outputs`

### 4.6 에러 처리 및 매핑
- [ ] Exception 매핑 로직 구현
  - [ ] `DioException` → `ServerFailure`
  - [ ] `SocketException` → `NetworkFailure`
  - [ ] `HiveError` → `CacheFailure`
  - [ ] `LocationServiceDisabledException` → `LocationFailure`

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `lib/data/datasources/remote/restaurant_api.dart` | Retrofit API 인터페이스 |
| `lib/data/datasources/local/hive_database.dart` | Hive 로컬 DB |
| `lib/data/repositories/restaurant_repository_impl.dart` | Repository 구현체 |

## 🎯 완료 조건

- ✅ API 데이터 소스 구현 완료
- ✅ 로컬 데이터 소스 구현 완료
- ✅ DTO 모델 정의 완료
- ✅ Repository 구현체 완료
- ✅ 코드 생성 완료

## 🚀 다음 단계

Phase 5: Presentation 레이어 (홈/지도) 구현으로 이동
