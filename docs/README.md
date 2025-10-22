# 오점너 (오늘 점심 뭐 먹을래?) - 개발 계획서

> 🍽️ **점심 메뉴 고민 해결사!** 날씨, 거리, 랜덤 추천으로 오늘의 식당을 찾아드려요.

## 📖 프로젝트 소개

**오점너**는 점심 메뉴 선택의 어려움을 해결하는 Flutter 기반 모바일 애플리케이션입니다. 
날씨 정보, 현재 위치 기반 거리, 완전 랜덤 중 원하는 방식으로 식당을 추천받을 수 있습니다.

### 🎯 핵심 기능

| 기능 | 설명 |
|------|------|
| 🎰 **슬롯머신 추천** | 날씨/거리/랜덤 기반으로 식당 추천 |
| 🗺️ **지도 보기** | 주변 식당을 지도에서 확인 |
| 📝 **방문 기록** | 방문한 식당 기록 및 통계 |
| ☀️ **날씨 연동** | 날씨에 맞는 메뉴 추천 |

### 💬 친근한 UI/UX

모든 메시지는 카카오, 배달의 민족 스타일의 친근한 톤으로 제공됩니다.

- "오늘 점심 뭐 먹을래? 🍽️"
- "배고프면 일도 안 되지! 빨리 골라볼까?"
- "두근두근... 어디가 나올까?"

## 🛠️ 기술 스택

### 핵심 프레임워크

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.19+ | 크로스 플랫폼 UI |
| Dart | 3.3+ | 프로그래밍 언어 |
| Riverpod | 2.4+ | 상태 관리 |
| Hive | 2.2+ | 로컬 NoSQL DB |
| Drift | 2.14+ | 로컬 SQL DB |
| Dio | 5.4+ | HTTP 클라이언트 |
| Retrofit | 4.1+ | 타입 안전 API |

### 추가 라이브러리

| 라이브러리 | 용도 |
|-----------|------|
| Naver Maps Flutter Plugin | 지도 표시 |
| Geolocator | 위치 정보 |
| Lottie | 애니메이션 |
| flutter_dotenv | 환경 변수 |

### 선택 이유

- **Riverpod**: 강력한 상태 관리, 컴파일 타임 안전성
- **Hive**: 빠른 NoSQL, 간단한 API
- **Clean Architecture**: 테스트 가능, 확장 가능

## 🏗️ 아키텍처

### Clean Architecture 레이어

```
Presentation Layer (UI)
  ↓ Uses
Domain Layer (Business Logic)
  ↓ Implements
Data Layer (Data Sources)
```

#### 레이어별 역할

| 레이어 | 역할 |
|--------|------|
| **Presentation** | UI 렌더링, 상태 관리 (Riverpod), Use Case 호출 |
| **Domain** | 비즈니스 로직 (플랫폼 독립적), 엔티티, Repository 인터페이스 |
| **Data** | API 통신, 로컬 DB, DTO ↔ Entity 변환 |

### 폴더 구조

```
lib/
├── main.dart
├── app.dart
├── core/                     # 공통 기능
│   ├── constants/           # 상수
│   ├── theme/               # 테마
│   ├── utils/               # 유틸리티
│   └── errors/              # 에러 처리
├── data/                     # Data Layer
│   ├── datasources/
│   │   ├── remote/          # API (Retrofit)
│   │   └── local/           # Hive/Drift
│   ├── models/              # DTOs
│   └── repositories/        # Repository 구현
├── domain/                   # Domain Layer
│   ├── entities/            # 비즈니스 모델
│   ├── repositories/        # Repository 인터페이스
│   └── usecases/            # Use Cases
└── presentation/             # Presentation Layer
    ├── pages/               # 화면
    ├── widgets/             # 재사용 컴포넌트
    └── providers/           # Riverpod Providers
```

## 📱 주요 화면

### 1. 홈 화면 (Home)
- 날씨 정보 카드
- 슬롯머신 버튼 (날씨/거리/랜덤 추천)
- 지도 보기 버튼
- 방문 기록 버튼

### 2. 지도 화면 (Map)
- Naver Maps 지도
- 거리 선택 드롭다운 (100m/500m/1000m)
- 식당 마커 표시
- 하단 슬라이드업 식당 리스트

### 3. 슬롯머신 화면 (Slot Machine)
- Lottie 애니메이션
- 추천 전략 선택 (날씨/거리/랜덤)
- 결과 카드 (식당 정보 + 추천 이유)

### 4. 방문 기록 화면 (History)
- 방문한 식당 리스트
- 통계 대시보드 (총 방문, 좋아하는 테마 등)

## 📋 개발 계획 (7 Phases)

| Phase | 제목 | 상태 | 문서 |
|-------|------|------|------|
| Phase 1 | 프로젝트 초기 설정 | ⬜ | [📄 보기](./phases/phase1-project-setup.md) |
| Phase 2 | Core 레이어 구현 | ⬜ | [📄 보기](./phases/phase2-core-layer.md) |
| Phase 3 | Domain 레이어 구현 | ⬜ | [📄 보기](./phases/phase3-domain-layer.md) |
| Phase 4 | Data 레이어 구현 | ⬜ | [📄 보기](./phases/phase4-data-layer.md) |
| Phase 5 | Presentation 레이어 (홈/지도) | ⬜ | [📄 보기](./phases/phase5-presentation-home-map.md) |
| Phase 6 | Presentation 레이어 (슬롯머신/히스토리) | ⬜ | [📄 보기](./phases/phase6-presentation-slot-history.md) |
| Phase 7 | 테스트 및 배포 | ⬜ | [📄 보기](./phases/phase7-testing-deployment.md) |

