//
//  AIView.swift
//  Prospero
//
//  AI 데이터 분석 화면 (Crypto + Macro 데이터 기반 투자 점수 분석)

import SwiftUI

/// AI 탭도 탭 전환 시 뷰가 재생성되므로, 마지막 조회 결과를 세션 캐시에 보관해
/// 재진입 시 스피너 없이 즉시 복원한다(Macro 탭과 동일한 패턴).
enum AIDashboardCache {
    static var analysisByDate: [String: AIAnalysisResponse] = [:]
    static var scoreByDate: [String: Double] = [:]
    static var availableDates: [String] = []
    static var selectedDate: String = ""
}

struct AIView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    @State private var analysis: AIAnalysisResponse? = AIDashboardCache.analysisByDate[AIDashboardCache.selectedDate]
    @State private var isLoading = AIDashboardCache.analysisByDate[AIDashboardCache.selectedDate] == nil  // 캐시 있으면 스피너 없이 시작
    @State private var errorMessage: String?

    // AI 탭 최근 7일 조회 (세션 캐시에서 복원)
    @State private var selectedDate: String = AIDashboardCache.selectedDate          // 선택된 날짜 (yyyyMMdd)
    @State private var availableDates: [String] = AIDashboardCache.availableDates    // 최근 7일 (오래된→최신)
    @State private var analysisCache: [String: AIAnalysisResponse] = AIDashboardCache.analysisByDate  // 날짜별 세션 캐시
    @State private var scoreByDate: [String: Double] = AIDashboardCache.scoreByDate  // 7일 점수 미니바용

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        ZStack {
            theme.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("Prospero")
                                .font(.custom("Snell Roundhand", size: 28))
                                .foregroundColor(theme.primaryText)

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // 헤더 아래 구분선
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.5)

                    // 최근 7일 날짜 셀렉터
                    if !availableDates.isEmpty {
                        AIDateSelectorView(
                            dates: availableDates,
                            selectedDate: selectedDate,
                            onSelect: { date in
                                guard date != selectedDate else { return }
                                Task { await loadData(for: date) }
                            }
                        )
                        .padding(.top, 12)
                    }

                    // Content
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(theme.primaryText)

                            Text(localization.ai("Analyzing data..."))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.red)

                            Text(localization.ai("Failed to Load Data"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.primaryText)

                            Text(error)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else if let analysis = analysis {
                        VStack(spacing: 20) {
                            // 7일 점수 추이 미니바
                            AIScoreTrendCard(
                                dates: availableDates,
                                scoreByDate: scoreByDate,
                                selectedDate: selectedDate,
                                onSelect: { date in
                                    guard date != selectedDate else { return }
                                    Task { await loadData(for: date) }
                                }
                            )

                            // 메인 점수 카드 (총점 및 신호)
                            AIMainScoreCard(analysis: analysis)

                            // 신호 범례
                            AISignalLegendCard()

                            // 연결 해석 분석 (v5.0)
                            AICrossIndicatorAnalysisCard(analysis: analysis)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 24) // 마지막 카드와 탭바 사이 최소 여백
            }
        }
        .task {
            // 날짜 목록(캐시 없을 때만 계산)
            if availableDates.isEmpty {
                availableDates = Self.recentDates(count: 7)
                AIDashboardCache.availableDates = availableDates
            }
            // 선택 날짜 분석이 아직 없으면 로드(최초 진입 또는 캐시 미스). 캐시 복원 시엔 스킵→즉시 표시.
            if analysis == nil {
                let target = selectedDate.isEmpty ? (availableDates.last ?? "") : selectedDate
                await loadData(for: target)
            }
            // 7일 점수 미니바 — 항상 호출(내부에서 캐시에 없는 날짜만 조회, 완비 시 no-op).
            // 클릭 없이 진입 즉시 7일 전체 점수가 채워지도록.
            await preloadTrendScores()
        }
    }

    /// 선택 날짜의 AI 분석 로드(세션 캐시 우선). 광고는 탭 진입 시에만 노출되므로 날짜 전환엔 광고 없음.
    private func loadData(for date: String) async {
        selectedDate = date
        AIDashboardCache.selectedDate = date

        // 세션 캐시 히트 → 네트워크 없이 즉시 표시
        if let cached = analysisCache[date] {
            analysis = cached
            errorMessage = nil
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        analysis = nil

        do {
            let result = try await AIAnalysisAPIService.shared.fetchAnalysisOnly(for: date)
            analysisCache[date] = result
            scoreByDate[date] = result.totalScore
            AIDashboardCache.analysisByDate[date] = result   // 재진입 복원용
            AIDashboardCache.scoreByDate[date] = result.totalScore
            // 응답 도착 시점에도 여전히 이 날짜가 선택돼 있을 때만 반영(빠른 연속 전환 대비)
            if selectedDate == date {
                analysis = result
                isLoading = false
            }
        } catch {
            if selectedDate == date {
                errorMessage = localization.ai("No analysis available")
                isLoading = false
            }
        }
    }

    /// 7일 점수 미니바를 위해 나머지 날짜 점수를 병렬 선로드(실패 날짜는 미니바에서 빈 막대).
    /// 응답이 도착할 때마다 @State를 갱신하면 막대가 하나씩 툭툭 나타나(버퍼 걸린 느낌) 므로,
    /// 루프에서는 로컬에만 모으고 그룹 완료 후 한 번에 반영해 막대가 동시에 채워지도록 한다.
    private func preloadTrendScores() async {
        var loaded: [String: AIAnalysisResponse] = [:]
        await withTaskGroup(of: (String, AIAnalysisResponse?).self) { group in
            for date in availableDates where analysisCache[date] == nil {
                group.addTask {
                    let result = try? await AIAnalysisAPIService.shared.fetchAnalysisOnly(for: date)
                    return (date, result)
                }
            }
            // 루프에서는 수집만 — @State 갱신 없음(리렌더 미발생)
            for await (date, result) in group {
                if let result = result { loaded[date] = result }
            }
        }
        guard !loaded.isEmpty else { return }

        // 정적 세션 캐시는 리렌더와 무관 → 개별 반영 무방(재진입 복원용)
        for (date, result) in loaded {
            AIDashboardCache.analysisByDate[date] = result
            AIDashboardCache.scoreByDate[date] = result.totalScore
        }
        // @State는 그룹 완료 후 한 번에 → 단일 리렌더로 막대 동시 표시
        analysisCache.merge(loaded) { _, new in new }
        var scores = scoreByDate
        for (date, result) in loaded { scores[date] = result.totalScore }
        scoreByDate = scores
    }

    /// AI 데이터를 미리 세션 캐시에 적재한다(광고 노출 중 호출).
    /// AIView 진입 시 캐시에서 즉시 복원되어 추가 로딩 없이 바로 표시된다.
    @MainActor
    static func prefetchIntoCache() {
        Task { @MainActor in
            let dates = recentDates(count: 7)
            if AIDashboardCache.availableDates.isEmpty {
                AIDashboardCache.availableDates = dates
            }
            guard let latest = dates.last else { return }
            if AIDashboardCache.selectedDate.isEmpty {
                AIDashboardCache.selectedDate = latest   // 기본 선택 = 최신 가용일
            }
            // 7일 전체를 병렬로 미리 조회(이미 캐시에 있는 날짜는 스킵)
            await withTaskGroup(of: (String, AIAnalysisResponse?).self) { group in
                for d in dates where AIDashboardCache.analysisByDate[d] == nil {
                    group.addTask {
                        (d, try? await AIAnalysisAPIService.shared.fetchAnalysisOnly(for: d))
                    }
                }
                for await (d, result) in group {
                    if let result = result {
                        AIDashboardCache.analysisByDate[d] = result
                        AIDashboardCache.scoreByDate[d] = result.totalScore
                    }
                }
            }
        }
    }

    /// 최근 N일(오래된→최신). 수집기 UTC 04:00 실행 + 분석 UTC 04:05 완료를 반영해 최신 가용일 계산.
    static func recentDates(count: Int) -> [String] {
        let utc = TimeZone(identifier: "UTC")!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = utc
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = utc

        let now = Date()
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        // AI 분석 완료(UTC 04:05) 전이면 전날이 최신 가용일
        let latest: Date
        if hour < 4 || (hour == 4 && minute < 5) {
            latest = cal.date(byAdding: .day, value: -1, to: now) ?? now
        } else {
            latest = now
        }

        return (0..<count)
            .compactMap { cal.date(byAdding: .day, value: -$0, to: latest) }
            .map { formatter.string(from: $0) }
            .reversed()
    }
}

