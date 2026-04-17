# prospero_collector 아키텍처

## 📐 시스템 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────┐
│     EventBridge (스케줄)                │
│  매일 UTC 04:00                         │
│  cron(0 4 * * ? *)                     │
└────────────┬────────────────────────────┘
             │ 트리거
             ▼
┌─────────────────────────────────────────┐
│   prospero_collector Lambda             │
│   (Python 3.11)                        │
│                                         │
│  ├─ lambda_function.py (진입점)        │
│  │  └─ lambda_handler()                │
│  │     ├─ 크립토 데이터 수집           │
│  │     ├─ 매크로 데이터 수집           │
│  │     └─ DynamoDB 저장               │
│  │                                     │
│  ├─ crypto_collector.py                │
│  │  ├─ _get_btc_price()               │
│  │  ├─ _get_long_short_ratio()        │
│  │  ├─ _get_exchange_balance()        │
│  │  ├─ _get_fear_greed_index()        │
│  │  └─ _get_open_interest()           │
│  │                                     │
│  ├─ macro_collector.py                 │
│  │  ├─ _get_fred_data()               │
│  │  ├─ _fetch_fred_single_date()      │
│  │  └─ _fetch_fred_date_range()       │
│  │                                     │
│  └─ dynamodb_writer.py                 │
│     ├─ save_crypto_data()             │
│     ├─ save_macro_data()              │
│     └─ _put_item()                    │
└────────────┬────────────────────────────┘
             │ 데이터 저장
             ▼
┌─────────────────────────────────────────┐
│   AWS DynamoDB (ap-northeast-2)        │
│                                         │
│  TB_CRYPTO_DATA                        │
│  ├─ PK: date (yyyyMMdd)                │
│  ├─ SK: timestamps (ISO 8601)          │
│  └─ 속성: btcPrice, longShortRatio,   │
│           exchangeBalance, fearGreedIndex,
│           openInterest                  │
│                                         │
│  TB_MACRO_DATA                         │
│  ├─ PK: date (yyyyMMdd)                │
│  ├─ SK: timestamps (ISO 8601)          │
│  └─ 속성: interestRate, treasury10y,  │
│           cpi, m2, unemployment,      │
│           dollarIndex                  │
└─────────────────────────────────────────┘
```

### 외부 API 연동

```
prospero_collector Lambda
│
├─ Binance API
│  ├─ https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT
│  │  └─ BTC 가격
│  │
│  └─ https://fapi.binance.com/futures/data/globalLongShortAccountRatio
│     ├─ 롱/숏 비율
│     └─ https://fapi.binance.com/fapi/v1/openInterest?symbol=BTCUSDT
│        └─ 오픈 인터레스트
│
├─ Alternative.me API
│  └─ https://api.alternative.me/fng/
│     └─ 공포탐욕지수
│
└─ FRED API (Federal Reserve Economic Data)
   └─ https://api.stlouisfed.org/fred/series/observations
      ├─ FEDFUNDS (기준금리)
      ├─ DGS10 (10년물 Treasury)
      ├─ CPIAUCSL (CPI)
      ├─ M2SL (M2 통화량)
      ├─ UNRATE (실업률)
      └─ DTWEXBGS (달러인덱스)
```

---

## 🔄 실행 흐름 (EventBridge 트리거)

### 매일 UTC 04:00 자동 실행

```
1️⃣ EventBridge 트리거
   시간: 매일 UTC 04:00
   cron(0 4 * * ? *)

2️⃣ lambda_handler(event={}, context)
   event: EventBridge Scheduled Event 또는 {}

3️⃣ _get_target_date(event) → 대상 날짜 결정
   └─ event에 date 없으면 오늘 날짜 사용

4️⃣ get_crypto_data(date_str) → 크립토 데이터 수집
   ├─ _get_btc_price() → Binance API
   ├─ _get_long_short_ratio() → Binance Futures
   ├─ _get_exchange_balance() → 0 (미연동)
   ├─ _get_fear_greed_index() → Alternative.me
   └─ _get_open_interest() → Binance Futures

   결과: {btcPrice, longShortRatio, exchangeBalance, fearGreedIndex, openInterest}

5️⃣ get_fred_api_key() → FRED API 키 조회
   ├─ 환경변수 FRED_API_KEY (우선)
   └─ SSM Parameter Store (폴백)

6️⃣ get_macro_data(date_str, fred_key) → 매크로 데이터 수집
   ├─ _get_fred_data("FEDFUNDS", date, key) → 기준금리
   ├─ _get_fred_data("DGS10", date, key) → 10년물 Treasury
   ├─ _get_fred_data("CPIAUCSL", date, key) → CPI
   ├─ _get_fred_data("M2SL", date, key) → M2 통화량
   ├─ _get_fred_data("UNRATE", date, key) → 실업률
   └─ _get_fred_data("DTWEXBGS", date, key) → 달러인덱스

   각 항목에서 폴백:
   - 해당 날짜 데이터 있으면 사용
   - 없으면 (주말/휴일) 최근 60일 내 최신 값 사용

   결과: {interestRate, treasury10y, cpi, m2, unemployment, dollarIndex}

