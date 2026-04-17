# prospero_app - iOS SwiftUI 애플리케이션

Prospero의 iOS 클라이언트 애플리케이션입니다. 암호화폐/거시경제 데이터를 시각화하고 AI 분석 결과를 표시합니다.

---

## 📱 앱 개요

### 주요 기능

**Crypto Dashboard**
- BTC 현재 가격 및 30일 변화율 시각화
- 공포탐욕지수 (Fear & Greed Index) 표시
- 롱/숏 비율 (Long/Short Ratio) 표시
- OI+가격 변화 (Open Interest + Price Change)
- 각 지표별 색상 코딩 (빨강/주황/초록)

**Macro Dashboard**
- 기준금리 (Interest Rate)
- CPI (소비자물가지수)
- 10년물 Treasury 수익률
- 달러인덱스 (Dollar Index)
- M2 (통화공급량)
- 실업률 (Unemployment Rate)
- 각 지표별 30일 추세 표시

**AI Analysis Tab**
- 종합 투자 점수 (0~100)
- 신호 표시 (Strong Buy ~ Strong Sell)
- 신호 범례 (5단계 설명)
- 11개 지표별 상세 분석
  - BTC 추세, 공포탐욕, 롱숏비율, OI+가격
  - 기준금리, 10Y Treasury, M2, 달러인덱스
  - 실업률, CPI, 상호작용(Interaction)

**Settings & Features**
- 다국어 지원 (한국어, 영어)
- 앱 아이콘 미리보기
- 테마 관리

### 기술 스택
- **최소 iOS 버전**: iOS 16.2+
- **UI Framework**: SwiftUI
- **데이터 포맷**: REST API (JSON via Codable)
- **네트워킹**: URLSession
- **타임대**: USD 시간대 (America/New_York) 기반 날짜 계산

---

## 🏗️ 프로젝트 구조

```
Prospero/
├── ProsperoApp.swift              # 앱 진입점
├── AppDelegate.swift              # 앱 생명주기
├── ContentView.swift              # 메인 탭 네비게이션
│
├── Views/                         # 화면 구성
│   ├── CryptoDashboardView.swift  # Crypto 대시보드
│   ├── MacroDashboardView.swift   # Macro 대시보드
│   ├── AIView.swift               # AI 분석 탭
│   ├── SettingsView.swift         # 설정 화면
│   ├── SplashScreenView.swift     # 스플래시 화면
│   ├── AppIconPreviewView.swift   # 아이콘 미리보기
│   └── Components/
│       ├── DataCard.swift         # 데이터 카드 (공통 UI)
│       └── BannerAdView.swift     # 광고 배너
│
├── Models/                        # Swift Codable 구조체
│   ├── CryptoAPIResponse.swift    # Crypto API 응답
│   ├── MacroAPIResponse.swift     # Macro API 응답
│   ├── CryptoDashboardData.swift  # Crypto 화면 데이터
│   ├── MacroDashboardData.swift   # Macro 화면 데이터
│   ├── DashboardData.swift        # 공통 데이터 모델
│   └── InvestmentScore.swift      # AI 점수 및 분석 모델
│
├── Services/                      # API 클라이언트
│   ├── CryptoAPIService.swift     # Crypto 데이터 조회
│   ├── MacroAPIService.swift      # Macro 데이터 조회
│   ├── AIAnalysisAPIService.swift # AI 분석 조회
│   └── RewardedAdManager.swift    # 광고 관리
│
├── Utils/                         # 유틸리티
│   ├── Localization.swift         # 다국어 지원 (한글/영어)
│   ├── ColorUtility.swift         # 지표별 색상 매핑
│   ├── AppColors.swift            # 앱 색상 정의
│   ├── ThemeManager.swift         # 테마 관리
│   └── AppIconGenerator.swift     # 앱 아이콘 생성
│
├── Prospero.xcodeproj/            # Xcode 프로젝트
└── Info.plist                     # 앱 메타데이터
```

---

## 📊 화면 구성 및 데이터 흐름

### 1️⃣ ContentView - 메인 탭 네비게이션

```
┌────────────────────────────────┐
│       Prospero (Header)        │
├────────────────────────────────┤
│                                │
│  [선택된 탭 컨텐츠]             │
│                                │
├────────────────────────────────┤
│ 🔷 Crypto │ 📊 Macro │ 🤖 AI  │
└────────────────────────────────┘
```

**데이터 흐름**:
1. 앱 시작 → SplashScreenView 표시
2. 탭 선택 → 해당 대시보드 로드
3. API 호출 → 데이터 수신 → 화면 렌더링

---

### 2️⃣ CryptoDashboardView - 암호화폐 대시보드

```
┌────────────────────────────────┐
│    BTC 가격 (현재값 + 30일%)   │
│    색상: 빨강/주황/초록         │
├────────────────────────────────┤
│  공포탐욕지수    │  롱숏비율    │
│  (현재 + 30일)  │  (비율 표시) │
├────────────────────────────────┤
│     OI+가격 변화              │
│    (현재 + 30일 추세)         │
└────────────────────────────────┘
```

