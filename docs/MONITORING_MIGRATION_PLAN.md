# 모니터링 인프라 마이그레이션 작업계획서

Prometheus → SigNoz 전환 작업계획서

## Phase 1: SigNoz 설치 및 병행 운영

- [x] SigNoz Helm Chart 값 검토 및 커스터마이징
  - `values.yaml`에 `global.clusterName: "ggorockee-nks"` 설정
  - 경로: `/Users/woohyeon/ggorockee/infra/charts/helm/prod/monitoring/signoz/values.yaml`
- [x] K8s 클러스터에 SigNoz 네임스페이스 생성
  - ArgoCD ApplicationSet이 자동 생성
- [x] SigNoz Helm Chart 배포
  - ArgoCD GitOps 배포 완료 (commit: 2600409)
  - `git push origin main` → ArgoCD 자동 sync
- [x] SigNoz UI 접속 확인 (Ingress/Port-forward)
  - Traefik IngressRoute로 접속 확인 완료
- [x] 기본 대시보드 동작 확인
  - 차트 정상 표시 확인

### ArgoCD 배포 확인

| 확인 항목 | 명령어 |
|----------|--------|
| ArgoCD Application 상태 | ArgoCD UI에서 signoz 앱 확인 |
| Pod 상태 | `kubectl get pods -n signoz` |
| Service 상태 | `kubectl get svc -n signoz` |
| UI 접속 | `kubectl port-forward svc/signoz-frontend 3301:3301 -n signoz` |

## Phase 2: Go Fiber OpenTelemetry 연동

- [x] `github.com/gofiber/contrib/otelfiber` 의존성 추가
- [x] OpenTelemetry SDK 초기화 코드 작성
  - `internal/telemetry/otel.go` 생성
- [x] Fiber 앱에 otelfiber 미들웨어 추가
  - `cmd/api/main.go`에 미들웨어 추가
- [x] GORM 트레이싱 연동 (DB 쿼리 추적)
  - `internal/config/database.go`에 otelgorm 플러그인 추가
- [x] SigNoz에서 트레이스 수신 확인
  - K8s 배포 완료 (2025-12-03)
  - 환경변수: `OTEL_EXPORTER_OTLP_ENDPOINT=signoz-otel-collector.monitoring:4317`

## Phase 3: Prometheus 메트릭 연동

- [ ] SigNoz OpenTelemetry Collector에 prometheus receiver 설정
- [ ] 기존 Prometheus 메트릭 SigNoz로 수집 확인
- [ ] SigNoz 대시보드에서 메트릭 시각화 확인
- [ ] 알림 규칙 마이그레이션 (필요시)

## Phase 4: 완전 전환 및 정리

- [ ] Prometheus 스택 트래픽 중단 테스트
- [ ] SigNoz 단독 운영 안정성 검증 (1주일)
- [ ] kube-prometheus-stack Helm release 삭제
- [ ] 불필요한 리소스 정리 (PVC, ConfigMap 등)
- [ ] 모니터링 문서 최종 업데이트
