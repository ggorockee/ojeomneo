# SNS 로그인 구현 계획서

## 개요
Google, Apple, Kakao SNS 로그인 기능을 구현합니다. 순서대로 Google → Apple → Kakao 순서로 진행합니다.

---

## [x] 1. 환경 설정 및 보안 준비

### [x] 1.1 Firebase Admin SDK 키 파일 보안 조치
- [x] Firebase Admin SDK 키 파일을 `server/config/firebase/` 디렉토리로 이동
  - 파일명: `ojeomneo-e7f17-firebase-adminsdk-fbsvc-ce8f5d54fe.json`
  - 목적: Firebase Admin SDK를 통한 사용자 인증 토큰 검증
- [x] `.gitignore`에 Firebase 키 파일 경로 추가
  - `server/config/firebase/*.json`
- [x] 서버 코드에서 키 값을 환경변수로 읽도록 수정 <-- 키파일 경로가 아니라 키 값 자체를 환경변수로 k8s에서 시크릿으로 주입할 예정 따라서 키값만 잇으면됨 그값으로 내가 k8s의 시크릿으로 injection할 예정

### [x] 1.2 환경변수 설정
#### Server (`server/.env.example` 생성)
- [x] `FIREBASE_ADMIN_SDK_KEY`: Firebase Admin SDK 키 JSON 문자열 (k8s 시크릿으로 주입) - Google 로그인 토큰 검증용
- [x] `APPLE_CLIENT_ID`: Apple OAuth 클라이언트 ID (iOS 앱용) - Bundle ID: `com.woohalabs.ojeomneo`
- [x] `APPLE_TEAM_ID`: Apple 개발팀 ID
- [x] `APPLE_KEY_ID`: Apple Key ID
- [x] `KAKAO_REST_API_KEY`: 카카오 REST API 키 (`4d3810fbbd527782757b7c2a0f737a7c`)
- [x] `server/internal/config/config.go`에 환경변수 필드 추가 완료

#### Mobile (`mobile/.env.example` 생성)
- [x] `APPLE_CLIENT_ID`: Apple OAuth 클라이언트 ID (iOS 전용) - Bundle ID: `com.woohalabs.ojeomneo`
- [x] `KAKAO_NATIVE_APP_KEY`: 카카오 네이티브 앱 키
- [x] `API_BASE_URL`: 백엔드 API 베이스 URL - `https://api.woohalabs.com/ojeomneo/v1`
- 참고: Google 로그인은 Firebase Authentication 사용 (추가 환경변수 불필요) 

---

## [x] 2. 백엔드 구현 (Server)

### [x] 2.1 SNS 토큰 검증 패키지 구현 (`server/pkg/sns/`)
참고: `/Users/woohyeon/ggorockee/reviewmaps/server/pkg/sns/`

- [x] `firebase.go`: Firebase Admin SDK 초기화 및 Google ID Token 검증
  - Firebase Admin SDK 초기화 (환경변수에서 JSON 키 값 읽기)
  - 함수: `VerifyFirebaseIDToken(ctx context.Context, idToken string) (*FirebaseUserInfo, error)`
  - Firebase ID Token 검증 및 사용자 정보 추출 (email, name, photo_url, uid)
  - Goroutine을 활용한 비동기 토큰 검증 및 사용자 정보 조회
  
- [x] `apple.go`: Apple Identity Token 검증 및 사용자 정보 추출
  - API: `https://appleid.apple.com/auth/keys` (JWKS)
  - 함수: `VerifyAppleToken(ctx context.Context, identityToken string, clientID string) (*AppleUserInfo, error)`
  - Goroutine을 활용한 비동기 토큰 파싱 및 검증
  
- [x] `kakao.go`: Kakao Access Token 검증 및 사용자 정보 추출
  - API: `https://kapi.kakao.com/v2/user/me`
  - 함수: `VerifyKakaoToken(ctx context.Context, accessToken string) (*KakaoUserInfo, error)`
  - Goroutine을 활용한 비동기 API 호출

### [x] 2.2 인증 서비스 확장 (`server/internal/service/auth.go`)
참고: `/Users/woohyeon/ggorockee/reviewmaps/server/internal/services/auth.go`

- [x] `AuthService` 구조체에 SNS 검증 패키지 및 Firebase Admin SDK 추가
- [x] `GoogleLogin(idToken string) (*AuthResponse, error)` 구현
  - Firebase ID Token 검증 (Firebase Admin SDK 사용)
  - 사용자 정보 추출 (email, name, photo_url, uid)
  - DB에 사용자 생성/조회 (login_method='google', social_id=uid)
  - JWT 토큰 발급 (goroutine으로 병렬 처리)
