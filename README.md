# Prospero - 암호화폐/거시경제 기반 투자 인사이트 플랫폼

**Prospero**는 비트코인과 거시경제 지표를 통합 분석하여 투자 신호를 제공하는 종합 플랫폼입니다. 결정론적 Python 기반 점수 계산과 LLM 정성적 분석을 결합하여 사용자에게 실시간 투자 분석을 제공합니다.

## 🎯 핵심 가치

- **결정론적 점수**: Python 기반의 확정적 투자 점수 계산
- **정성적 분석**: LLM을 활용한 지표별 상세 설명
- **실시간 데이터**: 암호화폐 + 거시경제 30일 데이터 기반 분석
- **자동화**: 매일 UTC 04:00 자동 데이터 수집 및 분석
- **iOS 네이티브**: 직관적인 대시보드 및 상세 분석

---

## 📊 프로젝트 구조

```
Prospero/ (Root)
├── prospero_app/         # iOS SwiftUI 앱 (프론트엔드)
├── prospero_collector/   # 데이터 수집기 (Python Lambda + EventBridge)
├── prospero_backend/     # REST API 서버 (Python Lambda + API Gateway)
├── prospero_ai/          # 분석 엔진 v4.1 (Python Lambda)
├── CLAUDE.md            # 개발 지침
└── README.md            # 이 파일
```

---

## 🏗️ 시스템 아키텍처

### 전체 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────┐
│                          iOS 앱 (prospero_app)                   │
│  • Crypto: BTC, 공포탐욕, 롱숏, OI                             │
│  • Macro: 금리, CPI, 달러인덱스 등                              │
│  • AI: 종합 점수 + 11개 지표 분석                              │
└─────────────────────────────────────────────────────────────────┘
                            ▲
                    REST API │ (HTTPS)
                            │
┌───────────────────────────┴──────────────────────────────────────┐
│               prospero_backend - API Gateway                      │
│  • /api/crypto-data/db/date-with-previous                        │
│  • /api/macro-data/db/date-with-previous                         │
└───────────────────────────┬──────────────────────────────────────┘
                            │ DynamoDB 쿼리
                            ▼
        ┌───────────────────────────────────┬─────────────────────┐
        │    TB_CRYPTO_DATA (DynamoDB)      │  TB_MACRO_DATA      │
        │  • BTC, 공포탐욕, 롱숏, OI        │  • 금리, CPI, M2    │
        │  • 30일 데이터                    │  • 달러인덱스 등    │
        └───────────────────────────────────┴─────────────────────┘
                            ▲
                    데이터 저장 │
                            │
        ┌───────────────────┴─────────────────┐
        │                                     │
        │   prospero_collector                │   prospero_ai
        │   (데이터 수집)                     │   (분석 엔진)
        │                                     │
        │  • Binance API                      │  1. 11개 지표 점수
        │  • Alternative.me                   │  2. 국면(Regime) 감지
        │  • FRED API                         │  3. 기본 점수 계산
        │                                     │  4. LLM 설명 생성
        │  실행: 매일 UTC 04:00               │  5. 결과 저장
        │  (EventBridge 스케줄)              │
        │                                     │
        └─────────────────┬─────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │   TB_AI_INSIGHT (DynamoDB)      │
        │  • 점수, 신호                   │
        │  • 11개 지표별 점수             │
        │  • 분석 설명 (한글/영어)        │
        └─────────────────────────────────┘
```

---

## 📦 모듈별 설명

### 1️⃣ prospero_app - iOS SwiftUI 앱

**역할**: 사용자 인터페이스 및 데이터 시각화

**주요 화면**:
- **Crypto View**: BTC 가격, 공포탐욕지수, 롱숏비율, OI 변화
- **Macro View**: 금리, CPI, 달러인덱스, Treasury 수익률 등
- **AI View**:
  - 종합 투자 점수 (0~100) 및 신호 (Strong Buy ~ Strong Sell)
  - 신호 범례 (5단계)
  - 11개 지표별 상세 분석 (탭 확장)

**기술 스택**: iOS 16.2+, SwiftUI, REST API 클라이언트

**위치**: `./prospero_app`
**상세**: [prospero_app/README.md](./prospero_app/README.md)

---

### 2️⃣ prospero_backend - REST API 서버

**역할**: iOS 앱과 DynamoDB 간의 데이터 중개

**API 엔드포인트**:
```
GET /api/crypto-data/db/date-with-previous?date=20260330
  → { crypto: { current, 30d_ago }, date }

GET /api/macro-data/db/date-with-previous?date=20260330
  → { macro: { current, 30d_ago }, date }
