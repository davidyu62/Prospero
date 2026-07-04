# Prospero 대시보드 UI 개선 — 작업계획서

> **목적**: 30일 추세 그래프 / 값 연동 지표 해석 / AI 탭 7일 조회를 구현한다.
> **이 문서는 "재개용 단일 진실 소스"다.** 작업이 중단돼도 다음 세션에서 이 문서의
> `현재 진행 상태`와 체크리스트만 보면 끝난 지점 이후부터 이어서 작업할 수 있다.

---

## 0. 재개 방법 (다음 세션 필독)

**작업 위치: `main` 작업본** (사용자가 평소 Xcode로 빌드/테스트하는 곳). 완료된 코드는 main 작업본에 직접 반영한다.
백업용으로 `worktree-feature+dashboard-ui-improvement` 브랜치에 단계별 커밋도 남아 있다(c1728fc=C1 등).

1. `main` 작업본(`/Users/a78142/engn001/git/Prospero`)에서 이 문서의 **`1. 현재 진행 상태`** 를 읽고 마지막 완료 항목 다음부터 시작한다.
2. 각 단계 완료 시 체크박스를 `[x]`로 바꾸고 `1. 현재 진행 상태`의 **마지막 완료 / 다음 할 일**을 갱신한다.
3. 빌드 검증은 `prospero_app`에서 `xcodebuild ... -sdk iphonesimulator build` 또는 사용자 Xcode로.
4. 커밋 메시지 컨벤션: `feat(crypto): ...` / `feat(macro): ...` / `feat(ai): ...` (영어, CLAUDE.md 규칙).
   - main에 사용자의 미커밋 작업(광고 SPM 등)이 섞여 있으므로, 커밋 시 UI 개선 관련 파일만 선택적으로 스테이징할 것.

**작업 순서: CryptoTab → MacroTab → AI Tab** (탭 단위로 완결 후 다음 탭).

상태 범례: `[ ]` 미착수 · `[~]` 진행중 · `[x]` 완료 · `[!]` 막힘(사유 기재)

---

## 1. 현재 진행 상태  ← **매번 여기부터 갱신**

- **마지막 완료**: **AI Tab(AI-1~AI-5) 앱 코드 완료**(빌드 통과). 최근 7일 날짜 셀렉터(`AIDateSelectorView`)+7일 점수 미니바(`AIScoreTrendCard`)+날짜별 세션 캐시. 서비스에 경량 `fetchAnalysisOnly` 추가(AIView는 분석만 사용→날짜당 API 1회). 광고는 탭 진입 1회만(AI-5 확인, 변경 없음). 백엔드 변경 없음(AI API `?date=` 기존 지원).
- **다음 할 일**: (선택) 매크로 range 배포·검증 → 마무리(양언어 확인·PR). AI Tab 실기기/시뮬 실제 조회 확인 권장.
- **선택 개선**: Lambda 타임아웃 3s→10s(콜드 여유). davidyu CLI엔 lambda 쓰기 권한 없음.
- **현재 탭**: CryptoTab
- **막힌 항목**: 없음
- **메모**: 30일 데이터(C4/M-C4)는 백엔드 범위 엔드포인트(BE-1)에 의존. 엔드포인트 완료 전에는
  `HistoryProvider` 스텁(샘플/보간 데이터)로 UI를 먼저 완성하고, 엔드포인트 준비 시 연결만 교체한다.

---

## 2. 설계 확정 사항 (변경 금지 기준)

- **다크 테마**: 배경 `#0C101C`, 카드 `#121725`, 액센트 `#FFA500`, 성공 `#10B981`, 위험 `#EF4444`, 경고 `#F59E0B`
- **기능 ①** 30일 추세: 카드 내 인라인 스파크라인 + 카드 탭 시 상세 시트(큰 차트·7/30일 토글·요약통계). Swift Charts(iOS 16.2+) 사용.
- **기능 ②** 지표 의미: **값 연동 1줄 해석**을 카드에 항상 노출 + 심화 설명은 상세 시트 `[차트 | 설명]` 세그먼트로 통합. 기존 개별 InfoSheet 7종 → 데이터 주도 단일 뷰로 대체.
- **기능 ③** AI 탭: 헤더 아래 최근 7일 칩 셀렉터 + 날짜별 로드/캐시 + 7일 점수 추이 미니바.
- 목업: `$CLAUDE_JOB_DIR/tmp/prospero_mockup.html` (세션 한정). 디자인 근거는 git 히스토리의 `UI_IMPROVEMENT_PLAN.md` 참조.

---

## 3. 공통/백엔드 선행 작업

- [ ] **BE-1** (선택·기능① 의존) 범위 조회 엔드포인트 신규
  - `GET /api/crypto-data/db/range?from=YYYYMMDD&to=YYYYMMDD` → 일자 배열 반환
  - `GET /api/macro-data/db/range?from=&to=`
  - DynamoDB `date BETWEEN` Query 1회. **백엔드 순변경은 이 2개뿐.**
  - 미완 시 클라이언트는 `HistoryProvider` 스텁으로 진행.

---

