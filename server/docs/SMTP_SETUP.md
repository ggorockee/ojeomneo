# SMTP 이메일 발송 설정 가이드

## 개요

오점너 서비스는 이메일 인증 및 비밀번호 재설정을 위해 Gmail SMTP를 사용합니다.

## 필수 환경변수

| 환경변수 | 설명 | 기본값 | 필수 여부 |
|---------|------|-------|----------|
| `SMTP_HOST` | SMTP 서버 주소 | `smtp.gmail.com` | ❌ |
| `SMTP_PORT` | SMTP 포트 | `587` | ❌ |
| `SMTP_USERNAME` | Gmail 계정 | - | ✅ |
| `SMTP_PASSWORD` | Gmail 앱 비밀번호 | - | ✅ |
| `SMTP_FROM` | 발신자 이메일 | `noreply@ojeomneo.com` | ❌ |

> **중요**: `SMTP_USERNAME`과 `SMTP_PASSWORD`가 설정되지 않으면 이메일 발송이 비활성화되고, 콘솔에 인증코드가 출력됩니다.

## Gmail 앱 비밀번호 생성 방법

### 1. Google 계정 2단계 인증 활성화
1. [Google 계정 보안](https://myaccount.google.com/security) 접속
2. "2단계 인증" 활성화

### 2. 앱 비밀번호 생성
1. [앱 비밀번호 관리](https://myaccount.google.com/apppasswords) 접속
2. "앱 선택" → "메일" 선택
3. "기기 선택" → "기타 (맞춤 이름)" 선택
4. 이름 입력 (예: `ojeomneo-prod`)
5. "생성" 클릭
6. **16자리 앱 비밀번호 복사** (공백 제거)

## Kubernetes Secret 설정

### 1. Secret 생성
```bash
# Base64 인코딩
echo -n "your-email@gmail.com" | base64
echo -n "your-app-password" | base64

# Secret YAML 작성
cat <<EOF > ojeomneo-smtp-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ojeomneo-api-credentials
  namespace: default
type: Opaque
data:
  SMTP_USERNAME: <base64-encoded-email>
  SMTP_PASSWORD: <base64-encoded-password>
  SMTP_FROM: <base64-encoded-from-email>
EOF

# Secret 적용
kubectl apply -f ojeomneo-smtp-secret.yaml
```

### 2. Deployment에 환경변수 추가
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
        env:
        - name: SMTP_HOST
          value: "smtp.gmail.com"
        - name: SMTP_PORT
          value: "587"
        - name: SMTP_USERNAME
          valueFrom:
            secretKeyRef:
              name: ojeomneo-api-credentials
              key: SMTP_USERNAME
        - name: SMTP_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ojeomneo-api-credentials
              key: SMTP_PASSWORD
        - name: SMTP_FROM
          valueFrom:
            secretKeyRef:
              name: ojeomneo-api-credentials
              key: SMTP_FROM
```

### 3. Pod 재시작
```bash
kubectl rollout restart deployment/ojeomneo-server
kubectl rollout status deployment/ojeomneo-server
```

## 로컬 개발 환경 설정

### 1. `.env` 파일 생성
```bash
cd server
cp .env.example .env
```

### 2. `.env` 파일 편집
```bash
# SMTP Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@ojeomneo.com
```

### 3. 서버 재시작
```bash
go run ./cmd/server
```

## 동작 확인

### 1. 로그 확인
```bash
# Kubernetes
kubectl logs -f deployment/ojeomneo-server | grep -i smtp

# 로컬
go run ./cmd/server 2>&1 | grep -i smtp
```

**정상 동작 시 로그**:
```log
{"level":"info","msg":"SMTP email service initialized","host":"smtp.gmail.com","port":"587"}
```

**비활성화 시 로그**:
```log
{"level":"warn","msg":"SMTP email service disabled (no credentials)"}
```

### 2. API 테스트
```bash
# 이메일 인증코드 발송 테스트
curl -X POST https://api.woohalabs.com/ojeomneo/v1/auth/email/send-code \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'

# 성공 응답
{
  "success": true,
  "message": "인증코드가 이메일로 발송되었습니다."
}
```

### 3. 이메일 수신 확인
- 받은 편지함에서 "[오점너] 이메일 인증 코드" 메일 확인
- 스팸 메일함도 확인

## 트러블슈팅

### 이메일이 발송되지 않는 경우

1. **환경변수 확인**
```bash
# Kubernetes
kubectl exec -it deployment/ojeomneo-server -- env | grep SMTP

# 로컬
env | grep SMTP
```

2. **Secret 확인**
```bash
kubectl get secret ojeomneo-api-credentials -o jsonpath='{.data}' | jq
```

3. **로그 확인**
```bash
kubectl logs -f deployment/ojeomneo-server | grep -E "SMTP|email"
```

### 일반적인 오류

| 오류 메시지 | 원인 | 해결 방법 |
|----------|------|---------|
| `SMTP disabled` | 환경변수 미설정 | `SMTP_USERNAME`, `SMTP_PASSWORD` 설정 |
| `535 Authentication failed` | 잘못된 앱 비밀번호 | 앱 비밀번호 재생성 및 재설정 |
| `Connection timeout` | 방화벽 차단 | 587 포트 아웃바운드 허용 |
| `Certificate verify failed` | SSL/TLS 오류 | Go 버전 및 인증서 확인 |

### Gmail 보안 알림

Gmail이 "보안 수준이 낮은 앱" 차단 메시지를 표시하는 경우:
1. **2단계 인증 활성화** (필수)
2. **앱 비밀번호 사용** (일반 비밀번호 사용 불가)
3. [Gmail 보안 설정](https://myaccount.google.com/security) 확인

## 프로덕션 권장 사항

### 1. 전용 Gmail 계정 사용
- 개인 계정 대신 서비스 전용 Gmail 계정 생성
- 예: `noreply@yourdomain.com` 또는 `no-reply@gmail.com`

### 2. 발송 제한 관리
Gmail SMTP 제한:
- 개인 계정: 500통/일
- Google Workspace: 2,000통/일

대량 발송이 필요한 경우:
- SendGrid, AWS SES, Mailgun 등 전문 서비스 사용 권장

### 3. 모니터링
- 이메일 발송 실패율 모니터링
- Prometheus 메트릭 수집
- Alert 설정 (발송 실패 시)

### 4. 백업 전략
- SMTP 서비스 장애 대비 대체 발송 수단 준비
- 콘솔 로그로 인증코드 확인 가능하도록 유지

## 참고 자료

- [Gmail SMTP 설정](https://support.google.com/mail/answer/7126229)
- [앱 비밀번호 생성](https://support.google.com/accounts/answer/185833)
- [Go SMTP 패키지](https://pkg.go.dev/net/smtp)
