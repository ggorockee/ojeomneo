# ⚠️ Phase 순서 변경 안내

> 📱 **환경변수 설정을 나중으로 미루고, UI를 먼저 구현합니다!**

## 🔔 중요 공지

개발 순서가 **UI 우선**으로 변경되었습니다.

### 변경 이유
- 화면을 먼저 보고 싶어요
- 환경변수는 나중에 설정하고 싶어요
- Mock 데이터로 먼저 동작 확인하고 싶어요

## 📋 새로운 개발 순서

```
[기본 설정]
Phase 1: 프로젝트 기본 설정 ← 환경변수 제외
Phase 2: Core 레이어 ← 환경설정 제외

[UI 먼저!]
Phase 3: Presentation (홈/지도) ← Mock 데이터
Phase 4: Presentation (슬롯머신/히스토리) ← Mock 데이터
✅ 이 시점에서 앱 완전 동작!

[로직 구현]
Phase 5: Domain 레이어
Phase 6: Data 레이어

[API 연동]
Phase 7: 환경변수 & API 연동 ← 새로 추가!

[마무리]
Phase 8: 테스트 및 배포
```

## 🚀 시작하기

### 1단계: Phase 순서 확인
```bash
cat docs/PHASE_MIGRATION_GUIDE.md
```

### 2단계: Phase 1 시작
```bash
cat docs/phases_new/phase1-basic-setup.md
flutter pub get
flutter run
```

### 3단계: Phase 2 진행
```bash
cat docs/phases_new/phase2-core-layer.md
```

### 4단계: Phase 3-4 (UI 구현)
```bash
# Mock 데이터 추가 필요
cat docs/phases/phase5-presentation-home-map.md
cat docs/phases/phase6-presentation-slot-history.md
```

## 📁 문서 위치

| 단계 | 문서 경로 | 설명 |
|-----|-----------|------|
| 순서 변경 가이드 | `docs/PHASE_MIGRATION_GUIDE.md` | 자세한 변경 내용 |
| Phase 1 (새) | `docs/phases_new/phase1-basic-setup.md` | 환경변수 제외 |
| Phase 2 (새) | `docs/phases_new/phase2-core-layer.md` | 환경설정 제외 |
| Phase 3 | `docs/phases/phase5-presentation-home-map.md` | Mock 데이터 추가 필요 |
| Phase 4 | `docs/phases/phase6-presentation-slot-history.md` | Mock 데이터 추가 필요 |
| Phase 5 | `docs/phases/phase3-domain-layer.md` | 기존 그대로 |
| Phase 6 | `docs/phases/phase4-data-layer.md` | 기존 그대로 |
| Phase 7 | **작성 필요** | 환경변수 & API |
| Phase 8 | `docs/phases/phase7-testing-deployment.md` | 기존 그대로 |

## ✨ 주요 차이점

### Phase 1-2: 환경변수 제거
```diff
- [ ] .env.dev 파일 생성
- [ ] .env.prod 파일 생성
- [ ] EnvConfig 클래스 생성
+ ⚠️ 이 작업들은 Phase 7로 이동!
```

### Phase 3-4: Mock 데이터 추가
```dart
// lib/presentation/mock/mock_data.dart (새로 생성)
class MockData {
  static final restaurants = [...];
  static final weather = Weather(...);
  static final visitHistory = [...];
}
```

### Phase 7: 새로 추가됨
```
- 환경변수 설정
- API 클라이언트 구성
- Mock 데이터 → 실제 API 교체
```

## 🎯 각 Phase 완료 시점

| Phase | 완료 시 상태 |
|-------|------------|
| Phase 1 | 빈 앱 실행됨 |
| Phase 2 | 테마 적용된 앱 |
| Phase 3-4 | **Mock 데이터로 완전 동작!** ⭐ |
| Phase 5-6 | 로컬 DB로 동작 |
| Phase 7 | **실제 API로 동작!** 🎉 |
| Phase 8 | 배포 준비 완료 |

## 📚 추가 문서

- `docs/UI_DESIGN_RULES.md` - Material Icons 규칙
- `docs/SCREEN_FLOW.md` - 화면별 구현 예시
- `.claude/DESIGN_ASCII.md` - 원본 화면 설계
- `docs/PHASE_ORDER_NEW.md` - 새로운 순서 상세

## ⚡ 빠른 시작

```bash
# 1. 의존성 설치
flutter pub get

# 2. Phase 1 문서 읽기
cat docs/phases_new/phase1-basic-setup.md

# 3. 개발 시작!
flutter run
```

---

**궁금한 점이 있다면**:
`docs/PHASE_MIGRATION_GUIDE.md` 참조
