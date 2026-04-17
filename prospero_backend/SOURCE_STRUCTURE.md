# prospero_backend 소스 코드 구조 및 역할

## 📂 프로젝트 구조

```
prospero_backend/
├── api_handler.py           # [메인] API Gateway 프록시 핸들러
├── dynamodb_reader.py       # [핵심] DynamoDB 조회 로직
├── deploy.sh                # 배포 스크립트
├── .gitignore               # Git 무시 파일 설정
├── README.md                # 프로젝트 개요
├── ARCHITECTURE.md          # 아키텍처 상세 설명
├── ENDPOINTS.md             # API 엔드포인트 가이드
├── SOURCE_STRUCTURE.md      # 이 파일
├── DEPLOYMENT.md            # (선택) 배포 가이드
├── requirements.txt         # Python 의존성
├── prospero_backend.zip     # Lambda 배포 패키지
└── __pycache__/             # Python 캐시 디렉토리
```

---

## 🔴 api_handler.py - API 진입점

**역할**: API Gateway 프록시 통합을 통해 모든 HTTP 요청을 처리하는 Lambda 진입점

**크기**: ~217줄

### 주요 구성

#### 1. 상수

```python
CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
}
```
모든 응답에 포함될 CORS 헤더. 크로스 오리진 요청 허용.

#### 2. 메인 핸들러: `lambda_handler(event, context)`

**호출**: AWS Lambda에서 API Gateway 프록시 이벤트 수신 시

**매개변수**:
- `event`: API Gateway에서 전달한 프록시 이벤트
  ```python
  {
      "httpMethod": "GET",
      "path": "/api/crypto-data/db/date-with-previous",
      "queryStringParameters": {"date": "20260330"}
  }
  ```
- `context`: Lambda 런타임 컨텍스트 (사용하지 않음)

**처리 흐름**:
```python
def lambda_handler(event, context):
    try:
        # 1단계: API Gateway와 Lambda URL 두 형식 지원
        http_method = event.get("httpMethod") or event.get("requestContext", {}).get("http", {}).get("method", "")
        path = event.get("path") or event.get("requestContext", {}).get("http", {}).get("path", "")
        params = event.get("queryStringParameters") or {}
        date = params.get("date")

        # 2단계: CORS preflight 처리
        if http_method == "OPTIONS":
            return _response(200, {})

        # 3단계: 경로별 핸들러 호출
        if "/api/crypto-data/7days" in path:
            return _handle_crypto_7days(date)
        # ... 기타 경로들

        # 4단계: 매칭되는 경로 없음
        return _response(404, {"error": "Not Found"})

    except Exception as e:
        return _response(500, {"error": str(e)})
```

**지원하는 경로**:
1. `/api/crypto-data/7days` → 7일 크립토 데이터
2. `/api/crypto-data/today` → 오늘 크립토 데이터
3. `/api/crypto-data/db/date-with-previous` → 크립토 + 전날 데이터
4. `/api/crypto-data/db/date` → 특정 날짜 크립토 데이터
5. `/api/macro-data/today` → 오늘 매크로 데이터
6. `/api/macro-data/db/date-with-previous` → 매크로 + 전날 데이터
7. `/api/macro-data/db/date` → 특정 날짜 매크로 데이터
8. `/api/ai-analysis/date` → AI 분석 데이터

#### 3. 크립토 핸들러 함수들

**`_handle_crypto_today()`** (69-77줄)
- **역할**: 오늘 크립토 데이터 조회
- **호출**: `/api/crypto-data/today`
- **로직**:
  ```python
  today = datetime.now().strftime("%Y%m%d")  # "20260402"
  data = get_crypto_data_by_date(today)
  return _response(200, _crypto_to_item(today, data))
  ```

**`_handle_crypto_by_date(date: str)`** (80-90줄)
- **역할**: 특정 날짜 크립토 데이터 조회
- **호출**: `/api/crypto-data/db/date?date=20260330`
- **검증**: date 길이 == 8
- **로직**:
  ```python
  data = get_crypto_data_by_date(date)
  if not data:
      return _response(404, {"error": f"해당 날짜({date})의 크립토 데이터가 없습니다."})
  return _response(200, _crypto_to_item(date, data))
  ```

**`_handle_crypto_date_with_previous(date: str)`** (93-111줄)
- **역할**: 크립토 현재 + 전날 데이터 조회 (가장 자주 사용)
- **호출**: `/api/crypto-data/db/date-with-previous?date=20260330`
- **검증**: date 길이 == 8
- **로직**:
  ```python
  prev_date = (datetime.strptime(date, "%Y%m%d") - timedelta(days=1)).strftime("%Y%m%d")
  request_data = get_crypto_data_by_date(date)
  previous_data = get_crypto_data_by_date(prev_date)

  return _response(200, {
      "requestDate": date,
      "previousDate": prev_date,
      "data": {
          "requestDate": _crypto_to_item(date, request_data),
          "previousDate": _crypto_to_item(prev_date, previous_data),
      }
  })
  ```

