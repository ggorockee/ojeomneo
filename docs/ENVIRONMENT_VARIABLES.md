# 환경변수 요약

이 문서는 Ojeomneo 프로젝트에서 필요한 모든 환경변수를 정리한 것입니다.

---

## 서버 (Server) 환경변수

### 데이터베이스 (PostgreSQL)
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `POSTGRES_SERVER` | PostgreSQL 서버 호스트 | ✅ | `localhost` | `postgres.example.com` | Secret |
| `POSTGRES_PORT` | PostgreSQL 포트 | ❌ | `5432` | `5432` | ConfigMap |
| `POSTGRES_DB` | 데이터베이스 이름 | ✅ | `ojeomneo` | `ojeomneo` | Secret |
| `POSTGRES_USER` | 데이터베이스 사용자 | ✅ | `ojeomneo` | `ojeomneo` | Secret |
| `POSTGRES_PASSWORD` | 데이터베이스 비밀번호 | ✅ | - | `your_password` | Secret |

### Redis
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `REDIS_HOST` | Redis 호스트 | ❌ | `localhost` | `redis.example.com` | ConfigMap |
| `REDIS_PORT` | Redis 포트 | ❌ | `6379` | `6379` | ConfigMap |
| `REDIS_PASSWORD` | Redis 비밀번호 | ❌ | - | `your_redis_password` | Secret |

### 애플리케이션 설정
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `APP_ENV` | 실행 환경 | ❌ | `development` | `production`, `development`, `staging` | ConfigMap |
| `APP_PORT` | 서버 포트 | ❌ | `3000` | `3000` | ConfigMap |

### Gemini API (LLM)
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `GEMINI_API_KEY` | Google Gemini API 키 | ✅ | - | `AIza...` | Secret |
| `GEMINI_MODEL` | 사용할 Gemini 모델 | ❌ | `gemini-1.5-flash` | `gemini-1.5-flash` | ConfigMap |

### OpenTelemetry (선택)
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP 엔드포인트 | ❌ | - | `http://otel-collector:4317` | ConfigMap |

### Cloudflare Images
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare 계정 ID | ✅ | - | `your_account_id` | Secret |
| `CLOUDFLARE_ACCOUNT_HASH` | Cloudflare 계정 해시 | ✅ | - | `your_account_hash` | Secret |
| `CLOUDFLARE_API_KEY` | Cloudflare API 키 | ✅ | - | `your_api_key` | Secret |

### JWT (인증 토큰)
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `JWT_SECRET_KEY` | JWT 서명 키 (비밀키) | ✅ | - | `your_secret_key_here` | Secret |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | Access Token 만료 시간 (분) | ❌ | `15` | `15` | ConfigMap |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | Refresh Token 만료 시간 (일) | ❌ | `7` | `7` | ConfigMap |

### SNS 로그인 - Google (Firebase)
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `FIREBASE_ADMIN_SDK_KEY` | Firebase Admin SDK 키 (JSON 문자열) | ✅ | - | `{"type":"service_account",...}` | Secret |

**⚠️ 중요:** 
- 이 값은 JSON 문자열 형식으로 제공되어야 합니다
- Kubernetes Secret으로 주입할 때는 전체 JSON을 문자열로 저장해야 합니다
- 파일 경로가 아니라 키 값 자체를 환경변수로 제공합니다

### SNS 로그인 - Apple
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `APPLE_CLIENT_ID` | Apple OAuth 클라이언트 ID (Bundle ID) | ✅ | - | `com.woohalabs.ojeomneo` | ConfigMap |
| `APPLE_TEAM_ID` | Apple 개발팀 ID | ✅ | - | `ABC123DEF4` | Secret |
| `APPLE_KEY_ID` | Apple Key ID | ✅ | - | `XYZ789ABC1` | Secret |

### SNS 로그인 - Kakao
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `KAKAO_REST_API_KEY` | 카카오 REST API 키 | ✅ | - | `4d3810fbbd527782757b7c2a0f737a7c` | Secret |

