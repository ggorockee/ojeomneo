# SNS 로그인 플랫폼 설정 가이드

## 개요
iOS 및 Android 플랫폼에서 SNS 로그인 (Google, Apple, Kakao)이 정상적으로 작동하도록 필요한 설정들을 정리합니다.

---

## iOS 설정

### 1. Firebase 설정
- ✅ `GoogleService-Info.plist` 파일이 `mobile/ios/Runner/` 경로에 위치
- Firebase Authentication과 Google Sign-In은 이 파일만으로 자동 설정됨

### 2. URL Scheme 설정
`mobile/ios/Runner/Info.plist`에 다음 URL Scheme이 필요합니다:

```xml
<!-- URL Schemes for SNS Login -->
<key>CFBundleURLTypes</key>
<array>
    <!-- Kakao Login URL Scheme -->
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakao582b06a868603f324eb551a2e67815f6</string>
        </array>
    </dict>
</array>
```

**참고**: 
- Kakao URL Scheme 형식: `kakao{KAKAO_NATIVE_APP_KEY}`
- 현재 카카오 네이티브 앱 키: `582b06a868603f324eb551a2e67815f6`

### 3. Sign in with Apple 설정
Xcode에서 다음 설정이 필요합니다:

1. Xcode에서 프로젝트 열기: `mobile/ios/Runner.xcworkspace`
2. Signing & Capabilities 탭에서 "Sign in with Apple" 추가
3. Bundle ID 확인: `com.woohalabs.ojeomneo`

**참고**: 이 설정은 Xcode에서 직접 수행해야 하며, 파일 기반 설정만으로는 완료되지 않습니다.

---

## Android 설정

### 1. Firebase 설정
- ✅ `google-services.json` 파일이 `mobile/android/app/` 경로에 위치
- ✅ `build.gradle.kts`에 Google Services 플러그인 추가됨:
  ```kotlin
  plugins {
      id("com.google.gms.google-services")
  }
  ```

### 2. 카카오 로그인 설정
Kakao Flutter SDK는 자동으로 네이티브 앱 키를 인식합니다. 추가 설정은 필요하지 않습니다.

**참고**: 
- 카카오 네이티브 앱 키는 `mobile/.env` 파일의 `KAKAO_NATIVE_APP_KEY`로 설정
- Kakao Flutter SDK가 런타임에 이 값을 읽어서 사용

### 3. AndroidManifest.xml
현재 설정으로 충분하며, 추가 설정은 필요하지 않습니다.

---

## 환경변수 설정

### Mobile (`.env` 파일)
`mobile/.env` 파일에 다음 환경변수가 설정되어 있어야 합니다:

```bash
# Kakao Native App Key
KAKAO_NATIVE_APP_KEY=582b06a868603f324eb551a2e67815f6

# Apple Client ID (iOS)
APPLE_CLIENT_ID=com.woohalabs.ojeomneo

# API Base URL
API_BASE_URL=https://api.woohalabs.com/ojeomneo/v1
```

---

## 체크리스트

### iOS
- [x] `GoogleService-Info.plist` 파일 확인
- [ ] `Info.plist`에 Kakao URL Scheme 추가 (진행 중)
- [ ] Xcode에서 Sign in with Apple Capability 추가
- [ ] 환경변수 파일 확인

### Android
- [x] `google-services.json` 파일 확인
- [x] `build.gradle.kts`에 Google Services 플러그인 확인
- [ ] 환경변수 파일 확인

---

## 테스트 체크리스트

### iOS
- [ ] Google 로그인 테스트
- [ ] Apple 로그인 테스트 (실제 기기 필요)
- [ ] Kakao 로그인 테스트

### Android
- [ ] Google 로그인 테스트
- [ ] Kakao 로그인 테스트

---

## 문제 해결

### iOS
1. **URL Scheme이 작동하지 않는 경우**
   - Info.plist 파일이 올바른 형식인지 확인
   - Xcode에서 프로젝트를 다시 빌드
   - 앱을 완전히 삭제 후 재설치

2. **Sign in with Apple이 작동하지 않는 경우**
   - Xcode에서 Capabilities 설정 확인
   - Apple Developer 계정에서 Sign in with Apple 활성화 확인
   - 실제 기기에서 테스트 (시뮬레이터에서는 제한적)

### Android
1. **Google 로그인이 작동하지 않는 경우**
   - `google-services.json` 파일 위치 확인
   - `build.gradle.kts`에 플러그인 추가 확인
   - SHA-1 인증서 지문이 Firebase Console에 등록되어 있는지 확인

2. **Kakao 로그인이 작동하지 않는 경우**
   - 환경변수 `KAKAO_NATIVE_APP_KEY` 설정 확인
   - 카카오 개발자 콘솔에서 앱 키 확인

---

## 참고 자료
- [Firebase iOS 설정](https://firebase.google.com/docs/ios/setup)
- [Firebase Android 설정](https://firebase.google.com/docs/android/setup)
- [Kakao Flutter SDK 가이드](https://developers.kakao.com/docs/latest/ko/flutter/getting-started)
- [Apple Sign In 가이드](https://developer.apple.com/sign-in-with-apple/)

---

## 최종 업데이트
- 날짜: 2024년
- 상태: iOS/Android 기본 설정 완료
- 다음 작업: 실제 기기 테스트 및 Xcode Capabilities 설정

