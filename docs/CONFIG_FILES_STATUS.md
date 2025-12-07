# 설정 파일 위치 및 상태 확인

## 개요
프로젝트에서 사용하는 모든 설정 파일들의 위치와 상태를 정리합니다.

---

## Firebase 설정 파일

### 1. Firebase Admin SDK (서버용)
- **파일명**: `ojeomneo-e7f17-firebase-adminsdk-fbsvc-ce8f5d54fe.json`
- **위치**: `server/config/firebase/`
- **용도**: 백엔드에서 Google ID Token 검증
- **상태**: ✅ 올바른 위치에 배치됨
- **보안**: `.gitignore`에 추가되어 Git에 커밋되지 않음
- **사용 방법**: 
  - 개발 환경: 파일에서 직접 읽기 (현재는 사용하지 않음)
  - 프로덕션: 환경변수 `FIREBASE_ADMIN_SDK_KEY`로 JSON 문자열 전체 전달

### 2. Android Firebase 설정
- **파일명**: `google-services.json`
- **위치**: `mobile/android/app/`
- **용도**: Android 앱에서 Firebase Authentication 및 Google Sign-In 사용
- **상태**: ✅ 올바른 위치에 배치됨
- **보안**: `.gitignore`에 추가되어 Git에 커밋되지 않음
- **프로젝트 정보**:
  - Project ID: `ojeomneo-e7f17`
  - Package Name: `com.woohalabs.ojeomneo`
  - App ID: `1:9000418106:android:332456f41bb8fd37782e03`

### 3. iOS Firebase 설정
- **파일명**: `GoogleService-Info.plist`
- **위치**: `mobile/ios/Runner/`
- **용도**: iOS 앱에서 Firebase Authentication 및 Google Sign-In 사용
- **상태**: ✅ 올바른 위치에 배치됨
- **보안**: `.gitignore`에 추가되어 Git에 커밋되지 않음
- **프로젝트 정보**:
  - Bundle ID: `com.woohalabs.ojeomneo`
  - Project ID: `ojeomneo-e7f17`
  - App ID: `1:9000418106:ios:9cbea4ee0bc4f70e782e03`

---

## 설정 파일 체크리스트

### ✅ 완료된 항목
- [x] Firebase Admin SDK 키 파일 위치 확인
- [x] Android Firebase 설정 파일 위치 확인
- [x] iOS Firebase 설정 파일 위치 확인
- [x] `.gitignore`에 민감한 파일 추가 완료

### 📝 참고 사항

1. **Firebase Admin SDK 키**
   - 현재는 파일로 저장되어 있지만, 실제 운영 환경에서는 환경변수로 주입됩니다
   - 파일 내용을 환경변수 `FIREBASE_ADMIN_SDK_KEY`에 JSON 문자열로 설정해야 합니다

2. **모바일 Firebase 설정 파일**
   - 이 파일들은 빌드 시 자동으로 포함됩니다
   - Firebase Console에서 다운로드한 파일을 그대로 사용합니다
   - 업데이트가 필요한 경우 Firebase Console에서 재다운로드하여 교체합니다

3. **보안**
   - 모든 Firebase 설정 파일은 `.gitignore`에 추가되어 Git에 커밋되지 않습니다
   - 파일이 실수로 커밋된 경우 즉시 Git에서 제거해야 합니다

---

## 파일 구조

```
ojeomneo/
├── server/
│   └── config/
│       └── firebase/
│           └── ojeomneo-e7f17-firebase-adminsdk-fbsvc-ce8f5d54fe.json
│
└── mobile/
    ├── android/
    │   └── app/
    │       └── google-services.json
    │
    └── ios/
        └── Runner/
            └── GoogleService-Info.plist
```

---

## 문제 해결

### 파일이 없는 경우
1. Firebase Console (https://console.firebase.google.com) 접속
2. 프로젝트 `ojeomneo-e7f17` 선택
3. 프로젝트 설정 > 일반 탭에서 설정 파일 다운로드
   - iOS: `GoogleService-Info.plist`
   - Android: `google-services.json`

### 파일 위치가 잘못된 경우
- **Android**: `mobile/android/app/google-services.json`로 이동
- **iOS**: `mobile/ios/Runner/GoogleService-Info.plist`로 이동

---

## 최종 업데이트
- 날짜: 2024년
- 상태: 모든 설정 파일 위치 확인 완료

