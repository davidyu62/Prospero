# prospero_backend - REST API 서버

Prospero의 백엔드 API 서버입니다. iOS 앱과 DynamoDB 간의 데이터 중개 역할을 수행합니다.

---

## 📋 개요

### 역할
- iOS 앱에서 요청한 암호화폐/거시경제 데이터를 DynamoDB에서 조회
- 현재 데이터 + 30일 전 데이터를 함께 반환
- JSON 형식으로 포맷팅하여 응답

### 기술 스택
- **런타임**: Python 3.11 (AWS Lambda)
- **API Gateway**: REST API
- **데이터베이스**: AWS DynamoDB (ap-northeast-2)
- **응답 형식**: JSON (Codable 호환)

---

## 🏗️ 아키텍처

### 호출 흐름

```
┌────────────────────────┐
│     iOS 앱             │
│  (prospero_app)        │
└────────────┬───────────┘
             │
             │ HTTP GET
             ▼
┌────────────────────────────────────────┐
│     API Gateway (REST)                 │
│  /api/crypto-data/db/date-with-previous│
│  /api/macro-data/db/date-with-previous │
└────────────┬───────────────────────────┘
             │
             │ Lambda 프록시 호출
             ▼
┌────────────────────────────────────────┐
│   prospero_backend Lambda               │
│   (api_handler.py)                     │
│                                        │
│  1. 요청 파싱                           │
│  2. DynamoDB 쿼리                      │
│  3. 데이터 포맷팅                      │
│  4. JSON 응답                          │
└────────────┬───────────────────────────┘
             │
             │ 데이터 조회
             ▼
┌────────────────────────────────────────┐
│   AWS DynamoDB (ap-northeast-2)        │
│                                        │
│  TB_CRYPTO_DATA                        │
│  └─ Partition: crypto_id               │
│     Sort: date                         │
│                                        │
│  TB_MACRO_DATA                         │
│  └─ Partition: indicator_id            │
│     Sort: date                         │
└────────────────────────────────────────┘
```

---

## 📡 API 엔드포인트

### 1. Crypto 데이터 조회

**요청**:
```
GET /api/crypto-data/db/date-with-previous?date=20260330
```

**쿼리 파라미터**:
| 파라미터 | 타입 | 설명 |
|---------|------|------|
| date | string | 조회 날짜 (yyyyMMdd 형식, 필수) |

**응답 (200 OK)**:
```json
{
  "crypto": {
    "current": {
      "btc_price": 62500.50,
      "btc_change7d": 3.25,
      "btc_change30d": 12.45,
      "fear_greed_current": 65,
      "fear_greed_avg30d": 58,
      "long_short_ratio": 1.25,
      "open_interest": 28500000000,
      "open_interest_change": 2.5,
      "open_interest_change30d": 8.3
    },
    "30d_ago": {
      "btc_price": 55650.25,
      "btc_change7d": -1.50,
      "btc_change30d": 5.20,
      "fear_greed_current": 48,
      "fear_greed_avg30d": 52,
      "long_short_ratio": 1.10,
      "open_interest": 26300000000,
      "open_interest_change": -1.2,
      "open_interest_change30d": 3.5
    }
  },
  "date": "20260330"
}
```

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| crypto.current | object | 현재 데이터 |
| crypto.30d_ago | object | 30일 전 데이터 |
| date | string | 조회 날짜 |

**에러 응답**:
```json
{
  "error": "데이터 조회 실패",
  "message": "상세 오류 메시지"
}
```

---

### 2. Macro 데이터 조회

**요청**:
```
GET /api/macro-data/db/date-with-previous?date=20260330
```

**쿼리 파라미터**:
| 파라미터 | 타입 | 설명 |
|---------|------|------|
| date | string | 조회 날짜 (yyyyMMdd 형식, 필수) |

**응답 (200 OK)**:
```json
{
  "macro": {
    "current": {
      "interest_rate": 4.33,
      "cpi": 3.2,
      "cpi_change": 0.5,
      "dollar_index": 104.25,
      "dollar_index_change": 1.2,
      "treasury10y": 4.42,
      "treasury10y_change": 0.08,
      "m2": 20500000000000,
      "m2_change": 0.2,
      "unemployment": 3.8,
      "unemployment_change": -0.1
    },
    "30d_ago": {
      "interest_rate": 4.25,
      "cpi": 3.1,
      "cpi_change": 0.3,
      "dollar_index": 103.05,
      "dollar_index_change": -0.5,
      "treasury10y": 4.34,
      "treasury10y_change": 0.02,
      "m2": 20450000000000,
      "m2_change": -0.1,
      "unemployment": 3.9,
      "unemployment_change": 0.05
    }
  },
  "date": "20260330"
}
```

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| macro.current | object | 현재 데이터 |
| macro.30d_ago | object | 30일 전 데이터 |
| date | string | 조회 날짜 |

