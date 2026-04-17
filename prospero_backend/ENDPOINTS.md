# prospero_backend API 엔드포인트

## 📡 엔드포인트 목록

### 📖 조회 (READ) - 데이터 읽기

| 메서드 | 경로 | 설명 | 작업 |
|--------|------|------|------|
| GET | `/api/crypto-data/db/date-with-previous` | 크립토 현재 + 전날 데이터 | 📖 조회 |
| GET | `/api/crypto-data/db/date` | 크립토 특정 날짜 데이터 | 📖 조회 |
| GET | `/api/crypto-data/today` | 크립토 오늘 데이터 | 📖 조회 |
| GET | `/api/crypto-data/7days` | 크립토 7일 데이터 | 📖 조회 |
| GET | `/api/macro-data/db/date-with-previous` | 매크로 현재 + 전날 데이터 | 📖 조회 |
| GET | `/api/macro-data/db/date` | 매크로 특정 날짜 데이터 | 📖 조회 |
| GET | `/api/macro-data/today` | 매크로 오늘 데이터 | 📖 조회 |
| GET | `/api/ai-analysis/date` | AI 분석 데이터 | 📖 조회 |

### 💾 생성 (CREATE) - 새 데이터 저장

| 메서드 | 경로 | 설명 | 작업 |
|--------|------|------|------|
| POST | `/api/crypto-data/db` | 새 크립토 데이터 저장 | 💾 저장 |
| POST | `/api/macro-data/db` | 새 매크로 데이터 저장 | 💾 저장 |
| POST | `/api/ai-analysis/db` | 새 AI 분석 데이터 저장 | 💾 저장 |

### ✏️ 수정 (UPDATE) - 기존 데이터 수정

| 메서드 | 경로 | 설명 | 작업 |
|--------|------|------|------|
| PUT | `/api/crypto-data/db` | 크립토 데이터 수정 | ✏️ 수정 |
| PUT | `/api/macro-data/db` | 매크로 데이터 수정 | ✏️ 수정 |
| PUT | `/api/ai-analysis/db` | AI 분석 데이터 수정 | ✏️ 수정 |

### 🗑️ 삭제 (DELETE) - 데이터 삭제

| 메서드 | 경로 | 설명 | 작업 |
|--------|------|------|------|
| DELETE | `/api/crypto-data/db/date` | 특정 날짜 크립토 데이터 삭제 | 🗑️ 삭제 |
| DELETE | `/api/macro-data/db/date` | 특정 날짜 매크로 데이터 삭제 | 🗑️ 삭제 |
| DELETE | `/api/ai-analysis/date` | 특정 날짜 AI 분석 데이터 삭제 | 🗑️ 삭제 |

---

## 1️⃣ 크립토 데이터: 현재 + 전날

### 요청

```http
GET /api/crypto-data/db/date-with-previous?date=20260330
```

**쿼리 파라미터**:
| 이름 | 타입 | 필수 | 형식 | 예시 |
|------|------|------|------|------|
| date | string | ✅ | yyyyMMdd | 20260330 |

### 응답

**상태 코드**: 200 OK

```json
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
      "longShortRatio": 1.22,
      "fearGreedIndex": 62,
      "openInterest": 28200000000
    }
  }
}
```

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| requestDate | string | 요청한 날짜 (yyyyMMdd) |
| previousDate | string | 이전 날짜 (yyyyMMdd) |
| data.requestDate | object | 요청 날짜의 크립토 데이터 |
| data.previousDate | object | 이전 날짜의 크립토 데이터 |
| btcPrice | number | BTC 가격 (USD) |
| longShortRatio | number | 롱/숏 비율 |
| fearGreedIndex | integer | 공포탐욕지수 (0~100) |
| openInterest | number | 오픈 인터레스트 (달러) |

### 에러 응답

**400 Bad Request** (date 파라미터 오류):
```json
{
  "error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."
}
```

**404 Not Found** (데이터 없음):
```json
{
  "error": "해당 날짜(20260330)의 크립토 데이터가 없습니다."
}
```

### 예시 (cURL)

```bash
curl -X GET \
  "https://api-gateway-url/api/crypto-data/db/date-with-previous?date=20260330" \
  -H "Content-Type: application/json"
```

### 예시 (Swift)

```swift
let url = URL(string: "https://api-gateway-url/api/crypto-data/db/date-with-previous?date=20260330")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    let decoder = JSONDecoder()
    let result = try decoder.decode(CryptoDateWithPrevious.self, from: data!)
    print(result)
}
task.resume()
```

