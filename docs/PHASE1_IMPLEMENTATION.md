# Phase 1 - MVP 구현 진행 상황

> 스케치 기반 메뉴 추천 API 구현

---

## 구현 체크리스트

### 1. 데이터 모델 (Server - Go GORM)

- [x] Menu 모델 생성
- [x] Sketch 모델 생성
- [x] Recommendation 모델 생성
- [x] AutoMigrate 적용

### 2. LLM 클라이언트

- [x] OpenAI API 클라이언트 구조체
- [x] Vision API 연동 (이미지 분석)
- [x] 프롬프트 템플릿 구현
- [x] 응답 파싱 로직
- [x] Mock 응답 (API 키 없을 때)

### 3. 서비스 레이어

- [x] Menu 서비스 (CRUD, 태그 매칭)
- [x] Sketch 서비스 (분석, 저장)
- [x] Recommendation 서비스 (추천 로직)

### 4. API 핸들러

- [x] `POST /ojeomneo/v1/sketch/analyze` - 스케치 분석 및 추천
- [x] `GET /ojeomneo/v1/sketch/history` - 히스토리 조회
- [x] `GET /ojeomneo/v1/sketch/:id` - 스케치 상세 조회
- [x] `GET /ojeomneo/v1/menus` - 메뉴 목록 조회
- [x] `GET /ojeomneo/v1/menus/categories` - 카테고리 목록
- [x] `GET /ojeomneo/v1/menus/:id` - 메뉴 상세 조회

### 5. 라우터 및 통합

- [x] 라우터 등록
- [x] Swagger 문서 생성
- [x] 환경변수 추가 (OPENAI_API_KEY, OPENAI_MODEL)

### 6. 초기 데이터

- [x] 메뉴 시드 데이터 (55개)

---

## 파일 구조 (완료)

```
server/
├── internal/
│   ├── model/
│   │   ├── menu.go           # [x] 메뉴 모델
│   │   ├── sketch.go         # [x] 스케치 모델
│   │   └── recommendation.go # [x] 추천 모델
│   ├── service/
│   │   ├── llm/
│   │   │   └── openai.go     # [x] OpenAI 클라이언트
│   │   ├── menu.go           # [x] 메뉴 서비스
│   │   └── sketch.go         # [x] 스케치 서비스
│   ├── handler/
│   │   ├── menu.go           # [x] 메뉴 핸들러
│   │   └── sketch.go         # [x] 스케치 핸들러
│   └── config/
│       └── config.go         # [x] OpenAI 설정 추가
└── cmd/api/
    └── main.go               # [x] 라우터 등록
```

---

## 구현 순서

| 순서 | 작업 | 상태 |
|------|------|------|
| 1 | Menu 모델 | [x] |
| 2 | Sketch 모델 | [x] |
| 3 | Recommendation 모델 | [x] |
| 4 | Config에 OpenAI 설정 추가 | [x] |
| 5 | OpenAI LLM 클라이언트 | [x] |
| 6 | Menu 서비스 | [x] |
| 7 | Sketch 서비스 | [x] |
| 8 | Menu 핸들러 | [x] |
| 9 | Sketch 핸들러 | [x] |
| 10 | main.go 라우터 등록 | [x] |
| 11 | Swagger 문서 | [x] |
| 12 | 메뉴 시드 데이터 | [x] |

---

## API 명세 (Phase 1)

### POST /ojeomneo/v1/sketch/analyze

스케치 이미지를 분석하여 메뉴를 추천합니다.

**Request**:

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| image | File | O | 스케치 이미지 (PNG/JPEG, max 5MB) |
| text | String | X | 추가 텍스트 입력 |
| device_id | String | O | 디바이스 식별자 (비회원) |

**Response (200)**:

```json
{
  "success": true,
  "data": {
    "sketch_id": "550e8400-e29b-41d4-a716-446655440000",
    "analysis": {
      "emotion": "피곤하고 위로받고 싶은",
      "keywords": ["따뜻함", "포근함", "집밥"],
      "mood": "calm"
    },
    "recommendation": {
      "primary": {
        "menu_id": 1,
        "name": "된장찌개",
        "category": "korean",
        "image_url": "https://...",
        "reason": "지친 하루 끝에 따뜻한 국물 한 숟갈은 마음까지 녹여줄 거예요",
        "tags": ["위로", "따뜻한", "국물"]
      },
      "alternatives": [
        {
          "menu_id": 2,
          "name": "칼국수",
          "category": "korean",
          "reason": "따끈한 면발이 속을 편하게 해줄 거예요"
        }
      ]
    },
    "created_at": "2024-01-15T12:00:00Z"
  }
}
```

### GET /ojeomneo/v1/sketch/history

디바이스별 스케치 히스토리를 조회합니다.

**Query Parameters**:

| 필드 | 타입 | 설명 |
|------|------|------|
| device_id | String | 디바이스 식별자 (필수) |
| page | Int | 페이지 번호 (default: 1) |
| limit | Int | 페이지당 개수 (default: 10) |

### GET /ojeomneo/v1/menus

메뉴 목록을 조회합니다.

**Query Parameters**:

| 필드 | 타입 | 설명 |
|------|------|------|
| category | String | 카테고리 필터 |
| tag | String | 태그 필터 |
| page | Int | 페이지 번호 (default: 1) |
| limit | Int | 페이지당 개수 (default: 20) |

### GET /ojeomneo/v1/menus/categories

사용 가능한 카테고리 목록을 반환합니다.

### GET /ojeomneo/v1/menus/:id

메뉴 상세 정보를 조회합니다.

---

## 환경 변수 (추가됨)

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| OPENAI_API_KEY | OpenAI API 키 | (없으면 mock 응답) |
| OPENAI_MODEL | 사용할 모델 | gpt-4o-mini |
| UPLOAD_PATH | 이미지 업로드 경로 | ./uploads |

---

## 남은 작업

1. **Swagger 문서 생성**
   - `swag init -g cmd/api/main.go -o docs`

2. **테스트**
   - API 통합 테스트
   - LLM 응답 검증

---

## 메뉴 시드 데이터 실행 방법

```bash
# 시드 데이터와 함께 서버 실행
SEED_DATA=true go run ./cmd/api

# 또는 환경변수 설정 후 실행
export SEED_DATA=true
go run ./cmd/api
```

## 메뉴 카테고리 (55개 메뉴)

| 카테고리 | 개수 | 예시 |
|----------|------|------|
| korean (한식) | 12 | 된장찌개, 김치찌개, 삼겹살, 비빔밥 |
| chinese (중식) | 6 | 짜장면, 짬뽕, 탕수육 |
| japanese (일식) | 7 | 초밥, 라멘, 돈카츠, 우동 |
| western (양식) | 7 | 스테이크, 파스타, 피자 |
| asian (아시안) | 6 | 쌀국수, 팟타이, 카레 |
| snack (분식) | 7 | 떡볶이, 김밥, 라면, 냉면 |
| cafe (카페) | 6 | 케이크, 아이스크림, 커피 |
| other (기타) | 5 | 치킨, 족발, 보쌈 |
