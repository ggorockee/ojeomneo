# 참고 화면 분석 및 구현 가이드

## 개요
`/Users/woohyeon/ggorockee/reviewmaps/` 디렉토리의 참고 화면들을 분석하여 현재 프로젝트 구현에 반영할 사항을 정리합니다.

---

## 참고 화면 디렉토리

- **모바일 참고 화면**: `/Users/woohyeon/ggorockee/reviewmaps/mobile`
- **서버 참고 코드**: `/Users/woohyeon/ggorockee/reviewmaps/server`

---

## 1. 모바일 화면 비교 분석

### 1.1 인증 관련 화면

#### 참고 프로젝트의 인증 화면 구조
```
/Users/woohyeon/ggorockee/reviewmaps/mobile/lib/screens/auth/
├── login_screen.dart          ✅ 현재 프로젝트에도 있음
├── sign_up_screen.dart        ❌ 현재 프로젝트에 없음 (TODO)
├── password_reset_screen.dart ❌ 현재 프로젝트에 없음 (TODO)
└── password_change_screen.dart ❌ 현재 프로젝트에 없음
```

#### 현재 프로젝트 상태

**✅ login_screen.dart** - 완료
- Google, Apple, Kakao 로그인 구현 완료
- 이메일/비밀번호 입력 필드 UI 완료
- TODO: 이메일 로그인 API 연동 필요

**❌ sign_up_screen.dart** - 미구현
- TODO 항목: 회원가입 화면 구현 (SignUpScreen)
- 참고 화면에서 구현 패턴 확인 필요

**❌ password_reset_screen.dart** - 미구현
- TODO 항목: 비밀번호 찾기 화면 구현 (ForgotPasswordScreen)
- 참고 화면에서 구현 패턴 확인 필요

**❌ password_change_screen.dart** - 미구현
- 로그인 후 비밀번호 변경 화면
- 우선순위: 낮음 (이메일 로그인 구현 후)

---

### 1.2 기타 화면 비교

| 화면 | 참고 프로젝트 | 현재 프로젝트 | 상태 |
|------|--------------|---------------|------|
| splash_screen.dart | ✅ 있음 | ✅ 있음 | ✅ 완료 |
| home_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 (스케치 화면이 메인) |
| main_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| profile_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| my_page_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| settings_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| map_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| search_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| notification_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |
| campaign_list_screen.dart | ✅ 있음 | ❌ 없음 | 미구현 |

**현재 프로젝트의 핵심 화면**:
- ✅ `sketch_screen.dart` - 스케치 그리기
- ✅ `result_screen.dart` - 추천 결과
- ✅ `history_screen.dart` - 히스토리
- ✅ `login_screen.dart` - 로그인

---

## 2. 서버 코드 비교 분석

### 2.1 핸들러 구조

#### 참고 프로젝트 핸들러
```
/Users/woohyeon/ggorockee/reviewmaps/server/internal/handlers/
├── auth.go              ✅ 현재 프로젝트에도 있음
├── user.go              ❌ 현재 프로젝트에 없음
├── app_config.go        ❌ 현재 프로젝트에 없음
├── campaign.go          ❌ 현재 프로젝트에 없음
├── category.go          ❌ 현재 프로젝트에 없음
├── keyword_alert.go     ❌ 현재 프로젝트에 없음
└── health.go            ❌ 현재 프로젝트에 없음 (모듈화 필요)
```

#### 현재 프로젝트 핸들러
```
server/internal/handler/
├── auth.go              ✅ SNS 로그인 구현 완료
├── menu.go              ✅ 메뉴 조회
├── sketch.go            ✅ 스케치 분석
└── health.go            ✅ (module/server.go에 통합)
```

---

## 3. TODO 항목 및 구현 가이드

### 3.1 우선순위 높음

#### 1. 이메일 로그인 구현
**현재 상태**: UI는 완료, API 연동 필요
**참고**: `/Users/woohyeon/ggorockee/reviewmaps/server/internal/handlers/auth.go`
- 백엔드 이메일 로그인 API 엔드포인트 확인
- `AuthService.loginWithEmail()` 메서드 구현
- JWT 토큰 발급 및 저장

