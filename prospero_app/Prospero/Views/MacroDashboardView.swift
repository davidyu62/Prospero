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
                        // Top Row: App Icon, Name, Refresh Button
                        HStack(spacing: 12) {
                            // App Icon
                            AppIconView(size: 44)
                            
                            // App Name
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Prospero")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(theme.primaryText)
                                
                                Text("AI Investment Insights")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(theme.secondaryText)
                            }
                            
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

                dashboardData = MacroDashboardData(
                    interestRate: MacroMetric(title: "Interest Rate", subtitle: "Federal Funds Rate", value: String(format: "%.2f%%", interestRateValue), change: formatChange(interestRateChange), changeIsPositive: interestRateChange >= 0),
                    treasury10y: MacroMetric(title: "10Y Treasury", subtitle: "Yield", value: String(format: "%.2f%%", treasury10yValue), change: formatChange(treasury10yChange), changeIsPositive: treasury10yChange >= 0),
                    cpi: MacroMetric(title: "CPI", subtitle: "Consumer Price Index", value: String(format: "%.2f%%", cpiValue / 100.0), change: formatChange(cpiChange), changeIsPositive: cpiChange >= 0),
                    m2: MacroMetric(title: "M2 Money Supply", subtitle: "Billions USD", value: formatM2(m2Value), change: formatChange(m2Change), changeIsPositive: m2Change >= 0),
                    unemployment: MacroMetric(title: "Unemployment", subtitle: "Rate", value: String(format: "%.2f%%", unemploymentValue), change: formatChange(unemploymentChange), changeIsPositive: unemploymentChange >= 0),
                    dollarIndex: MacroMetric(title: "Dollar Index", subtitle: "DXY", value: String(format: "%.2f", dollarIndexValue), change: formatChange(dollarIndexChange), changeIsPositive: dollarIndexChange >= 0)
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
                    dollarIndex: MacroMetric(title: "Dollar Index", subtitle: "DXY", value: "0.00", change: nil, changeIsPositive: nil)
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
