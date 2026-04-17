# prospero_backend 아키텍처

## 📐 시스템 아키텍처

### 전체 구조

```
┌─────────────────────────┐
│     iOS 앱             │
│   (prospero_app)       │
└────────────┬────────────┘
             │ HTTP GET
             │ (쿼리: date=yyyyMMdd)
             ▼
┌─────────────────────────────────────────┐
│     API Gateway (REST)                  │
│                                         │
│  /api/crypto-data/*                    │
│  /api/macro-data/*                     │
│  /api/ai-analysis/*                    │
└────────────┬────────────────────────────┘
             │ Lambda 프록시 통합
             │
             ▼
┌─────────────────────────────────────────┐
│   prospero_backend Lambda               │
│   (Python 3.11)                        │
│                                         │
│  ├─ api_handler.py (진입점)            │
│  │  └─ lambda_handler(event, context)  │
│  │     ├─ 요청 파싱                    │
│  │     ├─ 경로 분기                    │
│  │     └─ 응답 생성                    │
│  │                                     │
│  └─ dynamodb_reader.py                 │
│     ├─ get_crypto_data_by_date()      │
│     ├─ get_macro_data_by_date()       │
│     ├─ get_ai_analysis_by_date()      │
│     └─ get_crypto_data_7days()        │
└────────────┬────────────────────────────┘
             │ DynamoDB 쿼리/스캔
             │
             ▼
┌─────────────────────────────────────────┐
│   AWS DynamoDB (ap-northeast-2)        │
│                                         │
│  TB_CRYPTO_DATA                        │
│  ├─ PK: date                           │
│  └─ SK: timestamps                     │
│                                         │
│  TB_MACRO_DATA                         │
│  ├─ PK: date                           │
│  └─ SK: timestamps                     │
│                                         │
│  TB_AI_INSIGHT                         │
│  └─ PK: date                           │
└─────────────────────────────────────────┘
```

---

## 🔄 요청-응답 흐름

### 1. Crypto 데이터 조회 (`/api/crypto-data/db/date-with-previous`)

```
1️⃣ iOS 앱 요청
   GET /api/crypto-data/db/date-with-previous?date=20260330

2️⃣ API Gateway
   → Lambda 프록시 통합 호출
   event = {
       "httpMethod": "GET",
       "path": "/api/crypto-data/db/date-with-previous",
       "queryStringParameters": {"date": "20260330"}
   }

3️⃣ lambda_handler (api_handler.py:24-66)
   ├─ HTTP 메서드 확인 (GET)
   ├─ 경로 매칭: "/api/crypto-data/db/date-with-previous" 발견
   ├─ 쿼리 파라미터 추출: date = "20260330"
   └─ _handle_crypto_date_with_previous("20260330") 호출

4️⃣ _handle_crypto_date_with_previous (api_handler.py:93-111)
   ├─ 이전 날짜 계산: "20260329"
   ├─ get_crypto_data_by_date("20260330") → DynamoDB 쿼리
   ├─ get_crypto_data_by_date("20260329") → DynamoDB 쿼리
   └─ 결과 통합: {
       "requestDate": "20260330",
       "previousDate": "20260329",
       "data": {
           "requestDate": {...},
           "previousDate": {...}
       }
   }

5️⃣ DynamoDB 조회 (dynamodb_reader.py:19-29)
   ├─ Query 시도: date="20260330"로 쿼리
   ├─ Query 실패 시 Scan 폴백
   ├─ timestamps 내림차순 정렬
   └─ 최신 1건 반환

6️⃣ 데이터 포맷팅 (api_handler.py:159-168)
   {
       "date": "20260330",
       "btcPrice": 62500.50,
       "longShortRatio": 1.25,
       "fearGreedIndex": 65,
       "openInterest": 28500000000
   }

7️⃣ HTTP 응답 (api_handler.py:211-216)
   {
       "statusCode": 200,
       "headers": {
           "Content-Type": "application/json",
           "Access-Control-Allow-Origin": "*"
       },
       "body": "{...}"
   }

8️⃣ iOS 앱
   → JSON 파싱
   → Codable로 모델 생성
   → UI 갱신
```

### 2. AI 분석 데이터 조회 (`/api/ai-analysis/date`)