- [x] `AppleLogin(identityToken string) (*AuthResponse, error)` 구현
  - Apple Identity Token 검증
  - 사용자 정보 추출 (email, sub)
  - DB에 사용자 생성/조회 (login_method='apple', social_id=sub)
  - JWT 토큰 발급 (goroutine으로 병렬 처리)
- [x] `KakaoLogin(accessToken string) (*AuthResponse, error)` 구현
  - Kakao 토큰 검증
  - 사용자 정보 추출 (email, nickname, profile_image)
  - DB에 사용자 생성/조회 (login_method='kakao', social_id=kakao_id)
  - JWT 토큰 발급 (goroutine으로 병렬 처리)
- [x] `handleSNSLogin`: 공통 SNS 로그인 로직 구현 (goroutine 활용, Zap 로깅 통합)

### [x] 2.3 인증 핸들러 구현 (`server/internal/handler/auth.go`)
- [x] `AuthHandler` 구조체 생성 (Zap 로거 통합)
- [x] 라우터 설정: Uber-fx 모듈을 통한 자동 등록 (`server/internal/module/server.go`)
- [x] `POST /ojeomneo/v1/auth/google`: Google 로그인 엔드포인트
  - Request: `{ "id_token": "..." }` (Firebase ID Token)
  - Response: `{ "access_token": "...", "refresh_token": "...", "user": {...} }`
  - Goroutine을 활용한 비동기 로깅
- [x] `POST /ojeomneo/v1/auth/apple`: Apple 로그인 엔드포인트
  - Request: `{ "identity_token": "..." }` (Identity Token)
  - Response: `{ "access_token": "...", "refresh_token": "...", "user": {...} }`
  - Goroutine을 활용한 비동기 로깅
- [x] `POST /ojeomneo/v1/auth/kakao`: Kakao 로그인 엔드포인트
  - Request: `{ "access_token": "..." }`
  - Response: `{ "access_token": "...", "refresh_token": "...", "user": {...} }`
  - Goroutine을 활용한 비동기 로깅

### [x] 2.4 메인 라우터에 인증 라우트 추가 (`server/internal/module/server.go`)
- [x] Uber-fx 모듈을 통한 인증 엔드포인트 자동 등록
- [x] `/ojeomneo/v1/auth/google`, `/ojeomneo/v1/auth/apple`, `/ojeomneo/v1/auth/kakao` 라우트 설정

### [x] 2.5 JWT 토큰 관리 (`server/pkg/auth/jwt.go`)
- [x] Access Token 발급 함수 구현 (`GenerateAccessToken`)
- [x] Refresh Token 발급 함수 구현 (`GenerateRefreshToken`)
- [x] 토큰 검증 함수 구현 (`ValidateAccessToken`, `ValidateRefreshToken`)
- [x] 토큰 쌍 생성 함수 구현 (`GenerateTokenPair` - goroutine으로 병렬 처리)

---

## [x] 3. 모바일 구현 (Flutter)

### [x] 3.1 의존성 추가 (`mobile/pubspec.yaml`)
- [x] `firebase_core: ^3.8.1`: Firebase Core (이미 추가됨)
- [x] `firebase_auth: ^5.3.1`: Firebase Authentication (Google 로그인 포함)
- [x] `google_sign_in: ^6.2.1`: Google 로그인 (Firebase Auth와 함께 사용, 7.2.0에서 6.2.1로 다운그레이드)
- [x] `sign_in_with_apple: ^7.0.1`: Apple 로그인 (iOS 전용)
- [x] `kakao_flutter_sdk: ^1.10.0`: Kakao 로그인
- [x] `kakao_flutter_sdk_common: ^1.10.0`: Kakao SDK Common (명시적 추가)
- [x] `flutter_dotenv: ^5.2.1`: 환경변수 관리 (이미 추가됨)
- [x] `flutter_secure_storage: ^9.2.4`: 안전한 토큰 저장

### [x] 3.2 API 서비스 확장 (`mobile/lib/services/api_service.dart`)
- [x] `postSNSLogin(String provider, String token)`: SNS 로그인 API 호출
  - provider: 'google', 'apple', 'kakao'
  - token: Google은 `id_token` (Firebase ID Token), Apple/Kakao는 `identity_token`/`access_token`
  - endpoint: `/ojeomneo/v1/auth/{provider}`
  - Request: `{ "id_token": "..." }` (Google) 또는 `{ "identity_token": "..." }` (Apple) 또는 `{ "access_token": "..." }` (Kakao)
  - response: `{ "access_token", "refresh_token", "user" }`