**에러 응답**:
```json
{
  "error": "데이터 조회 실패",
  "message": "상세 오류 메시지"
}
```

---

## 📂 프로젝트 구조

```
prospero_backend/
├── api_handler.py           # API Gateway 프록시 핸들러 (메인)
├── dynamodb_reader.py       # DynamoDB 조회 로직
├── requirements.txt         # Python 의존성
├── deploy.sh               # Lambda 배포 스크립트
├── README.md               # 이 파일
└── __pycache__/            # Python 캐시
```

---

## 🔧 주요 파일 설명

### api_handler.py

**역할**: API Gateway의 프록시 통합 핸들러 (진입점)

**주요 함수**:
```python
def lambda_handler(event, context):
    """
    API Gateway 프록시 이벤트 처리

    event: {
        'httpMethod': 'GET',
        'path': '/api/crypto-data/db/date-with-previous',
        'queryStringParameters': {'date': '20260330'}
    }
    """
```

**처리 로직**:
1. HTTP 메서드 확인 (GET만 지원)
2. 요청 경로 확인
3. 쿼리 파라미터 추출 (`date`)
4. DynamoDB 조회
5. JSON 응답 반환

**응답 포맷**:
```python
{
    'statusCode': 200,
    'body': json.dumps(data),
    'headers': {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
    }
}
```

---

### dynamodb_reader.py

**역할**: DynamoDB 조회 로직 캡슐화

**주요 클래스**: `DynamoDBReader`

**주요 메서드**:

```python
class DynamoDBReader:
    def __init__(self, region: str = "ap-northeast-2"):
        """DynamoDB 클라이언트 초기화"""

    def get_crypto_data_with_previous(self, date: str) -> Dict:
        """
        현재 데이터 + 30일 전 데이터 조회

        Args:
            date: "yyyyMMdd" 형식의 날짜

        Returns:
            {
                "crypto": {
                    "current": {...},
                    "30d_ago": {...}
                },
                "date": "20260330"
            }
        """

    def get_macro_data_with_previous(self, date: str) -> Dict:
        """
        현재 데이터 + 30일 전 데이터 조회

        Args:
            date: "yyyyMMdd" 형식의 날짜

        Returns:
            {
                "macro": {
                    "current": {...},
                    "30d_ago": {...}
                },
                "date": "20260330"
            }
        """
```

**내부 구현**:
1. 30일 전 날짜 계산
2. DynamoDB에 두 개의 쿼리 실행
3. 결과 통합 및 포맷팅

**DynamoDB 쿼리 예**:
```python
# Crypto 데이터 조회
response = dynamodb.query(
    TableName='TB_CRYPTO_DATA',
    KeyConditionExpression='crypto_id = :id AND #d = :date',
    ExpressionAttributeNames={'#d': 'date'},
    ExpressionAttributeValues={
        ':id': {'S': 'BTC'},
        ':date': {'S': '20260330'}
    }
)
```

---

## 📊 DynamoDB 테이블 구조

### TB_CRYPTO_DATA

| 속성 | 타입 | 설명 |
|------|------|------|
| crypto_id (PK) | String | "BTC" (파티션 키) |
| date (SK) | String | "20260330" (정렬 키) |
| btc_price | Number | BTC 가격 (USD) |
| btc_change7d | Number | 7일 변화율 (%) |
| btc_change30d | Number | 30일 변화율 (%) |
| fear_greed_current | Number | 공포탐욕지수 (현재, 0~100) |
| fear_greed_avg30d | Number | 공포탐욕지수 (30일 평균) |
| long_short_ratio | Number | 롱/숏 비율 |
| open_interest | Number | OI (달러) |
| open_interest_change | Number | OI 변화율 (%) |
| open_interest_change30d | Number | OI 30일 변화율 (%) |
| created_at | String | 생성 시간 (ISO 8601) |

---

### TB_MACRO_DATA

| 속성 | 타입 | 설명 |
|------|------|------|
| indicator_id (PK) | String | "INTEREST_RATE", "CPI" 등 (파티션 키) |
| date (SK) | String | "20260330" (정렬 키) |
| interest_rate | Number | 기준금리 (%) |
| cpi | Number | CPI (%) |
| cpi_change | Number | CPI 변화율 (%) |
| dollar_index | Number | 달러인덱스 |
| dollar_index_change | Number | 달러인덱스 변화 (%) |
| treasury10y | Number | 10년물 Treasury 수익률 (%) |
| treasury10y_change | Number | Treasury 변화 (%) |
| m2 | Number | M2 (통화공급량) |
| m2_change | Number | M2 변화율 (%) |
| unemployment | Number | 실업률 (%) |
| unemployment_change | Number | 실업률 변화 (%) |
| created_at | String | 생성 시간 (ISO 8601) |