---

## 2️⃣ 크립토 데이터: 특정 날짜

### 요청

```http
GET /api/crypto-data/db/date?date=20260330
```

**쿼리 파라미터**:
| 이름 | 타입 | 필수 | 형식 |
|------|------|------|------|
| date | string | ✅ | yyyyMMdd |

### 응답

**상태 코드**: 200 OK

```json
{
  "date": "20260330",
  "btcPrice": 62500.50,
  "longShortRatio": 1.25,
  "fearGreedIndex": 65,
  "openInterest": 28500000000
}
```

---

## 3️⃣ 크립토 데이터: 오늘

### 요청

```http
GET /api/crypto-data/today
```

**쿼리 파라미터**: 없음

### 응답

**상태 코드**: 200 OK

```json
{
  "date": "20260402",
  "btcPrice": 63200.75,
  "longShortRatio": 1.28,
  "fearGreedIndex": 68,
  "openInterest": 29000000000
}
```

---

## 4️⃣ 크립토 데이터: 7일

### 요청

```http
GET /api/crypto-data/7days?date=20260330
```

**쿼리 파라미터**:
| 이름 | 타입 | 필수 | 형식 | 설명 |
|------|------|------|------|------|
| date | string | ✅ | yyyyMMdd | 종료 날짜 (이 날짜로부터 과거 7일) |

### 응답

**상태 코드**: 200 OK

```json
{
  "dates": [
    "20260324",
    "20260325",
    "20260326",
    "20260327",
    "20260328",
    "20260329",
    "20260330"
  ],
  "btcPrices": [
    59800.25,
    60200.50,
    60800.75,
    61200.00,
    61800.25,
    62200.50,
    62500.50
  ],
  "longShortRatios": [
    1.18,
    1.19,
    1.20,
    1.21,
    1.22,
    1.23,
    1.25
  ],
  "fearGreedIndices": [
    55,
    57,
    59,
    60,
    62,
    63,
    65
  ],
  "openInterests": [
    27200000000,
    27400000000,
    27600000000,
    27800000000,
    28000000000,
    28200000000,
    28500000000
  ]
}
```

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| dates | array | 날짜 배열 (yyyyMMdd) |
| btcPrices | array | BTC 가격 배열 |
| longShortRatios | array | 롱/숏 비율 배열 |
| fearGreedIndices | array | 공포탐욕지수 배열 |
| openInterests | array | 오픈 인터레스트 배열 |

**배열 길이**: 최대 7개 (데이터가 없는 날짜는 제외)

---

## 5️⃣ 매크로 데이터: 현재 + 전날

### 요청

```http
GET /api/macro-data/db/date-with-previous?date=20260330
```

**쿼리 파라미터**:
| 이름 | 타입 | 필수 | 형식 |
|------|------|------|------|
| date | string | ✅ | yyyyMMdd |

### 응답

**상태 코드**: 200 OK

```json
{
  "requestDate": "20260330",
  "previousDate": "20260329",
  "data": {
    "requestDate": {
      "date": "20260330",
      "interestRate": 4.50,
      "treasury10y": 4.25,
      "cpi": 3.2,
      "m2": 20500000000000,
      "unemployment": 3.8,
      "dollarIndex": 104.25
    },
    "previousDate": {
      "date": "20260329",
      "interestRate": 4.50,
      "treasury10y": 4.23,
      "cpi": 3.2,
      "m2": 20500000000000,
      "unemployment": 3.8,
      "dollarIndex": 104.20
    }
  }
}
```

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| interestRate | number | 기준금리 (%) |
| treasury10y | number | 10년물 Treasury 수익률 (%) |
| cpi | number | 소비자물가지수 (%) |
| m2 | number | M2 통화공급량 (달러) |
| unemployment | number | 실업률 (%) |
| dollarIndex | number | 달러인덱스 |

---

## 6️⃣ 매크로 데이터: 특정 날짜

### 요청

```http
GET /api/macro-data/db/date?date=20260330
```