// MARK: - 날짜 표시 유틸
enum AIDateFormat {
    /// yyyyMMdd → Date (UTC 기준)
    static func date(from yyyymmdd: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: yyyymmdd)
    }

    /// 월/일 (예: "6/30")
    static func monthDay(_ yyyymmdd: String) -> String {
        guard let d = date(from: yyyymmdd) else { return yyyymmdd }
        let f = DateFormatter()
        f.dateFormat = "M/d"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: d)
    }

    /// 요일 약어 (언어별)
    static func weekday(_ yyyymmdd: String, language: String) -> String {
        guard let d = date(from: yyyymmdd) else { return "" }
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "UTC")
        f.locale = Locale(identifier: language == "KOR" ? "ko_KR" : "en_US")
        f.dateFormat = language == "KOR" ? "EEE" : "EEE"
        return f.string(from: d)
    }
}

// MARK: - 최근 7일 날짜 셀렉터
struct AIDateSelectorView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    let dates: [String]            // 오래된→최신
    let selectedDate: String
    let onSelect: (String) -> Void

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dates, id: \.self) { date in
                        let isSelected = date == selectedDate
                        let isLatest = date == dates.last

                        Button {
                            onSelect(date)
                        } label: {
                            VStack(spacing: 2) {
                                Text(isLatest ? localization.ai("Today") : AIDateFormat.weekday(date, language: selectedLanguage))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(isSelected ? .white : theme.secondaryText)

                                Text(AIDateFormat.monthDay(date))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : theme.primaryText)
                            }
                            .frame(minWidth: 48)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color(red: 1.0, green: 0.65, blue: 0.0) : theme.cardIconBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.clear : theme.cardBorderColor, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .id(date)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .onAppear {
                // 최신(선택)일이 보이도록 우측 끝으로 스크롤
                proxy.scrollTo(selectedDate, anchor: .trailing)
            }
            .onChange(of: selectedDate) { newValue in
                withAnimation { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
    }
}

// MARK: - 7일 점수 추이 미니바
struct AIScoreTrendCard: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    let dates: [String]            // 오래된→최신
    let scoreByDate: [String: Double]
    let selectedDate: String
    let onSelect: (String) -> Void

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localization.ai("7-Day Score Trend"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.secondaryText)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    let score = scoreByDate[date]
                    let isSelected = date == selectedDate

                    Button {
                        onSelect(date)
                    } label: {
                        VStack(spacing: 6) {
                            // 점수 라벨
                            Text(score != nil ? String(format: "%.0f", score!) : "-")
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundColor(score != nil ? (isSelected ? theme.primaryText : theme.secondaryText) : theme.secondaryText.opacity(0.5))

                            // 막대 (높이 ∝ 점수/100, 최대 80pt)
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.cardIconBackground)
                                    .frame(height: 80)

                                if let score = score {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(barColor(for: score).opacity(isSelected ? 1.0 : 0.55))
                                        .frame(height: max(6, 80 * CGFloat(score / 100.0)))
                                }
                            }
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(isSelected ? Color(red: 1.0, green: 0.65, blue: 0.0) : Color.clear, lineWidth: 1.5)
                            )

                            // 날짜 라벨
                            Text(AIDateFormat.monthDay(date))
                                .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? theme.primaryText : theme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.cardShadow, radius: 12, x: 0, y: 4)
    }

    // 점수 구간별 신호 색상 (범례와 동일)
    private func barColor(for score: Double) -> Color {
        switch score {
        case 75...100: return Color(red: 0.0, green: 0.8, blue: 0.2)   // 강력매수
        case 58..<75:  return Color(red: 0.2, green: 0.8, blue: 0.4)   // 매수
        case 38..<58:  return Color(red: 1.0, green: 0.8, blue: 0.0)   // 보유
        case 22..<38:  return Color(red: 1.0, green: 0.6, blue: 0.0)   // 부분매도
        default:       return Color(red: 1.0, green: 0.2, blue: 0.2)   // 강력매도
        }
    }
}