### 기타
| 변수명 | 설명 | 필수 | 기본값 | 예시 | 주입 방식 |
|--------|------|------|--------|------|-----------|
| `SEED_DATA` | 시드 데이터 삽입 여부 | ❌ | - | `true` (설정 시 메뉴 데이터 자동 삽입) | ConfigMap |

---

## 모바일 (Mobile) 환경변수

**참고:** 모바일 앱은 현재 하드코딩된 값들을 사용하고 있습니다. 향후 `.env` 파일을 통한 환경변수 지원이 계획되어 있습니다.

### API 설정
| 변수명 | 설명 | 필수 | 기본값 (현재 하드코딩) | 예시 |
|--------|------|------|----------------------|------|
| `API_BASE_URL` | 백엔드 API 베이스 URL | ❌ | `https://api.woohalabs.com` | `https://api.woohalabs.com` |

### SNS 로그인 - Apple
| 변수명 | 설명 | 필수 | 기본값 | 예시 |
|--------|------|------|--------|------|
| `APPLE_CLIENT_ID` | Apple OAuth 클라이언트 ID (Bundle ID) | ✅ | - | `com.woohalabs.ojeomneo` |

### SNS 로그인 - Kakao
| 변수명 | 설명 | 필수 | 기본값 | 예시 |
|--------|------|------|--------|------|
| `KAKAO_NATIVE_APP_KEY` | 카카오 네이티브 앱 키 | ✅ | - | `your_kakao_native_app_key` |

**참고:** Google 로그인은 Firebase Authentication을 사용하므로 별도의 환경변수가 필요하지 않습니다. Firebase 설정 파일(`GoogleService-Info.plist`, `google-services.json`)만 필요합니다.

---

## Kubernetes Secret 주입 방법

### 서버 환경변수 예시

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ojeomneo-server-secrets
type: Opaque
stringData:
  # Database
  POSTGRES_SERVER: "postgres.example.com"
  POSTGRES_PORT: "5432"
  POSTGRES_DB: "ojeomneo"
  POSTGRES_USER: "ojeomneo"
  POSTGRES_PASSWORD: "your_password"
  
  # Redis
  REDIS_HOST: "redis.example.com"
  REDIS_PORT: "6379"
  REDIS_PASSWORD: "your_redis_password"
  
  # Gemini (API 키는 Secret)
  GEMINI_API_KEY: "AIza..."
  
  # Cloudflare (모두 Secret)
  CLOUDFLARE_ACCOUNT_ID: "your_account_id"
  CLOUDFLARE_ACCOUNT_HASH: "your_account_hash"
  CLOUDFLARE_API_KEY: "your_api_key"
  
  # JWT (Secret Key는 Secret, 만료 시간은 ConfigMap)
  JWT_SECRET_KEY: "your_secret_key_here"
  
  # Firebase (JSON 문자열 전체 - Secret)
  FIREBASE_ADMIN_SDK_KEY: |
    {
      "type": "service_account",
      "project_id": "ojeomneo-e7f17",
      ...
    }
  
  # Apple (Client ID는 ConfigMap, Team ID와 Key ID는 Secret)
  APPLE_TEAM_ID: "ABC123DEF4"
  APPLE_KEY_ID: "XYZ789ABC1"
  
  # Kakao (Secret)
  KAKAO_REST_API_KEY: "4d3810fbbd527782757b7c2a0f737a7c"
```

### Deployment에서 Secret과 ConfigMap 사용

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ojeomneo-server
spec:
  template:
    spec:
      containers:
      - name: server
        image: ojeomneo-server:latest
        envFrom:
        # ConfigMap에서 비민감한 설정값 주입
        - configMapRef:
            name: ojeomneo-server-config
        # Secret에서 민감한 정보 주입
        - secretRef:
            name: ojeomneo-server-secrets
```