```
1️⃣ iOS 앱 요청
   GET /api/ai-analysis/date?date=20260330

2️⃣ lambda_handler
   → _handle_ai_analysis_date("20260330") 호출

3️⃣ get_ai_analysis_by_date (dynamodb_reader.py:131-150)
   ├─ TB_AI_INSIGHT 테이블에서 GetItem
   ├─ Key: {"date": "20260330"}
   └─ 분석 데이터 전체 반환

4️⃣ _item_to_ai_analysis 변환 (dynamodb_reader.py:153-202)
   ├─ 각 스코어 필드 float 변환
   ├─ indicator_explanations JSON 파싱
   ├─ indicator_explanations_en JSON 파싱
   └─ 완성된 객체 반환

5️⃣ HTTP 응답
   {
       "date": "20260330",
       "total_score": 72.5,
       "signal_type": "강한 매수",
       "signal_color": "green",
       "crypto_score": 75.0,
       "macro_score": 70.0,
       ...
       "indicator_explanations": {...},
       "indicator_explanations_en": {...}
   }
```

---

## 🏗️ 컴포넌트별 역할

### api_handler.py - API 진입점

| 함수 | 역할 | 호출 시점 |
|------|------|---------|
| `lambda_handler()` | 모든 요청 처리, 경로 분기 | API Gateway에서 호출 |
| `_handle_crypto_today()` | 오늘 Crypto 데이터 | `/api/crypto-data/today` |
| `_handle_crypto_by_date()` | 특정 날짜 Crypto 데이터 | `/api/crypto-data/db/date?date=...` |
| `_handle_crypto_date_with_previous()` | Crypto + 전날 데이터 | `/api/crypto-data/db/date-with-previous?date=...` |
| `_handle_crypto_7days()` | 7일 Crypto 데이터 | `/api/crypto-data/7days?date=...` |
| `_handle_macro_today()` | 오늘 Macro 데이터 | `/api/macro-data/today` |
| `_handle_macro_by_date()` | 특정 날짜 Macro 데이터 | `/api/macro-data/db/date?date=...` |
| `_handle_macro_date_with_previous()` | Macro + 전날 데이터 | `/api/macro-data/db/date-with-previous?date=...` |
| `_handle_ai_analysis_date()` | AI 분석 데이터 | `/api/ai-analysis/date?date=...` |
| `_crypto_to_item()` | Crypto 데이터 포맷팅 | 응답 생성 전 |
| `_macro_to_item()` | Macro 데이터 포맷팅 | 응답 생성 전 |
| `_response()` | HTTP 응답 생성 | 모든 응답에서 |

### dynamodb_reader.py - 데이터 조회 계층

| 함수 | 역할 | 호출자 |
|------|------|--------|
| `get_crypto_data_by_date()` | TB_CRYPTO_DATA에서 날짜별 조회 | api_handler |
| `get_macro_data_by_date()` | TB_MACRO_DATA에서 날짜별 조회 | api_handler |
| `get_ai_analysis_by_date()` | TB_AI_INSIGHT에서 날짜별 조회 | api_handler |
| `get_crypto_data_7days()` | TB_CRYPTO_DATA에서 7일 조회 | api_handler |
| `_query_latest_by_date()` | DynamoDB Query/Scan 실행 | Crypto, Macro 조회 |
| `_item_to_crypto()` | DynamoDB 아이템을 Crypto 객체로 변환 | get_crypto_data_by_date |
| `_item_to_macro()` | DynamoDB 아이템을 Macro 객체로 변환 | get_macro_data_by_date |
| `_item_to_ai_analysis()` | DynamoDB 아이템을 AI 분석 객체로 변환 | get_ai_analysis_by_date |
| `_item_to_crypto_with_date()` | Crypto 아이템 + 날짜 변환 | get_crypto_data_7days |

---

## 📊 DynamoDB 쿼리 전략

### Query vs Scan 폴백

**상황**: TB_CRYPTO_DATA / TB_MACRO_DATA에 두 가지 키 스키마가 있을 수 있음

**1단계: Query (빠름, 파티션 키 필수)**
```python
client.query(
    TableName=table_name,
    KeyConditionExpression="#date = :date",
    ExpressionAttributeNames={"#date": "date"},
    ExpressionAttributeValues={":date": {"S": "20260330"}},
    ScanIndexForward=False,  # 내림차순 (최신 먼저)
    Limit=1
)
```

**2단계: Scan 폴백 (느림, 필터 기반)**
```python
client.scan(
    TableName=table_name,
    FilterExpression="#date = :date",
    ExpressionAttributeNames={"#date": "date"},
    ExpressionAttributeValues={":date": {"S": "20260330"}},
    Limit=100
)
```
- Query 실패 시 (파티션 키 불일치 등)
- 모든 아이템을 스캔한 후 `timestamps` 기준 최신 1건 선택

