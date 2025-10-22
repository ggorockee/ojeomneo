# Phase 2: Core 레이어 구현

> 🎯 **목표**: 공통 기능, 상수, 테마, 유틸리티 구현

## 📋 작업 목록

### 2.1 환경 설정 (Config)
- [ ] `lib/core/config/env_config.dart` 생성
  - [ ] `.env` 파일 로드 로직
  - [ ] 개발/운영 모드 구분
  - [ ] 환경 변수 접근 인터페이스
- [ ] `lib/core/config/app_config.dart` 생성
  - [ ] 앱 버전 정보
  - [ ] API 타임아웃 설정
  - [ ] 로그 레벨 설정

### 2.2 상수 정의 (Constants)
- [ ] `lib/core/constants/app_constants.dart` 생성
  - [ ] 앱 이름: "오점너"
  - [ ] 기본 거리 옵션: [100m, 500m, 1000m]
  - [ ] 추천 전략 타입: enum (날씨, 거리, 랜덤)
- [ ] `lib/core/constants/api_constants.dart` 생성
  - [ ] API 엔드포인트 정의
  - [ ] HTTP 상태 코드
  - [ ] 타임아웃 값
- [ ] `lib/core/constants/storage_keys.dart` 생성
  - [ ] Hive 박스 이름
  - [ ] SharedPreferences 키
  - [ ] 캐시 키 정의

### 2.3 테마 설정 (Theme)
- [ ] `lib/core/theme/app_colors.dart` 생성
  - [ ] Primary Yellow: #FFD500
  - [ ] Secondary Orange: #FF8A00
  - [ ] Gray Scale 정의
  - [ ] Semantic Colors (success, error, warning, info)
- [ ] `lib/core/theme/app_text_styles.dart` 생성
  - [ ] 제목 스타일 (친근한 폰트)
  - [ ] 본문 스타일
  - [ ] 버튼 텍스트 스타일
  - [ ] 캡션 스타일
- [ ] `lib/core/theme/app_theme.dart` 생성
  - [ ] Light Theme 정의
  - [ ] Dark Theme 정의 (선택사항)
  - [ ] 버튼 테마
  - [ ] 카드 테마
  - [ ] AppBar 테마

### 2.4 에러 처리 (Errors)
- [ ] `lib/core/errors/failures.dart` 생성
  - [ ] `Failure` 추상 클래스
  - [ ] `ServerFailure` 클래스
  - [ ] `CacheFailure` 클래스
  - [ ] `NetworkFailure` 클래스
  - [ ] `LocationFailure` 클래스
- [ ] `lib/core/errors/exceptions.dart` 생성
  - [ ] `ServerException`
  - [ ] `CacheException`
  - [ ] `NetworkException`
  - [ ] `LocationException`

### 2.5 유틸리티 (Utils)
- [ ] `lib/core/utils/logger.dart` 생성
  - [ ] 개발 모드 로그
  - [ ] 운영 모드 로그 (에러만)
  - [ ] 로그 포맷팅
- [ ] `lib/core/utils/validators.dart` 생성
  - [ ] 이메일 검증 (선택)
  - [ ] 거리 범위 검증
  - [ ] null 체크 유틸리티
- [ ] `lib/core/utils/date_formatter.dart` 생성
  - [ ] 날짜 포맷팅 ("오늘", "어제", "n일 전")
  - [ ] 시간 포맷팅
- [ ] `lib/core/utils/extensions.dart` 생성
  - [ ] String extensions
  - [ ] DateTime extensions
  - [ ] BuildContext extensions

### 2.6 친근한 메시지 상수
- [ ] `lib/core/constants/friendly_messages.dart` 생성
  - [ ] 홈 화면 메시지
    - [ ] "오늘 점심 뭐 먹을래? 🍽️"
    - [ ] "배고프면 일도 안 되지! 빨리 골라볼까?"
  - [ ] 슬롯머신 메시지
    - [ ] "돌려돌려 돌림판! 🎰"
    - [ ] "오늘의 행운이 당신을 기다려요!"
    - [ ] "두근두근... 어디가 나올까?"
  - [ ] 지도 화면 메시지
    - [ ] "가까운 맛집을 찾아봐요 🗺️"
    - [ ] "이 근처에 좋은 곳들이 많아요!"
  - [ ] 에러 메시지
    - [ ] "앗! 잠깐 문제가 생겼어요 😅"
    - [ ] "인터넷 연결을 확인해주세요!"
    - [ ] "위치 정보를 켜주시면 더 정확해요!"

## 📝 주요 파일

| 파일 경로 | 설명 |
|-----------|------|
| `lib/core/config/env_config.dart` | 환경 변수 설정 |
| `lib/core/theme/app_theme.dart` | 앱 테마 정의 |
| `lib/core/constants/friendly_messages.dart` | 친근한 메시지 |
| `lib/core/errors/failures.dart` | 에러 처리 |

## 🎯 완료 조건

- ✅ 환경 설정 로직 완료
- ✅ 테마 시스템 구현 완료
- ✅ 에러 처리 구조 완료
- ✅ 유틸리티 함수 구현 완료
- ✅ 친근한 메시지 정의 완료

## 🚀 다음 단계

Phase 3: Domain 레이어 구현으로 이동