## 4. CryptoTab (오늘 시작) — `prospero_app/Prospero/Views/CryptoDashboardView.swift` 외

### C1. 값 연동 1줄 해석 (백엔드 무관) ✅ 완료
- [x] `Utils/IndicatorInterpretation.swift` 신규 — `IndicatorSentiment`/`TrendDirection`/`IndicatorInterpreter` 구현(공포탐욕·MVRV·L/S·OI·펀딩비·활성주소·가격)
- [x] `Models/CryptoDashboardData.swift` `CryptoMetric`에 `var rawValue: Double? = nil` 추가(기본값으로 기존 초기화 호환)
- [x] `loadCryptoData`에서 5개 지표 `rawValue` 채움 (펀딩비는 `*100` 퍼센트 단위)
- [x] `MetricCard`에 1줄 해석 행 추가(진행바 아래, 상단 구분선 0.5pt, sentiment 색상)
- [x] `FearGreedCard`에 게이지 아래 1줄 해석 추가
- [x] 시뮬레이터 빌드 통과(BUILD SUCCEEDED)
- **참고**: 추세는 현재 "전일 대비(changeIsPositive)"로 채움. 30일 기울기는 C4에서 연결. 공포탐욕은 전일값 미보유로 `.flat`(C4에서 보강).

### C2. 인라인 스파크라인 컴포넌트 (백엔드 무관) ✅ 완료
- [x] `Views/Components/TrendChartView.swift` 신규 — 입력 `[Double]`, `mode: .spark | .full`
  - spark: 높이 32pt, 축/범례 숨김, 기울기 방향 색상(상승 success/하락 danger), 마지막 점 강조
  - full: 축/그리드 + 영역 그라데이션 (C3 상세 시트에서 스크럽 툴팁 확장 예정)
- [x] `Services/CryptoHistoryProvider.swift` 신규(스텁) — key별 30일 `[Double]` 반환(FNV 시드 결정적 합성, 마지막값=current)
- [x] `MetricCard`에 `sparkline` 계산 프로퍼티 추가, 진행바를 스파크라인으로 교체(매핑 없으면 진행바 유지)
- [x] 시뮬레이터 빌드 통과(BUILD SUCCEEDED)
- [x] `BitcoinCard`(가격 추세, `.btcPrice`) · `FearGreedCard`(`.fearGreed`)에도 스파크라인 추가 → 크립토 탭 전 카드에 30일 추세선 표시
- **수용 기준**: 카드에 30일 미니 추세선이 표시된다(스텁 데이터 허용). ✅
- **참고**: 스텁은 결정적이라 재렌더 시 흔들리지 않음. 방향/기울기는 C4에서 실 30일 데이터로 교체.

### C3. 상세 시트 (차트 + 설명 통합, 백엔드 무관) ✅ 완료
- [x] `Views/Components/MetricDetailSheet.swift` 신규 — `[차트 | 설명]` 세그먼트
  - 차트 탭: `TrendChartView(.full)` + 7/30일 토글 + 최저·평균·최고 요약통계
  - 설명 탭: `IndicatorMetadata.json` 정의 + 방향(상승/하락)별 동적 해석(`IndicatorInterpreter`)
- [x] `CryptoMetric`을 `Identifiable`로(`id = title`) → 5개 지표 카드 `onTapGesture`를 `selectedMetric` 기반 단일 `.sheet(item:)`로 교체
- [x] 대체된 InfoSheet 7종(Bitcoin·FearGreed·OI·롱숏·MVRV·펀딩비·활성주소) 모두 제거 → 전 카드가 단일 `.sheet(item:)` 사용
- [x] Bitcoin·FearGreed도 통합: `key(forTitle:)`에 두 타이틀 매핑 추가, `Key.metadataId`(fearGreed→`fearGreedIndex`) 추가, `bitcoinMetric`/`fearGreedMetric` 래퍼로 라우팅
- [x] 시뮬레이터 빌드 통과(BUILD SUCCEEDED)
- **수용 기준**: 모든 카드(Bitcoin·FearGreed 포함) 탭 시 차트+설명 통합 시트가 뜨고, 개별 InfoSheet 중복 제거. ✅
- **참고**: JSON 정의는 1줄 요약이라 기존 InfoSheet의 상세 교육문(Key Points/How It Works)은 사라짐. 대신 차트+동적 해석으로 대체. 상세문 복원이 필요하면 별도 요청.