7️⃣ save_data(date_str, crypto_data, macro_data)
   ├─ save_crypto_data(date, crypto_data)
   │  └─ _put_item("TB_CRYPTO_DATA", item)
   │     └─ client.put_item(TableName=..., Item=...)
   │
   └─ save_macro_data(date, macro_data)
      └─ _put_item("TB_MACRO_DATA", item)
         └─ client.put_item(TableName=..., Item=...)

8️⃣ 결과 반환
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

## 🔄 수동 실행 (API Gateway 또는 CLI)

### 1. AWS Lambda 콘솔에서 실행

```json
{
    "date": "20260330"
}
```

### 2. CLI 명령어

```bash
aws lambda invoke \
  --function-name prospero-collector \
  --payload '{"date":"20260330"}' \
  response.json
```

### 3. Python 로컬 실행

```bash
cd prospero_collector
python run_local.py        # 오늘 날짜
python run_local.py 20260330  # 특정 날짜
```

---

## 📊 데이터 수집 전략

### 크립토 데이터: API별 특성

| API | 엔드포인트 | 데이터 | 실시간성 | 신뢰도 |
|-----|----------|--------|---------|--------|
| Binance | `/api/v3/ticker/price` | BTC 가격 | 실시간 | ⭐⭐⭐⭐⭐ |
| Binance Futures | `/futures/data/globalLongShortAccountRatio` | 롱/숏 비율 | 5분 단위 | ⭐⭐⭐⭐ |
| Binance Futures | `/fapi/v1/openInterest` | 오픈 인터레스트 | 실시간 | ⭐⭐⭐⭐⭐ |
| Alternative.me | `/fng/` | 공포탐욕지수 | 일 1회 | ⭐⭐⭐⭐ |
| CryptoQuant | (미연동) | 거래소 잔고 | 일 1회 | ⭐⭐⭐⭐⭐ |

### 매크로 데이터: FRED API 폴백 전략

**상황**: 공휴일/주말은 데이터 없음

**1단계: 정확한 날짜 조회**
```
GET https://api.stlouisfed.org/fred/series/observations
?series_id=FEDFUNDS
&observation_start=2026-03-30&observation_end=2026-03-30
&api_key=...
```

**2단계: 폴백 (날짜 범위 조회)**
- 해당 날짜 데이터 없으면
- 최근 60일 범위 내에서 최신 관측값 사용
- 예: 월요일에 실행했는데 금요일 데이터 사용 가능

```
GET https://api.stlouisfed.org/fred/series/observations
?series_id=FEDFUNDS
&observation_start=2026-01-30&observation_end=2026-03-30
&sort_order=desc&limit=1
&api_key=...
```

### 데이터 타입 변환

**수집 → DynamoDB**
```
Python Decimal      → DynamoDB String (N 타입)
int/float          → String으로 변환 후 N 타입
None               → 저장하지 않음 (스킵)
```

**예시**:
```python
Decimal("62500.50")  → {"N": "62500.50"}
Decimal("1.25")      → {"N": "1.25"}
int(65)             → {"N": "65"}
```

---

## 🏗️ 컴포넌트별 역할

### lambda_function.py - 오케스트레이션

| 함수 | 역할 | 호출 시점 |
|------|------|---------|
| `lambda_handler()` | 수집 프로세스 오케스트레이션 | EventBridge 트리거 또는 수동 호출 |
| `get_fred_api_key()` | FRED API 키 조회 (환경변수/SSM) | lambda_handler() |
| `_get_target_date()` | 대상 날짜 결정 | lambda_handler() |

### crypto_collector.py - 크립토 데이터

| 함수 | 역할 | API |
|------|------|-----|
| `get_crypto_data()` | 크립토 데이터 수집 | Binance, Alternative.me |
| `_get_btc_price()` | BTC 가격 조회 | Binance API |
| `_get_long_short_ratio()` | 롱/숏 비율 조회 | Binance Futures API |
| `_get_exchange_balance()` | 거래소 잔고 (미연동) | CryptoQuant/Glassnode |
| `_get_fear_greed_index()` | 공포탐욕지수 조회 | Alternative.me API |
| `_get_open_interest()` | 오픈 인터레스트 조회 | Binance Futures API |

### macro_collector.py - 매크로 데이터

| 함수 | 역할 | API |
|------|------|-----|
| `get_macro_data()` | 매크로 데이터 수집 (6개 지표) | FRED API |
| `_get_fred_data()` | FRED 데이터 조회 (Query + Fallback) | FRED API |
| `_fetch_fred_single_date()` | 특정 날짜 데이터 조회 | FRED API |
| `_fetch_fred_date_range()` | 날짜 범위 최신값 조회 | FRED API |
| `_parse_observation()` | FRED 응답 파싱 | (내부 함수) |

### dynamodb_writer.py - DynamoDB 저장

