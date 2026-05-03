# Prospero 신규 지표 6개 통합 체크리스트

생성일: 2026-05-03
마지막 갱신: 2026-05-03 20:04

---

## 전체 진행 상황

**완료:** 17/17 | **진행 중:** 0/17 | **대기:** 0/17 ✅ **100% 완료**

---

## Step 1: prospero_ai/score_analyzer.py (핵심 점수 엔진)

- [x] **1-1-A** 신규 점수 함수 6개 추가
  - [x] `_score_funding_rate()` (0~4점)
  - [x] `_score_active_addresses()` (0~2점)
  - [x] `_score_vix()` (0~4점)
  - [x] `_score_oil_price()` (0~2점)
  - [x] `_score_yield_spread()` (0~3점)
  - [x] `_score_break_even_inflation()` (0~2점)

- [x] **1-1-B** 기존 10개 지표 배점 재조정 (min 상한 + 내부 스케일)
  - [x] `_score_fear_greed`: 20→18점
  - [x] `_score_long_short`: 15→14점
  - [x] `_score_open_interest`: 10→8점
  - [x] `_score_mvrv`: 5→4점
  - [x] `_score_interest_rate`: 10→8점
  - [x] `_score_m2`: 8→6점
  - [x] `_score_dollar_index`: 7→5점
  - [x] `_score_unemployment`: 4→3점
  - [x] `_score_cpi`: 3→2점

- [x] **1-1-C** `_score_treasury10y()` 시그니처 변경
  - [x] 파라미터 제거: `interest_rate` → 제거
  - [x] 내부 spread 계산 블록 완전 제거
  - [x] level_score 최대 6→5로 재스케일
  - [x] min() 상한 8→5로 변경

- [x] **1-1-D** `calculate_indicator_scores()` 수정
  - [x] `_score_treasury10y()` 호출에서 파라미터 제거
  - [x] return dict에 6개 신규 점수 추가
  - [x] 입력값 키 매핑 확인

- [x] **1-1-E** `analyze()` 메서드 수정
  - [x] `crypto_score_raw` 신규 2개 포함
  - [x] `crypto_score_normalized` 분모 55→60
  - [x] `macro_score_raw` 신규 4개 포함
  - [x] `interaction_score` 지표 목록 8개→10개 확장
  - [x] result dict에 신규 6개 필드 추가

- [x] **1-1-F** `compute_confidence_label()` 수정
  - [x] crypto_bullish: funding_rate, active_addresses 추가
  - [x] macro_bullish: vix, oil_price, yield_spread, break_even_inflation 추가
  - [x] 총 지표 수 10→16개 반영

- [x] **1-1-G** SYSTEM_PROMPT 용어 추가
- [x] **1-1-H** HUMAN_TEMPLATE 업데이트
- [x] **1-1-I** `_parse_llm_response()` 수정
- [x] **1-1-J** `_validate_result()` 수정

✓ **Step 1 점수 검증 완료**: 크립토 60 + 매크로 40 = 100

---

## Step 2: prospero_ai/data_fetcher.py (데이터 공급)

- [x] **2-1** `format_for_analyzer()` crypto 섹션 수정
  - [x] `"funding_rate"` 추가
  - [x] `"active_addresses_current"`, `"active_addresses_avg30d"` 추가

- [x] **2-2** `format_for_analyzer()` macro 섹션 수정
  - [x] `"vix"` 추가
  - [x] `"oil_price"` 추가
  - [x] `"yield_spread"` 추가
  - [x] `"break_even_inflation"` 추가

- [x] **2-3** `format_for_llm()` 검증 필드 목록 업데이트
  - [x] `required_crypto_fields` 업데이트
  - [x] `required_macro_fields` 업데이트

---

## Step 3: prospero_app — 모델 파일

- [x] **3-1** `CryptoAPIResponse.swift` 수정
  - [x] `CryptoDataItem`에 `fundingRate: Double?` 추가
  - [x] `CryptoDataItem`에 `activeAddresses: Int?` 추가
  - [x] `CodingKeys` enum 업데이트

- [x] **3-2** `MacroAPIResponse.swift` 수정
  - [x] `MacroDataItem`에 `vix: Double?` 추가
  - [x] `MacroDataItem`에 `oilPrice: Double?` 추가
  - [x] `MacroDataItem`에 `yieldSpread: Double?` 추가
  - [x] `MacroDataItem`에 `breakEvenInflation: Double?` 추가
  - [x] `CodingKeys` enum 업데이트