**응답**:
```json
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

---

## 7️⃣ 매크로 데이터: 오늘

### 요청

```http
GET /api/macro-data/today
```

**응답**:
```json
{
  "date": "20260402",
  "interestRate": 4.50,
  "treasury10y": 4.27,
  "cpi": 3.2,
  "m2": 20550000000000,
  "unemployment": 3.7,
  "dollarIndex": 104.50
}
```

---

## 8️⃣ AI 분석 데이터

### 요청

```http
GET /api/ai-analysis/date?date=20260330
```

**쿼리 파라미터**:
| 이름 | 타입 | 필수 | 형식 |
|------|------|------|------|
| date | string | ✅ | yyyyMMdd |

### 응답

**상태 코드**: 200 OK

```json
{
  "date": "20260330",
  "total_score": 72.5,
  "signal_type": "강한 매수",
  "signal_color": "green",
  "crypto_score": 75.0,
  "macro_score": 70.0,
  "btc_trend_score": 78.0,
  "fear_greed_score": 75.0,
  "long_short_score": 72.0,
  "open_interest_score": 74.0,
  "interest_rate_score": 68.0,
  "treasury10y_score": 70.0,
  "m2_score": 68.0,
  "dollar_index_score": 65.0,
  "unemployment_score": 72.0,
  "cpi_score": 70.0,
  "interaction_score": 71.0,
  "analysis_summary": "현재 시장은 크립토와 매크로 모두 긍정적 신호를 보이고 있습니다...",
  "analysis_summary_en": "The current market shows positive signals from both crypto and macro indicators...",
  "indicator_explanations": {
    "BTC 추세": "BTC는 상승 추세를 지속하고 있으며...",
    "공포탐욕지수": "공포탐욕지수는 탐욕 영역에 있으며..."
  },
  "indicator_explanations_en": {
    "BTC Trend": "BTC is continuing its uptrend...",
    "Fear & Greed Index": "The index is in the greed zone..."
  }
}
```

**응답 필드**:

| 필드 | 타입 | 설명 |
|------|------|------|
| date | string | 분석 날짜 (yyyyMMdd) |
| total_score | number | 종합 점수 (0~100) |
| signal_type | string | 신호 타입 ("강한 매수", "매수", "중립" 등) |
| signal_color | string | 신호 색상 ("green", "yellow", "red" 등) |
| crypto_score | number | 크립토 지표 점수 |
| macro_score | number | 매크로 지표 점수 |
| btc_trend_score | number | BTC 추세 점수 |
| fear_greed_score | number | 공포탐욕지수 점수 |
| long_short_score | number | 롱/숏 비율 점수 |
| open_interest_score | number | 오픈 인터레스트 점수 |
| interest_rate_score | number | 기준금리 점수 |
| treasury10y_score | number | 10년물 Treasury 점수 |
| m2_score | number | M2 통화공급량 점수 |
| dollar_index_score | number | 달러인덱스 점수 |
| unemployment_score | number | 실업률 점수 |
| cpi_score | number | CPI 점수 |
| interaction_score | number | 상호작용 점수 |
| analysis_summary | string | 분석 요약 (한글) |
| analysis_summary_en | string | 분석 요약 (영어) |
| indicator_explanations | object | 지표별 설명 (한글) |
| indicator_explanations_en | object | 지표별 설명 (영어) |

### 예시 (Swift)

```swift
struct AIAnalysisResponse: Codable {
    let date: String
    let total_score: Double
    let signal_type: String
    let signal_color: String
    let analysis_summary: String
    let indicator_explanations: [String: String]
}

let url = URL(string: "https://api-gateway-url/api/ai-analysis/date?date=20260330")!
let decoder = JSONDecoder()
let response = try decoder.decode(AIAnalysisResponse.self, from: data)
```

---

## 🔄 CORS 및 preflight 요청

모든 엔드포인트는 CORS를 지원합니다.

### OPTIONS 요청

```http
OPTIONS /api/crypto-data/db/date-with-previous
```

**응답**:
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type
```

---

## 📊 요청/응답 시간 비교

| 엔드포인트 | 조회 방식 | 예상 시간 |
|----------|---------|---------|
| date-with-previous | Query ×2 + 데이터 포맷 | 200~500ms |
| date | Query ×1 + 데이터 포맷 | 100~300ms |
| today | Query ×1 | 100~300ms |
| 7days | Query ×7 | 700~1500ms |
| ai-analysis | GetItem ×1 | 100~200ms |

**주의**: DynamoDB의 첫 Query가 느린 경우 (콜드 스타트, Scan 폴백) 시간이 증가할 수 있습니다.

---

## ⚠️ 에러 응답 가이드