**`_handle_crypto_7days(date: str)`** (184-194줄)
- **역할**: 7일 크립토 데이터 조회 (시계열 용도)
- **호출**: `/api/crypto-data/7days?date=20260330`
- **로직**:
  ```python
  data_7days = get_crypto_data_7days(date)
  return _response(200, data_7days)
  ```
- **반환 형식**: 배열 형식 (dates, btcPrices, longShortRatios, fearGreedIndices, openInterests)

#### 4. 매크로 핸들러 함수들

**`_handle_macro_today()`** (114-122줄)
- 오늘 매크로 데이터 조회

**`_handle_macro_by_date(date: str)`** (125-135줄)
- 특정 날짜 매크로 데이터 조회

**`_handle_macro_date_with_previous(date: str)`** (138-156줄)
- 매크로 현재 + 전날 데이터 조회 (크립토와 동일 구조)

#### 5. AI 분석 핸들러

**`_handle_ai_analysis_date(date: str)`** (171-181줄)
- **역할**: AI 분석 데이터 조회
- **호출**: `/api/ai-analysis/date?date=20260330`
- **로직**:
  ```python
  analysis_data = get_ai_analysis_by_date(date)
  return _response(200, analysis_data)
  ```

#### 6. 데이터 포맷팅 함수

**`_crypto_to_item(date: str, data: dict | None) -> dict | None`** (159-168줄)
- **역할**: DynamoDB 조회 결과를 응답 형식으로 변환
- **입력**: DynamoDB 아이템 (dict)
- **출력**:
  ```python
  {
      "date": "20260330",
      "btcPrice": 62500.50,
      "longShortRatio": 1.25,
      "fearGreedIndex": 65,
      "openInterest": 28500000000
  }
  ```
- **처리**: data가 None이면 None 반환

**`_macro_to_item(date: str, data: dict | None) -> dict | None`** (197-208줄)
- **역할**: 매크로 데이터 포맷팅
- **출력**:
  ```python
  {
      "date": "20260330",
      "interestRate": 4.50,
      "treasury10y": 4.25,
      "cpi": 3.2,
      "m2": 20500000000000,
      "unemployment": 3.8,
      "dollarIndex": 104.25
  }
  ```

#### 7. HTTP 응답 생성

**`_response(status_code: int, body: dict) -> dict`** (211-216줄)
- **역할**: Lambda 프록시 응답 형식 생성
- **입력**: HTTP 상태 코드, 응답 바디
- **출력**:
  ```python
  {
      "statusCode": 200,
      "headers": {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "Content-Type"
      },
      "body": "{...json...}"
  }
  ```

---

## 🔵 dynamodb_reader.py - DynamoDB 조회 계층

**역할**: DynamoDB 테이블(TB_CRYPTO_DATA, TB_MACRO_DATA, TB_AI_INSIGHT)에서 데이터를 조회하고 변환

**크기**: ~247줄

### 주요 구성

#### 1. 테이블 이름 관리

**`get_table_names() -> tuple[str, str]`** (12-16줄)
- **역할**: 환경 변수에서 테이블 이름 조회
- **반환**:
  ```python
  (
      os.environ.get("DYNAMODB_CRYPTO_TABLE", "TB_CRYPTO_DATA"),
      os.environ.get("DYNAMODB_MACRO_TABLE", "TB_MACRO_DATA")
  )
  ```
- **목적**: 테이블 이름을 코드가 아닌 환경 변수로 관리

#### 2. 크립토 데이터 조회

**`get_crypto_data_by_date(date: str) -> Optional[dict]`** (19-29줄)
- **역할**: 특정 날짜의 크립토 데이터 조회
- **매개변수**: date (yyyyMMdd 형식)
- **로직**:
  ```python
  crypto_table, _ = get_table_names()
  item = _query_latest_by_date(crypto_table, date)
  return _item_to_crypto(item) if item else None
  ```
- **반환**:
  ```python
  {
      "btcPrice": 62500.50,
      "longShortRatio": 1.25,
      "fearGreedIndex": 65,
      "openInterest": 28500000000
  }
  ```

#### 3. 매크로 데이터 조회

**`get_macro_data_by_date(date: str) -> Optional[dict]`** (32-42줄)
- **역할**: 특정 날짜의 매크로 데이터 조회
- **반환**:
  ```python
  {
      "interestRate": 4.50,
      "treasury10y": 4.25,
      "cpi": 3.2,
      "m2": 20500000000000,
      "unemployment": 3.8,
      "dollarIndex": 104.25
  }
  ```

