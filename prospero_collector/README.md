# Prospero_collector

크립토/매크로 경제 데이터를 수집하여 DynamoDB(TB_CRYPTO_DATA, TB_MACRO_DATA)에 저장하는 Python 프로젝트.

Lambda 배포 또는 로컬 실행 가능.

## 프로젝트 구조

```
Prospero_collector/
├── lambda_function.py   # Lambda 핸들러 (진입점)
├── crypto_collector.py  # Binance, Alternative.me API 호출
├── macro_collector.py   # FRED API 호출
├── dynamodb_writer.py   # DynamoDB PutItem
├── requirements.txt
├── PLAN.md              # Lambda 이전 계획
└── README.md
```

## 환경변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `FRED_API_KEY` | FRED API 키 | - |
| `FRED_API_KEY_PARAM` | SSM Parameter Store 경로 (Lambda용) | `/prospero/fred-api-key` |
| `DYNAMODB_CRYPTO_TABLE` | 크립토 테이블명 | TB_CRYPTO_DATA |
| `DYNAMODB_MACRO_TABLE` | 매크로 테이블명 | TB_MACRO_DATA |
| `AWS_ACCESS_KEY_ID` | AWS 자격증명 | - |
| `AWS_SECRET_ACCESS_KEY` | AWS 자격증명 | - |
| `AWS_DEFAULT_REGION` | AWS 리전 | ap-northeast-2 |

## 로컬 실행

```bash
# 의존성 설치
pip install -r requirements.txt

# .env 파일 사용 (application.properties 참조하여 생성됨)
# .env가 있으면 자동 로드됨
python run_local.py              # 오늘 날짜
python run_local.py 20241201     # 특정 날짜
```

환경변수 직접 설정:
```bash
export FRED_API_KEY=...
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-northeast-2
python run_local.py
```

## Lambda 배포

**[LAMBDA_DEPLOYMENT.md](./LAMBDA_DEPLOYMENT.md)** 참고 (단계별 가이드)

요약:
1. SSM Parameter Store에 FRED API 키 저장
2. `./deploy.sh` 실행 → zip 생성 및 Lambda 업데이트
3. EventBridge Rule: `cron(0 4 * * ? *)` (매일 UTC 04:00)
4. IAM: dynamodb:PutItem, ssm:GetParameter

## 데이터 소스

- **크립토**: Binance API, Alternative.me (Fear & Greed)
- **매크로**: FRED API (FEDFUNDS, DGS10, CPIAUCSL, M2SL, UNRATE, DTWEXBGS)
