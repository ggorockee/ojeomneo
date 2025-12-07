# 이메일 인증 및 회원가입 구현 계획

## 개요
참고 프로젝트(`/Users/woohyeon/ggorockee/reviewmaps/`)에 있는 endpoint와 화면을 현재 프로젝트에 구현합니다.

---

## 참고 프로젝트 분석

### 백엔드 Endpoint (참고 프로젝트)
- [x] POST `/auth/email/send-code` - 이메일 인증코드 발송
- [x] POST `/auth/email/verify-code` - 이메일 인증코드 확인
- [x] POST `/auth/signup` - 회원가입
- [x] POST `/auth/login` - 이메일 로그인
- [x] POST `/auth/refresh` - 토큰 갱신
- [x] GET `/auth/me` - 현재 사용자 정보 조회
- [x] DELETE `/auth/me` - 회원 탈퇴
- [x] POST `/auth/anonymous` - 익명 세션 생성
- [x] POST `/auth/kakao` - 카카오 로그인 ✅ 이미 구현됨
- [x] POST `/auth/google` - 구글 로그인 ✅ 이미 구현됨
- [x] POST `/auth/apple` - 애플 로그인 ✅ 이미 구현됨

### 모바일 화면 (참고 프로젝트)
- [x] `sign_up_screen.dart` - 회원가입 화면
- [x] `password_reset_screen.dart` - 비밀번호 찾기 화면
- [x] `login_screen.dart` - 로그인 화면 ✅ 이미 구현됨

---

## 구현 계획

### [ ] 1. 백엔드: 필수 모델 및 유틸리티

#### 1.1 EmailVerification 모델
- [ ] `server/internal/model/email_verification.go` 생성
- [ ] 이메일, 인증코드, 만료시간, 인증 여부 필드
- [ ] GORM 마이그레이션

#### 1.2 Password 해싱 유틸리티
- [ ] `server/pkg/auth/password.go` 생성
- [ ] `HashPassword` - bcrypt로 비밀번호 해싱
- [ ] `CheckPassword` - 비밀번호 검증

---

### [ ] 2. 백엔드: 인증 서비스 확장

#### 2.1 이메일 인증
- [ ] `SendEmailCode` - 6자리 인증코드 생성 및 발송
- [ ] `VerifyEmailCode` - 인증코드 검증
- [ ] `EmailVerificationToken` - 인증 완료 토큰 생성

#### 2.2 이메일 로그인
- [ ] `EmailLogin` - 이메일/비밀번호 로그인
- [ ] 비밀번호 검증
- [ ] JWT 토큰 발급

#### 2.3 회원가입
- [ ] `Signup` - 회원가입 처리
- [ ] 이메일 인증 확인
- [ ] 비밀번호 해싱
- [ ] 사용자 생성
- [ ] JWT 토큰 발급

#### 2.4 비밀번호 재설정
- [ ] `PasswordResetRequest` - 재설정 요청 (인증코드 발송)
- [ ] `PasswordResetVerify` - 인증코드 확인
- [ ] `PasswordResetConfirm` - 새 비밀번호 설정

#### 2.5 토큰 관리
- [ ] `RefreshToken` - Refresh Token으로 새 토큰 발급
- [ ] `GetMe` - 현재 사용자 정보 조회
- [ ] `DeleteMe` - 회원 탈퇴 (Soft Delete)

---

### [ ] 3. 백엔드: 인증 핸들러 확장

#### 3.1 이메일 인증 핸들러
- [ ] `POST /ojeomneo/v1/auth/email/send-code`
- [ ] `POST /ojeomneo/v1/auth/email/verify-code`

#### 3.2 로그인/회원가입 핸들러
- [ ] `POST /ojeomneo/v1/auth/login` - 이메일 로그인
- [ ] `POST /ojeomneo/v1/auth/signup` - 회원가입