### 진행 상황 추적

각 Phase 문서 내의 체크박스를 통해 진행 상황을 확인할 수 있습니다.

```markdown
- [ ] 작업 항목 (미완료)
- [x] 작업 항목 (완료)
```

## 🎨 디자인 시스템

### 컬러 팔레트

| 컬러 | Hex Code | 용도 |
|------|----------|------|
| Primary Yellow | #FFD500 | 메인 컬러 |
| Secondary Orange | #FF8A00 | 포인트 컬러 |
| Secondary Red | #FF5A5A | 에러, 경고 |
| Secondary Green | #00C896 | 성공 |
| Secondary Blue | #5B9FED | 정보 |

### 타이포그래피

- **Font Family**: Apple SD Gothic Neo, Pretendard, Noto Sans KR
- **Font Sizes**: 12px ~ 40px (다양한 크기)
- **Font Weights**: Regular (400) ~ Bold (700)

### 컴포넌트

- 버튼: 둥근 모서리 (border-radius: 16px), 그림자 효과
- 카드: 흰색 배경, 그림자 효과, 둥근 모서리
- 입력 필드: 회색 배경, focus 시 노란색 테두리

자세한 내용은 `.claude/global.css` 파일을 참조하세요.

## 🚀 시작하기

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

# 빌드
flutter build apk --release      # Android
flutter build ios --release      # iOS
```

### 환경 변수 설정

`.env.dev` 및 `.env.prod` 파일을 생성하고 다음 변수를 설정하세요:

```env
API_BASE_URL=https://api.example.com
NAVER_MAP_CLIENT_ID=your_client_id
LOG_LEVEL=debug
```

## 📚 추가 자료

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Riverpod 문서](https://riverpod.dev)
- [Clean Architecture 가이드](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## 🤝 기여하기

프로젝트에 기여하고 싶으신가요? Issue와 Pull Request를 환영합니다!

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

---

**Made with ❤️ by Woohalabs Team**

## 🎨 UI 디자인 시스템

### ⚠️ 핵심 규칙

#### 1. Material Icons 필수 사용 (Emoji 금지)

**절대 사용 금지:**
- ❌ Emoji: 🎰, 🗺️, 📍, 🍕, 🍜, ⭐, ✅ 등

**필수 사용:**
- ✅ Material Icons: `Icons.casino`, `Icons.map`, `Icons.location_on` 등

```dart
// ❌ 잘못된 예시
Text('🎰 슬롯머신')

// ✅ 올바른 예시
Row(
  children: [
    Icon(Icons.casino),
    Text('슬롯머신'),
  ],
)
```

#### 2. 색상 시스템 (.claude/global.css)

모든 색상은 CSS 변수에 정의된 값을 사용합니다.

```dart
// Primary Color (오렌지 계열)
Color(0xFFFF8844)  // oklch(0.7040 0.1910 22.2160)

// Background
Color(0xFFFFFFFF)  // oklch(1 0 0)

// Text
Color(0xFF252525)  // oklch(0.1450 0 0)
```

#### 3. Border Radius & Spacing

```dart
// Border Radius
radiusSm: 6.0
radiusMd: 8.0
radiusLg: 10.0
radiusXl: 14.0

// Spacing (0.25rem = 4px 기준)
spacing1: 4.0
spacing2: 8.0
spacing3: 12.0
spacing4: 16.0
spacing6: 24.0
spacing8: 32.0
```

### 📱 화면 설계

전체 화면은 `.claude/DESIGN_ASCII.md`에 ASCII 아트로 정의되어 있습니다.

**총 17개 화면:**
- 인증/온보딩: 5개
- 권한: 2개
- 메인 기능: 6개 (홈, 슬롯머신, 지도)
- 방문 기록: 2개
- 설정: 1개

### 🔗 추가 문서

| 문서 | 설명 |
|------|------|
| [UI_DESIGN_RULES.md](./UI_DESIGN_RULES.md) | Material Icons 사용 규칙, 색상/타이포그래피 가이드 |
| [SCREEN_FLOW.md](./SCREEN_FLOW.md) | 화면 흐름도 및 각 화면 상세 구현 예시 |
| [SUMMARY.md](./SUMMARY.md) | 프로젝트 전체 요약 (빠른 참조용) |

## 🚨 개발 시 주의사항

### 필수 확인 사항

1. **Emoji 사용 금지**
   - 모든 아이콘은 Material Icons 사용
   - 코드 검색: `grep -r "🎰\|🗺️\|📍" lib/` → 결과 0개여야 함

2. **색상 하드코딩 금지**
   - 테마에 정의된 색상만 사용
   - `Color(0xFF...)` 직접 사용 최소화

3. **일관된 스타일**
   - Border Radius: 정의된 값 사용
   - Spacing: 4px 배수 사용
   - Shadow: 정의된 스타일 사용

4. **친근한 메시지**
   - 카카오/배민 스타일 톤
   - 이모티콘 대신 느낌표, 물음표 활용
   - "~요", "~까요?" 등 부드러운 표현

### 개발 워크플로우

```bash
# 1. Phase 문서 확인
cat docs/phases/phase{N}-*.md

# 2. UI 규칙 확인
cat docs/UI_DESIGN_RULES.md

# 3. 화면 설계 확인
cat .claude/DESIGN_ASCII.md
cat docs/SCREEN_FLOW.md

# 4. 개발 진행
flutter run

# 5. 검증
flutter analyze
grep -r "🎰\|🗺️\|📍" lib/  # Emoji 체크
```

