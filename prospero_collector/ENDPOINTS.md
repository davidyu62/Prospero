# prospero_collector 엔드포인트

## 📡 개요

prospero_collector는 **데이터 수집 배치 프로세스**입니다. 주로 EventBridge에서 자동으로 실행되지만, 필요에 따라 API Gateway를 통해 수동으로 트리거할 수 있습니다.

---

## 🔄 자동 실행 (EventBridge)

### 스케줄

**매일 UTC 04:00 자동 실행**

```
cron(0 4 * * ? *)
```

- **시간**: 04:00 UTC (= 13:00 KST/한국시간)
- **주기**: 매일
- **트리거**: EventBridge Rule
- **대상**: prospero-collector Lambda

### 설정 예시

```json
{
    "Name": "prospero-collector-daily",
    "ScheduleExpression": "cron(0 4 * * ? *)",
    "State": "ENABLED",
    "Targets": [
        {
            "Arn": "arn:aws:lambda:ap-northeast-2:ACCOUNT_ID:function:prospero-collector",
            "RoleArn": "arn:aws:iam::ACCOUNT_ID:role/service-role/EventBridge-Invoke-Lambda"
        }
    ]
}
```

---

## 📡 API Gateway 트리거 (선택사항)

prospero_collector Lambda를 API Gateway로 노출하면 HTTP API로도 호출 가능합니다.

### 요청 포맷

**자동 실행 (오늘 날짜)**:
```http
POST /api/collector/run
```

**특정 날짜 실행**:
```http
POST /api/collector/run
Content-Type: application/json

{
  "date": "20260330"
}
```

또는 쿼리 파라미터:
```http
POST /api/collector/run?date=20260330
```

---

## 💾 Lambda 직접 호출

### AWS CLI

**오늘 날짜로 실행**:
```bash
aws lambda invoke \
  --function-name prospero-collector \
  --payload '{}' \
  response.json
```

**특정 날짜 실행**:
```bash
aws lambda invoke \
  --function-name prospero-collector \
  --payload '{"date":"20260330"}' \
  response.json

cat response.json
```

### Python SDK

```python
import boto3

client = boto3.client('lambda', region_name='ap-northeast-2')

# 오늘 날짜
response = client.invoke(
    FunctionName='prospero-collector',
    InvocationType='RequestResponse',
    Payload='{}'
)

# 특정 날짜
response = client.invoke(
    FunctionName='prospero-collector',
    InvocationType='RequestResponse',
    Payload='{"date":"20260330"}'
)

print(response['StatusCode'])
print(response['Payload'].read().decode())
```

---

## 📊 실행 요청

### 요청 형식

```json
{
  "date": "20260330"
}
```

**선택 파라미터**:
| 파라미터 | 타입 | 형식 | 설명 |
|---------|------|------|------|
| date | string | yyyyMMdd | 수집 대상 날짜 (생략 시 오늘) |
| targetDate | string | yyyy-MM-dd | 수집 대상 날짜 (alternative 형식) |

### 응답 형식

**상태 코드**: 200 OK

```json
{
  "statusCode": 200,
  "body": {
    "date": "20260402",
    "crypto_saved": true,
    "macro_saved": true
  }
}
```

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| statusCode | number | HTTP 상태 코드 (200 = 성공) |
| date | string | 처리한 날짜 (yyyyMMdd) |
| crypto_saved | boolean | 크립토 데이터 저장 성공 여부 |
| macro_saved | boolean | 매크로 데이터 저장 성공 여부 |

### 부분 성공 응답

```json
{
  "statusCode": 200,
  "body": {
    "date": "20260402",
    "crypto_saved": true,
    "macro_saved": false
  }
}
```

한 데이터 수집이 실패해도 다른 데이터는 저장될 수 있습니다.

### 에러 응답

**상태 코드**: 500 Internal Server Error

```json
{
  "statusCode": 500,
  "body": "Error message: ..."
}
```

**가능한 에러**:
- FRED API 키 없음
- DynamoDB 테이블 미존재
- IAM 권한 부족
- 외부 API 연결 실패 (모든 API가 실패)

---

## 🔐 인증 및 권한

### IAM 정책

