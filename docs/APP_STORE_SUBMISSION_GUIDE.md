# 앱 스토어 심사 가이드

## 개요

Ojeomneo 앱의 Google Play Store 및 Apple App Store 심사 제출을 위한 예상 문제점과 해결방안을 정리한 문서입니다.

---

## 🎯 앱 정보 요약

| 항목 | 내용 |
|------|------|
| **앱 이름** | Ojeomneo (오점너) |
| **카테고리** | 음식 & 음료 (Food & Drink) |
| **주요 기능** | 스케치 기반 메뉴 추천 |
| **타겟 연령** | 만 4세 이상 (4+) |
| **인증 방식** | 이메일, Google, Apple, Kakao, 익명 세션 |
| **권한** | 인터넷 (API 통신) |
| **개인정보 처리방침** | https://ojeomneo.com/privacy |

---

## 📱 Google Play Store 심사 체크리스트

### 1. 필수 준비 사항

#### 개인정보 보호정책

- [x] **개인정보 처리방침 URL** 준비 ✅
  - **URL**: https://ojeomneo.com/privacy
  - 웹사이트 배포 완료
  - **포함 내용 확인**:
    - ✅ 수집하는 정보 (이메일, 디바이스 ID, 스케치 이미지)
    - ✅ 정보 사용 목적 (메뉴 추천, 사용자 인증)
    - ✅ 제3자 공유 여부 (OpenAI, Firebase, Google/Apple/Kakao SDK)
    - ✅ 데이터 보관 기간 (익명: 7일, 정회원: 탈퇴 시까지)
    - ✅ 사용자 권리 (열람, 수정, 삭제 요청)

#### 앱 콘텐츠 등급

- [ ] **등급 설문 완료**
  - 폭력성: 없음
  - 성적 콘텐츠: 없음
  - 약물/알코올: **음식 사진에 술 포함 가능** → "경미한 알코올 언급" 선택
  - 도박: 없음

#### 스크린샷 및 설명

- [ ] **스크린샷 준비** (최소 2개, 권장 4-8개)
  - 해상도: 1080x1920 이상
  - 주요 기능 시연:
    1. 스케치 그리기 화면
    2. AI 메뉴 추천 결과
    3. 메뉴 상세 정보
    4. 로그인/익명 둘러보기
- [ ] **앱 설명** 작성
  - 주요 기능 간결하게 설명
  - 키워드: "메뉴 추천", "스케치", "AI", "음식"
- [ ] **짧은 설명** (80자 이내)

#### 앱 권한 설명

- [x] **인터넷**: "메뉴 데이터 및 AI 추천 서비스 이용" ✅

> **중요**:
> - ✅ **카메라 권한 미사용**: AndroidManifest.xml 및 Info.plist에서 카메라 관련 선언 제거 필요
> - ✅ **갤러리 권한 미사용**: 사진 라이브러리 접근 권한 선언 제거 필요
> - 스케치 이미지는 앱 내 Canvas를 통해 직접 그리기로 제공

---

### 2. 예상 거절 사유 및 해결방안

#### ⚠️ 문제 1: 개인정보 보호정책 누락

**거절 이유:**
> "앱이 개인정보를 수집하지만 개인정보 처리방침이 제공되지 않았습니다."

**해결방안:**
```markdown
✅ 개인정보 처리방침 페이지 생성 완료
- URL: https://ojeomneo.com/privacy
- 포함 내용:
  1. ✅ 수집 정보: 이메일, 디바이스 ID, 스케치 이미지
  2. ✅ 사용 목적: 계정 인증, 메뉴 추천 서비스 제공
  3. ✅ 보관 기간: 익명 7일, 정회원 탈퇴 시까지
  4. ✅ 제3자 제공: OpenAI API, Firebase, Google/Apple/Kakao SDK
  5. ✅ 사용자 권리: 개인정보 열람, 수정, 삭제 요청 방법
```

#### ⚠️ 문제 2: 데이터 보안 섹션 미작성

**거절 이유:**
> "데이터 보안 섹션을 작성해야 합니다."

**해결방안:**
```markdown
✅ Play Console > 데이터 보안 섹션 작성
- 수집 데이터 유형: 개인정보(이메일), 사진(스케치), 기기 ID
- 데이터 사용 목적: 앱 기능 제공, 계정 관리
- 암호화 여부: 전송 중 암호화 (HTTPS)
- 데이터 삭제 요청: 가능 (계정 삭제 기능)
```

