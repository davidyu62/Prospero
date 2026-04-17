# prospero_ai - 분석 엔진 (v4.1)

Prospero의 핵심 분석 엔진입니다. 11개 지표 기반 결정론적 투자 점수 계산과 LLM을 활용한 정성적 분석을 수행합니다.

---

## 📋 개요

### 역할
- 암호화폐/거시경제 데이터에서 11개 지표 점수 계산 (Python 결정론적)
- 시장 국면(Regime) 감지 및 강도 평가
- 기본 점수 + 조정값을 통한 최종 투자 점수 계산
- GPT-4 Turbo를 활용한 지표별 정성적 분석 생성
- 결과를 DynamoDB에 저장

### 기술 스택
- **런타임**: Python 3.11 (AWS Lambda)
- **분석 엔진**: Python (numpy 없는 경량 구현)
- **LLM**: OpenAI GPT-4 Turbo (langchain)
- **저장소**: AWS DynamoDB (ap-northeast-2)

### 핵심 특징
- **결정론적 점수**: Python 수식 기반 (재현 가능, 일관성)
- **LLM 역할 명확화**: 점수 계산 제외, 설명만 담당
- **국면 강도 확률**: 0.0 ~ 1.0 범위의 신뢰도 기반 가중치
- **JSON 완성도**: 항상 모든 필드 포함 (LLM 누락 대비)

---

## 🏗️ 아키텍처

### 전체 분석 파이프라인

```
┌──────────────────────────────────────────┐
│  DynamoDB 데이터 조회                   │
│  (TB_CRYPTO_DATA, TB_MACRO_DATA)        │
└────────────┬─────────────────────────────┘
             │
             │ 30일치 데이터
             ▼
┌──────────────────────────────────────────┐
│  prospero_ai Lambda (score_analyzer.py)  │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ 1단계: 11개 지표 점수 계산         │ │
│  │ (Python 결정론적)                   │ │
│  │                                    │ │
│  │ • BTC 추세 (0~10점)                │ │
│  │ • 공포탐욕지수 (0~20점)            │ │
│  │ • 롱숏비율 (0~15점)                │ │
│  │ • OI+가격 (0~10점)                 │ │
│  │ • 기준금리 (0~10점)                │ │
│  │ • 10Y Treasury (0~8점)              │ │
│  │ • M2 (0~8점)                       │ │
│  │ • 달러인덱스 (0~7점)               │ │
│  │ • 실업률 (0~4점)                   │ │
│  │ • CPI (0~3점)                      │ │
│  │ • 상호작용 (0~5점)                 │ │
│  └────────────┬───────────────────────┘ │
│               │                         │
│  ┌────────────▼───────────────────────┐ │
│  │ 2단계: 시장 국면 감지 + 강도 평가 │ │
│  │ • dip_buy, trend_follow, neutral, │ │
│  │   risk_off, euphoria             │ │
│  │ • 강도: 0.0 ~ 1.0 확률            │ │
│  └────────────┬───────────────────────┘ │
│               │                         │
│  ┌────────────▼───────────────────────┐ │
│  │ 3단계: 기본 점수 계산               │ │
│  │ base_score = ∑지표점수              │ │
│  │ regime_adjustment = ±6.0 × strength │ │
│  │ total_score = base + 조정값         │ │
│  └────────────┬───────────────────────┘ │
│               │                         │
│  ┌────────────▼───────────────────────┐ │
│  │ 4단계: 신호 결정 (5단계)           │ │
│  │ • Strong Buy (75~100)               │ │
│  │ • Buy (58~74)                      │ │
│  │ • Hold (38~57)                     │ │
│  │ • Partial Sell (22~37)             │ │
│  │ • Strong Sell (0~21)                │ │
│  └────────────┬───────────────────────┘ │
│               │                         │
│  ┌────────────▼───────────────────────┐ │
│  │ 5단계: LLM 정성적 분석 생성        │ │
│  │ • analysis_summary (한글/영어)     │ │
│  │ • 11개 지표별 설명                 │ │
│  │   (LLM 누락 시 기본값 채움)        │ │
│  └────────────┬───────────────────────┘ │
│               │                         │
│  ┌────────────▼───────────────────────┐ │
│  │ 6단계: 결과 검증 및 저장           │ │
│  │ • 필수 필드 확인                   │ │
│  │ • 점수 범위 검증 (0~100)           │ │
│  │ • TB_AI_INSIGHT에 저장             │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
             │
             │ 분석 결과
             ▼
┌──────────────────────────────────────────┐
│  DynamoDB TB_AI_INSIGHT                  │
│  (점수, 신호, 11개 지표 설명)            │
└──────────────────────────────────────────┘
             │
             │ iOS 앱 조회
             ▼
┌──────────────────────────────────────────┐
│  iOS 앱 (prospero_app)                   │
│  AI 탭에서 점수 및 분석 표시             │
└──────────────────────────────────────────┘
```

