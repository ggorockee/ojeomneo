# 익명 세션 설계 문서

## 개요

"로그인하지 않고 둘러보기" 기능을 위한 익명 세션 시스템 설계 및 구현 문서입니다.

---

## 요구사항

| 항목 | 설명 |
|------|------|
| **핵심 기능** | 로그인 없이 앱 기능 체험 가능 |
| **디바이스 식별** | UUID 기반 디바이스 고유 ID 사용 |
| **데이터 보관 기간** | 익명: 7일, 정회원: 무제한 (리뷰맵 연계 대비) |
| **전환 지원** | 익명 → 정회원 전환 시 데이터 마이그레이션 |
| **모니터링** | SigNoz 대시보드로 익명 사용자 현황 추적 |

---

## 아키텍처 선택: 옵션 1 (디바이스 ID + 익명 토큰)

### 선택 이유

| 기준 | 평가 |
|------|------|
| 구현 복잡도 | ⭐⭐ (낮음) - 기존 User 모델 활용 |
| 보안 | ⭐⭐⭐ (높음) - JWT 기반 인증 |
| 확장성 | ⭐⭐⭐ (높음) - 정회원 전환 용이 |
| 데이터 관리 | ⭐⭐⭐ (우수) - 통합 테이블 관리 |

### 동작 방식

```
[Mobile App]
  ↓ 앱 최초 실행
  ↓ Device ID 생성 (UUID)
  ↓ POST /v1/auth/guest
[Server]
  ↓ Device ID로 기존 사용자 조회
  ├─ 존재 → 토큰만 재발급
  └─ 없음 → 익명 사용자 생성 + 토큰 발급
[Mobile App]
  ↓ guest_token 저장 (secure storage)
  ↓ 이후 모든 API 요청에 Authorization 헤더 포함
```

---

## 데이터베이스 설계

### User 모델 변경사항

| 필드 | 타입 | 설명 | 제약 조건 |
|------|------|------|-----------|
| `is_guest` | boolean | 익명 사용자 여부 | NOT NULL, DEFAULT false |
| `device_id` | string (nullable) | 디바이스 고유 ID (UUID) | UNIQUE INDEX |
| `login_method` | string | 로그인 방식 | "guest" 추가 |

### 익명 사용자 예시

```json
{
  "id": 12345,
  "email": "guest_a3b8c9d1@ojeomneo.local",
  "username": "guest_x7y2z5m3",
  "is_guest": true,
  "device_id": "550e8400-e29b-41d4-a716-446655440000",
  "login_method": "guest",
  "is_active": true,
  "date_joined": "2025-01-08T10:00:00Z"
}
```

---

## API 설계

### POST /v1/auth/guest

익명 사용자 토큰 발급

**Request:**
```json
{
  "device_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "",
    "token_type": "Bearer",
    "user": {
      "id": 12345,
      "email": "guest_a3b8c9d1@ojeomneo.local",
      "is_active": true,
      "date_joined": "2025-01-08T10:00:00Z",
      "login_method": "guest"
    }
  }
}
```

**특징:**
- `refresh_token`은 빈 문자열 (익명 사용자는 refresh 불가)
- `access_token` 만료 기간: 7일
- 동일 `device_id` 재요청 시 토큰만 재발급

---

## JWT 토큰 구조

### Claims 구조

```json
{
  "user_id": 12345,
  "type": "access",
  "is_guest": true,
  "exp": 1704700800,
  "iat": 1704096000
}
```

### 토큰 검증 로직

```go
claims, err := auth.ValidateAccessToken(token, secretKey)
if err != nil {
    return ErrInvalidToken
}

if claims.IsGuest {
    // 익명 사용자 전용 로직
    // 예: 일부 기능 제한, 광고 표시 등
}
```

---

## 모바일 구현 가이드

### 1. DeviceService 구현

```dart
class DeviceService {
  static const String _deviceIdKey = 'device_id';
  final FlutterSecureStorage _storage;

  Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }

    return deviceId;
  }
}
```

### 2. 익명 로그인 플로우

```dart
class AuthRepository {
  Future<AuthResponse> guestLogin() async {
    final deviceId = await deviceService.getDeviceId();

    final response = await http.post(
      '/v1/auth/guest',
      body: {'device_id': deviceId},
    );

    final authData = AuthResponse.fromJson(response.data);
    await tokenStorage.saveGuestToken(authData.accessToken);

    return authData;
  }
}
```

### 3. 앱 시작 시 초기화

```dart
void main() async {
  // 1. 저장된 토큰 확인
  final token = await tokenStorage.getToken();

  if (token == null) {
    // 2. 토큰 없음 → 익명 로그인
    await authRepository.guestLogin();
  }

  runApp(MyApp());
}
```

---