### AI 분석 데이터 조회

```python
client.get_item(
    TableName="TB_AI_INSIGHT",
    Key={"date": {"S": "20260330"}}
)
```
- GetItem 사용 (더 빠름)
- TB_AI_INSIGHT는 date만이 키

---

## 🔐 CORS & 에러 처리

### CORS 설정

모든 응답에 다음 헤더 포함:
```python
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
}
```

OPTIONS 요청 (preflight) 처리:
```python
if http_method == "OPTIONS":
    return _response(200, {})
```

### 에러 처리 전략

| 상황 | 상태 코드 | 메시지 |
|------|----------|--------|
| date 파라미터 누락 또는 형식 오류 | 400 | "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요." |
| DynamoDB에 데이터 없음 | 404 | "해당 날짜(20260330)의 크립토 데이터가 없습니다." |
| DynamoDB 쿼리/Scan 실패 | 500 | 에러 메시지 |
| 미지원 경로 | 404 | "Not Found" |
| 예상 밖의 예외 | 500 | 에러 메시지 |

---

## 🎯 데이터 흐름 예시: "크립토 + 전날" 요청

```
입력: GET /api/crypto-data/db/date-with-previous?date=20260330

1. api_handler.lambda_handler(event, context)
   ├─ httpMethod = "GET"
   ├─ path = "/api/crypto-data/db/date-with-previous"
   ├─ date = "20260330"
   └─ _handle_crypto_date_with_previous("20260330") 호출

2. _handle_crypto_date_with_previous("20260330")
   ├─ 이전 날짜 계산: prev_date = "20260329"
   ├─ request_data = get_crypto_data_by_date("20260330")
   └─ previous_data = get_crypto_data_by_date("20260329")

3. get_crypto_data_by_date("20260330") [첫 번째 호출]
   ├─ _query_latest_by_date("TB_CRYPTO_DATA", "20260330")
   │  ├─ Query: date="20260330" → 성공
   │  └─ items[0] 반환
   ├─ _item_to_crypto(item)
   │  └─ {
   │      "btcPrice": 62500.50,
   │      "longShortRatio": 1.25,
   │      "fearGreedIndex": 65,
   │      "openInterest": 28500000000
   │  }
   └─ 반환

4. get_crypto_data_by_date("20260329") [두 번째 호출]
   ├─ _query_latest_by_date("TB_CRYPTO_DATA", "20260329")
   ├─ _item_to_crypto(item)
   └─ 반환

5. _handle_crypto_date_with_previous에서 통합
   {
       "requestDate": "20260330",
       "previousDate": "20260329",
       "data": {
           "requestDate": {
               "date": "20260330",
               "btcPrice": 62500.50,
               "longShortRatio": 1.25,
               "fearGreedIndex": 65,
               "openInterest": 28500000000
           },
           "previousDate": {
               "date": "20260329",
               "btcPrice": 61800.25,
               ...
           }
       }
   }

6. _response(200, body) → JSON 응답 생성
   {
       "statusCode": 200,
       "headers": {...},
       "body": "{...json...}"
   }

출력: HTTP 200 + JSON 바디
```

---

## ⚡ 성능 최적화

### Lambda 설정
- **메모리**: 256MB 이상 (권장 512MB)
- **타임아웃**: 30초
- **VPC**: 미사용 (콜드 스타트 최소화)

### DynamoDB 최적화
- **온디맨드**: Pay-per-request 권장 (변동 트래픽)
- **Query 선호**: 파티션 키로 빠른 조회
- **Scan 회피**: 폴백으로만 사용

### 캐싱 고려사항
- iOS 앱에서 응답을 로컬 캐시
- 같은 날짜 재요청 시 API 호출 스킵

---

## 🔍 디버깅

### 로그 확인
```
CloudWatch Logs
└─ /aws/lambda/prospero-retrieval (또는 함수명)
   ├─ [DEBUG] path=..., date=..., httpMethod=...
   ├─ [INFO] DynamoDB Query 성공
   ├─ [WARN] DynamoDB Query 실패 (폴백 중)
   ├─ [INFO] DynamoDB Scan 폴백 성공
   └─ [ERROR] ...
```

### 로컬 테스트
```python
from api_handler import lambda_handler

event = {
    'httpMethod': 'GET',
    'path': '/api/crypto-data/db/date-with-previous',
    'queryStringParameters': {'date': '20260330'}
}

result = lambda_handler(event, None)
print(result)
```

---

**마지막 업데이트**: 2026년 4월 2일
