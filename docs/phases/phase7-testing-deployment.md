# Phase 7: 테스트 및 배포

> 🎯 **목표**: 품질 보증, 테스트 작성, 빌드 및 배포 준비

## 📋 작업 목록

### 7.1 단위 테스트 (Unit Tests)
- [ ] Domain 레이어 테스트
  - [ ] `test/domain/usecases/get_recommendation_test.dart`
    - [ ] 날씨 기반 추천 로직 테스트
    - [ ] 거리 기반 추천 로직 테스트
    - [ ] 랜덤 추천 로직 테스트
  - [ ] `test/domain/usecases/get_nearby_restaurants_test.dart`
    - [ ] 거리 필터링 테스트
    - [ ] 정렬 로직 테스트
- [ ] Data 레이어 테스트
  - [ ] `test/data/repositories/restaurant_repository_impl_test.dart`
    - [ ] API 호출 성공 케이스
    - [ ] API 호출 실패 케이스
    - [ ] 캐싱 로직 테스트
  - [ ] `test/data/models/restaurant_dto_test.dart`
    - [ ] JSON 직렬화 테스트
    - [ ] Entity 변환 테스트

### 7.2 위젯 테스트 (Widget Tests)
- [ ] `test/presentation/pages/home_page_test.dart`
  - [ ] 홈 화면 렌더링 테스트
  - [ ] 버튼 탭 동작 테스트
  - [ ] 날씨 카드 표시 테스트
- [ ] `test/presentation/widgets/weather_card_test.dart`
  - [ ] 날씨 정보 표시 테스트
  - [ ] 날씨별 배경 색상 테스트
- [ ] `test/presentation/widgets/restaurant_list_item_test.dart`
  - [ ] 식당 정보 표시 테스트
  - [ ] 탭 동작 테스트

### 7.3 통합 테스트 (Integration Tests)
- [ ] `integration_test/app_test.dart`
  - [ ] 앱 시작 플로우 테스트
  - [ ] 홈 → 슬롯머신 → 추천 결과 플로우
  - [ ] 홈 → 지도 → 식당 선택 플로우
  - [ ] 방문 기록 추가/삭제 플로우

### 7.4 코드 품질 검사
- [ ] `flutter analyze` 실행
  - [ ] 모든 경고 해결
  - [ ] 린트 규칙 준수
- [ ] 코드 포맷팅
  - [ ] `dart format .` 실행
  - [ ] 일관된 코드 스타일 유지
- [ ] 코드 리뷰 체크리스트
  - [ ] Clean Architecture 원칙 준수
  - [ ] 에러 처리 완료
  - [ ] null safety 적용

### 7.5 성능 최적화
- [ ] 이미지 최적화
  - [ ] 이미지 압축
  - [ ] 캐시 설정
  - [ ] lazy loading 적용
- [ ] API 요청 최적화
  - [ ] 불필요한 요청 제거
  - [ ] 캐싱 전략 적용
  - [ ] Debouncing/Throttling
- [ ] 애니메이션 최적화
  - [ ] 부드러운 60fps 유지
  - [ ] 불필요한 rebuild 방지

### 7.6 빌드 설정
- [ ] Android 빌드 설정
  - [ ] `android/app/build.gradle` 설정
    - [ ] minSdkVersion 확인
    - [ ] targetSdkVersion 확인
    - [ ] 앱 버전 설정
  - [ ] 앱 아이콘 설정
  - [ ] 앱 이름 설정
  - [ ] 권한 설정 (위치, 인터넷)
- [ ] iOS 빌드 설정
  - [ ] `ios/Runner/Info.plist` 설정
    - [ ] 위치 권한 설명 추가
    - [ ] 앱 이름 설정
  - [ ] 앱 아이콘 설정
  - [ ] Bundle Identifier 설정

### 7.7 릴리스 빌드
- [ ] Android 릴리스 빌드
  - [ ] `flutter build apk --release`
  - [ ] `flutter build appbundle --release`
  - [ ] APK 크기 확인 (<50MB 권장)
- [ ] iOS 릴리스 빌드
  - [ ] `flutter build ios --release`
  - [ ] Archive 생성
  - [ ] IPA 파일 생성

### 7.8 배포 준비
- [ ] Google Play Console 준비
  - [ ] 앱 등록
  - [ ] 스크린샷 준비 (최소 2개, 각 화면)
  - [ ] 앱 설명 작성 (친근한 톤)
  - [ ] 개인정보 처리방침 작성
- [ ] App Store Connect 준비
  - [ ] 앱 등록
  - [ ] 스크린샷 준비
  - [ ] 앱 설명 작성
  - [ ] 개인정보 처리방침 작성

### 7.9 문서화
- [ ] README.md 업데이트
  - [ ] 프로젝트 소개
  - [ ] 설치 방법
  - [ ] 실행 방법
  - [ ] 주요 기능
  - [ ] 스크린샷
- [ ] API 문서 작성
  - [ ] API 엔드포인트 목록
  - [ ] 요청/응답 예시
- [ ] 개발 가이드 작성
  - [ ] 코드 구조 설명
  - [ ] 기여 방법
  - [ ] 버그 리포트 방법

### 7.10 모니터링 설정
- [ ] 에러 추적 설정
  - [ ] Firebase Crashlytics 통합
  - [ ] 에러 리포팅 설정
- [ ] 분석 설정
  - [ ] Firebase Analytics 통합
  - [ ] 주요 이벤트 추적 설정
    - [ ] 슬롯머신 사용
    - [ ] 지도 조회
    - [ ] 방문 기록 추가

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `test/domain/usecases/get_recommendation_test.dart` | 추천 로직 테스트 |
| `android/app/build.gradle` | Android 빌드 설정 |
| `ios/Runner/Info.plist` | iOS 설정 |

## 🎯 완료 조건

- ✅ 모든 테스트 통과 (단위/위젯/통합)
- ✅ 코드 품질 검사 통과
- ✅ 릴리스 빌드 성공
- ✅ 배포 준비 완료
- ✅ 문서화 완료

## 🎉 프로젝트 완료!

모든 Phase가 완료되었습니다. 배포 후 사용자 피드백을 수집하고 지속적인 개선을 진행하세요.

### 다음 개선 사항 아이디어
- 사용자 리뷰 및 평점 기능
- 소셜 공유 기능
- 친구와 함께 추천받기
- 식당 즐겨찾기 기능
- 푸시 알림 (점심시간 알림)