// MARK: - 메인 점수 카드
struct AIMainScoreCard: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    let analysis: AIAnalysisResponse

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(spacing: 20) {
            // 점수 표시
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: analysis.totalScore / 100.0)
                    .stroke(signalGradient(), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(String(format: "%.0f", analysis.totalScore))
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(signalColor())

                    Text("/100")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
            }
            .frame(height: 200)

            // 신호 타입
            HStack(spacing: 8) {
                Circle()
                    .fill(signalColor())
                    .frame(width: 10, height: 10)

                Text(analysis.signalType)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(signalColor())

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.ai("Cross-Indicator Analysis"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.secondaryText)

                // 연결 해석 분석 (언어 설정에 따라 선택)
                Text(selectedLanguage == "ENG" ? analysis.crossIndicatorAnalysisEn : analysis.crossIndicatorAnalysis)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(theme.secondaryText)
                    .lineSpacing(2)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        )
        .shadow(
            color: theme.cardShadow,
            radius: 12,
            x: 0,
            y: 4
        )
    }

    private func signalColor() -> Color {
        switch analysis.signalColor {
        case "strong_buy": return Color(red: 0.0, green: 0.8, blue: 0.2)
        case "buy": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "hold": return Color(red: 1.0, green: 0.8, blue: 0.0)
        case "partial_sell": return Color(red: 1.0, green: 0.6, blue: 0.0)
        case "strong_sell": return Color(red: 1.0, green: 0.2, blue: 0.2)
        default: return Color.gray
        }
    }

    private func signalGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                signalColor(),
                signalColor().opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 신호 범례