모든 엔드포인트는 다음과 같은 에러를 반환할 수 있습니다:

### 400 Bad Request

**원인**: 잘못된 요청

```json
{
  "error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."
}
```

**확인**:
- date 파라미터 누락 여부
- date 형식이 yyyyMMdd인지 확인
- 쿼리 파라미터 인코딩 확인

### 404 Not Found

**원인 1**: 데이터 없음
```json
{
  "error": "해당 날짜(20260330)의 크립토 데이터가 없습니다."
}
```

**원인 2**: 지원하지 않는 경로
```json
{
  "error": "Not Found"
}
```

### 500 Internal Server Error

**원인**: DynamoDB 오류 또는 기타 서버 오류

```json
{
  "error": "DynamoDB Scan 실패 (TB_CRYPTO_DATA): ..."
}
```

**확인**:
- AWS IAM 권한 확인
- DynamoDB 테이블 상태 확인
- CloudWatch Logs 확인

---

## 🎯 사용 시나리오

### 시나리오 1: 크립토 대시보드 초기 로드

```
1. GET /api/crypto-data/db/date-with-previous?date=20260330
2. GET /api/macro-data/db/date-with-previous?date=20260330
3. GET /api/ai-analysis/date?date=20260330
```

3개의 병렬 요청으로 전체 대시보드 데이터 로드

### 시나리오 2: 7일 차트 표시

```
GET /api/crypto-data/7days?date=20260330
```

1개의 요청으로 7일 데이터 조회 (중복 요청 방지)

### 시나리오 3: 과거 날짜 비교

```
1. GET /api/crypto-data/db/date?date=20260330  (현재)
2. GET /api/crypto-data/db/date?date=20260225  (1개월 전)
```

2개의 요청으로 1개월 전후 비교

---

## 💾 POST: 크립토 데이터 저장

### 요청

```http
POST /api/crypto-data/db
Content-Type: application/json
```

**요청 바디**:
```json
{
  "date": "20260330",
  "btcPrice": 62500.50,
  "longShortRatio": 1.25,
  "fearGreedIndex": 65,
  "openInterest": 28500000000
}
```

**필수 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| date | string | 날짜 (yyyyMMdd) |
| btcPrice | number | BTC 가격 (USD) |
| longShortRatio | number | 롱/숏 비율 |
| fearGreedIndex | integer | 공포탐욕지수 (0~100) |
| openInterest | number | 오픈 인터레스트 (달러) |

### 응답

**상태 코드**: 201 Created

```json
{
  "message": "크립토 데이터가 저장되었습니다.",
  "date": "20260330"
}
```

### 에러 응답

**400 Bad Request** (필드 누락 또는 형식 오류):
```json
{
  "error": "필수 필드가 누락되었거나 형식이 올바르지 않습니다.",
  "details": "date, btcPrice, longShortRatio, fearGreedIndex, openInterest 필수"
}
```

**409 Conflict** (같은 날짜 데이터 이미 존재):
```json
{
  "error": "해당 날짜(20260330)의 데이터가 이미 존재합니다. PUT으로 수정해주세요."
}
```

---

## ✏️ PUT: 크립토 데이터 수정

### 요청

```http
PUT /api/crypto-data/db
Content-Type: application/json
```

**요청 바디**:
```json
{
  "date": "20260330",
  "btcPrice": 63000.75,
  "longShortRatio": 1.28,
  "fearGreedIndex": 68,
  "openInterest": 28800000000
}
```

### 응답

**상태 코드**: 200 OK

```json
{
  "message": "크립토 데이터가 수정되었습니다.",
  "date": "20260330"
}
```

### 에러 응답

**404 Not Found** (데이터 없음):
```json
{
  "error": "해당 날짜(20260330)의 데이터가 없습니다. POST로 생성해주세요."
}
```

---

## 🗑️ DELETE: 크립토 데이터 삭제

### 요청

```http
DELETE /api/crypto-data/db/date?date=20260330
```

**쿼리 파라미터**:
| 이름 | 타입 | 필수 | 형식 |
|------|------|------|------|
| date | string | ✅ | yyyyMMdd |

### 응답

**상태 코드**: 200 OK

```json
{
  "message": "크립토 데이터가 삭제되었습니다.",
  "date": "20260330"
}
```

### 에러 응답

**404 Not Found** (데이터 없음):
```json
{
  "error": "해당 날짜(20260330)의 크립토 데이터가 없습니다."
}
```