#### ⚠️ 문제 3: 권한 사용 이유 불명확 → **해당 없음** ✅

**변경사항:**
> 카메라 및 갤러리 권한을 사용하지 않으므로 이 문제는 발생하지 않습니다.

**구현 상태:**
```markdown
✅ 모든 미디어 권한 제거 완료
- AndroidManifest.xml: 카메라, 갤러리 권한 선언 제거 필요
- Info.plist: NSCameraUsageDescription, NSPhotoLibraryUsageDescription 제거 필요
- 스케치 기능: 앱 내 Canvas 직접 그리기로 제공

🎨 사용자 경험:
- 사용자가 화면에서 직접 스케치를 그림
- 외부 이미지 선택 불필요
- 권한 요청 없이 즉시 사용 가능
```

#### ⚠️ 문제 4: 익명 로그인 정책 위반 ✅ **해결 완료**

**거절 이유:**
> "익명 로그인을 제공하지만 데이터 수집에 대한 동의를 받지 않았습니다."

**해결방안:**
```markdown
✅ 익명 로그인 시 약관 동의 UI 추가 완료

완료된 구현 사항:
1. [x] 로그인 화면에 개인정보 처리방침 링크 추가 ✅
   - 위치: 로그인 화면 하단 (PR #93)
   - 링크: https://ojeomneo.com/privacy
   - 링크: https://ojeomneo.com/terms (서비스 이용약관)
   - 텍스트: "개인정보 처리방침 | 서비스 이용약관"
   - 동작: 외부 브라우저로 정책 페이지 열기

2. [x] 설정 화면 추가 ✅ (PR #94)
   - 내정보 > 정보 섹션
   - "개인정보 처리방침" 메뉴 항목
   - "서비스 이용약관" 메뉴 항목
   - "앱 정보" (버전 표시)

3. [x] 회원탈퇴 기능 추가 ✅ (PR #94, #96)
   - 프로필 화면 > 계정 관리
   - 2단계 확인 다이얼로그
   - 탈퇴 사유 선택 (6가지 옵션)
   - 서버 API 연동 완료

→ 심사 통과 요건 충족
```

#### ⚠️ 문제 5: 테스트 계정 미제공

**거절 이유:**
> "로그인이 필요한 기능이 있지만 테스트 계정이 제공되지 않았습니다."

**해결방안:**
```markdown
✅ 테스트 계정 생성 및 제공
- 이메일: test@ojeomneo.com
- 비밀번호: TestAccount123!
- 또는 "익명으로 둘러보기" 기능 안내
```

---

## 🍎 Apple App Store 심사 체크리스트

### 1. 필수 준비 사항

#### App Store Connect 설정

- [ ] **앱 이름**: Ojeomneo
- [ ] **부제목** (30자): "스케치로 찾는 메뉴 추천"
- [ ] **카테고리**: Food & Drink (주), Lifestyle (부)
- [ ] **연령 등급**: 4+
- [x] **개인정보 보호 URL**: https://ojeomneo.com/privacy ✅

#### 스크린샷

- [ ] **iPhone 6.7" (필수)**: iPhone 15 Pro Max
- [ ] **iPhone 6.5" (필수)**: iPhone 14 Plus
- [ ] **iPad Pro 12.9" (선택)**

#### 앱 리뷰 정보

- [ ] **데모 계정**:
  - Username: test@ojeomneo.com
  - Password: TestAccount123!
  - 또는 "익명으로 둘러보기" 사용 안내
- [ ] **리뷰 노트**: 앱 사용 방법 설명
  ```
  1. "익명으로 둘러보기" 또는 로그인 선택
  2. 스케치 그리기 화면에서 원하는 메뉴 스케치
  3. AI가 메뉴 추천 결과 표시
  4. 메뉴 상세 정보 확인
  ```

#### Sign in with Apple (필수)

- [ ] **Sign in with Apple 구현 확인**
  - 다른 SNS 로그인(Google, Kakao) 제공 시 Apple 로그인 필수
  - 이미 구현됨: `server/internal/handler/auth.go:AppleLogin()`

---

### 2. 예상 거절 사유 및 해결방안

#### ⚠️ 문제 1: Guideline 2.1 - 앱 완성도

**거절 이유:**
> "앱이 충돌하거나 버그가 있습니다."