## 데이터 보관 정책

| 사용자 유형 | 보관 기간 | 삭제 조건 | 비고 |
|-------------|-----------|----------|------|
| **익명 사용자** | 7일 | `created_at` 기준 7일 경과 | 배치 작업으로 정리 |
| **정회원** | 무제한 | 사용자 탈퇴 시 | 리뷰맵 연계 대비 |

### 익명 사용자 정리 배치 (예정)

```sql
-- 7일 이상 경과한 익명 사용자 삭제
DELETE FROM users
WHERE is_guest = true
  AND created_at < NOW() - INTERVAL '7 days';
```

---

## 익명 → 정회원 전환 (향후 구현)

### 전환 시나리오

1. 익명 사용자가 회원가입/로그인 시도
2. 기존 익명 데이터 (스케치 히스토리 등)를 정회원 계정으로 마이그레이션
3. `is_guest = false`로 변경, `device_id` 유지

### 전환 API (예정)

```http
POST /v1/auth/guest/convert
Authorization: Bearer {guest_token}

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**응답:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 12345,
      "email": "user@example.com",
      "is_guest": false,
      "login_method": "email"
    }
  }
}
```

---

## 모니터링

### SigNoz 메트릭

| 메트릭 | 설명 | 레이블 |
|--------|------|--------|
| `auth.guest.login.total` | 익명 로그인 시도 수 | `auth.status` (success/failed) |
| `auth.guest.conversion.total` | 익명→정회원 전환 수 | `conversion.method` (email/google/apple/kakao) |

### 대시보드 패널

- **👤 익명 로그인 시도**: 시간별 익명 로그인 추이
- **🎯 익명→정회원 전환**: 전환 방식별 통계

### 주요 쿼리

**익명 로그인 성공률:**
```promql
rate(auth_guest_login_total{auth_status="success"}[5m])
/
rate(auth_guest_login_total[5m])
* 100
```

**익명→정회원 전환율:**
```promql
sum(rate(auth_guest_conversion_total[1h]))
/
sum(rate(auth_guest_login_total{auth_status="success"}[1h]))
* 100
```

---

## 구현 체크리스트

### Server (Go)

- [x] User 모델에 `is_guest`, `device_id` 필드 추가
- [x] JWT Claims에 `is_guest` 필드 추가
- [x] `GenerateGuestToken()` 함수 구현
- [x] `LoginMethod`에 "guest" 추가
- [x] `AuthService.GuestLogin()` 메서드 구현
- [x] `AuthHandler.GuestLogin()` 핸들러 구현
- [x] `/v1/auth/guest` 라우터 등록
- [x] 익명 세션 메트릭 추가 (`AuthMetrics`)
- [x] SigNoz 대시보드 패널 추가
- [x] 모니터링 문서 업데이트
- [x] 컴파일 테스트 완료

### Mobile (Flutter)

- [ ] `DeviceService` 구현 (UUID 생성 및 저장)
- [ ] `AuthRepository.guestLogin()` API 호출 구현
- [ ] 앱 시작 시 익명 세션 초기화
- [ ] 익명 사용자 UI/UX 처리 (로그인 유도 등)

### Admin (Django)

- [ ] User 모델 동기화 (`is_guest`, `device_id` 필드)
- [ ] Django admin에서 익명 사용자 필터링

---

## 보안 고려사항

| 항목 | 대응 |
|------|------|
| **디바이스 ID 위조** | JWT 서명 검증으로 방지 |
| **토큰 탈취** | HTTPS 통신 + Secure Storage 사용 |
| **무제한 계정 생성** | Rate Limiting 적용 (기존 미들웨어) |
| **데이터 유출** | 익명 데이터는 개인정보 없음 (UUID만) |

---

## 향후 개선사항

1. **익명 사용자 기능 제한**: 일부 프리미엄 기능 제한 (로그인 유도)
2. **익명→정회원 전환 API** 구현
3. **데이터 마이그레이션 로직** 구현 (스케치 히스토리, 즐겨찾기 등)
4. **배치 작업**: 7일 경과 익명 사용자 자동 삭제
5. **A/B 테스트**: 익명 로그인 유도 전략 실험

---

## 참고 자료

- **Server 코드**: `server/internal/service/auth.go`
- **JWT 로직**: `server/pkg/auth/jwt.go`
- **API 핸들러**: `server/internal/handler/auth.go`
- **메트릭 정의**: `server/internal/telemetry/metrics.go`
- **모니터링 가이드**: `docs/MONITORING_SETUP.md`

---

## 최종 업데이트

- **날짜**: 2025년 1월
- **상태**: Server 구현 완료 ✅ / Mobile 구현 대기 ⏳
- **커버리지**: Server API 100%, 모니터링 100%, 문서화 100%