| 함수 | 역할 | 테이블 |
|------|------|--------|
| `save_data()` | 크립토/매크로 통합 저장 | 두 테이블 |
| `save_crypto_data()` | 크립토 데이터 저장 | TB_CRYPTO_DATA |
| `save_macro_data()` | 매크로 데이터 저장 | TB_MACRO_DATA |
| `_build_crypto_item()` | 크립토 아이템 변환 | (내부) |
| `_build_macro_item()` | 매크로 아이템 변환 | (내부) |
| `_put_item()` | DynamoDB PutItem 실행 | (내부) |
| `_decimal_to_dynamo()` | 타입 변환 (Decimal → String) | (내부) |

---

## 🔐 에러 처리 전략

### 수집 단계: 부분 실패 허용

**상황**: 한 API 실패해도 다른 API는 수집 계속

```python
def get_crypto_data(date: str) -> Optional[dict]:
    result = {}

    try:
        btc_price = _get_btc_price()
        # → 실패해도 계속
    except Exception as e:
        print(f"[WARN] BTC 가격 조회 실패: {e}")
        # 빈 result 반환

    try:
        long_short = _get_long_short_ratio()
        # → 독립적으로 조회
    except Exception:
        pass

    return result if result else None  # 부분 수집도 반환
```

### 저장 단계: 실패 추적

```python
def save_data(date, crypto_data, macro_data) -> dict:
    result = {"crypto_saved": False, "macro_saved": False}

    if crypto_data:
        result["crypto_saved"] = save_crypto_data(date, crypto_data)
    else:
        print("[INFO] 크립토 데이터 없음")

    if macro_data:
        result["macro_saved"] = save_macro_data(date, macro_data)
    else:
        print("[INFO] 매크로 데이터 없음")

    return result  # 어느 것이 저장되었는지 반환
```

### CloudWatch 로그

```
[INFO] 크립토 데이터 수집 결과:
  btcPrice: 62500.50
  longShortRatio: 1.25
  exchangeBalance: 없음
  fearGreedIndex: 65
  openInterest: 28500000000

[WARN] Exchange Balance: API 미연동, 0으로 저장

[INFO] 매크로 데이터 수집 결과: {...}

[INFO] TB_CRYPTO_DATA 저장 완료: 20260330
[INFO] TB_MACRO_DATA 저장 완료: 20260330
```

---

## ⚡ 성능 최적화

### 병렬 API 호출 (향후 개선)

현재: 순차 호출 (O(T1 + T2 + ... + Tn))

```
_get_btc_price()          → 0.5s
_get_long_short_ratio()   → 0.5s
_get_exchange_balance()   → 0.5s
_get_fear_greed_index()   → 0.5s
_get_open_interest()      → 0.5s
─────────────────────────────
합계: ~2.5초
```

개선 방안: asyncio 또는 concurrent.futures 사용
```python
with ThreadPoolExecutor(max_workers=5) as executor:
    future_btc = executor.submit(_get_btc_price)
    future_ratio = executor.submit(_get_long_short_ratio)
    # ... 병렬 실행
```

### DynamoDB 최적화

- **PutItem**: 단일 아이템 저장 (적합)
- **배치**: 현재 2개 테이블만 저장하므로 배치 불필요
- **용량**: 온디맨드 (Pay-per-request) 권장

### Lambda 설정

- **메모리**: 256MB 이상 (권장 512MB)
- **타임아웃**: 60초 (충분함)
- **VPC**: 미사용 (콜드 스타트 최소화)

---

## 🔍 디버깅 및 모니터링

### CloudWatch Logs

```
/aws/lambda/prospero-collector

2026-04-02T04:00:00.123Z [INFO] Prospero_collector 실행 시작 - 날짜: 20260402
2026-04-02T04:00:01.456Z [INFO] BTC Price 조회 성공: 63200.75
2026-04-02T04:00:02.789Z [INFO] Long/Short Ratio 조회 성공: 1.28
2026-04-02T04:00:03.012Z [WARN] Exchange Balance: API 미연동
2026-04-02T04:00:04.345Z [INFO] Fear & Greed Index 조회 성공: 68
2026-04-02T04:00:05.678Z [INFO] Open Interest 조회 성공 (BTC): 29000000000
2026-04-02T04:00:06.901Z [INFO] 크립토 데이터 수집 결과: {...}
2026-04-02T04:00:08.234Z [INFO] interestRate 조회 성공: 4.50
...
2026-04-02T04:00:25.567Z [INFO] TB_CRYPTO_DATA 저장 완료: 20260402
2026-04-02T04:00:26.890Z [INFO] TB_MACRO_DATA 저장 완료: 20260402
```

### 로컬 테스트

```bash
cd prospero_collector

# 오늘 날짜로 테스트
python run_local.py

# 특정 날짜로 테스트
python run_local.py 20260330

# 또는 직접 실행
python -c "
from lambda_function import lambda_handler
result = lambda_handler({'date': '20260330'}, None)
print(result)
"
```

### EventBridge 모니터링

- **성공**: 응답 statusCode 200
- **실패**: 에러 로그 확인, 재시도 정책 (권장: 2회 재시도, 2시간)
- **데드레터 큐**: 실패 이벤트 저장 (선택사항)

---

**마지막 업데이트**: 2026년 4월 2일