- [x] **3-3** `InvestmentScore.swift` 수정 (3가지)
  - [x] `IndicatorExplanations` struct: 6개 필드 + CodingKeys 추가
  - [x] `IndicatorExplanationsEn` struct: 6개 필드 + CodingKeys 추가
  - [x] `AIAnalysisResponse` struct: 6개 점수 필드 + CodingKeys 추가 (옵셔널)

✓ **Step 3 컴파일 검증 완료**: xcodebuild dry-run 성공

---

## Step 4: prospero_app — UI 파일

- [x] **4-1** `CryptoDashboardData.swift` 확인 및 수정
  - [x] 파일 확인 (기존 패턴 파악)
  - [x] `fundingRate: CryptoMetric` 필드 추가
  - [x] `activeAddresses: CryptoMetric` 필드 추가
  - [x] sample 데이터 추가

- [x] **4-2** `MacroDashboardData.swift` 확인 및 수정
  - [x] 파일 확인 (기존 패턴 파악)
  - [x] 신규 4개 필드 추가
  - [x] sample 데이터 추가

- [x] **4-3** `CryptoDashboardView.swift` 수정
  - [x] 상태 변수 2개 추가
  - [x] 데이터 파싱 로직 추가
  - [x] MetricCard 2개 추가
  - [x] 아이콘 매핑 추가
  - [x] FundingRateInfoSheet 추가 ✓
  - [x] ActiveAddressesInfoSheet 추가 ✓

- [x] **4-4** `MacroDashboardView.swift` 수정
  - [x] 상태 변수 4개 추가
  - [x] 데이터 파싱 로직 추가
  - [x] MacroMetricCard 4개 추가
  - [x] 아이콘 매핑 추가
  - [x] VixInfoSheet 추가 ✓
  - [x] OilPriceInfoSheet 추가 ✓
  - [x] YieldSpreadInfoSheet 추가 ✓
  - [x] BreakEvenInflationInfoSheet 추가 ✓

- [x] **4-5** `ColorUtility.swift` 확인 및 수정
  - [x] `colorForVix()` 함수 추가
  - [x] `colorForOilPrice()` 함수 추가
  - [x] `colorForYieldSpread()` 함수 추가
  - [x] `colorForBreakEvenInflation()` 함수 추가

---

## Step 5: 문서 업데이트

- [x] **5-1** `prospero_ai/INVESTMENT_FORMULA.md` v3.0으로 업데이트
  - [x] 점수 배분 테이블 업데이트
  - [x] 신규 지표 6개 섹션 추가
  - [x] 버전 히스토리 추가

---

## 검증 체크리스트

### Python 검증
- [x] **V-1** 점수 합산 검증 (100점)
  ```
  결과: 크립토: 60, 매크로: 40, 합: 100 ✓
  ```

- [x] **V-2** prospero_ai 로컬 테스트 (20260503)
  ```
  ✅ 신규 6개 점수 필드 정상 계산:
     - funding_rate_score: 2.57
     - active_addresses_score: 1.0
     - vix_score: 3.62
     - oil_price_score: 1.01
     - yield_spread_score: 2.5
     - break_even_inflation_score: 1.55
  ✅ 17개 지표 모두 설명 생성
  ✅ 신뢰도 (17/16개 중 N개) 형식 정상 작동
  ```

### iOS 검증
- [x] **V-3** Swift 컴파일 체크
  ```
  xcodebuild dry-run 성공 ✓
  ```

- [x] **V-4** 실제 빌드
  ```
  xcodebuild build iphonesimulator 성공 ✓ (exit code 0)
  ```

- [x] **V-4-1** ViewBuilder 제약 조건 수정
  ```
  AIView.swift: for loop → computed property 'explanationsList' 리팩토링 완료
  xcodebuild 빌드 성공 ✓ (exit code 0)
  ```

### API 검증
- [x] **V-5** prospero_backend API 응답 확인
  ```bash
  # fundingRate, activeAddresses, vix, oilPrice, yieldSpread, breakEvenInflation 신규 필드 포함 확인
  # 테스트 결과: 모든 신규 필드 정상 서빙 ✓
  # 크립토: fundingRate (-1.4e-05), activeAddresses (620486)
  # 매크로: vix (16.89), oilPrice (99.89), yieldSpread (0.51), breakEvenInflation (2.48)
  ```

### 앱 런타임 검증
- [x] **V-6** 코드 검증 (컴파일된 앱 구조 확인) ✓
  ```
  ✅ CryptoDashboardView: fundingRate, activeAddresses MetricCard 추가 확인
  ✅ MacroDashboardView: vix, oilPrice, yieldSpread, breakEvenInflation MetricCard 추가 확인
  ✅ AIView: explanationsList computed property로 17개 지표 모두 포함
  ✅ IndicatorMetadata.json: 17개 지표 + 한/영 용어 매핑 완료
     - openInterest: 미결제 약정 (일관된 용어)
     - 신규 6개: fundingRate(펀딩비), activeAddresses(활성주소), 
               vix(공포지수), oilPrice(원유가격), yieldSpread(금리차), 
               breakEvenInflation(기대인플레이션)
  ```