#### 4. DynamoDB 쿼리/스캔 폴백

**`_query_latest_by_date(table_name: str, date: str) -> Optional[dict]`** (45-86줄)

**목적**: 두 가지 키 스키마를 지원하기 위한 유연한 조회

**1단계: Query 시도** (50-64줄)
```python
resp = client.query(
    TableName=table_name,
    KeyConditionExpression="#date = :date",
    ExpressionAttributeNames={"#date": "date"},
    ExpressionAttributeValues={":date": {"S": date}},
    ScanIndexForward=False,  # 내림차순
    Limit=1
)
```
- 파티션 키가 `date`인 경우 사용
- 가장 빠름 (O(1) 또는 O(log n))

**2단계: Scan 폴백** (68-83줄)
```python
resp = client.scan(
    TableName=table_name,
    FilterExpression="#date = :date",
    ExpressionAttributeNames={"#date": "date"},
    ExpressionAttributeValues={":date": {"S": date}},
    Limit=100
)
```
- Query 실패 시 (예: 파티션 키가 다른 스키마)
- 최대 100개 아이템 스캔 후 `timestamps` 기준 최신 1건 선택
- 느림 (O(n))

**주의**: Scan 실패 시 서버 오류 반환

#### 5. 데이터 타입 변환

**`_n_to_float(av: dict) -> Optional[float]`** (89-96줄)
- DynamoDB Number → Python float

**`_n_to_int(av: dict) -> Optional[int]`** (99-106줄)
- DynamoDB Number → Python int

**예시**:
```python
# DynamoDB 형식
av = {"N": "62500.50"}

# 변환 결과
_n_to_float(av)  # 62500.50 (float)
_n_to_int(av)    # 62500 (int)
```

#### 6. 크립토 데이터 변환

**`_item_to_crypto(item: dict) -> dict`** (109-116줄)
- DynamoDB 아이템 → Crypto 데이터
- 필드:
  - btcPrice: float
  - longShortRatio: float
  - fearGreedIndex: int
  - openInterest: float

**`_item_to_crypto_with_date(date: str, item: dict) -> dict`** (238-246줄)
- Crypto 데이터 + 날짜 포함
- 7일 조회 시 사용

#### 7. 매크로 데이터 변환

**`_item_to_macro(item: dict) -> dict`** (119-128줄)
- DynamoDB 아이템 → Macro 데이터
- 필드:
  - interestRate: float
  - treasury10y: float
  - cpi: float
  - m2: float
  - unemployment: float
  - dollarIndex: float

#### 8. AI 분석 데이터 조회

**`get_ai_analysis_by_date(date: str) -> Optional[dict]`** (131-150줄)
- **역할**: TB_AI_INSIGHT에서 분석 데이터 조회
- **로직**:
  ```python
  client.get_item(
      TableName="TB_AI_INSIGHT",
      Key={"date": {"S": date}}
  )
  ```
- GetItem 사용 (Query보다 빠름)
- 데이터 없으면 None 반환

**`_item_to_ai_analysis(item: dict) -> dict`** (153-202줄)
- **역할**: DynamoDB 아이템 → AI 분석 결과
- **주요 처리**:
  - 각 스코어 필드를 float로 변환
  - `indicator_explanations` JSON 파싱 (한글)
  - `indicator_explanations_en` JSON 파싱 (영어)
  - 파싱 실패 시 빈 dict 반환
- **반환 필드** (20개):
  - date, total_score, signal_type, signal_color
  - crypto_score, macro_score
  - 각 지표별 점수 (btc_trend_score, fear_greed_score 등)
  - analysis_summary, analysis_summary_en
  - indicator_explanations, indicator_explanations_en

#### 9. 7일 크립토 데이터

**`get_crypto_data_7days(date: str) -> dict`** (205-235줄)
- **역할**: 특정 날짜로부터 과거 7일 크립토 데이터 조회
- **로직**:
  ```python
  from datetime import datetime, timedelta

  data_list = []
  current_date = datetime.strptime(date, "%Y%m%d")

  # 과거 7일 조회
  for i in range(7):
      target_date = (current_date - timedelta(days=i)).strftime("%Y%m%d")
      item = _query_latest_by_date(crypto_table, target_date)
      if item:
          data_list.append(_item_to_crypto_with_date(target_date, item))

  # 날짜 역순 정렬 (오래된 것부터)
  data_list.sort(key=lambda x: x["date"])
  ```
- **반환 형식**: 배열별 리스트
  ```python
  {
      "dates": ["20260324", "20260325", ..., "20260330"],
      "btcPrices": [59800.25, 60200.50, ..., 62500.50],
      "longShortRatios": [...],
      "fearGreedIndices": [...],
      "openInterests": [...]
  }
  ```

