/sc:document --plan --ultrathink

📋 주요 내용
1. 기술 스택
핵심 프레임워크

Flutter 3.19+ (Dart 3.3+)
Riverpod 2.4+ (상태 관리)
Hive 2.2+ (로컬 NoSQL DB)
Drift 2.14+ (로컬 SQL DB)
Dio 5.4+ (HTTP 클라이언트)
Retrofit 4.1+ (타입 안전 API)
Naver Maps Flutter Plugin (지도)
Geolocator 10.1+ (위치)

선택 이유

Riverpod: 강력한 상태 관리, 컴파일 타임 안전성
Hive: 빠른 NoSQL, 간단한 API
Clean Architecture: 테스트 가능, 확장 가능


Presentation Layer (UI)
  ↓ Uses
Domain Layer (Business Logic)
  ↓ Implements
Data Layer (Data Sources)
```

**레이어별 역할**
- **Presentation**: UI 렌더링, 상태 관리 (Riverpod), Use Case 호출
- **Domain**: 비즈니스 로직 (플랫폼 독립적), 엔티티, Repository 인터페이스
- **Data**: API 통신, 로컬 DB, DTO ↔ Entity 변환

---

### 3. 프로젝트 폴더 구조
```
lib/
├── main.dart
├── app.dart
├── core/                     # 공통 기능
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── errors/
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


4. 주요 화면
홈 (Home)

날씨 정보 카드
슬롯머신 버튼 (날씨/거리/랜덤 추천)
지도 보기 버튼
방문 기록 버튼

지도 (Map)

Naver Maps 지도
거리 선택 드롭다운 (100/500/1000m)
식당 마커 표시
하단 슬라이드업 식당 리스트

슬롯머신

Lottie 애니메이션
추천 전략 선택 (날씨/거리/랜덤)
결과 카드 (식당 정보 + 추천 이유)

방문 기록 (History)

방문한 식당 리스트
통계 대시보드 (총 방문, 좋아하는 테마 등)

---
화면에 보여지는 모든 문구는, 카카오나 배달의 민족처럼 친근한 메시지로 표현
개발모드와 운영모드 변경할수있게 .env세팅
디자인 테마는 @.claude/global.css를 무조건 따를것

---
위 내용을 바탕으로 계획을 @docs/ 에 Phase 별로 작성해줘 그리고 그 계획은 todo list로 작성되어 내가 얼마나 개발되었는지 확인할 수 있게 체크표시할 수있게 해줘
그리고 모든 문서는 agents:markdown-summarizer을 사용해줘