# prospero_collector - 데이터 수집 엔진

Prospero의 데이터 수집 모듈입니다. Binance, Alternative.me, FRED API에서 암호화폐/거시경제 데이터를 수집하여 DynamoDB에 저장합니다.

---

## 📋 개요

### 역할
- **매일 UTC 04:00**에 자동으로 외부 API에서 데이터 수집
- 암호화폐 데이터: BTC 가격, 공포탐욕지수, 롱숏비율, OI 등
- 거시경제 데이터: 금리, CPI, M2, 달러인덱스 등
- 30일간의 데이터를 DynamoDB에 누적 저장
- 수집 오케스트레이션 및 에러 처리

### 기술 스택
- **런타임**: Python 3.11 (AWS Lambda)
- **스케줄**: AWS EventBridge (cron 기반)
- **저장소**: AWS DynamoDB (ap-northeast-2)
- **외부 API**: Binance, Alternative.me, FRED

---

## 🏗️ 아키텍처

### 전체 데이터 수집 파이프라인

```
┌─────────────────────────────────────────┐
│   AWS EventBridge                       │
│   스케줄: cron(0 4 * * ? *)             │
│   (매일 UTC 04:00 실행)                 │
└────────────┬────────────────────────────┘
             │
             │ Lambda 호출
             ▼
┌─────────────────────────────────────────┐
│   prospero_collector Lambda             │
│   (lambda_function.py - 진입점)         │
│                                         │
│  1. 날짜 및 데이터 수집 오케스트레이션 │
│  2. 에러 처리 및 재시도                │
└────────────┬────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
┌──────────────┐  ┌─────────────────┐
│ 암호화폐 수집 │  │ 거시경제 수집   │
│              │  │                 │
│crypto_       │  │macro_           │
│collector.py  │  │collector.py     │
└──────┬───────┘  └────────┬────────┘
       │                   │
   ┌───▼──────────────────┐│
   │   동시 실행           ││
   └─────────────────────┘│
                          │
       ┌──────────┬────────┘
       │ 외부API  │
       ▼          ▼
   ┌─────┐  ┌──────────────┐
   │Binance  │Alternative.me│
   │(BTC가격) │(공포탐욕,   │
   │ OI등)   │ 롱숏비율)    │
   └─────┘  └──────────────┘

       ┌──────────────┐
       │  FRED API    │
       │ (금리,CPI등) │
       └──────┬───────┘
              │
              ▼
   ┌─────────────────────────────┐
   │ dynamodb_writer.py          │
   │ - 데이터 정제 및 검증       │
   │ - DynamoDB 저장             │
   └────────────┬────────────────┘
                │
                ▼
   ┌─────────────────────────────┐
   │ AWS DynamoDB (ap-northeast-2)
   │                             │
   │ TB_CRYPTO_DATA              │
   │ TB_MACRO_DATA               │
   └─────────────────────────────┘
```

---

## 📂 프로젝트 구조

```
prospero_collector/
├── lambda_function.py        # Lambda 진입점
├── crypto_collector.py       # Binance, Alternative.me 수집
├── macro_collector.py        # FRED API 수집
├── dynamodb_writer.py        # DynamoDB 쓰기
├── requirements.txt          # Python 의존성
├── deploy.sh                # Lambda 배포 스크립트
├── README.md                # 이 파일
├── LAMBDA_DEPLOYMENT.md     # Lambda 상세 가이드
├── API_GATEWAY_MIGRATION.md # API Gateway 관련
├── PLAN.md                  # 초기 계획
└── prospero_collector.zip   # 배포 패키지
```

---

## 🔄 데이터 수집 흐름

### 1️⃣ Lambda 진입점 (lambda_function.py)

**역할**: 전체 수집 프로세스 오케스트레이션

```python
def lambda_handler(event, context):
    """
    EventBridge로부터 매일 UTC 04:00 자동 호출

    1. 수집 날짜 결정 (오늘 또는 파라미터로 지정)
    2. 암호화폐 + 거시경제 데이터 동시 수집
    3. 에러 처리 및 로깅
    4. DynamoDB 저장
    """
```

**처리 로직**:
1. 날짜 파싱 (event에서 date 파라미터 추출, 없으면 오늘)
2. CryptoCollector 시작
3. MacroCollector 시작
4. 두 수집기 병렬 실행
5. 결과 검증 및 통합
6. CloudWatch 로그 기록

---

### 2️⃣ 암호화폐 수집 (crypto_collector.py)

**역할**: Binance + Alternative.me에서 데이터 수집

**수집 대상**:

| 항목 | 소스 | 설명 |
|------|------|------|
| BTC 가격 | Binance | 현재 USDT 가격 |
| 7일 변화 | Binance | 7일 수익률 (%) |
| 30일 변화 | Binance | 30일 수익률 (%) |
| OI (Open Interest) | Binance | 선물 미결제 약정 (USD) |
| OI 변화 | Binance | OI 일일 변화율 (%) |
| OI 30일 변화 | Binance | OI 30일 변화율 (%) |
| 공포탐욕지수 | Alternative.me | 0~100 (공포 ← → 탐욕) |
| 공포탐욕 30일 평균 | Alternative.me | 30일 평균값 |
| 롱/숏 비율 | Alternative.me | 장포지션 / 단포지션 |

