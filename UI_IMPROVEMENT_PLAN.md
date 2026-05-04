# Prospero Crypto & Macro 대시보드 UI 개선 계획

## Context

현재 Crypto/Macro 탭이 단순 수직 나열 구조. 사용자는 참고 앱(크립토 퀀트 스타일)처럼 시각적 계층 구조와 확장성을 갖춘 UI를 원함. 향후 지표가 추가될 예정이라 카테고리 구조와 컴팩트한 레이아웃이 핵심.

**현재 문제점:**
- `MacroMetric.change` 필드가 있지만 UI에서 완전히 숨겨진 상태 (`arrow.right` 아이콘만 표시)
- Crypto MetricCard의 progress bar가 오늘 값만 표시 (전일 비교 없음)
- 지표가 늘어나면 flat 리스트는 한계에 봉착
- 핵심 수치를 한눈에 볼 수 있는 요약 영역 없음

---

## 추천 방향: 3단계 점진적 개선

### Phase 1 - 즉시 적용 (모델 변경 없음)
**아이디어 4: 델타 배지 + 아이디어 1: Summary Strip**

#### 1-A. DeltaBadge 컴포넌트 신규 생성
```
파일: prospero_app/Prospero/Views/Components/DeltaBadge.swift
```
- `change: String?` + `isPositive: Bool?` 받아 Capsule 스타일 배지 렌더링
- isPositive=true → `successColor.opacity(0.15)` 배경 + 초록 텍스트
- isPositive=false → `dangerColor.opacity(0.15)` 배경 + 빨강 텍스트
- 둘 다 nil이면 EmptyView

#### 1-B. MacroMetricCard에 DeltaBadge 추가
```
파일: prospero_app/Prospero/Views/MacroDashboardView.swift
```
- 기존 `arrow.right` 아이콘 제거
- 우측에 `DeltaBadge(changeText: metric.change, isPositive: metric.changeIsPositive)` 추가
- 카드 padding 16→12로 축소하여 더 많은 정보 표시

#### 1-C. SummaryStripView 상단 추가
```
파일: prospero_app/Prospero/Views/Components/SummaryStripView.swift
```
- 가로 스크롤 `ScrollView(.horizontal)` + `HStack(spacing: 10)`
- `SummaryChipView`: 너비 ~95pt 고정, VStack(아이콘 16pt + 값 16pt bold + 레이블 10pt)
- Crypto: BTC가격 / 공포탐욕 / MVRV / OI / L/S (5개 칩)
- Macro: 금리 / 10Y / CPI / M2 / 실업률 / DXY (6개 칩)
- `ColorUtility`에 `colorForFearGreed(_:) -> Color` 추출 (현재 두 곳에 중복 구현)

---

### Phase 2 - 카테고리 탭 (확장성 핵심)
**아이디어 3: 서브 카테고리 탭**

```
파일: prospero_app/Prospero/Views/Components/CategoryTabBar.swift
     prospero_app/Prospero/Views/CryptoDashboardView.swift
     prospero_app/Prospero/Views/MacroDashboardView.swift
```

**CategoryTabBar 컴포넌트:**
- `tabs: [String]` + `@Binding var selected: String` 제네릭 설계
- Pill 버튼 스타일: 선택 → `accentColor` 배경, 미선택 → `cardIconBackground`
- 가로 스크롤로 탭 수 제한 없음

**Crypto 카테고리 매핑:**
- All / 심리 (FearGreed, LongShort) / 온체인 (MVRV, OI) / 거래 (future)

**Macro 카테고리 매핑:**
- All / 금리 (InterestRate, Treasury10y) / 물가 (CPI) / 고용 (Unemployment) / 유동성 (M2, DollarIndex)

`@State var selectedCategory: String = "All"` + 조건부 렌더링으로 구현 (모델 변경 없음)

---

### Phase 3 - Lollipop Chart (고도화)
**아이디어 2: 오늘 vs 전일 시각 비교**

```
파일: prospero_app/Prospero/Models/CryptoDashboardData.swift (+prevBarProgress: Double? 추가)
     prospero_app/Prospero/Views/CryptoDashboardView.swift (loadCryptoData() 수정)
     prospero_app/Prospero/Views/Components/LollipopChartView.swift (신규)
```

**모델 변경 (최소화):**
```swift
struct CryptoMetric {
    // 기존 필드들...
    let prevBarProgress: Double?  // 추가: 전일 정규화 값 0.0~1.0
}
```

**LollipopChartView 구조:**
- `GeometryReader` 기반 캔버스
- baseline rail: height 2 dim 배경선
- prev dot: `Circle` 8pt, `white.opacity(0.25)`
- today dot: `Circle` 12pt, `accentColor` (border 포함)
- 두 점 사이 `Path`로 연결선 (accentColor.opacity(0.4))
- `currentProgress: Double`, `previousProgress: Double?` 파라미터

**기존 progress bar 교체:**
`MetricCard` 하단 3pt 높이 바 → `LollipopChartView(height: 20)` 교체

---

## 재사용할 기존 코드

| 재사용 대상 | 파일 위치 |
|-----------|---------|
| `ThemeManager.cardBackground, cardCornerRadius` | `Utils/ThemeManager.swift` |
| `ColorUtility.colorForInterestRate/CPI...` | `Utils/ColorUtility.swift` |
| `CryptoMetric.barProgress` (Phase 3 prev 계산 참고) | `Models/CryptoDashboardData.swift` |
| `MetricCard` 레이아웃 구조 | `Views/CryptoDashboardView.swift` |
| `MacroMetricCard` HStack 구조 | `Views/MacroDashboardView.swift` |
| `DataCard.swift` | 현재 미사용 - 삭제 또는 재활용 고려 |