**Lambda 실행 역할 필수 권한**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter"
            ],
            "Resource": [
                "arn:aws:ssm:ap-northeast-2:*:parameter/prospero/fred-api-key"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "logs:*",
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

### FRED API 키 관리

**방법 1: 환경변수** (간단)
```
Lambda 함수 설정 → 환경변수
FRED_API_KEY = xxx
```

**방법 2: SSM Parameter Store** (권장)
```
AWS Systems Manager → Parameter Store
/prospero/fred-api-key = xxx (Secure String 타입)
```

Lambda는 자동으로 SSM에서 조회합니다.

---

## 📊 데이터 흐름

### 실행 순서

```
1. EventBridge 또는 수동 호출
   ↓
2. lambda_handler(event, context)
   ├─ _get_target_date(event) → "20260402"
   ├─ get_crypto_data("20260402")
   │  ├─ Binance API → BTC 가격, 롱/숏 비율, 오픈 인터레스트
   │  └─ Alternative.me → 공포탐욕지수
   │
   ├─ get_fred_api_key() → FRED API 키
   ├─ get_macro_data("20260402", api_key)
   │  └─ FRED API → 기준금리, Treasury, CPI, M2, 실업률, 달러인덱스
   │
   └─ save_data("20260402", crypto_data, macro_data)
      ├─ TB_CRYPTO_DATA 저장
      └─ TB_MACRO_DATA 저장
   ↓
3. 응답 반환
   {
     "statusCode": 200,
     "body": {
       "date": "20260402",
       "crypto_saved": true,
       "macro_saved": true
     }
   }
```

---

## 📈 수집 데이터

### 크립토 데이터 (TB_CRYPTO_DATA)

| 필드 | 출처 | 타입 | 설명 |
|------|------|------|------|
| btcPrice | Binance | Decimal | BTC 가격 (USD) |
| longShortRatio | Binance Futures | Decimal | 글로벌 롱/숏 비율 |
| exchangeBalance | CryptoQuant | Decimal | 거래소 잔고 (미연동, 0) |
| fearGreedIndex | Alternative.me | Integer | 공포탐욕지수 (0~100) |
| openInterest | Binance Futures | Decimal | 미결제 약정 (BTC 단위) |
| date | - | String | 날짜 (yyyyMMdd) |
| timestamps | - | String | 저장 시간 (ISO 8601) |

### 매크로 데이터 (TB_MACRO_DATA)

| 필드 | 출처 | 타입 | 설명 |
|------|------|------|------|
| interestRate | FRED (FEDFUNDS) | Decimal | 미국 기준금리 (%) |
| treasury10y | FRED (DGS10) | Decimal | 10년물 Treasury 수익률 (%) |
| cpi | FRED (CPIAUCSL) | Decimal | 소비자물가지수 (%) |
| m2 | FRED (M2SL) | Decimal | M2 통화공급량 (달러) |
| unemployment | FRED (UNRATE) | Decimal | 미국 실업률 (%) |
| dollarIndex | FRED (DTWEXBGS) | Decimal | 달러인덱스 |
| date | - | String | 날짜 (yyyyMMdd) |
| timestamps | - | String | 저장 시간 (ISO 8601) |

---

## 🔄 재시도 및 타이밍

### EventBridge 재시도 정책 (권장)

```json
{
    "RetryPolicy": {
        "MaximumEventAge": 3600,  // 1시간
        "MaximumRetryAttempts": 2
    },
    "DeadLetterConfig": {
        "Arn": "arn:aws:sqs:ap-northeast-2:ACCOUNT_ID:dlq-prospero"
    }
}
```

### Lambda 타임아웃

- **현재**: 60초
- **예상 소요**: 20~30초
- **여유**: 충분

---

## 📊 실행 예시

### 예 1: CLI로 특정 날짜 수집

```bash
aws lambda invoke \
  --function-name prospero-collector \
  --payload '{"date":"20260330"}' \
  --region ap-northeast-2 \
  response.json

cat response.json
```

**출력**:
```json
{
  "statusCode": 200,
  "body": {
    "date": "20260330",
    "crypto_saved": true,
    "macro_saved": true
  }
}
```

### 예 2: Python으로 오늘 실행

```python
import boto3
import json

lambda_client = boto3.client('lambda', region_name='ap-northeast-2')

response = lambda_client.invoke(
    FunctionName='prospero-collector',
    InvocationType='RequestResponse'
)

payload = json.loads(response['Payload'].read())
print(f"Status: {payload['statusCode']}")
print(f"Date: {payload['body']['date']}")
print(f"Crypto Saved: {payload['body']['crypto_saved']}")
print(f"Macro Saved: {payload['body']['macro_saved']}")
```

### 예 3: 로컬 테스트

```bash
cd prospero_collector
export FRED_API_KEY=your_key
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-northeast-2

# 오늘 날짜
python run_local.py

# 특정 날짜
python run_local.py 20260330
```

---

## 📋 외부 API 엔드포인트

### Binance API

| 엔드포인트 | 메서드 | 데이터 |
|----------|--------|--------|
| `https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT` | GET | BTC 가격 |
| `https://fapi.binance.com/futures/data/globalLongShortAccountRatio?symbol=BTCUSDT&period=5m&limit=1` | GET | 롱/숏 비율 |
| `https://fapi.binance.com/fapi/v1/openInterest?symbol=BTCUSDT` | GET | 오픈 인터레스트 |

### Alternative.me API

| 엔드포인트 | 메서드 | 데이터 |
|----------|--------|--------|
| `https://api.alternative.me/fng/` | GET | 공포탐욕지수 |

### FRED API

| 엔드포인트 | 메서드 | 설명 |
|----------|--------|------|
| `https://api.stlouisfed.org/fred/series/observations` | GET | 경제 지표 시계열 |

**FRED Series IDs**:
- `FEDFUNDS`: 기준금리
- `DGS10`: 10년물 Treasury
- `CPIAUCSL`: CPI
- `M2SL`: M2 통화량
- `UNRATE`: 실업률
- `DTWEXBGS`: 달러인덱스

---

## ⚠️ 주의사항

### 데이터 가용성

1. **크립토 데이터**: 실시간, 항상 사용 가능
2. **매크로 데이터**:
   - 평일: 대부분 사용 가능
   - 주말/공휴일: FRED에 새 데이터 없음 → 최근 60일 내 최신값 사용

### API 한계

| API | 한계 | 대응 |
|-----|------|------|
| FRED | 매월 1회 업데이트 (월초) | 폴백: 최근값 사용 |
| Binance | 간헐적 다운타임 | 재시도 (기본값) |
| Alternative.me | 일 1회 업데이트 | 캐시 사용 |

### 오류 처리

- **일부 API 실패**: 다른 데이터는 저장 (부분 성공)
- **전체 API 실패**: 저장하지 않음 (에러 반환)
- **DynamoDB 실패**: Lambda 에러 발생 (재시도)

---

**마지막 업데이트**: 2026년 4월 2일