**API 호출 상세**:

```python
# Binance API 예시
GET https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT
→ Response: {
    "symbol": "BTCUSDT",
    "lastPrice": "62500.50",  # 현재 가격
    "priceChangePercent": "3.25",  # 24h 변화율
    "quoteAssetVolume": "..."
}

# Binance 펀딩 OI
GET https://api.binance.com/api/v3/openInterest?symbol=BTCUSDT
→ OpenInterest 달러값

# Alternative.me API
GET https://api.alternative.me/fng/
→ Response: {
    "data": [{
        "value": "65",  # 공포탐욕 점수
        "value_classification": "Greed",
        "timestamp": "1711737600"
    }]
}

# Alternative.me 롱/숏 비율
GET https://api.alternative.me/crypto/fear-and-greed/?limit=1000
→ 최신 1000개 데이터로 30일 평균 계산
```

**데이터 처리**:
1. API 응답 파싱
2. 데이터 검증 (Null 체크, 범위 확인)
3. 30일 변화율 계산 (필요시)
4. 결과 딕셔너리 반환

```python
{
    "date": "20260330",
    "btc_price": 62500.50,
    "btc_change7d": 3.25,
    "btc_change30d": 12.45,
    "fear_greed_current": 65,
    "fear_greed_avg30d": 58,
    "long_short_ratio": 1.25,
    "open_interest": 28500000000,
    "open_interest_change": 2.5,
    "open_interest_change30d": 8.3
}
```

---

### 3️⃣ 거시경제 수집 (macro_collector.py)

**역할**: FRED API에서 경제 지표 수집

**수집 지표**:

| 지표명 | FRED 코드 | 설명 |
|--------|----------|------|
| 기준금리 | FEDFUNDS | 연방기금금리 (%) |
| 10년물 Treasury | DGS10 | 10년물 수익률 (%) |
| CPI | CPIAUCSL | 소비자물가지수 (%) |
| M2 | M2SL | 통화공급량 (달러) |
| 달러인덱스 | DTWEXBGS | 달러 지수 (인덱스) |
| 실업률 | UNRATE | 실업률 (%) |

**API 호출 상세**:

```python
# FRED API 기본 형식
GET https://api.stlouisfed.org/fred/series/data?
    series_id={CODE}&
    api_key={FRED_API_KEY}&
    file_type=json&
    limit=2

예) FEDFUNDS (기준금리)
GET https://api.stlouisfed.org/fred/series/data?
    series_id=FEDFUNDS&
    api_key=...&
    file_type=json

응답:
{
    "observations": [
        {"date": "2026-02-28", "value": "4.25"},
        {"date": "2026-03-30", "value": "4.33"}
    ]
}
```

**데이터 처리**:
1. API 응답에서 최근 2개 데이터 추출 (현재 + 30일 전)
2. 데이터 유효성 검증
3. 변화율 계산 (필요시)
4. 결과 딕셔너리 반환

```python
{
    "date": "20260330",
    "interest_rate": 4.33,
    "interest_rate_change": 0.08,
    "cpi": 3.2,
    "cpi_change": 0.1,
    "dollar_index": 104.25,
    "dollar_index_change": 1.2,
    "treasury10y": 4.42,
    "treasury10y_change": 0.08,
    "m2": 20500000000000,
    "m2_change": 0.2,
    "unemployment": 3.8,
    "unemployment_change": -0.1
}
```

---

### 4️⃣ DynamoDB 저장 (dynamodb_writer.py)

**역할**: 수집된 데이터를 DynamoDB에 저장

**주요 클래스**: `DynamoDBWriter`

**메서드**:

```python
class DynamoDBWriter:
    def write_crypto_data(self, date: str, data: Dict) -> None:
        """
        TB_CRYPTO_DATA 테이블에 저장

        데이터 예시:
        {
            "btc_price": 62500.50,
            "btc_change7d": 3.25,
            "fear_greed_current": 65,
            ...
        }
        """

    def write_macro_data(self, date: str, data: Dict) -> None:
        """
        TB_MACRO_DATA 테이블에 저장

        데이터 예시:
        {
            "interest_rate": 4.33,
            "cpi": 3.2,
            "dollar_index": 104.25,
            ...
        }
        """
```

**저장 포맷** (DynamoDB):

**TB_CRYPTO_DATA**:
```json
{
    "crypto_id": {"S": "BTC"},
    "date": {"S": "20260330"},
    "btc_price": {"N": "62500.50"},
    "btc_change7d": {"N": "3.25"},
    "btc_change30d": {"N": "12.45"},
    "fear_greed_current": {"N": "65"},
    ...
    "created_at": {"S": "2026-03-30T04:00:00Z"}
}
```