---

## 📂 프로젝트 구조

```
prospero_ai/
├── score_analyzer.py        # 핵심 분석 엔진 (v4.1)
├── data_fetcher.py         # DynamoDB 데이터 조회
├── result_writer.py        # 분석 결과 저장
├── lambda_function.py      # Lambda 진입점
├── run_local.py           # 로컬 테스트
├── requirements.txt        # Python 의존성
├── INVESTMENT_FORMULA.md   # 점수 계산 공식 상세
├── DEPLOYMENT.md          # Lambda 배포 가이드
└── README.md              # 이 파일
```

---

## 🧮 점수 계산 알고리즘

### 1️⃣ 11개 지표 점수 계산

#### Crypto 지표 (4개, 총 50점)

**BTC 추세 (0~10점)**
```
30일 변화율에 따른 점수:
  ≥ +30%: 10점 (강한 상승)
  +15% ~ +30%: 7~10점
  0% ~ +15%: 3~7점
  -10% ~ 0%: 1~3점
  < -10%: 0점 (약세)

공식: 선형 보간 또는 단계별 매핑
```

**공포탐욕지수 (0~20점)**
```
공포탐욕 점수 (0~100)와 30일 평균을 고려:
  현재값 ≥ 70 (탐욕): 높은 점수 (10~20)
  현재값 ≥ 평균: 중간 점수 (10~15)
  현재값 < 평균: 낮은 점수 (5~10)
  현재값 < 30 (극심한 공포): 기회 신호 (15~20)
```

**롱/숏 비율 (0~15점)**
```
비율 범위:
  ≥ 1.3: 15점 (강한 장포지션)
  1.0 ~ 1.3: 5~15점 (점진적)
  0.8 ~ 1.0: 5~10점 (균형)
  < 0.8: 0~5점 (단포지션 우위)
```

**OI+가격 (0~10점)**
```
OI 변화 + 가격 변화 결합:
  둘 다 상승: 10점
  OI 상승, 가격 하락: 5점 (약세 신호)
  OI 하락, 가격 상승: 7점 (강한 상승)
  둘 다 하락: 0~3점
```

---

#### Macro 지표 (6개, 총 40점)

**기준금리 (0~10점)**
```
이상적 범위: 3.0% ~ 4.5%
  3.0% ~ 4.5%: 10점 (최적)
  2.5% ~ 3.0% 또는 4.5% ~ 5.5%: 5~10점
  < 2.5% 또는 > 5.5%: 0~5점
```

**10년물 Treasury (0~8점)**
```
이상적 범위: 4.0% ~ 4.5%
  4.0% ~ 4.5%: 8점
  3.5% ~ 4.0% 또는 4.5% ~ 5.0%: 4~8점
  < 3.5% 또는 > 5.0%: 0~4점
```

**M2 (0~8점)**
```
증가세 선호:
  전월 대비 증가: 8점
  거의 변화 없음: 4점
  감소: 0~2점
```