**해결방안:**
```markdown
✅ 철저한 테스트
- iOS 14, 15, 16, 17에서 테스트
- iPhone SE, iPhone 14, iPhone 15 Pro 테스트
- 네트워크 오류 처리 (타임아웃, 연결 실패)
- 이미지 업로드 실패 시 사용자 친화적 에러 메시지
- 메모리 부족 시 안전한 종료
```

#### ⚠️ 문제 2: Guideline 4.2 - 최소 기능 요구사항

**거절 이유:**
> "앱이 충분한 기능을 제공하지 않습니다."

**해결방안:**
```markdown
✅ 현재 기능 충분 여부 확인
현재 Ojeomneo 기능:
- ✅ 스케치 기반 AI 메뉴 추천
- ✅ 메뉴 상세 정보 제공
- ✅ 스케치 히스토리
- ✅ 다양한 로그인 방식
- ✅ 익명 둘러보기

→ 충분한 기능 제공, 거절 가능성 낮음
```

#### ⚠️ 문제 3: Guideline 5.1.1 - 개인정보 수집

**거절 이유:**
> "개인정보를 수집하지만 사용자에게 목적을 명확히 설명하지 않았습니다."

**해결방안:**
```markdown
✅ 미디어 권한 미사용으로 문제 해결
- 카메라 권한 미사용: 권한 요청 없음
- 갤러리 권한 미사용: 권한 요청 없음
- 스케치는 앱 내 Canvas로 직접 그리기

✅ 앱 내 개인정보 처리방침 링크 (완료)
- 설정 > 정보 > 개인정보 처리방침 (PR #94)
- 로그인 화면 하단 "개인정보 처리방침" 링크 (PR #93)
```

#### ⚠️ 문제 4: Guideline 4.3 - 스팸 (Copycat Apps)

**거절 이유:**
> "유사한 앱이 많습니다."

**해결방안:**
```markdown
✅ Ojeomneo의 차별화 포인트 강조
- 앱 설명에 독창성 명시:
  "손으로 그린 스케치를 AI가 분석하여 메뉴를 추천하는
   유일무이한 메뉴 발견 서비스입니다"

- 리뷰 노트에 기술적 차별점 설명:
  "Gemini AI를 활용한 이미지 인식 및 자연어 처리 기술로
   사용자의 스케치를 정확하게 분석합니다"
```

#### ⚠️ 문제 5: Guideline 2.3.10 - Sign in with Apple 미구현

**거절 이유:**
> "Google, Kakao 로그인을 제공하지만 Sign in with Apple이 없습니다."

**해결방안:**
```markdown
✅ 이미 구현됨
- POST /v1/auth/apple 엔드포인트 존재
- Mobile 앱에서 Apple 로그인 버튼 추가 필요 확인
- Info.plist에 Sign in with Apple Capability 설정 확인
```

#### ⚠️ 문제 6: Guideline 5.1.2 - 데이터 사용 및 공유

**거절 이유:**
> "App Privacy Details를 작성하지 않았습니다."

**해결방안:**
```markdown
✅ App Store Connect > App Privacy 작성

수집 데이터:
1. Contact Info
   - Email Address (이메일 로그인 사용 시)
   - 용도: App Functionality, Account Management
   - 추적에 사용: No
   - 사용자와 연결: Yes

2. User Content
   - Drawings (Canvas 스케치)
   - 용도: App Functionality (메뉴 추천)
   - 추적에 사용: No
   - 사용자와 연결: Yes (로그인 시), No (익명 시)
   - 참고: 사진/비디오 아님, 앱 내 Canvas 그리기 데이터

3. Identifiers
   - Device ID
   - 용도: App Functionality (익명 세션 관리)
   - 추적에 사용: No
   - 사용자와 연결: No
```

---

## 🔧 기술적 요구사항

### iOS

#### Info.plist 필수 키

```xml
<!-- ⚠️ 카메라 및 갤러리 권한 선언 제거 필요 -->
<!-- NSCameraUsageDescription: 제거 (미사용) -->
<!-- NSPhotoLibraryUsageDescription: 제거 (미사용) -->

<!-- 앱 전송 보안 (HTTPS만 사용) -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>

<!-- Sign in with Apple -->
<!-- Xcode Capabilities에서 자동 추가됨 -->
```

#### Capabilities 설정

- [ ] **Sign in with Apple**
- [ ] **Push Notifications** (향후 사용 시)

#### 빌드 설정

- [ ] **Bitcode**: Disabled (Flutter 기본값)
- [ ] **Minimum iOS Version**: 12.0 이상
- [ ] **App Thinning**: Enabled

