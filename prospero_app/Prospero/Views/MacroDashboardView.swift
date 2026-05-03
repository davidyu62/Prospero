//
//  MacroDashboardView.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI
import UIKit

struct MacroDashboardView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var dashboardData = MacroDashboardData.sample
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showInterestRateInfo = false
    @State private var showTreasury10yInfo = false
    @State private var showCPIInfo = false
    @State private var showM2Info = false
    @State private var showUnemploymentInfo = false
    @State private var showDollarIndexInfo = false
    @State private var showVixInfo = false              // v3.0 신규
    @State private var showOilPriceInfo = false        // v3.0 신규
    @State private var showYieldSpreadInfo = false     // v3.0 신규
    @State private var showBreakEvenInflationInfo = false // v3.0 신규
    @State private var updatedTime: String = ""
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
                    VStack(spacing: 12) {
                        MacroMetricCard(metric: dashboardData.interestRate, valueColor: colorForInterestRate(dashboardData.interestRate.value), theme: theme)
                            .onTapGesture {
                                showInterestRateInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.treasury10y, valueColor: colorForTreasury(dashboardData.treasury10y.value), theme: theme)
                            .onTapGesture {
                                showTreasury10yInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.cpi, valueColor: colorForCPI(dashboardData.cpi.value), theme: theme)
                            .onTapGesture {
                                showCPIInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.m2, valueColor: colorForM2(dashboardData.m2.value), theme: theme)
                            .onTapGesture {
                                showM2Info = true
                            }
                        MacroMetricCard(metric: dashboardData.unemployment, valueColor: colorForUnemployment(dashboardData.unemployment.value), theme: theme)
                            .onTapGesture {
                                showUnemploymentInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.dollarIndex, valueColor: colorForDollarIndex(dashboardData.dollarIndex.value), theme: theme)
                            .onTapGesture {
                                showDollarIndexInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.vix, valueColor: colorForVix(dashboardData.vix.value), theme: theme)
                            .onTapGesture {
                                showVixInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.oilPrice, valueColor: colorForOilPrice(dashboardData.oilPrice.value), theme: theme)
                            .onTapGesture {
                                showOilPriceInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.yieldSpread, valueColor: colorForYieldSpread(dashboardData.yieldSpread.value), theme: theme)
                            .onTapGesture {
                                showYieldSpreadInfo = true
                            }
                        MacroMetricCard(metric: dashboardData.breakEvenInflation, valueColor: colorForBreakEvenInflation(dashboardData.breakEvenInflation.value), theme: theme)
                            .onTapGesture {
                                showBreakEvenInflationInfo = true
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // 배너 + 네비게이션 바
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    if let error = errorMessage {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            // Macro 탭이 나타날 때만 데이터 로드
            Task {
                await loadMacroData()
            }
        }
        .sheet(isPresented: $showInterestRateInfo) {
            InterestRateInfoSheet()
        }
        .sheet(isPresented: $showTreasury10yInfo) {
            Treasury10yInfoSheet()
        }
        .sheet(isPresented: $showCPIInfo) {
            CPIInfoSheet()
        }
        .sheet(isPresented: $showM2Info) {
            M2InfoSheet()
        }
        .sheet(isPresented: $showUnemploymentInfo) {
            UnemploymentInfoSheet()
        }
        .sheet(isPresented: $showDollarIndexInfo) {
            DollarIndexInfoSheet()
        }
        .sheet(isPresented: $showVixInfo) {
            VixInfoSheet()
        }
        .sheet(isPresented: $showOilPriceInfo) {
            OilPriceInfoSheet()
        }
        .sheet(isPresented: $showYieldSpreadInfo) {
            YieldSpreadInfoSheet()
        }
        .sheet(isPresented: $showBreakEvenInflationInfo) {
            BreakEvenInflationInfoSheet()
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
                    interestRate: MacroMetric(title: "Interest Rate", subtitle: "Federal Funds Rate", value: String(format: "%.2f%%", interestRateValue), change: formatChange(interestRateChange), changeIsPositive: interestRateChange >= 0),
                    treasury10y: MacroMetric(title: "10Y Treasury", subtitle: "Yield", value: String(format: "%.2f%%", treasury10yValue), change: formatChange(treasury10yChange), changeIsPositive: treasury10yChange >= 0),
                    cpi: MacroMetric(title: "CPI", subtitle: "Consumer Price Index", value: String(format: "%.2f%%", cpiValue / 100.0), change: formatChange(cpiChange), changeIsPositive: cpiChange >= 0),
                    m2: MacroMetric(title: "M2 Money Supply", subtitle: "Billions USD", value: formatM2(m2Value), change: formatChange(m2Change), changeIsPositive: m2Change >= 0),
                    unemployment: MacroMetric(title: "Unemployment", subtitle: "Rate", value: String(format: "%.2f%%", unemploymentValue), change: formatChange(unemploymentChange), changeIsPositive: unemploymentChange >= 0),
                    dollarIndex: MacroMetric(title: "Dollar Index", subtitle: "DXY", value: String(format: "%.2f", dollarIndexValue), change: formatChange(dollarIndexChange), changeIsPositive: dollarIndexChange >= 0),
                    vix: MacroMetric(title: "VIX", subtitle: "Volatility Index", value: String(format: "%.2f", vixValue), change: formatChange(vixChange), changeIsPositive: vixChange <= 0),  // v3.0 신규: 음수(하락) = 좋음
                    oilPrice: MacroMetric(title: "Oil Price", subtitle: "WTI Crude", value: String(format: "$%.2f", oilPriceValue), change: formatChange(oilPriceChange), changeIsPositive: oilPriceChange >= 0),  // v3.0 신규
                    yieldSpread: MacroMetric(title: "Yield Spread", subtitle: "T10Y2Y", value: String(format: "%+.2f%%", yieldSpreadValue), change: yieldSpreadChange != 0 ? String(format: "%+.2f%%", yieldSpreadChange) : nil, changeIsPositive: yieldSpreadChange >= 0),  // v3.0 신규
                    breakEvenInflation: MacroMetric(title: "Break-Even Inflation", subtitle: "10Y BE", value: String(format: "%.2f%%", breakEvenInflationValue), change: breakEvenInflationChange != 0 ? String(format: "%+.2f%%", breakEvenInflationChange) : nil, changeIsPositive: breakEvenInflationChange <= 0)  // v3.0 신규: 2% 근처가 최적
                )
                print("✅ Macro 데이터 업데이트 완료 - \(displayDate)")
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
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
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

// MARK: - Interest Rate Info Sheet
struct InterestRateInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "percent")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.macroMetric("Interest Rate"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is the Federal Funds Rate?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("The Federal Funds Rate is the interest rate at which depository institutions (banks) lend reserve balances to other depository institutions overnight. It's set by the Federal Reserve and is one of the most important economic indicators."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Rate Increases"), description: localization.infoSheet("Tightens monetary policy, slows economic growth"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Rate Decreases"), description: localization.infoSheet("Loosens monetary policy, stimulates growth"))
                            MacroInfoRow(icon: "chart.line.uptrend.xyaxis", title: localization.infoSheet("Market Impact"), description: localization.infoSheet("Affects borrowing costs and investment decisions"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("The Federal Reserve adjusts the federal funds rate to influence economic activity. When rates rise, borrowing becomes more expensive, which can slow inflation but also economic growth. When rates fall, borrowing becomes cheaper, stimulating spending and investment. This rate directly impacts mortgage rates, credit card rates, and other consumer loans."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - 10Y Treasury Info Sheet
struct Treasury10yInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.green)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.macroMetric("10Y Treasury"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is the 10-Year Treasury Yield?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("The 10-Year Treasury Yield is the return on investment for the U.S. government's 10-year bond. It's considered a benchmark for long-term interest rates and is closely watched as an indicator of economic expectations."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Rising Yields"), description: localization.infoSheet("Often signals economic growth expectations"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Falling Yields"), description: localization.infoSheet("May indicate economic concerns or flight to safety"))
                            MacroInfoRow(icon: "chart.bar.fill", title: localization.infoSheet("Risk-Free Rate"), description: localization.infoSheet("Used as benchmark for other investments"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("When investors buy Treasury bonds, they're lending money to the U.S. government. The yield represents the return they receive. Higher yields typically indicate stronger economic growth expectations or inflation concerns. Lower yields may suggest economic uncertainty or deflationary pressures. The 10-year yield is particularly important as it influences mortgage rates, corporate borrowing costs, and stock valuations."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - CPI Info Sheet
struct CPIInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.orange)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.macroMetric("CPI"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is CPI?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("The Consumer Price Index (CPI) measures the average change over time in the prices paid by urban consumers for a market basket of consumer goods and services. It's the most widely used indicator of inflation."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Rising CPI"), description: localization.infoSheet("Indicates inflation - prices are increasing"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Falling CPI"), description: localization.infoSheet("Indicates deflation - prices are decreasing"))
                            MacroInfoRow(icon: "target", title: localization.infoSheet("Target Rate"), description: localization.infoSheet("Central banks typically target 2% inflation"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("The CPI tracks price changes for a basket of goods and services that represents what typical consumers buy, including food, housing, transportation, medical care, and more. When CPI rises, it means consumers need to spend more to buy the same goods, indicating inflation. Central banks use CPI data to make monetary policy decisions. High inflation erodes purchasing power, while deflation can signal economic weakness."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - M2 Money Supply Info Sheet
struct M2InfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.yellow.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.yellow)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.macroMetric("M2 Money Supply"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is M2 Money Supply?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("M2 is a measure of the money supply that includes cash, checking deposits, savings deposits, money market securities, and other time deposits. It represents the total amount of money available in the economy for spending and investment."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Increasing M2"), description: localization.infoSheet("More money in circulation, can fuel inflation"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Decreasing M2"), description: localization.infoSheet("Less money available, may slow economic activity"))
                            MacroInfoRow(icon: "chart.line.uptrend.xyaxis", title: localization.infoSheet("Economic Indicator"), description: localization.infoSheet("Reflects monetary policy and economic health"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("M2 includes all forms of money that are easily accessible for spending. When the Federal Reserve increases the money supply (through quantitative easing or other measures), M2 rises. This can stimulate economic activity but may also lead to inflation if it grows too quickly. Conversely, a shrinking M2 can indicate tighter monetary policy or economic contraction. It's measured in billions of U.S. dollars."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Unemployment Info Sheet
struct UnemploymentInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.red)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.macroMetric("Unemployment"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is the Unemployment Rate?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("The Unemployment Rate measures the percentage of the labor force that is jobless and actively seeking employment. It's a key indicator of economic health and labor market conditions."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Low Unemployment"), description: localization.infoSheet("Strong economy, tight labor market"))
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("High Unemployment"), description: localization.infoSheet("Weak economy, excess labor supply"))
                            MacroInfoRow(icon: "target", title: localization.infoSheet("Natural Rate"), description: localization.infoSheet("Typically around 4-5% in healthy economies"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("The unemployment rate is calculated by dividing the number of unemployed people by the total labor force (employed + unemployed). A low unemployment rate indicates a strong job market and healthy economy, but extremely low rates can lead to wage inflation. High unemployment suggests economic weakness and can lead to reduced consumer spending. The Federal Reserve considers unemployment when setting monetary policy, as it relates to both inflation and economic growth."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Dollar Index Info Sheet
struct DollarIndexInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "dollarsign.square.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.green)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.macroMetric("Dollar Index"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is the Dollar Index?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("The U.S. Dollar Index (DXY) measures the value of the U.S. dollar against a basket of foreign currencies, including the Euro, Japanese Yen, British Pound, Canadian Dollar, Swedish Krona, and Swiss Franc. It's a key indicator of dollar strength."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Rising DXY"), description: localization.infoSheet("Strong dollar, makes imports cheaper"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Falling DXY"), description: localization.infoSheet("Weak dollar, makes exports more competitive"))
                            MacroInfoRow(icon: "globe", title: localization.infoSheet("Global Impact"), description: localization.infoSheet("Affects international trade and commodity prices"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("The Dollar Index is calculated as a weighted geometric mean of the dollar's value against the basket of currencies. A value above 100 means the dollar is stronger than the baseline (set in 1973), while below 100 means it's weaker. A strong dollar makes U.S. exports more expensive but imports cheaper, while a weak dollar has the opposite effect. The index is closely watched by traders, investors, and policymakers as it impacts global trade, commodity prices (which are often priced in dollars), and emerging market economies."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - VIX Info Sheet
struct VixInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.red)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Title
                    Text(localization.macroMetric("VIX"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is the VIX?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(localization.infoSheet("The VIX (Volatility Index), also known as the 'Fear Index,' measures the market's expectation of 30-day volatility based on S&P 500 index option prices. It's a key gauge of investor fear and market uncertainty."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)

                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Low VIX (≤15)"), description: localization.infoSheet("Low fear, stable markets, bullish sentiment"))
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("High VIX (>30)"), description: localization.infoSheet("High fear, volatile markets, risk-off sentiment"))
                            MacroInfoRow(icon: "chart.line.uptrend.xyaxis", title: localization.infoSheet("Market Indicator"), description: localization.infoSheet("Inverse correlation with stock market performance"))
                        }

                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        Text(localization.infoSheet("The VIX is derived from the implied volatility of S&P 500 index options, representing what traders expect about future market swings. When investors are confident, the VIX stays low; when uncertainty increases, the VIX rises sharply. A VIX below 15 typically indicates complacency and strong risk appetite. A spike above 30 signals panic and flight to safety. Crypto markets often move in inverse correlation with the VIX - when traditional markets stabilize (VIX falls), capital may flow back to risk assets like crypto."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Oil Price Info Sheet
struct OilPriceInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.orange)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Title
                    Text(localization.macroMetric("Oil Price"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is Oil Price?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(localization.infoSheet("The Oil Price (WTI Crude) is the cost per barrel of West Texas Intermediate crude oil, a primary benchmark for global oil prices. It reflects supply-demand dynamics and geopolitical factors that impact the global economy."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)

                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "chart.line.uptrend.xyaxis", title: localization.infoSheet("Optimal Range ($60-80)"), description: localization.infoSheet("Stable prices support economic growth"))
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("High Oil Prices (>$90)"), description: localization.infoSheet("Inflation pressure, reduces consumer spending"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Low Oil Prices (<$50)"), description: localization.infoSheet("Economic weakness signal, deflationary pressure"))
                        }

                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        Text(localization.infoSheet("Oil prices impact inflation, transportation costs, and manufacturing expenses across the economy. High oil prices can trigger stagflation (high inflation with weak growth), while low prices may indicate recession fears. The price is driven by OPEC production decisions, geopolitical events, supply disruptions, and global economic growth expectations. For crypto investors, elevated oil prices often correlate with inflation concerns that drive investment in alternative assets like Bitcoin."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Yield Spread Info Sheet
struct YieldSpreadInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.purple)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Title
                    Text(localization.macroMetric("Yield Spread"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is Yield Spread?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(localization.infoSheet("The Yield Spread (T10Y2Y) is the difference between 10-year and 2-year U.S. Treasury yields. It's a critical indicator of economic expectations and is often used as a recession predictor when the curve inverts (negative spread)."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)

                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Positive Spread (>0.5%)"), description: localization.infoSheet("Normal curve, economic growth expected"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Negative Spread (<0%)"), description: localization.infoSheet("Inverted curve, recession warning signal"))
                            MacroInfoRow(icon: "exclamationmark.circle.fill", title: localization.infoSheet("Recession Predictor"), description: localization.infoSheet("Inversion has preceded most U.S. recessions"))
                        }

                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        Text(localization.infoSheet("Normally, longer-term bonds have higher yields than shorter-term bonds (positive spread). When short-term rates rise above long-term rates due to expected future economic weakness, the curve inverts. This inversion has been a reliable predictor of recession: every inversion in the past 50 years has preceded a downturn. For crypto markets, yield curve inversion often triggers risk-off sentiment, but it can also precede monetary policy shifts (rate cuts) that eventually support alternative assets."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Break-Even Inflation Info Sheet
struct BreakEvenInflationInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Icon
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "chart.line.downtrend.xyaxis")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.red)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)

                    // Title
                    Text(localization.macroMetric("Break-Even Inflation"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is Break-Even Inflation?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(localization.infoSheet("Break-Even Inflation (10Y BE) is the market's expectation of average inflation over the next 10 years, derived from the difference between nominal Treasury yields and TIPS (Treasury Inflation-Protected Securities) yields. It reflects investor inflation expectations."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)

                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            MacroInfoRow(icon: "target", title: localization.infoSheet("Optimal Range (1.8-2.3%)"), description: localization.infoSheet("Fed target achieved, stable growth"))
                            MacroInfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Above 2.5%"), description: localization.infoSheet("Inflation concerns, may trigger policy tightening"))
                            MacroInfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Below 1.5%"), description: localization.infoSheet("Deflation fears, economic weakness signal"))
                        }

                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        Text(localization.infoSheet("Market participants buy TIPS to protect against inflation, creating a spread with nominal Treasuries. This spread reflects inflation expectations. When expectations rise above the Fed's 2% target, the central bank may maintain hawkish policies to contain inflation, which pressures risk assets. Conversely, when expectations fall below target, it may signal demand weakness or impending rate cuts. For crypto investors, elevated inflation expectations can support Bitcoin as an inflation hedge, while deflation fears typically trigger broad risk-off sentiment."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
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
