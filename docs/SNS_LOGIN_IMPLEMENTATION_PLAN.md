# SNS 로그인 구현 계획서

## 개요
Google, Apple, Kakao SNS 로그인 기능을 구현합니다. 순서대로 Google → Apple → Kakao 순서로 진행합니다.

---

## [ ] 1. 환경 설정 및 보안 준비

### [x] 1.1 Firebase Admin SDK 키 파일 보안 조치
- [x] Firebase Admin SDK 키 파일을 `server/config/firebase/` 디렉토리로 이동
  - 파일명: `ojeomneo-e7f17-firebase-adminsdk-fbsvc-ce8f5d54fe.json`
  - 목적: Firebase Admin SDK를 통한 사용자 인증 토큰 검증
- [x] `.gitignore`에 Firebase 키 파일 경로 추가
  - `server/config/firebase/*.json`
- [ ] 서버 코드에서 키 값을 환경변수로 읽도록 수정 <-- 키파일 경로가 아니라 키 값 자체를 환경변수로 k8s에서 시크릿으로 주입할 예정 따라서 키값만 잇으면됨 그값으로 내가 k8s의 시크릿으로 injection할 예정

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
- [x] `KAKAO_NATIVE_APP_KEY`: 카카오 네이티브 앱 키 (`582b06a868603f324eb551a2e67815f6`)
- [x] `API_BASE_URL`: 백엔드 API 베이스 URL - `https://api.woohalabs.com/ojeomneo/v1`
- 참고: Google 로그인은 Firebase Authentication 사용 (추가 환경변수 불필요) 

---

## [ ] 2. 백엔드 구현 (Server)

### [ ] 2.1 SNS 토큰 검증 패키지 구현 (`server/pkg/sns/`)
참고: `/Users/woohyeon/ggorockee/reviewmaps/server/pkg/sns/`

- [ ] `firebase.go`: Firebase Admin SDK 초기화 및 Google ID Token 검증
  - Firebase Admin SDK 초기화 (환경변수에서 JSON 키 값 읽기)
  - 함수: `VerifyFirebaseIDToken(ctx context.Context, idToken string) (*FirebaseUserInfo, error)`
  - Firebase ID Token 검증 및 사용자 정보 추출 (email, name, photo_url, uid)
  
- [ ] `apple.go`: Apple Identity Token 검증 및 사용자 정보 추출
  - API: `https://appleid.apple.com/auth/keys` (JWKS)
  - 함수: `VerifyAppleToken(ctx context.Context, identityToken string, clientID string) (*AppleUserInfo, error)`
  
- [ ] `kakao.go`: Kakao Access Token 검증 및 사용자 정보 추출
  - API: `https://kapi.kakao.com/v2/user/me`
  - 함수: `VerifyKakaoToken(ctx context.Context, accessToken string) (*KakaoUserInfo, error)`

### [ ] 2.2 인증 서비스 확장 (`server/internal/service/auth.go`)
참고: `/Users/woohyeon/ggorockee/reviewmaps/server/internal/services/auth.go`

- [ ] `AuthService` 구조체에 SNS 검증 패키지 및 Firebase Admin SDK 추가
- [ ] `GoogleLogin(idToken string) (*AuthResponse, error)` 구현
  - Firebase ID Token 검증 (Firebase Admin SDK 사용)
  - 사용자 정보 추출 (email, name, photo_url, uid)
  - DB에 사용자 생성/조회 (login_method='google', social_id=uid)
  - JWT 토큰 발급
- [ ] `AppleLogin(identityToken string) (*AuthResponse, error)` 구현
  - Apple Identity Token 검증
  - 사용자 정보 추출 (email, sub)
  - DB에 사용자 생성/조회 (login_method='apple', social_id=sub)
  - JWT 토큰 발급