#### 2. 회원가입 화면 구현
**현재 상태**: TODO 주석만 존재
**참고**: `/Users/woohyeon/ggorockee/reviewmaps/mobile/lib/screens/auth/sign_up_screen.dart`
- 화면 구조 및 UI 컴포넌트 확인
- 백엔드 회원가입 API 엔드포인트 확인
- `AuthService.signUp()` 메서드 구현

#### 3. 비밀번호 찾기 화면 구현
**현재 상태**: TODO 주석만 존재 (2곳)
**참고**: `/Users/woohyeon/ggorockee/reviewmaps/mobile/lib/screens/auth/password_reset_screen.dart`
- 화면 구조 및 UI 컴포넌트 확인
- 백엔드 비밀번호 재설정 API 엔드포인트 확인
- 이메일 발송 로직 확인

### 3.2 우선순위 낮음

#### 4. 비밀번호 변경 화면
- 로그인 후 프로필 설정에서 사용
- 참고: `/Users/woohyeon/ggorockee/reviewmaps/mobile/lib/screens/auth/password_change_screen.dart`

---

## 4. 참고 화면 활용 방법

### 4.1 화면 구조 분석

참고 프로젝트의 화면을 분석하여:
1. **UI 패턴 확인**: 버튼 스타일, 입력 필드, 에러 처리 등
2. **상태 관리**: Provider, StatefulWidget 등
3. **네비게이션**: 화면 전환 패턴
4. **API 연동**: 서비스 레이어 구조

### 4.2 코드 재사용

참고 화면의 코드를 직접 복사하지 않고:
- **패턴만 참고**: 구조와 로직 흐름 참고
- **현재 프로젝트 스타일 적용**: `AppTheme`, `ScreenUtil` 등 기존 스타일 유지
- **의존성 확인**: 참고 프로젝트와 현재 프로젝트의 패키지 차이 확인

---

## 5. 구현 체크리스트

### 5.1 인증 관련 화면

- [ ] **회원가입 화면** (`sign_up_screen.dart`)
  - [ ] 화면 구조 분석
  - [ ] UI 컴포넌트 구현
  - [ ] 백엔드 API 연동
  - [ ] 유효성 검사
  
- [ ] **비밀번호 찾기 화면** (`password_reset_screen.dart`)
  - [ ] 화면 구조 분석
  - [ ] UI 컴포넌트 구현
  - [ ] 백엔드 API 연동
  - [ ] 이메일 발송 확인

- [ ] **이메일 로그인 완성**
  - [ ] 백엔드 API 확인
  - [ ] `AuthService.loginWithEmail()` 구현
  - [ ] 에러 처리 개선

### 5.2 추가 기능 (선택)

- [ ] **비밀번호 변경 화면**
- [ ] **프로필 화면**
- [ ] **설정 화면**
- [ ] **알림 화면**

---

## 6. 참고 자료

### 6.1 참고 경로
- 참고 모바일 코드: `/Users/woohyeon/ggorockee/reviewmaps/mobile`
- 참고 서버 코드: `/Users/woohyeon/ggorockee/reviewmaps/server`

### 6.2 관련 문서
- `docs/SNS_LOGIN_IMPLEMENTATION_PLAN.md` - SNS 로그인 구현 계획
- `docs/SCREEN_IMPLEMENTATION_STATUS.md` - 화면 구현 상태

---

## 7. 다음 단계

1. **참고 화면 상세 분석**
   - `sign_up_screen.dart` 구조 분석
   - `password_reset_screen.dart` 구조 분석
   - 서버 핸들러 패턴 분석

2. **백엔드 API 확인**
   - 이메일 로그인 엔드포인트
   - 회원가입 엔드포인트
   - 비밀번호 재설정 엔드포인트

3. **구현 계획 수립**
   - 각 화면별 구현 계획 문서 작성
   - API 명세 확인
   - 개발 일정 수립

---

## 최종 업데이트
- 날짜: 2024년
- 상태: 참고 화면 분석 완료, 구현 가이드 작성
- 다음 작업: 참고 화면 상세 분석 및 구현 계획 수립

