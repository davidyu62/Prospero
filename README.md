# Prospero

크립토/거시경제 데이터 기반 투자 인사이트 서비스

## 프로젝트 구조

```
Prospero/
├── prospero_app/         # iOS 앱 (SwiftUI)
├── prospero_collector/   # 데이터 수집기 (Python, AWS Lambda)
└── prospero_backend/     # API 서버 (Python, AWS Lambda + API Gateway)
```

## 아키텍처

```
[prospero_collector]
    외부 API(Binance, FRED 등)에서 크립토/거시경제 데이터 수집
    → DynamoDB(TB_CRYPTO_DATA, TB_MACRO_DATA) 저장
    → 매일 UTC 04:00 자동 실행 (EventBridge)

[prospero_backend]
    DynamoDB 데이터를 REST API로 제공
    → API Gateway + Lambda

[prospero_app]
    iOS 앱에서 API 호출 → 대시보드 표시
```

## 각 프로젝트 상세

- [prospero_app](./prospero_app/README.md) — iOS SwiftUI 앱
- [prospero_collector](./prospero_collector/README.md) — 데이터 수집 Lambda
- [prospero_backend](./prospero_backend/README.md) — 조회 API Lambda
