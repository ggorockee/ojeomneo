# 스케치 기반 메뉴 추천 - 작업계획서

> 작성일: 2025-12-04
> PRD 문서: [SKETCH_RECOMMENDATION_PRD.md](./SKETCH_RECOMMENDATION_PRD.md)

---

## 진행 현황 요약

| Phase | 설명 | 진행률 |
|-------|------|--------|
| Phase 0 | 앱 버전 관리 시스템 | **8/8 ✅** |
| Phase 1 | 이미지 업로드 인프라 | **4/5 (80%)** |
| Phase 2 | 메뉴 데이터 기반 구축 | 0/8 |
| Phase 3 | 스케치 분석 API | 0/12 |
| Phase 4 | Mobile UI 구현 | 0/10 |

---

## Phase 0: 앱 버전 관리 시스템

> 난이도: 낮음 | 의존성: 없음 | 우선순위: 최상

앱 출시 전 필수 기능. 강제 업데이트 제어로 긴급 대응 가능.

### Server (Go)

- [x] AppVersion 모델 생성 (GORM)
- [x] GET /ojeomneo/v1/app/version API 구현
- [x] 버전 비교 로직 구현 (Semantic Versioning)

### Admin (Django)

- [x] AppVersion 모델 생성 (managed=False)
- [x] AppVersion Admin 등록 (Unfold)
- [ ] iOS/Android 초기 데이터 생성 (Admin UI에서 수동 입력)

### Mobile (Flutter)

- [x] 앱 시작 시 버전 체크 로직
- [x] 강제 업데이트 팝업 UI (흰색 배경, 회색 오버레이)

---

## Phase 1: 이미지 업로드 인프라 (Cloudflare Images)

> 난이도: 중간 | 의존성: Cloudflare 계정 | 우선순위: 높음

메뉴 이미지 저장을 위한 인프라. 관리자만 업로드 (Mobile 사용자는 업로드 불필요).

### Server (Go)

- [x] Cloudflare Images 클라이언트 구현
- [x] POST /ojeomneo/v1/images/upload API 구현 (파일 업로드)
- [x] POST /ojeomneo/v1/images/upload-url API 구현 (URL에서 업로드)
- [x] DELETE /ojeomneo/v1/images/:id API 구현

### Admin (Django)

- [ ] 메뉴 이미지 업로드 UI (Phase 2에서 구현)

---

## Phase 2: 메뉴 데이터 기반 구축

> 난이도: 낮음 | 의존성: Phase 1 (이미지 저장) | 우선순위: 높음

추천 시스템의 기반이 되는 메뉴 데이터 관리.

### Server (Go)

- [ ] Menu 모델 생성/수정 (image_url 필드 추가)
- [ ] 메뉴 태그 구조 설계 (emotion_tags, situation_tags, attribute_tags)

### Admin (Django)

- [ ] Menu 모델 동기화 (managed=False)
- [ ] Menu Admin 등록 (이미지 업로드 + 태그 관리)
- [ ] 메뉴 이미지 업로드 UI (Cloudflare Images API 활용)

### 데이터

- [ ] 초기 메뉴 데이터 50개 입력
- [ ] 감정/상황/특성 태그 매핑
- [ ] 메뉴별 대표 이미지 업로드

---

## Phase 3: 스케치 분석 API

> 난이도: 높음 | 의존성: Phase 1, Phase 2 | 우선순위: 핵심

핵심 기능. LLM을 활용한 스케치 분석 및 메뉴 추천.

### Server (Go)

- [ ] Sketch 모델 생성
- [ ] Recommendation 모델 생성
- [ ] POST /ojeomneo/v1/sketch/analyze API 구현
- [ ] LLM 클라이언트 설정 (Gemini Vision API)
- [ ] 분석 프롬프트 구현 (감정/키워드/분위기 추출)
- [ ] 메뉴 매칭 로직 구현 (태그 유사도 기반)
- [ ] 추천 이유 생성 프롬프트 구현
- [ ] 응답 캐싱 (Redis)

### Admin (Django)

- [ ] Sketch 모델 동기화
- [ ] Recommendation 모델 동기화
- [ ] 스케치/추천 조회 Admin (읽기 전용)

### 테스트

- [ ] LLM 분석 결과 검증 테스트
- [ ] 메뉴 매칭 정확도 테스트

---

## Phase 4: Mobile UI 구현

> 난이도: 중간 | 의존성: Phase 3 | 우선순위: 핵심

사용자 인터페이스 구현.

### 스케치 화면

- [ ] 캔버스 위젯 구현 (자유 드로잉)
- [ ] 텍스트 입력 모드
- [ ] 혼합 모드 (드로잉 + 텍스트)
- [ ] "추천받기" 버튼 및 이미지 캡처

### 결과 화면

- [ ] 로딩 애니메이션 (재미있는 문구)
- [ ] 메뉴 추천 카드 UI
- [ ] 추천 이유 표시
- [ ] 다시하기 버튼

### 추가 기능

- [ ] 히스토리 화면 (선택)
- [ ] SNS 공유 기능 (선택)

---

## 환경변수 체크리스트

### Server

| 변수명 | 설명 | Phase | 상태 |
|--------|------|-------|------|
| CLOUDFLARE_ACCOUNT_ID | Cloudflare 계정 ID | 1 | ✅ |
| CLOUDFLARE_ACCOUNT_HASH | Cloudflare Account Hash | 1 | ✅ |
| CLOUDFLARE_API_KEY | Cloudflare Images API 토큰 | 1 | ✅ |
| GEMINI_API_KEY | Gemini API 키 | 3 | ✅ |

---

## 우선순위 정리

```
Phase 0 (앱 버전) ─────────────────────────────────────┐
                                                       │
Phase 1 (이미지 인프라) ──→ Phase 2 (메뉴 데이터) ──→ Phase 3 (스케치 API) ──→ Phase 4 (Mobile UI)
```

**권장 순서**: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4

- Phase 0: 독립적, 언제든 먼저 완료 가능
- Phase 1-4: 순차적 의존성 존재

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2025-12-04 | 초안 작성 |
| 2025-12-04 | Phase 0 완료 (앱 버전 관리 시스템) |
| 2025-12-04 | Phase 1 Server 완료 (Cloudflare Images API), R2 → Images로 변경 |
