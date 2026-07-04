//
//  MacroDashboardView.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI
import UIKit

/// Macro 탭은 탭 전환 시 뷰가 재생성되므로, 마지막 실데이터를 세션 캐시에 보관해
/// 재진입 시 샘플/스켈레톤 없이 즉시 복원한다(백그라운드에서 조용히 갱신).
enum MacroDashboardCache {
    static var data: MacroDashboardData?
    static var histories: [String: [Double]] = [:]
    static var historyDates: [Date] = []
    static var historyEndDate: Date?
    static var updatedTime: String = ""
}

struct MacroDashboardView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var dashboardData = MacroDashboardCache.data ?? .empty
    @State private var isDataLoaded = MacroDashboardCache.data != nil   // 캐시 있으면 즉시 표시
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedMacroMetric: MacroMetric?   // 모든 지표 카드 → 통합 상세 시트
    @State private var histories: [String: [Double]] = MacroDashboardCache.histories // 지표 key.rawValue → 실데이터(없으면 스텁 폴백)
    @State private var historyEndDate: Date? = MacroDashboardCache.historyEndDate     // 히스토리 마지막 날짜(X축 날짜 표기용)
    @State private var historyDates: [Date] = MacroDashboardCache.historyDates        // 6개월 월별 실제 날짜(오래된→최신)
    @State private var updatedTime: String = MacroDashboardCache.updatedTime
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        ZStack {
            theme.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        // Top Row: App Name
                        HStack(spacing: 12) {
                            Text("Prospero")
                                .font(.custom("Snell Roundhand", size: 28))
                                .foregroundColor(theme.primaryText)

                            Spacer()
                        }
                        
                        // Bottom Row: Updated Time
                        HStack {
                            Spacer()
                            if !updatedTime.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(theme.tertiaryText)
                                    Text("\(localization.common("Updated")) \(updatedTime)")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.secondaryText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 헤더 아래 구분선
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.top, 12)

                    // Macro Metric Cards
                    if isDataLoaded {
                        VStack(spacing: 12) {
                            MacroMetricCard(metric: dashboardData.interestRate, valueColor: colorForInterestRate(dashboardData.interestRate.value), history: history(for: dashboardData.interestRate), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.interestRate }
                            MacroMetricCard(metric: dashboardData.treasury10y, valueColor: colorForTreasury(dashboardData.treasury10y.value), history: history(for: dashboardData.treasury10y), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.treasury10y }
                            MacroMetricCard(metric: dashboardData.cpi, valueColor: colorForCPI(dashboardData.cpi.value), history: history(for: dashboardData.cpi), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.cpi }
                            MacroMetricCard(metric: dashboardData.m2, valueColor: colorForM2(dashboardData.m2.value), history: history(for: dashboardData.m2), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.m2 }
                            MacroMetricCard(metric: dashboardData.unemployment, valueColor: colorForUnemployment(dashboardData.unemployment.value), history: history(for: dashboardData.unemployment), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.unemployment }
                            MacroMetricCard(metric: dashboardData.dollarIndex, valueColor: colorForDollarIndex(dashboardData.dollarIndex.value), history: history(for: dashboardData.dollarIndex), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.dollarIndex }
                            MacroMetricCard(metric: dashboardData.vix, valueColor: colorForVix(dashboardData.vix.value), history: history(for: dashboardData.vix), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.vix }
                            MacroMetricCard(metric: dashboardData.oilPrice, valueColor: colorForOilPrice(dashboardData.oilPrice.value), history: history(for: dashboardData.oilPrice), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.oilPrice }
                            MacroMetricCard(metric: dashboardData.yieldSpread, valueColor: colorForYieldSpread(dashboardData.yieldSpread.value), history: history(for: dashboardData.yieldSpread), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.yieldSpread }
                            MacroMetricCard(metric: dashboardData.breakEvenInflation, valueColor: colorForBreakEvenInflation(dashboardData.breakEvenInflation.value), history: history(for: dashboardData.breakEvenInflation), theme: theme)
                                .onTapGesture { selectedMacroMetric = dashboardData.breakEvenInflation }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24) // 마지막 카드와 탭바 사이 최소 여백
                    } else if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        // 로드 전: 샘플 대신 고정 크기 스켈레톤(깜빡임·리사이즈 방지)
                        DashboardLoadingPlaceholder(theme: theme, cardHeights: Array(repeating: 92, count: 10))
                            .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            // 최초 진입(캐시 없음)에만 로드. 재진입 시엔 캐시 복원값을 그대로 유지(재로딩·값 변동 방지).
            if !isDataLoaded {
                Task {
                    await loadMacroData()
                }
            }
        }
        .sheet(item: $selectedMacroMetric) { metric in
            MetricDetailSheet(metric: metric, history: history(for: metric), isMacro: true, endDate: historyEndDate, historyDates: historyDates.isEmpty ? nil : historyDates, theme: theme)
        }
    }
    
    // 지표 카드의 30일 실데이터 조회(없으면 nil → 카드가 스텁으로 폴백)
    private func history(for metric: MacroMetric) -> [Double]? {
        guard let key = IndicatorInterpreter.key(forTitle: metric.title) else { return nil }
        return histories[key.rawValue]
    }

    // 최근 6개월 '각 달 1일' 데이터를 받아 지표 key별 배열로 저장한다. 실패하면 비워 카드가 스텁으로 폴백.
    private func loadMacroHistory(endDate: String) async {
        // 실패(스텁 폴백) 시에도 X축 날짜가 나오도록 요청 종료일을 먼저 설정
        let fmt0 = DateFormatter()
        fmt0.dateFormat = "yyyyMMdd"
        fmt0.timeZone = TimeZone(identifier: "UTC")
        historyEndDate = fmt0.date(from: endDate)
        do {
            let r = try await MacroAPIService.shared.fetchMacroRange(date: endDate, months: 6)  // 최근 6개월(월 단위 그래프)
            var h: [String: [Double]] = [:]
            func put(_ key: IndicatorInterpreter.Key, _ arr: [Double]) {
                if arr.count >= 2 { h[key.rawValue] = arr }
            }
            put(.interestRate, r.interestRates)
            put(.treasury10y, r.treasury10ys)
            put(.cpi, r.cpis.map { $0 / 100.0 })  // 카드 rawValue와 동일 단위(%)
            put(.m2, r.m2s)
            put(.unemployment, r.unemployments)
            put(.dollarIndex, r.dollarIndices)
            put(.vix, r.vixs)
            put(.oilPrice, r.oilPrices)
            put(.yieldSpread, r.yieldSpreads)
            put(.breakEvenInflation, r.breakEvenInflations)
            histories = h
            historyDates = r.dates.compactMap { fmt0.date(from: $0) }
            if let last = historyDates.last { historyEndDate = last }
            print("✅ Macro 6개월 월별 데이터 로드 완료 - \(r.dates.count)개월")
        } catch {
            print("⚠️ Macro 6개월 월별 데이터 로드 실패 → 스텁 폴백: \(error)")
            histories = [:]
            historyDates = []
        }
    }

    private func loadMacroData() async {
        isLoading = true
        errorMessage = nil

        // 수집기는 매일 UTC 04:00에 실행되어 그날(UTC 기준) 데이터를 DynamoDB에 저장함.
        // UTC 04:05 전이면 당일 데이터가 아직 없으므로 어제 요청, 04:05 이후면 오늘 요청.
        let utc = TimeZone(identifier: "UTC")!
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utc
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = utc

        let now = Date()
        let utcHour = utcCalendar.component(.hour, from: now)
        let utcMinute = utcCalendar.component(.minute, from: now)

        // 수집기(UTC 04:00)와 AI 분석(UTC 04:05) 완료 전이면 전날 요청
        let requestDate: String
        if utcHour < 4 || (utcHour == 4 && utcMinute < 5) {
            let yesterday = utcCalendar.date(byAdding: .day, value: -1, to: now)!
            requestDate = formatter.string(from: yesterday)
        } else {
            requestDate = formatter.string(from: now)
        }

        print("🔄 Macro API 호출 시작 - UTC 기준 날짜: \(requestDate), UTC 시간: \(utcHour):\(String(format: "%02d", utcMinute))")
        
        do {
            let response = try await MacroAPIService.shared.fetchMacroDataWithPrevious(date: requestDate)
            
            print("✅ Macro API 응답 받음 - requestDate: \(response.requestDate), previousDate: \(response.previousDate)")
            print("📊 requestData: \(response.data.requestDate != nil ? "있음" : "없음")")
            print("📊 previousData: \(response.data.previousDate != nil ? "있음" : "없음")")
            
            // requestDate가 없으면 previousDate를 메인으로 사용 (폴백)
            let mainData = response.data.requestDate ?? response.data.previousDate
            let prevData = response.data.requestDate != nil ? response.data.previousDate : nil
            let displayDate = response.data.requestDate != nil ? response.requestDate : response.previousDate

            if let data = mainData {
                print("📈 Macro 데이터 파싱 시작 (메인: \(displayDate))")
                let previousData = prevData

                updatedTime = formatDateString(displayDate)
                let interestRateValue = data.interestRate ?? 0.0
                let interestRateChange = calculatePercentageChange(current: data.interestRate ?? 0.0, previous: previousData?.interestRate ?? 0.0)
                let treasury10yValue = data.treasury10y ?? 0.0
                let treasury10yChange = calculatePercentageChange(current: data.treasury10y ?? 0.0, previous: previousData?.treasury10y ?? 0.0)
                let cpiValue = data.cpi ?? 0.0
                let cpiChange = calculatePercentageChange(current: data.cpi ?? 0.0, previous: previousData?.cpi ?? 0.0)
                let m2Value = data.m2 ?? 0.0
                let m2Change = calculatePercentageChange(current: data.m2 ?? 0.0, previous: previousData?.m2 ?? 0.0)
                let unemploymentValue = data.unemployment ?? 0.0
                let unemploymentChange = calculatePercentageChange(current: data.unemployment ?? 0.0, previous: previousData?.unemployment ?? 0.0)
                let dollarIndexValue = data.dollarIndex ?? 0.0
                let dollarIndexChange = calculatePercentageChange(current: data.dollarIndex ?? 0.0, previous: previousData?.dollarIndex ?? 0.0)
                let vixValue = data.vix ?? 20.0  // v3.0 신규
                let vixChange = calculatePercentageChange(current: data.vix ?? 20.0, previous: previousData?.vix ?? 20.0)  // v3.0 신규
                let oilPriceValue = data.oilPrice ?? 70.0  // v3.0 신규
                let oilPriceChange = calculatePercentageChange(current: data.oilPrice ?? 70.0, previous: previousData?.oilPrice ?? 70.0)  // v3.0 신규
                let yieldSpreadValue = data.yieldSpread ?? 0.5  // v3.0 신규
                let yieldSpreadChange = (data.yieldSpread ?? 0.5) - (previousData?.yieldSpread ?? 0.5)  // v3.0 신규
                let breakEvenInflationValue = data.breakEvenInflation ?? 2.3  // v3.0 신규
                let breakEvenInflationChange = (data.breakEvenInflation ?? 2.3) - (previousData?.breakEvenInflation ?? 2.3)  // v3.0 신규

                dashboardData = MacroDashboardData(
                    interestRate: MacroMetric(title: "Interest Rate", subtitle: "Federal Funds Rate", value: String(format: "%.2f%%", interestRateValue), change: formatChange(interestRateChange), changeIsPositive: interestRateChange >= 0, rawValue: interestRateValue),
                    treasury10y: MacroMetric(title: "10Y Treasury", subtitle: "Yield", value: String(format: "%.2f%%", treasury10yValue), change: formatChange(treasury10yChange), changeIsPositive: treasury10yChange >= 0, rawValue: treasury10yValue),
                    cpi: MacroMetric(title: "CPI", subtitle: "Consumer Price Index", value: String(format: "%.2f%%", cpiValue / 100.0), change: formatChange(cpiChange), changeIsPositive: cpiChange >= 0, rawValue: cpiValue / 100.0),
                    m2: MacroMetric(title: "M2 Money Supply", subtitle: "Billions USD", value: formatM2(m2Value), change: formatChange(m2Change), changeIsPositive: m2Change >= 0, rawValue: m2Value),
                    unemployment: MacroMetric(title: "Unemployment", subtitle: "Rate", value: String(format: "%.2f%%", unemploymentValue), change: formatChange(unemploymentChange), changeIsPositive: unemploymentChange >= 0, rawValue: unemploymentValue),
                    dollarIndex: MacroMetric(title: "Dollar Index", subtitle: "DXY", value: String(format: "%.2f", dollarIndexValue), change: formatChange(dollarIndexChange), changeIsPositive: dollarIndexChange >= 0, rawValue: dollarIndexValue),
                    vix: MacroMetric(title: "VIX", subtitle: "Volatility Index", value: String(format: "%.2f", vixValue), change: formatChange(vixChange), changeIsPositive: vixChange <= 0, rawValue: vixValue),  // v3.0 신규: 음수(하락) = 좋음
                    oilPrice: MacroMetric(title: "Oil Price", subtitle: "WTI Crude", value: String(format: "$%.2f", oilPriceValue), change: formatChange(oilPriceChange), changeIsPositive: oilPriceChange >= 0, rawValue: oilPriceValue),  // v3.0 신규
                    yieldSpread: MacroMetric(title: "Yield Spread", subtitle: "T10Y2Y", value: String(format: "%+.2f%%", yieldSpreadValue), change: yieldSpreadChange != 0 ? String(format: "%+.2f%%", yieldSpreadChange) : nil, changeIsPositive: yieldSpreadChange >= 0, rawValue: yieldSpreadValue),  // v3.0 신규
                    breakEvenInflation: MacroMetric(title: "Break-Even Inflation", subtitle: "10Y BE", value: String(format: "%.2f%%", breakEvenInflationValue), change: breakEvenInflationChange != 0 ? String(format: "%+.2f%%", breakEvenInflationChange) : nil, changeIsPositive: breakEvenInflationChange <= 0, rawValue: breakEvenInflationValue)  // v3.0 신규: 2% 근처가 최적
                )
                print("✅ Macro 데이터 업데이트 완료 - \(displayDate)")
                isDataLoaded = true   // 실데이터 표시 시작(스켈레톤 종료)

                // 30일 추세 실데이터 로드(실패 시 스텁 폴백)
                await loadMacroHistory(endDate: displayDate)

                // 재진입 시 즉시 복원용 세션 캐시 갱신
                MacroDashboardCache.data = dashboardData
                MacroDashboardCache.histories = histories
                MacroDashboardCache.historyDates = historyDates
                MacroDashboardCache.historyEndDate = historyEndDate
                MacroDashboardCache.updatedTime = updatedTime
            } else {
                print("⚠️ requestDate·previousDate 모두 nil. 데이터 없음.")
                updatedTime = ""
                dashboardData = MacroDashboardData(
                    interestRate: MacroMetric(title: "Interest Rate", subtitle: "Federal Funds Rate", value: "0.00%", change: nil, changeIsPositive: nil),
                    treasury10y: MacroMetric(title: "10Y Treasury", subtitle: "Yield", value: "0.00%", change: nil, changeIsPositive: nil),
                    cpi: MacroMetric(title: "CPI", subtitle: "Consumer Price Index", value: "0.00%", change: nil, changeIsPositive: nil),
                    m2: MacroMetric(title: "M2 Money Supply", subtitle: "Billions USD", value: "0", change: nil, changeIsPositive: nil),
                    unemployment: MacroMetric(title: "Unemployment", subtitle: "Rate", value: "0.00%", change: nil, changeIsPositive: nil),
                    dollarIndex: MacroMetric(title: "Dollar Index", subtitle: "DXY", value: "0.00", change: nil, changeIsPositive: nil),
                    vix: MacroMetric(title: "VIX", subtitle: "Volatility Index", value: "0.00", change: nil, changeIsPositive: nil),  // v3.0 신규
                    oilPrice: MacroMetric(title: "Oil Price", subtitle: "WTI Crude", value: "$0.00", change: nil, changeIsPositive: nil),  // v3.0 신규
                    yieldSpread: MacroMetric(title: "Yield Spread", subtitle: "T10Y2Y", value: "+0.00%", change: nil, changeIsPositive: nil),  // v3.0 신규
                    breakEvenInflation: MacroMetric(title: "Break-Even Inflation", subtitle: "10Y BE", value: "0.00%", change: nil, changeIsPositive: nil)  // v3.0 신규
                )
            }
        } catch {
            print("❌ Macro API 호출 실패: \(error)")
            print("   에러 타입: \(type(of: error))")
            if let urlError = error as? URLError {
                print("   URL 에러 코드: \(urlError.code.rawValue)")
                print("   URL 에러 설명: \(urlError.localizedDescription)")
            }
            
            // API 호출 실패 시 데이터를 0으로 설정
            dashboardData = MacroDashboardData(
                interestRate: MacroMetric(
                    title: "Interest Rate",
                    subtitle: "Federal Funds Rate",
                    value: "0.00%",
                    change: nil,
                    changeIsPositive: nil
                ),
                treasury10y: MacroMetric(
                    title: "10Y Treasury",
                    subtitle: "Yield",
                    value: "0.00%",
                    change: nil,
                    changeIsPositive: nil
                ),
                cpi: MacroMetric(
                    title: "CPI",
                    subtitle: "Consumer Price Index",
                    value: "0.00%",
                    change: nil,
                    changeIsPositive: nil
                ),
                m2: MacroMetric(
                    title: "M2 Money Supply",
                    subtitle: "Billions USD",
                    value: "0",
                    change: nil,
                    changeIsPositive: nil
                ),
                unemployment: MacroMetric(
                    title: "Unemployment",
                    subtitle: "Rate",
                    value: "0.00%",
                    change: nil,
                    changeIsPositive: nil
                ),
                dollarIndex: MacroMetric(
                    title: "Dollar Index",
                    subtitle: "DXY",
                    value: "0.00",
                    change: nil,
                    changeIsPositive: nil
                ),
                vix: MacroMetric(
                    title: "VIX",
                    subtitle: "Volatility Index",
                    value: "0.00",
                    change: nil,
                    changeIsPositive: nil
                ),
                oilPrice: MacroMetric(
                    title: "Oil Price",
                    subtitle: "WTI Crude",
                    value: "$0.00",
                    change: nil,
                    changeIsPositive: nil
                ),
                yieldSpread: MacroMetric(
                    title: "Yield Spread",
                    subtitle: "T10Y2Y",
                    value: "+0.00%",
                    change: nil,
                    changeIsPositive: nil
                ),
                breakEvenInflation: MacroMetric(
                    title: "Break-Even Inflation",
                    subtitle: "10Y BE",
                    value: "0.00%",
                    change: nil,
                    changeIsPositive: nil
                )
            )
            
            errorMessage = "데이터를 불러올 수 없습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func calculatePercentageChange(current: Double, previous: Double) -> Double {
        guard previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    
    private func formatDateString(_ dateString: String) -> String {
        // yyyyMMdd 형식의 날짜를 "December 31, 2023" 형식으로 변환
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMMM d, yyyy"
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        return outputFormatter.string(from: date)
    }
    
    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "▲" : "▼"
        return "\(sign) \(String(format: "%.2f", abs(change)))%"
    }

    private func formatM2(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    // MARK: - Color Helper Functions

    private func colorForInterestRate(_ valueString: String) -> Color {
        guard let value = Double(valueString.replacingOccurrences(of: "%", with: "")) else {
            return .white
        }
        return ColorUtility.colorForInterestRate(value)
    }

    private func colorForTreasury(_ valueString: String) -> Color {
        guard let value = Double(valueString.replacingOccurrences(of: "%", with: "")) else {
            return .white
        }
        return ColorUtility.colorForTreasury(value)
    }

    private func colorForCPI(_ valueString: String) -> Color {
        guard let value = Double(valueString.replacingOccurrences(of: "%", with: "")) else {
            return .white
        }
        return ColorUtility.colorForCPI(value)
    }

    private func colorForM2(_ valueString: String) -> Color {
        // M2는 변화율이 들어오므로, 양수/음수로 판단
        let cleanValue = valueString.replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleanValue) else {
            return .white
        }
        return ColorUtility.colorForM2(value)
    }

    private func colorForUnemployment(_ valueString: String) -> Color {
        guard let value = Double(valueString.replacingOccurrences(of: "%", with: "")) else {
            return .white
        }
        return ColorUtility.colorForUnemployment(value)
    }

    private func colorForDollarIndex(_ valueString: String) -> Color {
        guard let value = Double(valueString) else {
            return .white
        }
        return ColorUtility.colorForDollarIndex(value)
    }

    // v3.0 신규 색상 함수들
    private func colorForVix(_ valueString: String) -> Color {
        guard let value = Double(valueString) else {
            return .white
        }
        return ColorUtility.colorForVix(value)
    }

    private func colorForOilPrice(_ valueString: String) -> Color {
        let cleanValue = valueString.replacingOccurrences(of: "$", with: "")
        guard let value = Double(cleanValue) else {
            return .white
        }
        return ColorUtility.colorForOilPrice(value)
    }

    private func colorForYieldSpread(_ valueString: String) -> Color {
        let cleanValue = valueString.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "+"))
        guard let value = Double(cleanValue) else {
            return .white
        }
        return ColorUtility.colorForYieldSpread(value)
    }

    private func colorForBreakEvenInflation(_ valueString: String) -> Color {
        guard let value = Double(valueString.replacingOccurrences(of: "%", with: "")) else {
            return .white
        }
        return ColorUtility.colorForBreakEvenInflation(value)
    }
}