---

## 📋 의존성 (requirements.txt)

```
boto3          # AWS SDK (Lambda 런타임에 포함, 배포 패키지에서 생략 가능)
requests       # (현재 미사용, 향후 외부 API 호출 시 필요)
```

**주의**: Lambda 런타임에 boto3가 포함되므로, 배포 패키지에는 포함하지 않아도 됨.

---

## 🔧 deploy.sh - 배포 스크립트

**역할**: 소스 코드를 ZIP 파일로 압축하여 Lambda에 배포 가능하게 만듦

**구조**:
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 prospero_backend 압축 중..."

# 기존 zip 삭제
rm -f prospero_backend.zip

# 필수 파일만 압축
zip -q prospero_backend.zip \
    api_handler.py \
    dynamodb_reader.py

echo "✅ 완료: prospero_backend.zip"
```

**사용**:
```bash
./deploy.sh
```

**출력**:
```
📦 prospero_backend 압축 중...
✅ 완료: prospero_backend.zip (15K)
```

---

## 🎯 호출 흐름 (복합 요청)

### 예: 크립토 현재 + 전날 데이터 요청

```
1. API Gateway → lambda_handler(event, context)
   event = {
       "httpMethod": "GET",
       "path": "/api/crypto-data/db/date-with-previous",
       "queryStringParameters": {"date": "20260330"}
   }

2. lambda_handler()
   ├─ http_method = "GET"
   ├─ path = "/api/crypto-data/db/date-with-previous"
   ├─ date = "20260330"
   ├─ 경로 매칭
   └─ _handle_crypto_date_with_previous("20260330") 호출

3. _handle_crypto_date_with_previous("20260330")
   ├─ prev_date = "20260329"
   ├─ request_data = get_crypto_data_by_date("20260330")
   │  ├─ _query_latest_by_date("TB_CRYPTO_DATA", "20260330")
   │  │  ├─ Query 시도 → 성공
   │  │  └─ items[0] 반환
   │  ├─ _item_to_crypto(item)
   │  │  └─ {"btcPrice": 62500.50, ...}
   │  └─ 반환
   │
   ├─ previous_data = get_crypto_data_by_date("20260329")
   │  ├─ _query_latest_by_date("TB_CRYPTO_DATA", "20260329")
   │  ├─ _item_to_crypto(item)
   │  └─ 반환
   │
   └─ 통합 결과 반환

4. _response(200, body)
   └─ API Gateway 프록시 형식 반환

5. API Gateway → iOS 앱
   ├─ HTTP 200
   └─ JSON 바디
```

---

## 💡 설계 패턴

### 1. 계층 분리 (Layered Architecture)

- **api_handler.py**: HTTP 프로토콜 계층
  - 요청 파싱, 경로 분기, 응답 형식

- **dynamodb_reader.py**: 데이터 접근 계층
  - DynamoDB 쿼리, 데이터 변환

### 2. 폴백 메커니즘 (Fallback)

DynamoDB Query 실패 → Scan으로 자동 폴백
- 유연성: 키 스키마 변경에 강함
- 성능 저하: Scan은 느림 (최대 100개 아이템만 검색)

### 3. 날짜 계산

```python
prev_date = (datetime.strptime(date, "%Y%m%d") - timedelta(days=1)).strftime("%Y%m%d")
```
- 문자열 → datetime → timedelta → 문자열
- 타임존 미적용 (UTC로 취급)

### 4. Optional 처리

```python
data = get_crypto_data_by_date(date)  # Optional[dict]
if not data:
    return _response(404, {"error": "..."})
```
- 데이터 없을 때 명시적으로 404 반환
- API 응답 일관성 유지

---

## 🚀 성능 최적화 포인트

1. **DynamoDB Query**: 파티션 키 사용으로 O(log n) 성능
2. **Scan 회피**: Query 실패 시에만 Scan 사용
3. **배열 조회**: 7일 데이터는 배열 형식으로 하나의 응답으로 반환
4. **GetItem**: AI 분석 데이터는 date만 키이므로 GetItem 사용 (빠름)

---

## 🐛 에러 처리 전략

| 함수 | 에러 처리 |
|------|---------|
| `lambda_handler()` | try-except로 모든 예외 캐치, 500 반환 |
| `_query_latest_by_date()` | Query 실패 시 Scan 폴백, 둘 다 실패 시 None 반환 |
| `_item_to_crypto()` | None 입력 시 None 반환 |
| `_item_to_ai_analysis()` | JSON 파싱 실패 시 빈 dict {} 반환 |
| `get_crypto_data_7days()` | 데이터 없으면 빈 배열 반환 |

---

**마지막 업데이트**: 2026년 4월 2일