**달러인덱스 (0~7점)**
```
이상적 범위: 100 ~ 104
  100 ~ 104: 7점
  104 ~ 108: 3~7점
  < 100 또는 > 108: 0~3점
```

**실업률 (0~4점)**
```
낮을수록 좋음:
  < 3.5%: 4점
  3.5% ~ 4.0%: 3점
  4.0% ~ 4.5%: 2점
  > 4.5%: 0~1점
```

**CPI (0~3점)**
```
이상적 범위: 2.0% ~ 2.5%
  2.0% ~ 2.5%: 3점
  1.5% ~ 2.0% 또는 2.5% ~ 3.0%: 2점
  < 1.5% 또는 > 3.0%: 0~1점
```

---

#### 상호작용 (0~5점, 또는 -3~+3)

```
암호 추세(BTC) × 거시경제 점수의 상호작용:
  동향 일치 (상승-상승 또는 하락-하락): +3점
  약한 불일치: 0~1점
  강한 불일치 (상승-하락): -3점

특수 케이스:
  BTC 급락 + 금리 인상: -3점 (압박)
  BTC 급등 + 금리 인하: +3점 (시너지)
```

---

### 2️⃣ 시장 국면(Regime) 감지 + 강도

**국면 판단 로직**:

```python
def detect_regime(crypto_dict, macro_dict):
    """
    여러 신호를 종합하여 5가지 국면 중 하나 판단
    """

    # 신호 수집
    btc_trend = crypto_dict["btc_change30d"]
    fear_greed = crypto_dict["fear_greed_current"]
    macro_health = macro_score  # 거시경제 점수
    interest_trend = interest_rate_change

    # 국면 판단
    if btc_trend < -15 and fear_greed < 30:
        regime = "dip_buy"  # 매수 기회 (급락 + 공포)
    elif btc_trend > 10 and macro_health > 50:
        regime = "trend_follow"  # 추세 추종
    elif macro_health > 60:
        regime = "euphoria"  # 과열 경고 (과도한 낙관)
    elif interest_trend > 0.2:  # 금리 급상승
        regime = "risk_off"  # 위험회피
    else:
        regime = "neutral"  # 중립

    # 강도 계산 (0.0 ~ 1.0)
    strength = calculate_regime_strength(signals)

    return {"regime": regime, "strength": strength}
```

**5가지 국면**:

| 국면 | 특징 | 최대 조정값 |
|------|------|-----------|
| dip_buy | BTC 급락 + 공포 극심 | +6.0 |
| trend_follow | 강한 상승 추세 | +3.0 |
| neutral | 중립 신호 | 0.0 |
| risk_off | 약세 신호 | -4.0 |
| euphoria | 과열 경고 | -6.0 |

**강도 계산**:
```
strength = 신호 신뢰도 (0.0 ~ 1.0)
  • 매우 명확한 신호: 0.8 ~ 1.0
  • 중간 신호: 0.5 ~ 0.8
  • 약한 신호: 0.2 ~ 0.5
  • 매우 약한 신호: 0.0 ~ 0.2
```

---

### 3️⃣ 최종 점수 계산

**공식**:
```
base_score = ∑(11개 지표 점수)      # 0 ~ 90 범위
regime_adjustment = 국면_최대값 × 강도  # ±6.0 × strength
interaction_score = 상호작용            # ±3.0

total_score = base_score + regime_adjustment + interaction_score
범위: 0 ~ 100 (clamp)
```

**예시**:
```
base_score = 65
regime = "trend_follow", strength = 0.8
regime_adjustment = 3.0 × 0.8 = 2.4
interaction_score = 1.0

total_score = 65 + 2.4 + 1.0 = 68.4
신호: "Buy"
```

---

### 4️⃣ 신호 결정

```python
def determine_signal(score):
    if score >= 75:
        return "Strong Buy", "#00FF00"  # 진초록
    elif score >= 58:
        return "Buy", "#00DD00"  # 초록
    elif score >= 38:
        return "Hold", "#999999"  # 회색
    elif score >= 22:
        return "Partial Sell", "#FF9900"  # 주황
    else:
        return "Strong Sell", "#FF0000"  # 빨강
```