- [ ] `KakaoLogin(accessToken string) (*AuthResponse, error)` 구현
  - Kakao 토큰 검증
  - 사용자 정보 추출 (email, nickname, profile_image)
  - DB에 사용자 생성/조회 (login_method='kakao', social_id=kakao_id)
  - JWT 토큰 발급

### [ ] 2.3 인증 핸들러 구현 (`server/internal/handler/auth.go`)
- [ ] `AuthHandler` 구조체 생성
- [ ] 라우터 설정 함수: `SetupAuthRoutes(router fiber.Router, db *database.DB, cfg *config.Config)`
- [ ] `POST /ojeomneo/v1/auth/google`: Google 로그인 엔드포인트
  - Request: `{ "id_token": "..." }` (Firebase ID Token)
  - Response: `{ "access_token": "...", "refresh_token": "...", "user": {...} }`
- [ ] `POST /ojeomneo/v1/auth/apple`: Apple 로그인 엔드포인트
  - Request: `{ "access_token": "..." }` (identity_token)
  - Response: `{ "access_token": "...", "refresh_token": "...", "user": {...} }`
- [ ] `POST /ojeomneo/v1/auth/kakao`: Kakao 로그인 엔드포인트
  - Request: `{ "access_token": "..." }`
  - Response: `{ "access_token": "...", "refresh_token": "...", "user": {...} }`

### [ ] 2.4 메인 라우터에 인증 라우트 추가 (`server/cmd/api/main.go`)
- [ ] `SetupAuthRoutes` 호출하여 인증 엔드포인트 등록

### [ ] 2.5 JWT 토큰 관리 (`server/pkg/auth/jwt.go`)
- [ ] Access Token 발급 함수 확인/구현
- [ ] Refresh Token 발급 함수 확인/구현
- [ ] 토큰 검증 함수 확인/구현

---

## [ ] 3. 모바일 구현 (Flutter)

### [ ] 3.1 의존성 추가 (`mobile/pubspec.yaml`)
- [ ] `firebase_core: ^3.x.x`: Firebase Core (이미 추가됨)
- [ ] `firebase_auth: ^5.x.x`: Firebase Authentication (Google 로그인 포함)
- [ ] `google_sign_in: ^7.2.0`: Google 로그인 (Firebase Auth와 함께 사용)
- [ ] `sign_in_with_apple: ^7.0.1`: Apple 로그인 (iOS 전용)
- [ ] `kakao_flutter_sdk: ^1.10.0`: Kakao 로그인
- [ ] `flutter_dotenv: ^6.0.0`: 환경변수 관리 (이미 추가됨)
- [ ] `flutter_secure_storage: ^9.2.4`: 안전한 토큰 저장

### [ ] 3.2 API 서비스 확장 (`mobile/lib/services/api_service.dart`)
- [ ] `postSNSLogin(String provider, String token)`: SNS 로그인 API 호출
  - provider: 'google', 'apple', 'kakao'
  - token: Google은 `id_token` (Firebase ID Token), Apple/Kakao는 `access_token`
  - endpoint: `/ojeomneo/v1/auth/{provider}`
  - Request: `{ "id_token": "..." }` (Google) 또는 `{ "access_token": "..." }` (Apple/Kakao)
  - response: `{ "access_token", "refresh_token", "user" }`

### [ ] 3.3 인증 서비스 구현 (`mobile/lib/services/auth_service.dart`)
- [ ] `AuthService` 클래스 생성
- [ ] `loginWithGoogle()`: Google 로그인 플로우 (Firebase Authentication 사용)
  1. `google_sign_in`으로 Google 로그인 수행
  2. Google 계정 인증 후 `GoogleSignInAuthentication` 획득
  3. Firebase Auth로 `GoogleAuthProvider`를 사용하여 로그인
  4. Firebase ID Token 획득 (`User.getIdToken()`)
  5. 백엔드 API 호출하여 JWT 토큰 획득 (`id_token` 전송)
  6. 토큰 저장 (flutter_secure_storage 사용)