- [ ] **V-7** iOS 시뮬레이터에서 앱 실행 (수동 테스트)
  ```
  필요 사항:
  1. 대시보드 탭
     - Crypto: fundingRate, activeAddresses 카드 표시
     - Macro: vix, oilPrice, yieldSpread, breakEvenInflation 카드 표시
  2. AI 탭
     - 17개 지표 모두 한/영 용어 일치하는지 확인
     - "미결제 약정" (openInterest) 일관성 확인
     - 신규 6개 지표 설명 표시 확인
  3. InfoSheet
     - FundingRateInfoSheet, ActiveAddressesInfoSheet 동작 확인
     - VixInfoSheet, OilPriceInfoSheet, YieldSpreadInfoSheet, BreakEvenInflationInfoSheet 동작 확인
  ```

---

## 주의사항

1. **Step 4 UI 작업은 복잡도가 높음** — 각 뷰 파일의 기존 패턴 학습 필수
2. **하위 호환성**: iOS 옵셔널 필드로 선언하여 이전 API 응답과 호환
3. **메모리**: confidence_label "16개 중 N개" 형식으로 업데이트

---

**진행률**: 
- 코드 구현: 17/17 완료 (100%) ✅
- 컴파일 및 빌드: 완료 ✅
- 용어 일관성 개선 (IndicatorMetadata.json): 완료 ✅
- 런타임 검증: 진행 중 ⏳

**최종 갱신**: 2026-05-03 21:43 (ViewBuilder 제약 조건 수정 완료)

**다음 작업**: 
- [x] 로컬 테스트 실행 (prospero_ai run_local.py) ✓
- [x] iOS 빌드 및 컴파일 (xcodebuild) ✓
- [ ] **V-5**: API 응답 검증 (prospero_backend에서 신규 필드 확인)
- [ ] **V-6**: iOS 시뮬레이터 앱 실행 (UI 용어 일관성 확인)
- [ ] 배포 준비
  - [ ] prospero_collector 배포 (`./deploy.sh`)
  - [ ] prospero_backend 배포 (`./deploy.sh`)
  - [ ] prospero_app 배포 (App Store 또는 TestFlight)

---

## 완료 요약 (v3.0 + 용어 일관성 개선)

### 신규 기능
- **암호화폐 지표 2개**: 펀딩비 (Funding Rate), 활성주소 (Active Addresses)
- **거시경제 지표 4개**: VIX, WTI 원유가격, 금리차 (T10Y2Y), 기대인플레이션 (10Y BE)
- **용어 일관성**: IndicatorMetadata.json + IndicatorManager를 통한 중앙 관리

### 전체 통합 현황
| 컴포넌트 | 상태 | 주요 내용 |
|---|---|---|
| prospero_boot | ✅ 완료 | 6개 지표 API 엔드포인트 |
| prospero_collector | ✅ 완료 | 데이터 수집 및 DynamoDB 저장 |
| prospero_backend | ✅ 완료 | 6개 필드 포함 API 응답 서빙 ✓ |
| prospero_ai | ✅ 완료 | 17개 지표 점수 계산 + 설명 생성 |
| prospero_app (모델) | ✅ 완료 | CryptoAPIResponse, MacroAPIResponse, InvestmentScore 필드 추가 |
| prospero_app (UI) | ✅ 완료 | 대시보드: 17개 MetricCard + 6개 InfoSheet |
|                    | ✅ 완료 | AI 탭: 17개 지표 한/영 용어 일관성 |
| prospero_app (아키텍처) | ✅ 완료 | IndicatorManager + IndicatorMetadata.json 구현 |
| 문서 | ✅ 완료 | INVESTMENT_FORMULA.md v3.0 |

### 점수 체계 (최종 확정)
- **크립토 점수**: 60점 (10+18+14+8+4+4+2)
- **거시경제 점수**: 40점 (8+5+6+5+3+2+4+2+3+2)
- **전체 합계**: 100점 (변경 없음)

### 용어 일관성 개선 결과
✅ 하드코딩 제거: 모든 지표 용어를 IndicatorMetadata.json에서 관리
✅ 단일 소스 진실(SSOT): IndicatorManager를 통한 일관된 접근
✅ 예시:
  - openInterest: "미결제 약정" (이전 불일치: "개방관심도" vs "미결제 약정" 해결)
  - 신규 6개: 모두 JSON 정의 기준으로 통일
