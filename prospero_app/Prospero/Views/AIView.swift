//
//  AIView.swift
//  Prospero
//
//  AI 데이터 분석 화면 (Crypto + Macro 데이터 기반 투자 점수 분석)

import SwiftUI

struct AIView: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    @State private var analysis: AIAnalysisResponse?
    @State private var cryptoData: CryptoDataItem?
    @State private var macroData: MacroDataItem?
    @State private var isLoading = true
    @State private var errorMessage: String?

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
                            AppIconView(size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Analysis")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(theme.primaryText)

                                Text(localization.ai("Investment Signal Analysis"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.secondaryText)
                            }

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

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
                            // 메인 점수 카드 (총점 및 신호)
                            AIMainScoreCard(analysis: analysis)

                            // 신호 범례
                            AISignalLegendCard()

                            // 연결 해석 분석 (v5.0)
                            AICrossIndicatorAnalysisCard(analysis: analysis)

                            // 지표 분석 (원시값)
                            if let crypto = cryptoData, let macro = macroData {
                                AIIndicatorCard(crypto: crypto, macro: macro)
                            }

                            // 지표별 상세 설명
                            AIDetailedExplanationCard(analysis: analysis)

                            Spacer()
                                .frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 120)
            }
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        // 수집기는 매일 UTC 04:00에 실행되어 그날(UTC 기준) 데이터를 DynamoDB에 저장함.
        // AI 분석은 UTC 04:05에 완료되므로, UTC 04:05 전이면 당일 데이터가 아직 없음.
        let utc = TimeZone(identifier: "UTC")!
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utc
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = utc

        let now = Date()
        let utcHour = utcCalendar.component(.hour, from: now)
        let utcMinute = utcCalendar.component(.minute, from: now)

        // AI 분석 완료(UTC 04:05) 전이면 전날 요청
        let analysisDate: String
        if utcHour < 4 || (utcHour == 4 && utcMinute < 5) {
            let yesterday = utcCalendar.date(byAdding: .day, value: -1, to: now)!
            analysisDate = formatter.string(from: yesterday)
        } else {
            analysisDate = formatter.string(from: now)
        }

        do {
            let result = try await AIAnalysisAPIService.shared.fetchAIAnalysis(for: analysisDate)
            self.analysis = result.analysis
            self.cryptoData = result.crypto
            self.macroData = result.macro
            isLoading = false
        } catch {
            self.errorMessage = localization.ai("Unable to load data.")
            isLoading = false
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
                    signal: "Strong Buy",
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

// MARK: - 상세 설명 카드
struct AIDetailedExplanationCard: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    let analysis: AIAnalysisResponse
    @State private var expandedIndex: Int? = nil

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(selectedLanguage == "ENG" ? "Indicator Explanations" : "지표 설명")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.secondaryText)

                Spacer()
            }

            // 언어 설정에 따라 한국어 또는 영어 설명 선택
            let explanations: [(String, String)] = selectedLanguage == "ENG" ? [
                (localization.ai("BTC Trend"), analysis.indicatorExplanationsEn.btcTrend),
                (localization.ai("Fear & Greed"), analysis.indicatorExplanationsEn.fearGreed),
                (localization.ai("Long/Short Ratio"), analysis.indicatorExplanationsEn.longShort),
                (localization.ai("Open Interest"), analysis.indicatorExplanationsEn.openInterest),
                (localization.ai("Interest Rate"), analysis.indicatorExplanationsEn.interestRate),
                (localization.ai("Treasury 10Y"), analysis.indicatorExplanationsEn.treasury10y),
                (localization.ai("M2 Supply"), analysis.indicatorExplanationsEn.m2),
                (localization.ai("Dollar Index"), analysis.indicatorExplanationsEn.dollarIndex),
                (localization.ai("Unemployment"), analysis.indicatorExplanationsEn.unemployment),
                (localization.ai("CPI"), analysis.indicatorExplanationsEn.cpi),
                (localization.ai("Interaction"), analysis.indicatorExplanationsEn.interaction)
            ] : [
                (localization.ai("BTC Trend"), analysis.indicatorExplanations.btcTrend),
                (localization.ai("Fear & Greed"), analysis.indicatorExplanations.fearGreed),
                (localization.ai("Long/Short Ratio"), analysis.indicatorExplanations.longShort),
                (localization.ai("OI + Price"), analysis.indicatorExplanations.openInterest),
                (localization.ai("Interest Rate"), analysis.indicatorExplanations.interestRate),
                (localization.ai("Treasury 10Y"), analysis.indicatorExplanations.treasury10y),
                (localization.ai("M2 Supply"), analysis.indicatorExplanations.m2),
                (localization.ai("Dollar Index"), analysis.indicatorExplanations.dollarIndex),
                (localization.ai("Unemployment"), analysis.indicatorExplanations.unemployment),
                (localization.ai("CPI"), analysis.indicatorExplanations.cpi),
                (localization.ai("Interaction"), analysis.indicatorExplanations.interaction)
            ]

            VStack(spacing: 10) {
                ForEach(explanations.indices, id: \.self) { index in
                    ExplanationRow(
                        title: explanations[index].0,
                        text: explanations[index].1,
                        isExpanded: expandedIndex == index,
                        theme: theme
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedIndex = expandedIndex == index ? nil : index
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
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
}

// MARK: - 설명 행
struct ExplanationRow: View {
    let title: String
    let text: String
    let isExpanded: Bool
    let theme: ThemeManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }

            if isExpanded {
                Text(text)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(theme.secondaryText)
                    .lineSpacing(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .background(theme.cardIconBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.cardBorderColor, lineWidth: 1)
        )
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

// MARK: - 지표 분석 카드 (원시값)
struct AIIndicatorCard: View {
    @EnvironmentObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    let crypto: CryptoDataItem
    let macro: MacroDataItem

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Text(localization.ai("Market Indicators"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Spacer()
            }

            VStack(spacing: 12) {
                // 크립토 지표
                IndicatorValueGroup(
                    title: localization.ai("Crypto Indicators"),
                    indicators: [
                        (localization.ai("Fear & Greed"), crypto.fearGreedIndex.map { String(format: "%.0f", Double($0)) } ?? "N/A", ""),
                        (localization.ai("Long/Short Ratio"), crypto.longShortRatio.map { String(format: "%.2f", $0) } ?? "N/A", selectedLanguage == "ENG" ? "x" : "배"),
                        (localization.ai("Open Interest"), crypto.openInterest.map { String(format: "%.0f", $0) } ?? "N/A", "BTC")
                    ],
                    theme: theme,
                    isCrypto: true
                )

                Divider()
                    .foregroundColor(theme.cardBackground)

                // 매크로 지표
                IndicatorValueGroup(
                    title: localization.ai("Macro Indicators"),
                    indicators: [
                        (localization.ai("Interest Rate"), macro.interestRate.map { String(format: "%.2f", $0) } ?? "N/A", "%"),
                        (localization.ai("Treasury 10Y"), macro.treasury10y.map { String(format: "%.2f", $0) } ?? "N/A", "%"),
                        (localization.ai("M2 Supply"), macro.m2.map { String(format: "%.0f", $0 / 1000) } ?? "N/A", selectedLanguage == "ENG" ? "billion USD" : "조 USD"),
                        (localization.ai("Dollar Index"), macro.dollarIndex.map { String(format: "%.2f", $0) } ?? "N/A", ""),
                        (localization.ai("Unemployment"), macro.unemployment.map { String(format: "%.2f", $0) } ?? "N/A", "%"),
                        (localization.ai("CPI"), macro.cpi.map { String(format: "%.2f", $0 / 100) } ?? "N/A", "%")
                    ],
                    theme: theme,
                    isCrypto: false
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                    .fill(theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
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
}

// MARK: - 지표값 그룹
struct IndicatorValueGroup: View {
    let title: String
    let indicators: [(String, String, String)]
    let theme: ThemeManager
    let isCrypto: Bool

    var groupColor: Color {
        isCrypto ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(red: 0.4, green: 0.6, blue: 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(groupColor)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.secondaryText)

                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(indicators, id: \.0) { label, value, unit in
                    VStack(spacing: 6) {
                        HStack {
                            Text(label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.secondaryText)

                            Spacer()
                        }

                        HStack(spacing: 4) {
                            Text(value)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(groupColor)

                            if !unit.isEmpty {
                                Text(unit)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.secondaryText)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(groupColor.opacity(0.1))
                        )
                    }
                }
            }
        }
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
                // 신뢰도 라벨
                HStack(spacing: 8) {
                    Text(selectedLanguage == "ENG" ? "Confidence:" : "신뢰도:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.secondaryText)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(confidenceColor())
                            .frame(width: 8, height: 8)

                        Text(analysis.confidenceLabel)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(confidenceColor())
                    }

                    Spacer()
                }

                Divider()
                    .foregroundColor(theme.cardBorderColor)

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