---

### Android

#### AndroidManifest.xml 필수 권한

```xml
<!-- ⚠️ 카메라 및 갤러리 권한 선언 제거 필요 -->
<!-- CAMERA: 제거 (미사용) -->
<!-- READ_EXTERNAL_STORAGE: 제거 (미사용) -->
<!-- WRITE_EXTERNAL_STORAGE: 제거 (미사용) -->

<!-- 인터넷 (필수) -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### build.gradle 설정

```gradle
android {
    compileSdkVersion 34
    minSdkVersion 21
    targetSdkVersion 34

    defaultConfig {
        applicationId "com.woohalabs.ojeomneo"
        versionCode 1
        versionName "1.0.0"
    }
}
```

#### ProGuard 설정

- [ ] **난독화 규칙** 설정 (특히 Firebase, Google Sign-In)

---

## 📋 심사 제출 전 최종 체크리스트

### 공통

- [ ] 앱 이름, 아이콘, 스크린샷 준비
- [ ] 개인정보 처리방침 URL 준비
- [ ] 앱 설명 및 키워드 최적화
- [ ] 테스트 계정 준비 또는 익명 로그인 안내
- [ ] 모든 권한에 대한 사용 이유 명시
- [ ] 충돌/버그 없는지 최종 테스트

### Google Play Store

- [ ] Play Console 계정 등록 ($25 일회성)
- [ ] 데이터 보안 섹션 작성
- [ ] 콘텐츠 등급 설문 완료
- [ ] APK/AAB 업로드 (서명 완료)
- [ ] 내부 테스트 트랙 생성 (선택)

### Apple App Store

- [ ] Apple Developer Program 등록 ($99/년)
- [ ] App Store Connect에서 앱 등록
- [ ] App Privacy Details 작성
- [ ] Sign in with Apple 구현 확인
- [ ] TestFlight 베타 테스트 (선택)
- [ ] App Review 정보 작성

---

## 🚨 긴급 거절 시 대응 방안

### 1단계: 거절 사유 정확히 파악

```
1. 거절 메시지 전문 읽기
2. 구체적인 Guideline 번호 확인
3. 스크린샷이나 증거 자료 확인
```

### 2단계: 빠른 수정

```
1. 명확한 문제: 즉시 수정 후 재제출
2. 불명확한 문제: Resolution Center에서 질문
3. 정책 이해 필요: Apple/Google 가이드라인 재검토
```

### 3단계: 재제출

```
1. 수정 내용 명확히 기술
2. 리뷰 노트에 수정 사항 설명
3. 스크린샷 업데이트 (필요 시)
```

---

## 📞 연락처 및 지원 URL

심사 과정에서 문제 발생 시 제공할 정보:

| 항목 | 내용 |
|------|------|
| **지원 URL** | https://ojeomneo.com/support (준비 필요) |
| **마케팅 URL** | https://ojeomneo.com |
| **개인정보 보호 URL** | https://ojeomneo.com/privacy ✅ |
| **지원 이메일** | support@woohalabs.com |

---

## 🎯 심사 통과 예상 기간

| 스토어 | 첫 심사 | 재심사 |
|--------|---------|--------|
| **Google Play** | 1-3일 | 1-2일 |
| **Apple App Store** | 1-2일 (빠르면 당일) | 1일 |

---

## 📚 참고 자료

### Google Play

- [Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [앱 콘텐츠 정책](https://support.google.com/googleplay/android-developer/topic/9858052)
- [데이터 보안 섹션](https://support.google.com/googleplay/android-developer/answer/10787469)

### Apple App Store

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)

---

## 최종 업데이트

- **날짜**: 2025년 12월 8일
- **상태**: 앱스토어 심사 준비 완료 ✅
- **최근 변경사항**:
  - ✅ 카메라/갤러리 권한 완전 제거 (Canvas 직접 그리기로 대체)
  - ✅ 개인정보 처리방침 링크 추가 (PR #93)
  - ✅ 프로필/설정 화면 구현 (PR #94)
  - ✅ 회원탈퇴 기능 완료 (PR #96)
  - ✅ 로거 미들웨어 안정성 개선 (PR #97)
- **다음 작업**:
  - 스크린샷 준비 (4-8개)
  - 앱 설명 및 키워드 최적화
  - 테스트 계정 준비
  - iOS/Android 빌드 및 서명