---

## 💾 POST: 매크로 데이터 저장

### 요청

```http
POST /api/macro-data/db
Content-Type: application/json
```

**요청 바디**:
```json
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

**필수 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| date | string | 날짜 (yyyyMMdd) |
| interestRate | number | 기준금리 (%) |
| treasury10y | number | 10년물 Treasury 수익률 (%) |
| cpi | number | 소비자물가지수 (%) |
| m2 | number | M2 통화공급량 (달러) |
| unemployment | number | 실업률 (%) |
| dollarIndex | number | 달러인덱스 |

### 응답

**상태 코드**: 201 Created

```json
{
  "message": "매크로 데이터가 저장되었습니다.",
  "date": "20260330"
}
```

---

## ✏️ PUT: 매크로 데이터 수정

### 요청

```http
PUT /api/macro-data/db
Content-Type: application/json
```

**요청 바디**: POST와 동일

### 응답

**상태 코드**: 200 OK

```json
{
  "message": "매크로 데이터가 수정되었습니다.",
  "date": "20260330"
}
```

---

## 🗑️ DELETE: 매크로 데이터 삭제

### 요청

```http
DELETE /api/macro-data/db/date?date=20260330
```

### 응답

**상태 코드**: 200 OK

```json
{
  "message": "매크로 데이터가 삭제되었습니다.",
  "date": "20260330"
}
```

---

## 💾 POST: AI 분석 데이터 저장

### 요청

```http
POST /api/ai-analysis/db
Content-Type: application/json
```

**요청 바디**:
```json
{
  "date": "20260330",
  "total_score": 72.5,
  "signal_type": "강한 매수",
  "signal_color": "green",
  "crypto_score": 75.0,
  "macro_score": 70.0,
  "btc_trend_score": 78.0,
  "fear_greed_score": 75.0,
  "long_short_score": 72.0,
  "open_interest_score": 74.0,
  "interest_rate_score": 68.0,
  "treasury10y_score": 70.0,
  "m2_score": 68.0,
  "dollar_index_score": 65.0,
  "unemployment_score": 72.0,
  "cpi_score": 70.0,
  "interaction_score": 71.0,
  "analysis_summary": "현재 시장은 크립토와 매크로 모두 긍정적 신호를 보이고 있습니다.",
  "analysis_summary_en": "The current market shows positive signals from both crypto and macro indicators.",
  "indicator_explanations": {
    "BTC 추세": "BTC는 상승 추세를 지속하고 있으며...",
    "공포탐욕지수": "공포탐욕지수는 탐욕 영역에 있으며..."
  },
  "indicator_explanations_en": {
    "BTC Trend": "BTC is continuing its uptrend...",
    "Fear & Greed Index": "The index is in the greed zone..."
  }
}
```

**필수 필드**: date, total_score, signal_type, signal_color, 각 점수 필드들

### 응답

**상태 코드**: 201 Created

```json
{
  "message": "AI 분석 데이터가 저장되었습니다.",
  "date": "20260330"
}
```

---

## ✏️ PUT: AI 분석 데이터 수정

### 요청

```http
PUT /api/ai-analysis/db
Content-Type: application/json
```

**요청 바디**: POST와 동일

### 응답

**상태 코드**: 200 OK

```json
{
  "message": "AI 분석 데이터가 수정되었습니다.",
  "date": "20260330"
}
```

---

## 🗑️ DELETE: AI 분석 데이터 삭제

### 요청

```http
DELETE /api/ai-analysis/date?date=20260330
```

### 응답

**상태 코드**: 200 OK

```json
{
  "message": "AI 분석 데이터가 삭제되었습니다.",
  "date": "20260330"
}
```

---

## 🔐 인증 및 권한

모든 CRUD 엔드포인트 (POST, PUT, DELETE)는 **관리자 인증**이 필요합니다.

### 권장 인증 방식

**1. AWS IAM 인증** (권장)
```
Authorization: AWS4-HMAC-SHA256 Credential=...
```

**2. API 키 (간단한 방식)**
```
Authorization: Bearer <api-key>
```

**3. JWT 토큰** (확장성)
```
Authorization: Bearer <jwt-token>
```

### IAM 정책 예시

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:UpdateItem",
                "dynamodb:DeleteItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA",
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_AI_INSIGHT"
            ]
        }
    ]
}
```

---

**마지막 업데이트**: 2026년 4월 2일