### [x] 3.3 인증 서비스 구현 (`mobile/lib/services/auth_service.dart`)
- [x] `AuthService` 클래스 생성 (싱글톤 패턴)
- [x] `loginWithGoogle()`: Google 로그인 플로우 (Firebase Authentication 사용)
  1. `google_sign_in`으로 Google 로그인 수행
  2. Google 계정 인증 후 `GoogleSignInAuthentication` 획득
  3. Firebase Auth로 `GoogleAuthProvider`를 사용하여 로그인
  4. Firebase ID Token 획득 (`User.getIdToken()`)
  5. 백엔드 API 호출하여 JWT 토큰 획득 (`id_token` 전송)
  6. 토큰 저장 (flutter_secure_storage 사용)
- [x] `loginWithApple()`: Apple 로그인 플로우 (iOS 전용)
  1. `sign_in_with_apple`으로 Apple 로그인 수행
  2. Identity Token 획득
  3. 백엔드 API 호출하여 JWT 토큰 획득
  4. 토큰 저장
- [x] `loginWithKakao()`: Kakao 로그인 플로우
  1. `kakao_flutter_sdk`로 Kakao 로그인 수행 (KakaoTalk 앱 우선, 실패 시 웹 로그인)
  2. Access Token 획득
  3. 백엔드 API 호출하여 JWT 토큰 획득
  4. 토큰 저장
- [x] 추가 기능: 토큰 조회, 로그인 상태 확인, 로그아웃

### [x] 3.4 로그인 화면 통합 (`mobile/lib/screens/login_screen.dart`)
- [x] `_handleGoogleLogin()`: Google 로그인 버튼 핸들러 구현
  - `AuthService.loginWithGoogle()` 호출
  - 성공 시 `/home`으로 이동
  - 실패 시 에러 메시지 표시
- [x] `_handleAppleLogin()`: Apple 로그인 버튼 핸들러 구현
  - iOS 전용 체크 포함
  - `AuthService.loginWithApple()` 호출
  - 성공 시 `/home`으로 이동
  - 실패 시 에러 메시지 표시
- [x] `_handleKakaoLogin()`: Kakao 로그인 버튼 핸들러 구현
  - `AuthService.loginWithKakao()` 호출
  - 성공 시 `/home`으로 이동
  - 실패 시 에러 메시지 표시

### [x] 3.5 iOS 설정 (`mobile/ios/`)
- [x] `GoogleService-Info.plist` 추가 (Firebase Console에서 다운로드) - 확인됨
- [x] `Info.plist`에 Kakao URL Scheme 추가 완료 - 검증 완료
  - Kakao: `kakao582b06a868603f324eb551a2e67815f6`
- [x] Capabilities에 Sign in with Apple 추가 - Info.plist 설정 완료
- 참고: 자세한 설정 가이드는 `docs/SNS_LOGIN_PLATFORM_SETUP.md` 참조

### [x] 3.6 Android 설정 (`mobile/android/`)
- [x] `google-services.json` 추가 (Firebase Console에서 다운로드) - 확인됨
- [x] `android/app/build.gradle.kts`에 Google Services 플러그인 추가 확인됨
- [x] AndroidManifest.xml 설정 확인 완료 (Kakao SDK는 자동으로 환경변수에서 키 읽음)
- 참고: 자세한 설정 가이드는 `docs/SNS_LOGIN_PLATFORM_SETUP.md` 참조

---

## [ ] 4. 테스트

### [ ] 4.1 백엔드 API 테스트
- [ ] Google 로그인 API 테스트 (Postman/curl) - Firebase ID Token으로 테스트
- [ ] Apple 로그인 API 테스트 (Postman/curl)
- [ ] Kakao 로그인 API 테스트 (Postman/curl)
- [ ] 에러 케이스 테스트 (잘못된 토큰, 만료된 토큰 등)

**참고**: 테스트를 위해서는 환경변수 설정이 먼저 필요합니다.

### [ ] 4.2 모바일 앱 테스트
- [ ] Google 로그인 테스트 (iOS/Android)
- [ ] Apple 로그인 테스트 (iOS 전용)
- [ ] Kakao 로그인 테스트 (iOS/Android)
- [ ] 로그인 후 토큰 저장 확인
- [ ] 로그인 후 사용자 정보 표시 확인

**참고**: 실제 기기 테스트가 권장됩니다 (특히 Apple 로그인).

### [ ] 4.3 통합 테스트
- [ ] 백엔드-모바일 연동 테스트
- [ ] 여러 기기에서 동일 계정 로그인 테스트
- [ ] 로그아웃 후 재로그인 테스트

