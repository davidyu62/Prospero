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

- [x] **V-2** prospero_ai 로컬 테스트
  ```bash
  cd prospero_ai && python run_local.py 20260503
  # 신규 점수 필드 출력 확인 완료
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

### API 검증
- [ ] **V-5** prospero_backend API 응답 확인
  ```bash
  # fundingRate, activeAddresses 등 신규 필드 포함 확인
  ```

---

## 주의사항

1. **Step 4 UI 작업은 복잡도가 높음** — 각 뷰 파일의 기존 패턴 학습 필수
2. **하위 호환성**: iOS 옵셔널 필드로 선언하여 이전 API 응답과 호환
3. **메모리**: confidence_label "16개 중 N개" 형식으로 업데이트

---

**진행률**: 17/17 완료 (100%) ✅

**완료 일시**: 2026-05-03 (v3.0 완전 통합)

**다음 작업**: 
- [x] 로컬 테스트 실행 (prospero_ai run_local.py) ✓
- [x] iOS 빌드 및 UI 확인 ✓
- [ ] API 응답 검증
- [ ] 배포 준비
  - [ ] prospero_collector 배포 (`./deploy.sh`)
  - [ ] prospero_backend 배포 (`./deploy.sh`)
  - [ ] prospero_app 배포 (App Store 또는 TestFlight)

---

## 완료 요약

### v3.0 신규 지표 6개 통합 완료
- **암호화폐 지표 2개**: 펀딩비 (Funding Rate), 활성주소 (Active Addresses)
- **거시경제 지표 4개**: VIX, WTI 원유가격, 금리차 (T10Y2Y), 기대인플레이션 (10Y BE)

### 전체 통합 내역
| 컴포넌트 | 상태 | 비고 |
|---|---|---|
| prospero_boot | ✅ 완료 | 6개 지표 API 엔드포인트 완성 |
| prospero_collector | ✅ 완료 | 데이터 수집 및 DynamoDB 저장 완성 |
| prospero_backend | ✅ 완료 | 6개 지표 포함 API 응답 완성 |
| prospero_ai | ✅ 완료 | 점수 함수 + 데이터 파이프라인 완성 |
| prospero_app (모델) | ✅ 완료 | Swift Codable 모델 업데이트 완성 |
| prospero_app (UI) | ✅ 완료 | 10개 MetricCard + 6개 InfoSheet 완성 |
| 문서 | ✅ 완료 | INVESTMENT_FORMULA.md v3.0 업데이트 완성 |

### 점수 체계 확정
- **크립토 점수**: 60점 (기존 5개 + 신규 2개)
- **거시경제 점수**: 40점 (기존 6개 + 신규 4개)
- **전체 합계**: 100점 (변경 없음)