struct AISignalLegendCard: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(selectedLanguage == "ENG" ? "Signal Legend" : "신호 범례")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)

                Spacer()
            }

            VStack(spacing: 8) {
                SignalLegendRow(
                    signal: selectedLanguage == "ENG" ? "Strong Buy" : "강력매수",
                    range: selectedLanguage == "ENG" ? "75-100" : "75-100점",
                    color: Color(red: 0.0, green: 0.8, blue: 0.2)
                )

                SignalLegendRow(
                    signal: selectedLanguage == "ENG" ? "Buy" : "매수",
                    range: selectedLanguage == "ENG" ? "58-74" : "58-74점",
                    color: Color(red: 0.2, green: 0.8, blue: 0.4)
                )

                SignalLegendRow(
                    signal: selectedLanguage == "ENG" ? "Hold" : "보유",
                    range: selectedLanguage == "ENG" ? "38-57" : "38-57점",
                    color: Color(red: 1.0, green: 0.8, blue: 0.0)
                )

                SignalLegendRow(
                    signal: selectedLanguage == "ENG" ? "Partial Sell" : "부분매도",
                    range: selectedLanguage == "ENG" ? "22-37" : "22-37점",
                    color: Color(red: 1.0, green: 0.6, blue: 0.0)
                )

                SignalLegendRow(
                    signal: selectedLanguage == "ENG" ? "Strong Sell" : "강력매도",
                    range: selectedLanguage == "ENG" ? "0-21" : "0-21점",
                    color: Color(red: 1.0, green: 0.2, blue: 0.2)
                )
            }
            .padding(12)
            .background(theme.cardIconBackground)
            .cornerRadius(8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        )
        .shadow(
            color: theme.cardShadow,
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

// MARK: - 신호 범례 행
struct SignalLegendRow: View {
    @EnvironmentObject var theme: ThemeManager
    let signal: String
    let range: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(signal)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(theme.primaryText)
                .frame(width: 90, alignment: .leading)

            Text(range)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}


// MARK: - 지표 그룹
struct IndicatorGroup: View {
    let title: String
    let indicators: [(String, Double, Double)]
    let theme: ThemeManager

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)

                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(indicators, id: \.0) { label, score, maxScore in
                    HStack(spacing: 12) {
                        Text(label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                            .frame(width: 70, alignment: .leading)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.cardIconBackground)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.primaryGradient)
                                    .frame(width: geometry.size.width * (score / maxScore))
                            }
                        }
                        .frame(height: 6)

                        Text(String(format: "%.1f", score))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
    }
}