```

**기능**:
- DynamoDB에서 현재 + 30일 전 데이터 조회
- JSON 포맷 변환 및 응답
- CORS 처리

**기술 스택**: Python 3.11, Lambda, API Gateway

**위치**: `./prospero_backend`

---

### 3️⃣ prospero_collector - 데이터 수집기

**역할**: 외부 API에서 데이터 수집 및 DynamoDB 저장

**수집 대상**:
| 데이터 | 소스 | 주기 |
|--------|------|------|
| BTC 가격, OI, 펀딩레이트 | Binance API | 매일 |
| 공포탐욕지수, 롱숏비율 | Alternative.me | 매일 |
| 금리, CPI, M2, 달러인덱스 등 | FRED API | 매일 |

**실행 시간**: 매일 UTC 04:00 (AWS EventBridge)

**기술 스택**: Python 3.11, Lambda, EventBridge

**위치**: `./prospero_collector`
**상세**: [prospero_collector/README.md](./prospero_collector/README.md)

---

### 4️⃣ prospero_ai - 분석 엔진 (v4.1)

**역할**: 투자 점수 계산 및 정성적 분석 생성

**5단계 분석 파이프라인**:

#### 1️⃣ 11개 지표 점수 계산 (Python 결정론적)

**Crypto 지표 (4개, 총 50점)**:
```
BTC 추세 (0~10):   30일/7일 변화율 기반
공포탐욕 (0~20):   현재값 + 30일 평균
롱숏비율 (0~15):   비율 범위 기반
OI+가격 (0~10):    OI 변화 + 가격 변화
```

**Macro 지표 (6개, 총 40점)**:
```
기준금리 (0~10):     3~4.5% 이상적
10Y Treasury (0~8):  4~4.5% 이상적
M2 (0~8):            증가세 선호
달러인덱스 (0~7):    100~104 이상적
실업률 (0~4):        낮을수록 좋음
CPI (0~3):           2~2.5% 이상적
```

**상호작용 (0~5)**:
```
암호 추세 × 거시경제 점수 상호작용 효과
```

#### 2️⃣ 시장 국면(Regime) 감지 + 강도 평가

```
국면 종류:
  • dip_buy:       BTC 급락 + 공포 극심 (조정: +6.0)
  • trend_follow:  강세 추세 (조정: +3.0)
  • neutral:       중립 (조정: 0.0)
  • risk_off:      약세 신호 (조정: -4.0)
  • euphoria:      과열 경고 (조정: -6.0)

강도(strength): 0.0 ~ 1.0 (확률적 가중치)
최종 조정값 = max_adjustment × strength
```

#### 3️⃣ 기본 점수 + 조정값 계산

```
base_score = 11개 지표의 합 (0~90)
regime_adjustment = ±6.0 × strength
interaction_score = ±3점
total_score = base_score + regime_adjustment + interaction_score
최종 범위: 0 ~ 100
```

#### 4️⃣ 신호 결정

```
Strong Buy:     75~100점
Buy:            58~74점
Hold:           38~57점
Partial Sell:   22~37점
Strong Sell:    0~21점
```

#### 5️⃣ LLM 정성적 분석

**역할**: 점수 설명 (점수 계산 없음)
```
• analysis_summary:       종합 분석 (3~5문장, 한글/영어)
• indicator_explanations: 11개 지표별 설명 (각 2~4문장)

보장: 항상 모든 11개 지표 포함 (LLM 누락 대비)
```

**기술 스택**: Python 3.11, Lambda, OpenAI GPT-4 Turbo

**위치**: `./prospero_ai`
**상세**: [prospero_ai/INVESTMENT_FORMULA.md](./prospero_ai/INVESTMENT_FORMULA.md)

---

## 📅 데이터 흐름 (타임라인)

```
매일 UTC 04:00
  ↓
[prospero_collector] 데이터 수집
  ├→ Binance, FRED, Alternative.me 호출
  ├→ TB_CRYPTO_DATA 저장
  └→ TB_MACRO_DATA 저장
  ↓
[prospero_ai] 분석 실행 (자동/API)
  ├→ DynamoDB에서 30일 데이터 조회
  ├→ 11개 지표 점수 계산
  ├→ 시장 국면 감지 + 강도 평가
  ├→ GPT-4로 정성적 분석 생성
  └→ TB_AI_INSIGHT 저장
  ↓
[iOS 앱 사용자]
  ├→ prospero_backend API 호출
  ├→ DynamoDB 데이터 조회
  └→ 대시보드 + AI 분석 화면 렌더링
```

---

## ⚙️ AWS 인프라

### DynamoDB 테이블
| 테이블 | 파티션 키 | 역할 |
|--------|----------|------|
| TB_CRYPTO_DATA | crypto_id / date | BTC, 공포탐욕, 롱숏, OI |
| TB_MACRO_DATA | indicator_id / date | 금리, CPI, 달러인덱스 등 |
| TB_AI_INSIGHT | date | 점수, 신호, 분석 결과 |

### Lambda 함수
| 함수 | 트리거 | 역할 |
|------|--------|------|
| prospero-collector | EventBridge (매일 04:00 UTC) | 데이터 수집 |
| prospero-retrieval | API Gateway | 앱 API 백엔드 |
| prospero-ai | Lambda 호출 또는 API | 분석 엔진 |

### API Gateway
- **리소스**: `/api/crypto-data/*`, `/api/macro-data/*`
- **통합**: Lambda 프록시
- **리전**: ap-northeast-2 (서울)

---

## 📚 상세 문서

각 모듈의 상세 정보는 하위 디렉터리의 README를 참고하세요:

- [prospero_app/README.md](./prospero_app/README.md) — iOS 앱 아키텍처 및 구성
- [prospero_backend/README.md](./prospero_backend/README.md) — API 서버 구조 및 엔드포인트
- [prospero_collector/README.md](./prospero_collector/README.md) — 데이터 수집 파이프라인
- [prospero_ai/README.md](./prospero_ai/README.md) — 분석 엔진 및 점수 계산 로직

---

## 📝 최근 변경사항

**v4.1 (2026-03-30)**:
- 국면 강도(strength) 추가 (확률적 가중치)
- 상호작용 점수 영향력 축소 (±5 → ±3)
- LLM 역할 명확화 (점수 계산 제외)
- iOS AI탭 11개 지표 모두 표시 보장

---

**Last Updated**: 2026년 3월 30일