### ConfigMap 예시

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ojeomneo-server-config
data:
  # 애플리케이션 기본 설정
  APP_ENV: "production"
  APP_PORT: "3000"
  
  # 데이터베이스 설정 (기본값)
  POSTGRES_PORT: "5432"
  
  # Redis 연결 설정 (기본값)
  REDIS_HOST: "ojeomneo-redis-master"
  REDIS_PORT: "6379"
  
  # Gemini LLM 설정 (기본값)
  GEMINI_MODEL: "gemini-2.0-flash"
  
  # OpenTelemetry 설정
  OTEL_EXPORTER_OTLP_ENDPOINT: "signoz-otel-collector.monitoring:4317"
  
  # JWT 토큰 설정 (기본값)
  JWT_ACCESS_TOKEN_EXPIRE_MINUTES: "15"
  JWT_REFRESH_TOKEN_EXPIRE_DAYS: "7"
  
  # SNS 로그인 설정 - Apple (기본값)
  APPLE_CLIENT_ID: "com.woohalabs.ojeomneo"
  
  # 기타 설정
  SEED_DATA: "true"
```

---

## 개발 환경 설정 (.env 파일)

### 서버 (`server/.env`)

```bash
# Database
POSTGRES_SERVER=localhost
POSTGRES_PORT=5432
POSTGRES_DB=ojeomneo
POSTGRES_USER=ojeomneo
POSTGRES_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Gemini
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-1.5-flash

# Cloudflare
CLOUDFLARE_ACCOUNT_ID=your_account_id
CLOUDFLARE_ACCOUNT_HASH=your_account_hash
CLOUDFLARE_API_KEY=your_api_key

# JWT
JWT_SECRET_KEY=your_secret_key_here
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# Firebase (JSON 문자열 - 한 줄로 작성하거나 \n 사용)
FIREBASE_ADMIN_SDK_KEY={"type":"service_account","project_id":"ojeomneo-e7f17",...}

# Apple
APPLE_CLIENT_ID=com.woohalabs.ojeomneo
APPLE_TEAM_ID=your_team_id
APPLE_KEY_ID=your_key_id

# Kakao
KAKAO_REST_API_KEY=your_kakao_rest_api_key
```

### 모바일 (`mobile/.env`)

```bash
# API
API_BASE_URL=https://api.woohalabs.com

# Apple
APPLE_CLIENT_ID=com.woohalabs.ojeomneo

# Kakao
KAKAO_NATIVE_APP_KEY=your_kakao_native_app_key
```

---

## 체크리스트

개발 환경 설정 시 다음을 확인하세요:

### 서버
- [ ] PostgreSQL 연결 정보 설정
- [ ] Redis 연결 정보 설정 (선택)
- [ ] Gemini API 키 설정
- [ ] Cloudflare Images 설정 (이미지 업로드 기능 사용 시)
- [ ] JWT 비밀키 설정 (보안을 위해 강력한 랜덤 문자열 사용)
- [ ] Firebase Admin SDK 키 설정 (Google 로그인 사용 시)
- [ ] Apple 로그인 설정 (Apple 로그인 사용 시)
- [ ] Kakao 로그인 설정 (Kakao 로그인 사용 시)

### 모바일
- [ ] API 베이스 URL 설정
- [ ] Apple 로그인 설정 (Apple 로그인 사용 시)
- [ ] Kakao 로그인 설정 (Kakao 로그인 사용 시)
- [ ] Firebase 설정 파일 추가 (`GoogleService-Info.plist`, `google-services.json`)

---

## 보안 주의사항

1. **절대 Git에 커밋하지 마세요**
   - `.env` 파일은 `.gitignore`에 포함되어 있습니다
   - 비밀키나 API 키가 포함된 파일은 절대 커밋하지 마세요

2. **프로덕션 환경**
   - 모든 비밀값은 Kubernetes Secret으로 관리하세요
   - 환경변수는 반드시 Secret을 통해 주입하세요

3. **JWT Secret Key**
   - 최소 32자 이상의 랜덤 문자열을 사용하세요
   - 프로덕션과 개발 환경은 다른 키를 사용하세요

4. **Firebase Admin SDK Key**
   - JSON 문자열 전체를 환경변수로 제공하세요
   - 파일 경로가 아닌 키 값 자체를 제공해야 합니다

---

## 참고 자료

- [서버 설정 코드](../../server/internal/config/config.go)
- [SNS 로그인 구현 계획서](./SNS_LOGIN_IMPLEMENTATION_PLAN.md)