---

### 5️⃣ LLM 정성적 분석

**역할**: 점수 계산이 아닌 설명만 담당

**LLM 프롬프트 구조**:

```
System Prompt:
- 기관투자자 산하 애널리스트 역할
- 이미 계산된 점수 변경 금지
- 실제 지표값으로 분석 (점수 아님)
- 3~5문장의 종합 분석
- 11개 지표별 2~4문장 설명
- 한글/영어 모두 제공

Human Template:
- 총점, 신호, 기본점수
- 시장국면, 강도
- 조정값 정보
- 원본 데이터 (암호/거시경제)
```

**출력 JSON**:
```json
{
  "analysis_summary": "BTC 강한 상승세와 ...",
  "analysis_summary_en": "Strong Bitcoin uptrend...",
  "indicator_explanations": {
    "btc_trend": "BTC가 지난 30일간 12.5% 상승...",
    "fear_greed": "공포탐욕지수가 65로 탐욕 심화...",
    ...
    "interaction": "암호와 거시경제 신호 일치..."
  },
  "indicator_explanations_en": {
    "btc_trend": "Bitcoin has risen 12.5% over 30 days...",
    ...
  }
}
```

**보장**: 항상 11개 지표 모두 포함 (LLM 누락 대비 자동 채움)

---

## 📂 핵심 모듈 상세

### score_analyzer.py

**역할**: 전체 분석 오케스트레이션

**주요 클래스**: `ScoreAnalyzer`

**주요 메서드**:

```python
class ScoreAnalyzer:
    def analyze(self, date: str,
                crypto_data_json: str,
                macro_data_json: str) -> Dict:
        """
        완전한 분석 수행 및 결과 반환

        Args:
            date: "yyyyMMdd" 형식의 분석 날짜
            crypto_data_json: 암호화폐 데이터 (JSON 문자열)
            macro_data_json: 거시경제 데이터 (JSON 문자열)

        Returns:
            {
                "total_score": 68.4,
                "signal_type": "Buy",
                "signal_color": "#00DD00",
                "base_score": 65.0,
                "regime": "trend_follow",
                "regime_strength": 0.8,
                "regime_adjustment": 2.4,
                "interaction_score": 1.0,
                "btc_trend_score": 7.5,
                ... (11개 지표 점수),
                "analysis_summary": "...",
                "indicator_explanations": {
                    "btc_trend": "...",
                    ... (11개 지표 설명)
                },
                "indicator_explanations_en": {...},
                "date": "20260330"
            }
        """

    def calculate_indicator_scores(self, crypto_dict, macro_dict) -> Dict:
        """11개 지표 점수 계산"""

    def _determine_signal(self, score: float) -> tuple:
        """점수 → 신호 변환"""

    def _parse_llm_response(self, raw_response: str) -> Dict:
        """LLM 응답 파싱 (markdown, JSON 추출, 누락 채움)"""

    def _validate_result(self, result: Dict) -> None:
        """결과 검증 (필수 필드, 범위)"""
```

---

### data_fetcher.py

**역할**: DynamoDB에서 30일치 데이터 조회

```python
class DataFetcher:
    def get_30day_data(self, date: str) -> Dict:
        """
        30일치 데이터 조회

        Returns:
        {
            "crypto": {
                "date": "20260330",
                "current": {btc_price, ...},
                "30d_ago": {...}
            },
            "macro": {
                "date": "20260330",
                "current": {interest_rate, ...},
                "30d_ago": {...}
            }
        }
        """

    def format_for_llm(self, raw_data: Dict) -> Dict:
        """
        데이터를 LLM 프롬프트용으로 포맷
        → JSON 문자열로 변환
        """
```

---

### result_writer.py

**역할**: 분석 결과를 TB_AI_INSIGHT에 저장