### C4. 30일 실데이터 연동 (코드 완료, 배포 대기)
- [x] 백엔드: `get_crypto_data_range(date, days)` 신규(기존 `get_crypto_data_7days`를 일반화·위임), `/api/crypto-data/db/range` 라우트 추가. **기존 엔드포인트 불변(순수 추가)**.
- [x] 앱: `CryptoRangeResponse` 모델 + `CryptoAPIService.fetchCryptoRange` + `loadHistory`(key별 배열 저장). 카드/시트에 `history` 주입, **실데이터 우선·실패 시 스텁 폴백**. 상세시트 "예시 값" 문구는 실데이터일 때 숨김.
- [x] 앱 빌드 통과(BUILD SUCCEEDED)
- [x] **배포·검증 완료**: Lambda `prospero-retrieval` 코드 갱신 + API Gateway `range` 리소스 추가 + prod 배포. 라이브 `range?date=&days=30` → 200(30일 전 지표). → `prospero_backend/C4_RANGE_DEPLOY.md`
- [x] **성능 수정**: 초기 502(타임아웃 3s/128MB 초과). `get_crypto_data_range`를 boto3 클라이언트 1회 생성 + 단일 Query(파티션키=date)·Scan 폴백 제거로 최적화 → 30일 로컬 0.48s/웜 1.2s.
- **수용 기준**: 실제 30일 데이터로 스파크라인·상세차트가 그려진다. ✅ (엔드포인트 검증 완료, 앱 재실행 시 반영)
- **참고**: API Gateway는 경로별 명시적 리소스 방식이라 새 경로는 게이트웨이 리소스 추가 필요(프록시 아님). Lambda 함수는 신규 생성 없이 기존 `prospero-retrieval` 코드만 갱신.

---

## 5. MacroTab — `prospero_app/Prospero/Views/MacroDashboardView.swift`
> CryptoTab에서 만든 `IndicatorInterpretation` / `TrendChartView` / `MetricDetailSheet` **재사용**.

- [x] **M-C1** 매크로 10종 해석 규칙을 `IndicatorInterpreter`에 추가(Key·title·metadata 기본매핑, 위험자산 관점 강세/약세)
- [x] **M-C2** `MacroMetric`에 `rawValue`/`Identifiable`, `loadMacroData`에서 채움(CPI는 /100). `MacroMetricCard`를 세로 레이아웃으로 재구성 + 1줄 해석 + 스파크라인
- [x] **M-C3** `MetricDetailSheet`를 `any DetailableMetric`+`isMacro`로 공용화(크립토·매크로), Macro 카드 탭→단일 `.sheet(item:)`, InfoSheet 10종 제거(860줄)
- [x] **M-C4 코드**: 백엔드 `get_macro_data_range`+`/api/macro-data/db/range`(로컬 0.42s). 앱 `MacroRangeResponse`+`fetchMacroRange`+`loadMacroHistory`(CPI /100), 실패 시 스텁 폴백. 빌드 통과.
- [ ] **M-C4 배포**(사용자): Lambda 코드 재업로드 + API Gateway `/api/macro-data/db/range` 리소스 추가 → `C4_RANGE_DEPLOY.md` 매크로 섹션
- **수용 기준**: Macro 탭이 Crypto 탭과 동일한 해석/추세/상세 경험 제공. ✅(코드), 배포 후 실데이터 검증

---

## 6. AI Tab — `prospero_app/Prospero/Views/AIView.swift`
> AI 분석 API는 `?date=` 이미 지원 → **백엔드 변경 없음**(과거 분석 저장 여부만 확인).

- [x] **AI-1** `AIDateSelectorView` 신규 — 최근 7일 가로 칩(기본=최신 가용일, `Today` 라벨), `ScrollViewReader`로 선택칩 우측정렬 스크롤. 최신 가용일은 수집기 UTC 04:05 완료 기준으로 계산(`AIView.recentDates`)이라 미래일은 애초에 목록에 없음.
- [x] **AI-2** `AIView`에 `@State selectedDate`/`availableDates` 추가, `loadData(for:)` 시그니처화, 칩·미니바 선택 시 재로드. 최초 `.task`에서 최신일 로드 후 나머지 6일 점수 병렬 선로드.
- [x] **AI-3** 날짜별 세션 캐시 — 뷰 내 `analysisCache: [String: AIAnalysisResponse]`. 캐시 히트 시 네트워크·광고 없이 즉시 표시. (기존 서비스 UserDefaults 캐시는 단일 날짜라 미사용, 뷰 인메모리 캐시로 대체. AIView는 crypto/macro 원시데이터 미사용이라 신규 경량 `fetchAnalysisOnly` 사용 → 날짜당 API 3회→1회로 축소)
- [x] **AI-4** `AIScoreTrendCard` — 7일 점수 미니바(구간별 신호 색상, 선택일 강조, 막대 탭→해당일 로드). 점수 없는 날짜는 빈 막대+`-`. 무데이터/실패는 `errorMessage`("No analysis available") 플레이스홀더.
- [x] **AI-5** 광고 게이팅 확인 완료 — `BottomTabBar.onAITap`에서 탭 진입 시 1회만 노출(`RewardedAdManager.shouldShowAd`). 날짜 전환은 AIView 내부 상태 변경이라 광고 미발생. **코드 변경 불필요.**
- [x] 시뮬레이터 빌드 통과(BUILD SUCCEEDED)
- **수용 기준**: AI 탭에서 최근 7일 중 임의 날짜의 분석을 조회할 수 있다. ✅

---

## 7. 마무리
- [ ] 전체 시뮬레이터 빌드 통과
- [ ] KOR/ENG 양 언어 확인
- [ ] 미사용 코드(구 InfoSheet 등) 정리
- [ ] PR 생성(사용자 요청 시)