---

## [x] 5. 문서화

### [x] 5.1 API 문서
- [x] 환경변수 문서화 완료 (`docs/ENVIRONMENT_VARIABLES.md`)
- [x] SNS 로그인 구현 계획서 작성 완료 (본 문서)
- [x] SNS 로그인 플랫폼 설정 가이드 작성 완료 (`docs/SNS_LOGIN_PLATFORM_SETUP.md`)
- [ ] Swagger 문서에 SNS 로그인 엔드포인트 추가 (추후 작업)
- [ ] Request/Response 스키마 정의 (추후 작업)

### [x] 5.2 설정 가이드
- [x] 환경변수 설정 가이드 완료 (`docs/ENVIRONMENT_VARIABLES.md`)
- [x] Firebase 설정 가이드 완료 (`docs/SNS_LOGIN_PLATFORM_SETUP.md`)
- [x] iOS/Android 플랫폼별 설정 가이드 완료 (`docs/SNS_LOGIN_PLATFORM_SETUP.md`)

---

## 진행 순서
1. Google 로그인 완료 → 2. Apple 로그인 완료 → 3. Kakao 로그인 완료

각 단계마다 백엔드 → 모바일 순서로 구현하고 테스트합니다.

---

## 현재 진행 상황 요약

### ✅ 완료된 작업 (구현 완료)
- ✅ **백엔드 SNS 로그인 API 구현 완료** (Google, Apple, Kakao)
  - `pkg/sns/firebase.go` - Firebase ID Token 검증
  - `pkg/sns/apple.go` - Apple Identity Token 검증
  - `pkg/sns/kakao.go` - Kakao Access Token 검증
  - `internal/service/auth.go` - SNS 로그인 서비스 로직
  - `internal/handler/auth.go` - SNS 로그인 엔드포인트
- ✅ **Flutter 인증 서비스 구현 완료** (모든 SNS 로그인 플로우)
  - `lib/services/auth_service.dart` - Google, Apple, Kakao 로그인 플로우
  - `lib/screens/login_screen.dart` - SNS 로그인 UI 통합
- ✅ **플랫폼 설정 완료**
  - iOS: Firebase, Kakao URL Scheme, Apple Sign In 설정
  - Android: Firebase, Google Services 플러그인 설정
- ✅ **의존성 설정 완료**
  - Server: Firebase Admin SDK, JWT, SNS 검증 패키지
  - Mobile: Firebase Auth, Google Sign-In, Apple Sign-In, Kakao SDK
- ✅ **문서화 완료**
  - 환경변수 문서 (`docs/ENVIRONMENT_VARIABLES.md`)
  - SNS 로그인 구현 계획서 (본 문서)
  - SNS 로그인 플랫폼 설정 가이드 (`docs/SNS_LOGIN_PLATFORM_SETUP.md`)

### ⚠️ 다음 단계 (환경변수 설정 및 테스트)
1. **환경변수 설정**
   - Server `.env` 파일에 SNS 인증 키 값 설정
   - Mobile `.env` 파일에 API URL 및 SNS 앱 키 설정
   - Kubernetes Secret 준비 (프로덕션 배포용)

2. **테스트 진행**
   - 백엔드 API 테스트 (Postman/curl)
   - 모바일 앱 통합 테스트 (실제 기기 권장)
   - 전체 플로우 검증 (로그인 → 토큰 발급 → 사용자 정보 조회)

3. **추가 문서화 (선택)**
   - Swagger API 문서 업데이트
   - Request/Response 스키마 정의

---

## 참고 자료
- 참고 서버 코드: `/Users/woohyeon/ggorockee/reviewmaps/server`
- 참고 모바일 코드: `/Users/woohyeon/ggorockee/reviewmaps/mobile`
- Firebase Admin SDK: https://firebase.google.com/docs/admin/setup
- Firebase Authentication: https://firebase.google.com/docs/auth
- Firebase Auth Flutter: https://firebase.google.com/docs/auth/flutter/start
- Google Sign-In with Firebase: https://firebase.google.com/docs/auth/flutter/federated-auth#google
- Apple Sign-In: https://pub.dev/packages/sign_in_with_apple
- Kakao SDK: https://developers.kakao.com/docs

---

## 최종 업데이트
- 날짜: 2025년 1월
- 상태: **Server 및 Mobile SNS 인증 구현 100% 완료**
- 진행률: **구현 완료 ✅ / 환경변수 설정 대기 ⏳ / 테스트 대기 ⏳**
- 다음 작업: 환경변수 설정 후 통합 테스트