**핵심 로직**:
- 날짜 계산: USD 시간대 기반 (UTC-5)
  - USD 04:00 이전이면 전날 데이터 + 전전날 데이터 요청
- ColorUtility로 각 지표별 색상 결정
- 백그라운드 상태에서도 자동 새로고침

**API 호출**:
```swift
GET /api/crypto-data/db/date-with-previous?date=20260330
```

---

### 3️⃣ MacroDashboardView - 거시경제 대시보드

```
┌────────────────────────────────┐
│   기준금리    │  10Y Treasury   │
│  (현재/30일) │   (현재/30일)   │
├────────────────────────────────┤
│   달러인덱스   │     M2          │
│  (현재/30일)  │   (현재/30일)   │
├────────────────────────────────┤
│  실업률       │     CPI         │
│ (현재/30일)  │   (현재/30일)   │
└────────────────────────────────┘
```

**핵심 로직**:
- 각 지표마다 이상적 범위 정의 (ColorUtility 참고)
- 30일 변화율 표시로 추세 파악
- 실업률은 낮을수록, CPI는 2~2.5%가 이상적

**API 호출**:
```swift
GET /api/macro-data/db/date-with-previous?date=20260330
```

---

### 4️⃣ AIView - AI 분석 탭

```
┌────────────────────────────────┐
│    총점: 72.5 / 100            │
│    신호: Buy (파란색)          │
├────────────────────────────────┤
│  신호 범례                     │
│  Strong Buy  75-100 (진초록)   │
│  Buy         58-74  (초록)     │
│  Hold        38-57  (회색)     │
│  Partial Sell 22-37 (주황)     │
│  Strong Sell  0-21  (빨강)     │
├────────────────────────────────┤
│  지표별 분석 (탭으로 확장)     │
│  ▶ BTC 추세                    │
│  ▶ 공포탐욕지수                │
│  ▶ 롱숏비율                    │
│  ... (11개 지표)               │
└────────────────────────────────┘
```

**11개 지표**:
1. BTC 추세
2. 공포탐욕지수
3. 롱숏비율
4. OI+가격
5. 기준금리
6. 10Y Treasury
7. M2
8. 달러인덱스
9. 실업률
10. CPI
11. 상호작용(Interaction)

**데이터 구조**:
```swift
struct InvestmentScore: Codable {
    let date: String
    let total_score: Double
    let signal_type: String
    let signal_color: String
    let base_score: Double
    let regime: String
    let regime_strength: Double
    let regime_adjustment: Double
    let interaction_score: Double

    // 11개 지표 점수
    let btc_trend_score: Double
    let fear_greed_score: Double
    // ... 등등

    // 분석 설명 (한글/영어)
    let analysis_summary: String
    let analysis_summary_en: String
    let indicator_explanations: [String: String]
    let indicator_explanations_en: [String: String]
}
```

---

## 🌐 API 호출 구조

### CryptoAPIService

```swift
func fetchCryptoData(date: String) -> CryptoDashboardData
  ↓
GET /api/crypto-data/db/date-with-previous?date={yyyyMMdd}
  ↓
응답: {
  "crypto": {
    "current": { btcPrice, btcChange7d, btcChange30d, ... },
    "30d_ago": { btcPrice, ... }
  },
  "date": "20260330"
}
  ↓
CryptoDashboardData로 매핑
  ↓
CryptoDashboardView에서 렌더링
```

### MacroAPIService

```swift
func fetchMacroData(date: String) -> MacroDashboardData
  ↓
GET /api/macro-data/db/date-with-previous?date={yyyyMMdd}
  ↓
응답: {
  "macro": {
    "current": { interestRate, cpi, dollarIndex, ... },
    "30d_ago": { interestRate, ... }
  },
  "date": "20260330"
}
  ↓
MacroDashboardData로 매핑
  ↓
MacroDashboardView에서 렌더링
```

### AIAnalysisAPIService

```swift
func fetchAIAnalysis(date: String) -> InvestmentScore
  ↓
GET /api/ai-analysis/db/date?date={yyyyMMdd}
  ↓
응답: {
  "total_score": 72.5,
  "signal_type": "Buy",
  "indicator_explanations": { ... 11개 지표 ... },
  ...
}
  ↓
InvestmentScore로 매핑
  ↓
AIView에서 렌더링
```

---

## 🎨 색상 시스템

### ColorUtility 함수 매핑

**Crypto 변화율 색상** (`colorForCryptoChange`):
```
≥ +5%:        밝은 초록 (0.20, 0.95, 0.40)
+2%~+5%:      중간 초록 (.successColor)
0%~+2%:       밝은 초록 (0.40, 0.85, 0.50)
0%:           회색 (0.70, 0.70, 0.70)
-2%~0%:       밝은 빨강 (1.0, 0.50, 0.50)
-5%~-2%:      중간 빨강 (1.0, 0.60, 0.60)
≤ -5%:        어두운 빨강 (1.0, 0.30, 0.30)
```

**Macro 지표 색상**:
- `colorForCPI`: 2~2.5% 범위 = 초록
- `colorForInterestRate`: 3~4.5% 범위 = 초록
- `colorForUnemployment`: 낮을수록 = 초록
- 등등...