#### 3.3 비밀번호 재설정 핸들러
- [ ] `POST /ojeomneo/v1/auth/password/reset-request`
- [ ] `POST /ojeomneo/v1/auth/password/reset-verify`
- [ ] `POST /ojeomneo/v1/auth/password/reset-confirm`

#### 3.4 토큰 및 사용자 관리 핸들러
- [ ] `POST /ojeomneo/v1/auth/refresh` - 토큰 갱신
- [ ] `GET /ojeomneo/v1/auth/me` - 사용자 정보 조회
- [ ] `DELETE /ojeomneo/v1/auth/me` - 회원 탈퇴

---

### [ ] 4. 백엔드: 라우터 등록

- [ ] `server/internal/module/server.go`에 새 엔드포인트 등록
- [ ] Swagger 문서 업데이트

---

### [ ] 5. 모바일: AuthService 확장

#### 5.1 이메일 인증
- [ ] `sendEmailCode` - 인증코드 발송
- [ ] `verifyEmailCode` - 인증코드 확인

#### 5.2 이메일 로그인/회원가입
- [ ] `loginWithEmail` - 이메일 로그인
- [ ] `signUp` - 회원가입

#### 5.3 비밀번호 재설정
- [ ] `passwordResetRequest` - 재설정 요청
- [ ] `passwordResetVerify` - 인증코드 확인
- [ ] `passwordResetConfirm` - 비밀번호 변경

#### 5.4 토큰 관리
- [ ] `refreshToken` - 토큰 갱신
- [ ] `getUserInfo` - 사용자 정보 조회
- [ ] `deleteAccount` - 회원 탈퇴

---

### [ ] 6. 모바일: 화면 구현

#### 6.1 회원가입 화면
- [ ] `mobile/lib/screens/auth/sign_up_screen.dart` 생성
- [ ] 이메일 인증코드 발송/확인 UI
- [ ] 이름, 비밀번호 입력 필드
- [ ] 회원가입 처리

#### 6.2 비밀번호 찾기 화면
- [ ] `mobile/lib/screens/auth/password_reset_screen.dart` 생성
- [ ] 이메일 인증코드 발송/확인 UI
- [ ] 새 비밀번호 입력 필드
- [ ] 비밀번호 재설정 처리

#### 6.3 로그인 화면 연결
- [ ] `login_screen.dart`에서 이메일 로그인 구현
- [ ] 회원가입 화면으로 이동
- [ ] 비밀번호 찾기 화면으로 이동

---

### [ ] 7. 모바일: 모델 추가

- [ ] 이메일 인증 관련 모델 (`EmailSendCodeResponse`, `EmailVerifyCodeResponse`)
- [ ] 회원가입 요청/응답 모델 (`SignUpRequest`, `SignUpResponse`)
- [ ] 비밀번호 재설정 모델 (`PasswordResetRequest`, `PasswordResetVerifyResponse`)

---

## 구현 순서

1. **백엔드 기본 구조** (모델, 유틸리티)
   - EmailVerification 모델
   - Password 해싱 유틸리티

2. **백엔드 서비스 레이어**
   - 이메일 인증 서비스
   - 이메일 로그인 서비스
   - 회원가입 서비스
   - 비밀번호 재설정 서비스

3. **백엔드 핸들러 및 라우터**
   - 모든 엔드포인트 핸들러 구현
   - 라우터 등록

4. **모바일 서비스 확장**
   - AuthService에 메서드 추가
   - API 호출 로직 구현

5. **모바일 화면 구현**
   - 회원가입 화면
   - 비밀번호 찾기 화면
   - 로그인 화면 연결

---

## 참고 자료
- 참고 서버 코드: `/Users/woohyeon/ggorockee/reviewmaps/server`
- 참고 모바일 코드: `/Users/woohyeon/ggorockee/reviewmaps/mobile`

---

## 최종 업데이트
- 날짜: 2024년
- 상태: 계획 수립 완료, 구현 시작