```python
class ResultWriter:
    def write_analysis(self, date: str, analysis_result: Dict) -> None:
        """
        분석 결과 저장

        저장되는 필드:
        - date, total_score, signal_type, signal_color
        - 11개 지표 점수
        - regime, regime_strength, regime_adjustment
        - analysis_summary (한글/영어)
        - indicator_explanations (한글/영어)
        - created_at (타임스탬프)
        """

    def read_analysis(self, date: str) -> Dict:
        """저장된 분석 결과 조회"""
```

---

## 📊 DynamoDB 테이블

### TB_AI_INSIGHT

```
파티션 키: date (String) = "yyyyMMdd"

속성:
├── total_score (Number)              # 0~100
├── base_score (Number)               # 기본점수
├── signal_type (String)              # "Buy", ...
├── signal_color (String)             # "#00DD00"
├── regime (String)                   # "trend_follow"
├── regime_strength (Number)          # 0.0~1.0
├── regime_adjustment (Number)        # ±조정값
├── interaction_score (Number)        # ±상호작용
│
├── btc_trend_score (Number)          # 11개 지표점수
├── fear_greed_score (Number)
├── long_short_score (Number)
├── open_interest_score (Number)
├── interest_rate_score (Number)
├── treasury10y_score (Number)
├── m2_score (Number)
├── dollar_index_score (Number)
├── unemployment_score (Number)
├── cpi_score (Number)
├── interaction (Number)
│
├── analysis_summary (String)         # 종합 분석 (한글)
├── analysis_summary_en (String)      # 종합 분석 (영어)
├── indicator_explanations (String)   # JSON (11개 지표, 한글)
├── indicator_explanations_en (String)# JSON (11개 지표, 영어)
│
└── created_at (String)               # ISO 8601
```

---

## 🔧 환경 설정

### 필수 환경변수

```bash
# OpenAI
OPENAI_API_KEY=sk-...

# AWS
AWS_DEFAULT_REGION=ap-northeast-2
DYNAMODB_CRYPTO_TABLE=TB_CRYPTO_DATA
DYNAMODB_MACRO_TABLE=TB_MACRO_DATA
DYNAMODB_AI_TABLE=TB_AI_INSIGHT
```

### Python 의존성

```
langchain
langchain_openai
boto3
requests
python-dotenv
```

---

## 🧪 로컬 테스트

```python
# run_local.py 실행
python run_local.py 20260330

# 출력:
# ✅ 크립토 데이터 조회
# ✅ 매크로 데이터 조회
# 🤖 ChatGPT 분석 중...
# ✅ 분석 결과 (JSON)
```

---

## 🔐 보안 고려사항

1. **OpenAI API 키**: AWS Secrets Manager 또는 .env 사용
2. **DynamoDB**: IAM 권한으로 접근 제어
3. **데이터 검증**: 모든 입력 검증
4. **에러 로깅**: 민감한 정보 제외

---

## 📈 성능 최적화

1. **경량 구현**: numpy 없이 기본 Python으로 계산
2. **병렬 처리**: 암호/거시경제 동시 조회 (data_fetcher)
3. **LLM 호출 최소화**: 하루 1회만 실행
4. **캐싱**: 결과 DynamoDB 저장으로 재조회 시간 절약

---

## 📝 주요 고려사항

1. **결정론적 점수**: 재현 가능, 감시 가능
2. **LLM 역할 명확화**: 설명만 담당, 점수 변경 금지
3. **모든 필드 포함**: 11개 지표 항상 포함 (LLM 누락 대비)
4. **데이터 신선도**: 매일 UTC 04:00 이후 실행 가능
5. **에러 복구**: 실패 시 CloudWatch 알람

---

## 📚 참고 문서

- [INVESTMENT_FORMULA.md](./INVESTMENT_FORMULA.md) - 점수 공식 상세 설명
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Lambda 배포 가이드

---

**Last Updated**: 2026년 3월 30일