// MARK: - 점수 Pill
struct ScorePill: View {
    let label: String
    let score: Double
    let maxScore: Double
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)

            HStack(spacing: 4) {
                Text(String(format: "%.0f", score))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)

                Text("/\(Int(maxScore))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - 연결 해석 분석 카드 (v5.0)
struct AICrossIndicatorAnalysisCard: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    let analysis: AIAnalysisResponse

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(selectedLanguage == "ENG" ? "Analysis Details" : "분석 상세")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Spacer()
            }

            VStack(spacing: 14) {
                // 신호 근거
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == "ENG" ? "Signal Rationale" : "신호 근거")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.secondaryText)

                    Text(selectedLanguage == "ENG" ? analysis.signalRationaleEn : analysis.signalRationale)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(theme.primaryText)
                        .lineSpacing(1.5)
                }

                Divider()
                    .foregroundColor(theme.cardBorderColor)

                // 강세 요인
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(selectedLanguage == "ENG" ? "Bullish Factors" : "강세 요인")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.secondaryText)

                        Spacer()
                    }

                    let bullishList = selectedLanguage == "ENG" ? analysis.bullishFactorsEn : analysis.bullishFactors
                    VStack(alignment: .leading, spacing: 6) {
                        if bullishList.isEmpty {
                            Text(selectedLanguage == "ENG" ? "No bullish factors" : "강세 요인 없음")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(theme.secondaryText)
                        } else {
                            ForEach(bullishList, id: \.self) { factor in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                                        .frame(width: 6, height: 6)

                                    Text(factor)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(theme.primaryText)
                                        .lineSpacing(1.2)

                                    Spacer()
                                }
                            }
                        }
                    }
                }

                Divider()
                    .foregroundColor(theme.cardBorderColor)

                // 약세 요인
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(selectedLanguage == "ENG" ? "Bearish Factors" : "약세 요인")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.secondaryText)

                        Spacer()
                    }

                    let bearishList = selectedLanguage == "ENG" ? analysis.bearishFactorsEn : analysis.bearishFactors
                    VStack(alignment: .leading, spacing: 6) {
                        if bearishList.isEmpty {
                            Text(selectedLanguage == "ENG" ? "No bearish factors" : "약세 요인 없음")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(theme.secondaryText)
                        } else {
                            ForEach(bearishList, id: \.self) { factor in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.2, blue: 0.2))
                                        .frame(width: 6, height: 6)

                                    Text(factor)
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(theme.primaryText)
                                        .lineSpacing(1.2)

                                    Spacer()
                                }
                            }
                        }
                    }
                }

                Divider()
                    .foregroundColor(theme.cardBorderColor)

                // 신뢰도 이유
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedLanguage == "ENG" ? "Confidence Reason" : "신뢰도 이유")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.secondaryText)

                    Text(selectedLanguage == "ENG" ? analysis.confidenceReasonEn : analysis.confidenceReason)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(theme.primaryText)
                        .lineSpacing(1.5)
                }
            }
            .padding(16)
            .background(theme.cardIconBackground)
            .cornerRadius(8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .fill(theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        )
        .shadow(
            color: theme.cardShadow,
            radius: 12,
            x: 0,
            y: 4
        )
    }

    private func confidenceColor() -> Color {
        switch analysis.confidenceLabel {
        case "High":
            return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "Medium":
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        case "Low":
            return Color(red: 1.0, green: 0.2, blue: 0.2)
        default:
            return Color.gray
        }
    }
}

#Preview {
    AIView()
        .environmentObject(ThemeManager.shared)
}