---

## 🌍 다국어 지원

### Localization.swift

**지원 언어**: 한국어, 영어

**텍스트 매핑 예시**:
```swift
// 한글
"BTC Trend" → "BTC 추세"
"Fear & Greed" → "공포탐욕지수"
"미결제 약정" → Open Interest 항목명

// 영어는 그대로 표시
```

**사용 예**:
```swift
Text(localize("BTC Trend"))  // 현재 언어 설정에 따라 표시
```

---

## 📋 모델 정의

### InvestmentScore (AI 점수)

```swift
struct InvestmentScore: Codable {
    let date: String
    let total_score: Double              // 0~100
    let signal_type: String              // "Strong Buy", "Buy", "Hold", ...
    let signal_color: String             // "#00FF00", "#FF6600", ...
    let base_score: Double               // 기본 점수
    let regime: String                   // "dip_buy", "trend_follow", ...
    let regime_strength: Double          // 0.0~1.0
    let regime_adjustment: Double        // ±조정값
    let interaction_score: Double        // ±상호작용

    // 11개 지표 점수
    let btc_trend_score: Double
    let fear_greed_score: Double
    let long_short_score: Double
    let open_interest_score: Double
    let interest_rate_score: Double
    let treasury10y_score: Double
    let m2_score: Double
    let dollar_index_score: Double
    let unemployment_score: Double
    let cpi_score: Double
    let interaction: Double

    // 분석 설명
    let analysis_summary: String
    let analysis_summary_en: String
    let indicator_explanations: [String: String]
    let indicator_explanations_en: [String: String]
}
```

### CryptoAPIResponse

```swift
struct CryptoAPIResponse: Codable {
    let crypto: CryptoData
    let date: String
}

struct CryptoData: Codable {
    let current: [String: Double]  // btcPrice, fearGreedIndex, ...
    let 30d_ago: [String: Double]
}
```

### MacroAPIResponse

```swift
struct MacroAPIResponse: Codable {
    let macro: MacroData
    let date: String
}

struct MacroData: Codable {
    let current: [String: Double]  // interestRate, cpi, ...
    let 30d_ago: [String: Double]
}
```

---

## ⏰ 시간대 처리 (중요)

### 날짜 계산 로직

**상황**: 데이터는 매일 UTC 04:00에 생성됨

**처리**:
1. 현재 시간을 USD 시간대로 변환 (America/New_York)
2. USD 시간이 04:00 이전이면 → 전날 데이터 + 전전날 데이터 요청
3. USD 시간이 04:00 이후면 → 당일 데이터 + 전날 데이터 요청

**예시**:
```
한국: 2026-03-03 10:00 (수요일)
→ USD: 2026-03-02 20:00 (화요일)
→ USD 04:00 이전이므로 3월2일, 3월1일 데이터 요청
```

**코드 위치**: `CryptoDashboardView.swift (207-238줄)`, `MacroDashboardView.swift (161-188줄)`

---

## 🔧 설정 및 상수

### 시스템 설정
- **Bundle ID**: com.davidyu.Prospero
- **최소 iOS**: 16.2+
- **Orientation**: 세로모드 전용 (Portrait only)
- **확대/축소**: 비활성화

### API 엔드포인트
- **Debug**: `http://localhost:8080` (로컬 개발)
- **Release**: AWS API Gateway URL (프로덕션)

**변경 위치**: `CryptoAPIService.swift`, `MacroAPIService.swift`, `AIAnalysisAPIService.swift`

---

## 📝 주요 파일 설명

### Views

| 파일 | 역할 |
|------|------|
| ContentView.swift | 메인 탭 네비게이션 |
| CryptoDashboardView.swift | Crypto 데이터 표시 및 날짜 계산 |
| MacroDashboardView.swift | Macro 데이터 표시 및 날짜 계산 |
| AIView.swift | 점수, 신호, 11개 지표 분석 표시 |
| SettingsView.swift | 언어 설정, 테마 관리 |
| SplashScreenView.swift | 앱 로딩 화면 |

### Services

| 파일 | 역할 |
|------|------|
| CryptoAPIService.swift | GET /api/crypto-data/... 호출 |
| MacroAPIService.swift | GET /api/macro-data/... 호출 |
| AIAnalysisAPIService.swift | AI 분석 데이터 조회 |
| RewardedAdManager.swift | 광고 관리 |

### Utils

| 파일 | 역할 |
|------|------|
| Localization.swift | 한글/영어 텍스트 매핑 |
| ColorUtility.swift | 지표값 → 색상 변환 |
| AppColors.swift | 앱 전역 색상 정의 |
| ThemeManager.swift | 테마 전환 |

---

## 📌 주의사항

1. **API 엔드포인트**: 배포 시 프로덕션 URL로 변경 필요
2. **시간대**: USD 기준으로 날짜 계산하므로 TimeZone 설정 확인
3. **네트워킹**: 모든 API 호출은 백그라운드에서 처리
4. **에러 처리**: 네트워크 오류 시 이전 캐시 데이터 표시

---

**Last Updated**: 2026년 3월 30일