- [ ] `loginWithApple()`: Apple 로그인 플로우 (iOS 전용)
  1. `sign_in_with_apple`으로 Apple 로그인 수행
  2. Identity Token 획득
  3. 백엔드 API 호출하여 JWT 토큰 획득
  4. 토큰 저장
- [ ] `loginWithKakao()`: Kakao 로그인 플로우
  1. `kakao_flutter_sdk`로 Kakao 로그인 수행
  2. Access Token 획득
  3. 백엔드 API 호출하여 JWT 토큰 획득
  4. 토큰 저장

### [ ] 3.4 로그인 화면 통합 (`mobile/lib/screens/login_screen.dart`)
- [ ] `_handleGoogleLogin()`: Google 로그인 버튼 핸들러 구현
  - `AuthService.loginWithGoogle()` 호출
  - 성공 시 `/home`으로 이동
  - 실패 시 에러 메시지 표시
- [ ] `_handleAppleLogin()`: Apple 로그인 버튼 핸들러 구현
  - `AuthService.loginWithApple()` 호출
  - 성공 시 `/home`으로 이동
  - 실패 시 에러 메시지 표시
- [ ] `_handleKakaoLogin()`: Kakao 로그인 버튼 핸들러 구현
  - `AuthService.loginWithKakao()` 호출
  - 성공 시 `/home`으로 이동
  - 실패 시 에러 메시지 표시

### [ ] 3.5 iOS 설정 (`mobile/ios/`)
- [ ] `Info.plist`에 URL Scheme 추가
  - Firebase/Google: `{REVERSED_CLIENT_ID}` (GoogleService-Info.plist에서 확인)
  - Kakao: `kakao{KAKAO_NATIVE_APP_KEY}`
- [ ] Capabilities에 Sign in with Apple 추가
- [ ] `GoogleService-Info.plist` 추가 (Firebase Console에서 다운로드) - 필수

### [ ] 3.6 Android 설정 (`mobile/android/`)
- [ ] `android/app/build.gradle`에 Google Services 플러그인 추가 - 필수 (Firebase Auth 사용)
- [ ] `google-services.json` 추가 (Firebase Console에서 다운로드) - 필수
- [ ] `AndroidManifest.xml`에 카카오 네이티브 앱 키 설정

---

## [ ] 4. 테스트

### [ ] 4.1 백엔드 API 테스트
- [ ] Google 로그인 API 테스트 (Postman/curl) - Firebase ID Token으로 테스트
- [ ] Apple 로그인 API 테스트 (Postman/curl)
- [ ] Kakao 로그인 API 테스트 (Postman/curl)
- [ ] 에러 케이스 테스트 (잘못된 토큰, 만료된 토큰 등)

### [ ] 4.2 모바일 앱 테스트
- [ ] Google 로그인 테스트 (iOS/Android)
- [ ] Apple 로그인 테스트 (iOS 전용)
- [ ] Kakao 로그인 테스트 (iOS/Android)
- [ ] 로그인 후 토큰 저장 확인
- [ ] 로그인 후 사용자 정보 표시 확인

### [ ] 4.3 통합 테스트
- [ ] 백엔드-모바일 연동 테스트
- [ ] 여러 기기에서 동일 계정 로그인 테스트
- [ ] 로그아웃 후 재로그인 테스트

---

## [ ] 5. 문서화

### [ ] 5.1 API 문서 업데이트
- [ ] Swagger 문서에 SNS 로그인 엔드포인트 추가
- [ ] Request/Response 스키마 정의

### [ ] 5.2 README 업데이트
- [ ] 환경변수 설정 가이드 추가
- [ ] Firebase 설정 가이드 추가
- [ ] 각 SNS 플랫폼별 설정 가이드 추가

---

## 진행 순서
1. Google 로그인 완료 → 2. Apple 로그인 완료 → 3. Kakao 로그인 완료

각 단계마다 백엔드 → 모바일 순서로 구현하고 테스트합니다.

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