**TB_MACRO_DATA**:
```json
{
    "indicator_id": {"S": "MACRO"},
    "date": {"S": "20260330"},
    "interest_rate": {"N": "4.33"},
    "cpi": {"N": "3.2"},
    "dollar_index": {"N": "104.25"},
    ...
    "created_at": {"S": "2026-03-30T04:00:00Z"}
}
```

---

## 📊 DynamoDB 테이블 정의

### TB_CRYPTO_DATA

```
파티션 키: crypto_id (String) = "BTC"
정렬 키: date (String) = "yyyyMMdd"

속성:
├── btc_price (Number)
├── btc_change7d (Number)
├── btc_change30d (Number)
├── fear_greed_current (Number)
├── fear_greed_avg30d (Number)
├── long_short_ratio (Number)
├── open_interest (Number)
├── open_interest_change (Number)
├── open_interest_change30d (Number)
└── created_at (String - ISO 8601)
```

---

### TB_MACRO_DATA

```
파티션 키: indicator_id (String) = "MACRO"
정렬 키: date (String) = "yyyyMMdd"

속성:
├── interest_rate (Number)
├── interest_rate_change (Number)
├── cpi (Number)
├── cpi_change (Number)
├── dollar_index (Number)
├── dollar_index_change (Number)
├── treasury10y (Number)
├── treasury10y_change (Number)
├── m2 (Number)
├── m2_change (Number)
├── unemployment (Number)
├── unemployment_change (Number)
└── created_at (String - ISO 8601)
```

---

## 🔧 환경 설정

### 필수 환경변수

**로컬 실행**:
```bash
export FRED_API_KEY=abc123xyz...
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-northeast-2
export DYNAMODB_CRYPTO_TABLE=TB_CRYPTO_DATA
export DYNAMODB_MACRO_TABLE=TB_MACRO_DATA
```

**Lambda (AWS SSM Parameter Store)**:
```
/prospero/fred-api-key = "abc123xyz..."
```

### 필수 IAM 권한

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "dynamodb:PutItem",
            "Resource": [
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
                "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ssm:GetParameter",
            "Resource": "arn:aws:ssm:ap-northeast-2:*:parameter/prospero/*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:*",
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
```

---

## 🔄 에러 처리 및 재시도

### 재시도 전략

```python
# Binance API: 최대 3회 재시도 (지수 백오프)
# 실패 시 기본값 반환

# FRED API: 최대 3회 재시도
# 실패 시 에러 로그 및 CloudWatch 알람

# DynamoDB: 자동 재시도 (boto3)
# 실패 시 Lambda 실패 (EventBridge에서 재실행)
```

### 로깅

```python
# CloudWatch Logs에 기록
print(f"✅ 크립토 데이터 수집 완료: {date}")
print(f"❌ FRED API 호출 실패: {error_message}")
print(f"⚠️ 유효하지 않은 데이터: {field_name}")
```

---

## 📈 데이터 흐름 상세 (타임라인)

```
UTC 03:59
└─ EventBridge 대기

UTC 04:00
├─ Lambda 시작
├─ 날짜 설정: 오늘 (UTC)
│
├─ CryptoCollector 시작
│  ├─ Binance API 호출 (BTC 정보)
│  ├─ Alternative.me API 호출 (공포탐욕, 롱숏)
│  ├─ 데이터 검증
│  └─ 결과 반환
│
├─ MacroCollector 시작
│  ├─ FRED API 호출 (6개 지표)
│  ├─ 데이터 검증
│  └─ 결과 반환
│
├─ DynamoDB에 저장
│  ├─ PutItem: TB_CRYPTO_DATA
│  └─ PutItem: TB_MACRO_DATA
│
├─ 결과 로깅
└─ Lambda 완료

UTC 04:05
└─ prospero_ai 분석 실행 (별도 트리거)
```

---

## 🐛 데이터 검증

### Crypto 데이터 검증

```python
# BTC 가격: 양수, 0이 아님
# 변화율: -100% ~ +500% 범위
# 공포탐욕: 0 ~ 100 범위
# 롱숏비율: 양수, 합리적 범위
# OI: 양수
```

### Macro 데이터 검증

```python
# 금리: 음수 아님, 0 ~ 10% 범위
# CPI: 0 ~ 30% 범위
# 달러인덱스: 50 ~ 150 범위
# M2: 양수
# 실업률: 0 ~ 20% 범위
```

---

## 📝 주요 고려사항

1. **API 레이트 제한**: Binance 최대 1200 req/min, FRED 핸들링
2. **데이터 신선도**: 매일 정확히 UTC 04:00에 수집
3. **배경 처리**: 동시 실행으로 수집 시간 최소화
4. **에러 복구**: 실패 시 CloudWatch 알람 발생
5. **시간대**: 모든 데이터 UTC 기준

---

**Last Updated**: 2026년 3월 30일