// MARK: - Macro Metric Card
struct MacroMetricCard: View {
    let metric: MacroMetric
    let valueColor: Color
    var history: [Double]? = nil   // 30일 실데이터(없으면 스텁)
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    // 값 연동 해석 (rawValue + 전일 대비 추세). 매핑 없거나 rawValue 없으면 nil.
    private var interpretation: IndicatorInterpretation? {
        guard let key = IndicatorInterpreter.key(forTitle: metric.title),
              let raw = metric.rawValue else { return nil }
        let trend: TrendDirection = metric.changeIsPositive == nil
            ? .flat
            : (metric.changeIsPositive! ? .up : .down)
        return IndicatorInterpreter.interpret(key, value: raw, trend: trend, language: selectedLanguage)
    }

    // 30일 스파크라인 (실데이터 우선, 없으면 스텁)
    private var sparkline: [Double]? {
        guard let key = IndicatorInterpreter.key(forTitle: metric.title),
              let raw = metric.rawValue else { return nil }
        if let history, history.count >= 2 { return history }
        return CryptoHistoryProvider.history(for: key, current: raw, days: 30)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
            // Icon placeholder
            Circle()
                .fill(theme.cardIconBackground)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: iconForMetric(metric.title))
                        .font(.system(size: 20))
                        .foregroundColor(valueColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(localization.macroMetric(metric.title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                Text(localization.macroMetric(metric.subtitle))
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(metric.value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(valueColor)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.tertiaryText)
            }
            }

            // 30일 추세 스파크라인 (실데이터 우선, 없으면 스텁)
            if let spark = sparkline {
                TrendChartView(values: spark, mode: .spark)
            }

            // 값 연동 1줄 해석 (오늘 값/방향의 의미)
            if let interp = interpretation {
                VStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5)
                    HStack(spacing: 6) {
                        Text(interp.sentiment.symbol)
                            .font(.system(size: 12, weight: .bold))
                        Text(interp.text)
                            .font(.system(size: 11.5, weight: .medium))
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(interp.sentiment.color)
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
    
    private func iconForMetric(_ title: String) -> String {
        switch title {
        case "Interest Rate":
            return "percent"
        case "10Y Treasury":
            return "chart.line.uptrend.xyaxis"
        case "CPI":
            return "chart.bar.fill"
        case "M2 Money Supply":
            return "dollarsign.circle.fill"
        case "Unemployment":
            return "person.2.fill"
        case "Dollar Index":
            return "dollarsign.square.fill"
        case "VIX":  // v3.0 신규
            return "bolt.fill"
        case "Oil Price":  // v3.0 신규
            return "drop.fill"
        case "Yield Spread":  // v3.0 신규
            return "arrow.up.arrow.down"
        case "Break-Even Inflation":  // v3.0 신규
            return "chart.line.downtrend.xyaxis"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - Macro Info Row
struct MacroInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    MacroDashboardView()
        .environmentObject(ThemeManager.shared)
}