---

## 🔄 데이터 흐름 상세

### Crypto 데이터 조회 흐름

```
1. iOS 앱 요청
   GET /api/crypto-data/db/date-with-previous?date=20260330

2. API Gateway
   → Lambda 프록시 호출

3. api_handler.lambda_handler()
   ├─ event 파싱
   ├─ date = "20260330" 추출
   └─ DynamoDBReader.get_crypto_data_with_previous("20260330") 호출

4. DynamoDBReader.get_crypto_data_with_previous()
   ├─ 30일 전 날짜 계산: "20260228"
   ├─ Query 1: crypto_id="BTC", date="20260330"
   ├─ Query 2: crypto_id="BTC", date="20260228"
   └─ 결과 통합 및 반환

5. api_handler가 JSON으로 응답
   {
     "crypto": {
       "current": {...},
       "30d_ago": {...}
     },
     "date": "20260330"
   }

6. iOS 앱이 받아서 Codable로 파싱
   CryptoDashboardData 객체 생성
```

---

## ⚙️ 환경 설정

### AWS IAM 권한 필수

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query",
                "dynamodb:GetItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA"
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

### 환경 변수 (Lambda)

```
AWS_DEFAULT_REGION = ap-northeast-2
DYNAMODB_CRYPTO_TABLE = TB_CRYPTO_DATA
DYNAMODB_MACRO_TABLE = TB_MACRO_DATA
```

---

## 🔐 CORS & API Gateway 설정

### CORS 활성화

API Gateway의 각 메서드에 대해 CORS 활성화:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type
Access-Control-Allow-Methods: GET, OPTIONS
```

### 리소스 구조 (API Gateway)

```
API Gateway: prospero-api
├─ /api
│  ├─ /crypto-data
│  │  └─ /db
│  │     └─ /date-with-previous
│  │        └─ GET (Lambda: prospero-backend)
│  │
│  └─ /macro-data
│     └─ /db
│        └─ /date-with-previous
│           └─ GET (Lambda: prospero-backend)
```

---

## 🧪 로컬 테스트

### Python 테스트

```python
import json
from api_handler import lambda_handler

# Mock event (API Gateway 프록시)
event = {
    'httpMethod': 'GET',
    'path': '/api/crypto-data/db/date-with-previous',
    'queryStringParameters': {'date': '20260330'}
}

result = lambda_handler(event, None)
print(json.dumps(json.loads(result['body']), indent=2))
```

### 직접 DynamoDB 조회

```python
from dynamodb_reader import DynamoDBReader

reader = DynamoDBReader()

# Crypto 데이터
crypto_data = reader.get_crypto_data_with_previous("20260330")
print(crypto_data)

# Macro 데이터
macro_data = reader.get_macro_data_with_previous("20260330")
print(macro_data)
```

---

## 📈 성능 고려사항

### DynamoDB 최적화

1. **파티션 키 설계**: crypto_id / indicator_id로 분산
2. **정렬 키**: date로 시간순 정렬
3. **쿼리 전략**: 정확한 파티션 키 사용으로 효율적 조회
4. **읽기 용량**: 온디맨드(Pay-per-request) 권장

### Lambda 최적화

1. **메모리**: 256MB 이상 권장
2. **타임아웃**: 30초 (충분한 DynamoDB 응답 시간)
3. **콜드 스타트**: VPC 미사용으로 최소화

---

## 🐛 에러 처리

### 가능한 에러 케이스

| 상황 | 상태 코드 | 메시지 |
|------|----------|--------|
| date 파라미터 누락 | 400 | "date 파라미터 필수" |
| 유효하지 않은 date 형식 | 400 | "date는 yyyyMMdd 형식" |
| 데이터 없음 | 404 | "해당 날짜의 데이터 없음" |
| DynamoDB 오류 | 500 | "데이터베이스 조회 실패" |
| 기타 서버 오류 | 500 | "서버 오류" |

### 에러 응답 형식

```json
{
    "statusCode": 400,
    "body": {
        "error": "잘못된 요청",
        "message": "date 파라미터는 필수입니다"
    }
}
```

---

## 📝 주요 고려사항

1. **시간대**: 데이터는 UTC 기반, 클라이언트에서 로컬 시간대로 변환
2. **날짜 형식**: yyyyMMdd 형식 엄격히 준수
3. **데이터 가용성**: 30일 이전 데이터 없을 시 부분 응답
4. **성능**: DynamoDB 온디맨드로 변동 트래픽 처리
5. **보안**: API Gateway에서 API 키 또는 AWS_IAM 인증 권장

---

**Last Updated**: 2026년 3월 30일