---

## 화면 목업

### 현재 Crypto 화면 (Before)
```
┌─────────────────────────────────────┐
│ Prospero              오후 2:30 기준│
│──────────────────────────────────── │
│ ┌───────────────────────────────┐   │
│ │ 🟠  Bitcoin (BTC)             │   │
│ │     $94,762                   │   │
│ │     ▲ +2.3%  [탐욕 72]        │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 공포탐욕지수          72 탐욕 │   │
│ │ [====│││││████████░░░░░░░░░░]│   │
│ │  극공 공포  중립  탐욕  극탐 │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🟠  미결제약정                │   │
│ │     OpenInterest   $42.3B     │   │
│ │     ▲ +6.7%                   │   │
│ │ [████████████░░░░░░░░░░░░░░░] │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🟠  롱숏비율                  │   │
│ │     Long/Short     1.12       │   │
│ │     ▲ +0.05                   │   │
│ │ [██████████████░░░░░░░░░░░░░] │   │
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 개선된 Crypto 화면 (After - Phase 1+2+3)
```
┌─────────────────────────────────────┐
│ Prospero              오후 2:30 기준│
│──────────────────────────────────── │
│  ── Summary Strip (가로 스크롤) ──  │
│ ┌──────┐┌──────┐┌──────┐┌──────┐→  │
│ │ 🪙   ││ 😨   ││ 📊   ││ 📈   │   │
│ │$94.7K││  72  ││ 1.41 ││$42.3B│   │
│ │  BTC ││ F&G  ││ MVRV ││  OI  │   │
│ └──────┘└──────┘└──────┘└──────┘   │
│                                     │
│  ── 카테고리 탭 ──────────────────  │
│ [  All  ] [ 심리 ] [온체인] [ 거래]│
│           ▔▔▔▔▔▔                    │
│ ┌───────────────────────────────┐   │
│ │ 🟠  Bitcoin (BTC)             │   │
│ │     $94,762  ▲ +2.3%          │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🟠  미결제약정   $42.3B       │   │
│ │     OpenInterest  ▲+6.7% 🟢  │   │ ← DeltaBadge
│ │     ○────────────────●        │   │ ← Lollipop (전일→오늘)
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🔵  롱숏비율      1.12        │   │
│ │     Long/Short    ▲+0.05 🟢  │   │ ← DeltaBadge
│ │         ○──────────●          │   │ ← Lollipop
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 현재 Macro 화면 (Before)
```
┌─────────────────────────────────────┐
│ Prospero              오후 2:30 기준│
│──────────────────────────────────── │
│ ┌───────────────────────────────┐   │
│ │ 🟢  기준금리       4.50%  →  │   │
│ │     Interest Rate             │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🔴  10년물국채     4.78%  →  │   │
│ │     Treasury 10Y              │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🟡  CPI            2.89%  →  │   │
│ │     소비자물가지수             │   │
│ └───────────────────────────────┘   │
│    ... (6개 동일 패턴 반복)          │
└─────────────────────────────────────┘
```

### 개선된 Macro 화면 (After - Phase 1+2)
```
┌─────────────────────────────────────┐
│ Prospero              오후 2:30 기준│
│──────────────────────────────────── │
│  ── Summary Strip (가로 스크롤) ──  │
│ ┌──────┐┌──────┐┌──────┐┌──────┐→  │
│ │ 💰   ││ 📈   ││ 🏪   ││ 💵   │   │
│ │4.50% ││4.78% ││2.89% ││100.3 │   │
│ │ 금리 ││ 10Y  ││ CPI  ││ DXY  │   │
│ └──────┘└──────┘└──────┘└──────┘   │
│                                     │
│  ── 카테고리 탭 ──────────────────  │
│ [ All ] [ 금리 ] [ 물가 ] [ 고용 ] │
│          ▔▔▔▔▔▔                     │
│ ┌───────────────────────────────┐   │
│ │ 🟢  기준금리      4.50%       │   │
│ │     Interest Rate  ─ 0.00% ⚪│   │ ← DeltaBadge (변화없음)
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🔴  10년물국채    4.78%       │   │
│ │     Treasury 10Y  ▲+0.12% 🔴│   │ ← DeltaBadge (상승=위험)
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │
│ │ 🟡  CPI            2.89%      │   │
│ │     소비자물가지수 ▼-0.05% 🟢│   │ ← DeltaBadge (하락=좋음)
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 검증 방법

1. Xcode 시뮬레이터에서 Crypto 탭 → Summary Strip 가로 스크롤 동작 확인
2. Macro 탭 → 각 지표 카드에 델타 배지 표시 확인
3. 카테고리 탭 전환 시 지표 필터링 동작 확인
4. 다크/라이트 모드 양쪽에서 색상 정상 표시 확인
5. 데이터 로딩 전(로딩 상태) → 로딩 후 상태 전환 시 레이아웃 깨짐 없는지 확인

---

## 구현 우선순위 요약

| Phase | 내용 | 모델 변경 | 예상 난이도 |
|-------|------|---------|---------|
| 1 | 델타 배지 + Summary Strip | 없음 | 쉬움 |
| 2 | 카테고리 탭 | 없음 | 보통 |
| 3 | Lollipop Chart | `prevBarProgress` 1필드 추가 | 보통 |
