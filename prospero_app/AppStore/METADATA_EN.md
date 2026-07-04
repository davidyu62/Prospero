# Prospero — App Store Connect 영문 메타데이터 (v1.0)

App Store Connect의 각 입력란에 그대로 복사해 넣을 수 있도록 필드별로 정리했습니다.
각 항목의 글자 수 제한을 준수했습니다. (스크린샷은 `screenshots/` 폴더 참조)

---

## App Name (앱 이름) — 최대 30자

```
Prospero: Crypto & Macro
```
(24자)

> 대안: `Prospero — Market Signals` (24자)

---

## Subtitle (부제) — 최대 30자

```
Bitcoin, macro & AI signals
```
(27자)

---

## Promotional Text (프로모션 텍스트) — 최대 170자
> 앱 심사 없이 언제든 수정 가능한 영역. 프로모션·시즌성 문구에 활용.

```
Track Bitcoin, on-chain metrics, and key macro indicators in one place — plus a daily AI investment score that reads the whole market at a glance.
```
(143자)

---

## Keywords (키워드) — 최대 100자, 쉼표로 구분(공백 최소화)

```
bitcoin,crypto,BTC,fear greed,macro,CPI,inflation,DXY,VIX,treasury,on-chain,MVRV,investing
```
(90자)

---

## Description (설명) — 최대 4000자

```
Prospero brings crypto and macro markets together in one clean, fast dashboard — so you can read the market at a glance instead of juggling ten different tabs.

Every day, Prospero pulls the numbers that actually move markets and turns them into a single, easy-to-read investment score, powered by AI cross-indicator analysis.

CRYPTO DASHBOARD
• Bitcoin (BTC) price with 24h change and trend
• Fear & Greed Index with contextual reading (e.g. "extreme fear — oversold")
• Open Interest (futures market)
• Long/Short Ratio
• MVRV valuation
• Funding Rate
• Active Addresses (network activity)

MACRO DASHBOARD
• Federal Funds Rate
• 10-Year Treasury Yield
• CPI (Consumer Price Index)
• M2 Money Supply
• Unemployment Rate
• Dollar Index (DXY)
• VIX (volatility)
• Oil Price (WTI Crude)
• Yield Spread (10Y–2Y)
• Break-Even Inflation
Each indicator comes with a plain-language interpretation so you know what the number means for risk appetite.

AI INVESTMENT SCORE
• A daily 0–100 score with a clear Buy / Hold / Sell signal
• 7-day score trend so you can see momentum
• Cross-Indicator Analysis that explains, in one short paragraph, why the score moved — connecting crypto momentum, valuation, and macro conditions

WHY PROSPERO
• One screen for both crypto and macro — no more tab-hopping
• Real numbers, updated daily
• Clean light and dark themes
• English and Korean supported
• Built for speed: your data restores instantly between tabs

Prospero is an information and analytics tool. It does not execute trades and does not hold your funds.

DISCLAIMER
Prospero is provided for informational and educational purposes only and does not constitute financial, investment, or trading advice. Markets are volatile and past performance does not guarantee future results. Always do your own research and consult a licensed professional before making investment decisions.
```

> 위 본문은 약 1,700자 내외로 4000자 제한 이내입니다.

---

## What's New (새로운 기능) — 버전별 릴리스 노트

```
Welcome to Prospero 1.0.

• Crypto dashboard: Bitcoin price, Fear & Greed Index, Open Interest, Long/Short Ratio, MVRV, Funding Rate, and Active Addresses
• Macro dashboard: 10 key indicators including Fed Funds Rate, 10Y Treasury, CPI, DXY, and VIX
• AI investment score with a daily Buy/Hold/Sell signal and cross-indicator analysis
• Light and dark themes, English and Korean

Thanks for trying Prospero. We'd love your feedback!
```

---

## Category (카테고리)
- **Primary**: Finance
- **Secondary (선택)**: Business 또는 News

---

## 등록 시 별도 준비/설정 체크리스트

App Store Connect 제출 전 아래 항목을 반드시 준비/확인해야 합니다.

### 필수 URL
- [ ] **Privacy Policy URL** — AdMob(광고 SDK)을 사용하므로 **개인정보처리방침 URL이 필수**입니다. 반드시 공개된 웹 페이지 필요.
- [ ] **Support URL** — 문의/지원 페이지 (간단한 랜딩 페이지 또는 이메일 안내 페이지도 가능)
- [ ] **Marketing URL** (선택)

### App Privacy (앱 개인정보 보호) 신고
- [ ] AdMob(Google Mobile Ads) SDK 사용 → **광고용 데이터 수집 신고** 필요
  - Identifiers → **Device ID (IDFA)**: 추적(Tracking) 목적으로 사용 가능성 → "Data Used to Track You"에 신고
  - SKAdNetwork 사용(Info.plist에 SKAdNetworkItems 등록됨) → 광고 성과 측정
  - Usage Data(제품 상호작용) — 광고 SDK가 수집할 수 있음
- [ ] **App Tracking Transparency(ATT)**: IDFA로 추적한다면 `NSUserTrackingUsageDescription` 문자열과 ATT 권한 요청 프롬프트가 필요합니다. (현재 Info.plist에 미포함 → 추적 시 추가 필요)

### 기타 설정
- [ ] **Age Rating(연령 등급)**: 금융 정보 앱 → 대체로 4+ (도박/음란 없음). 설문에서 "무제한 웹 접근/사용자 생성 콘텐츠" 없음으로 응답.
- [ ] **Export Compliance(수출 규정)**: HTTPS 표준 암호화만 사용 시 "면제(exempt)" 선택 가능. `ITSAppUsesNonExemptEncryption = NO`를 Info.plist에 추가하면 매 빌드 질문을 건너뛸 수 있음.
- [ ] **App Icon(1024×1024)**: 마케팅 아이콘 준비 (알파 채널 없는 PNG)
- [ ] **디바이스 지원**: iPhone 전용으로 변경 완료(device family = 1). iPad 스크린샷 불필요.
- [ ] **번들 ID**: `com.davidyu.Prospero`, 버전 1.0 (MARKETING_VERSION)

### 스크린샷 (`screenshots/` 폴더)
두 가지 사이즈 세트를 준비했습니다. **App Store Connect가 요구하는 슬롯에 맞는 세트를 업로드**하세요.
- **`*_1284x2778.png`** (6.5"/6.7" 슬롯용) — Crypto/Macro/AI × 다크/라이트 6장. **1284×2778** 정확히 일치.
  현재 App Store Connect가 이 사이즈(1242×2688 또는 1284×2778)를 요구하므로 **이 세트를 업로드**하면 됩니다.
- **`*_6.9.png`** (6.9" 슬롯용) — 원본 **1320×2868** 6장. ASC가 6.9" 슬롯을 요구할 때 사용.
- 참고: 앱이 iOS 26.2를 요구해 1284×2778/1242×2688은 네이티브 렌더가 불가하여, 6.9" 원본을
  해당 해상도로 정확히 리사이즈했습니다(종횡비 차 0.4% 미만, 육안 동일).
- 라이트/다크 중 한 세트만 올려도 되고, 슬롯당 최대 10장까지 등록 가능.
