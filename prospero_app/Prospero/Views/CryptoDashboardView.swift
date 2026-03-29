//
//  CryptoDashboardView.swift
//  Prospero
//
//  Created on $(date)
//

import SwiftUI
import UIKit

struct CryptoDashboardView: View {
    @EnvironmentObject var theme: ThemeManager
    @State private var dashboardData = CryptoDashboardData.sample
    @State private var selectedTab: TabItem = .crypto
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showBitcoinInfo = false
    @State private var showFearGreedInfo = false
    @State private var showOpenInterestInfo = false
    @State private var showLongShortRatioInfo = false
    @State private var updatedTime: String = ""
    @State private var showAdNotReadyAlert = false
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        ZStack {
            theme.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab Content
                Group {
                    switch selectedTab {
                    case .crypto:
                        // Crypto Dashboard Content
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
                                        
                                        // Refresh Button
                                        Button(action: {
                                            Task {
                                                await loadCryptoData()
                                            }
                                        }) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(theme.secondaryText)
                                                .frame(width: 36, height: 36)
                                                .background(
                                        Circle()
                                            .fill(theme.cardIconBackground)
                                                )
                                        }
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
                                
                                // Bitcoin Card
                                BitcoinCard(data: dashboardData.bitcoin, theme: theme)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        showBitcoinInfo = true
                                    }
                                
                                // Fear & Greed Index Card
                                FearGreedCard(data: dashboardData.fearGreed, theme: theme)
                                    .padding(.horizontal, 20)
                                    .onTapGesture {
                                        showFearGreedInfo = true
                                    }
                                
                                // Small Metric Cards
                                VStack(spacing: 12) {
                                    MetricCard(metric: dashboardData.openInterest, theme: theme)
                                        .onTapGesture {
                                            showOpenInterestInfo = true
                                        }
                                    MetricCard(metric: dashboardData.longShortRatio, theme: theme)
                                        .onTapGesture {
                                            showLongShortRatioInfo = true
                                        }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 120) // 콘텐츠 하단 여백 (배너 + 네비게이션 바)
                                
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
                    case .macro:
                        // Macro Dashboard View
                        MacroDashboardView()
                    case .ai:
                        // AI 데이터 분석
                        AIView()
                    case .settings:
                        // Settings View
                        SettingsView()
                    }
                }
                
                // 배너 광고 (스크롤 영역과 네비게이션 바 사이)
                BannerAdView()
                
                // Bottom Tab Bar (화면 하단에 고정)
                BottomTabBar(selectedTab: $selectedTab, theme: theme, onAITap: {
                    // TODO: 광고 재활성화 예정
                    // RewardedAdManager.shared.showAd(
                    //     onReward: { selectedTab = .ai },
                    //     onAdNotReady: { showAdNotReadyAlert = true }
                    // )
                    selectedTab = .ai
                })
            }
        }
        .task {
            // 초기 시간 설정
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            updatedTime = timeFormatter.string(from: Date())
            // 앱 시작 시 Crypto 탭이 기본 선택되므로 Crypto 데이터만 로드
            if selectedTab == .crypto {
                await loadCryptoData()
            }
        }
        .onChange(of: selectedTab) { newTab in
            // 탭 변경 시 해당 탭의 데이터 로드
            Task {
                if newTab == .crypto {
                    await loadCryptoData()
                }
            }
        }
        .sheet(isPresented: $showBitcoinInfo) {
            BitcoinInfoSheet()
        }
        .sheet(isPresented: $showFearGreedInfo) {
            FearGreedInfoSheet()
        }
        .sheet(isPresented: $showOpenInterestInfo) {
            OpenInterestInfoSheet()
        }
        .sheet(isPresented: $showLongShortRatioInfo) {
            LongShortRatioInfoSheet()
        }
        .alert(localization.common("Ad Not Ready"), isPresented: $showAdNotReadyAlert) {
            Button(localization.common("OK"), role: .cancel) {}
        } message: {
            Text(localization.common("Ad Loading Message"))
        }
    }
    
    private func loadCryptoData() async {
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

        print("🔄 API 호출 시작 - UTC 기준 날짜: \(requestDate), UTC 시간: \(utcHour):\(String(format: "%02d", utcMinute))")
        
        do {
            let response = try await CryptoAPIService.shared.fetchCryptoDataWithPrevious(date: requestDate)
            
            print("✅ API 응답 받음 - requestDate: \(response.requestDate), previousDate: \(response.previousDate)")
            print("📊 requestData: \(response.data.requestDate != nil ? "있음" : "없음")")
            print("📊 previousData: \(response.data.previousDate != nil ? "있음" : "없음")")
            
            // requestDate 데이터가 없으면 previousDate를 메인으로 사용 (폴백)
            let mainData = response.data.requestDate ?? response.data.previousDate
            let prevData = response.data.requestDate != nil ? response.data.previousDate : nil
            let displayDate = response.data.requestDate != nil ? response.requestDate : response.previousDate

            if let data = mainData {
                print("📈 데이터 파싱 시작 (메인: \(displayDate))")
                let previousData = prevData

                let btcPrice = data.btcPrice ?? 0.0
                let btcChange24h = calculatePercentageChange(
                    current: data.btcPrice ?? 0.0,
                    previous: previousData?.btcPrice ?? 0.0
                )
                let fearGreedValue = data.fearGreedIndex ?? 50
                let fearGreedLabel = getFearGreedLabel(fearGreedValue)
                let openInterestValue = data.openInterest ?? 0.0
                let openInterestChange = calculatePercentageChange(
                    current: data.openInterest ?? 0.0,
                    previous: previousData?.openInterest ?? 0.0
                )
                let longShortRatioValue = data.longShortRatio ?? 0.0
                let longShortRatioChange = calculatePercentageChange(
                    current: data.longShortRatio ?? 0.0,
                    previous: previousData?.longShortRatio ?? 0.0
                )

                updatedTime = formatDateString(displayDate)
                dashboardData = CryptoDashboardData(
                    bitcoin: BitcoinData(
                        price: btcPrice,
                        change24h: btcChange24h,
                        high24h: 0,
                        low24h: 0,
                        volume24h: 0,
                        dominance: 0,
                        updatedAt: ""
                    ),
                    fearGreed: FearGreedData(value: fearGreedValue, label: fearGreedLabel),
                    openInterest: CryptoMetric(
                        title: "Open Interest",
                        subtitle: "Futures Market",
                        value: formatOpenInterest(openInterestValue),
                        change: formatChange(openInterestChange),
                        changeIsPositive: openInterestChange >= 0
                    ),
                    longShortRatio: CryptoMetric(
                        title: "Long/Short Ratio",
                        subtitle: "Market Sentiment",
                        value: String(format: "%.2f", longShortRatioValue),
                        change: formatChange(longShortRatioChange),
                        changeIsPositive: longShortRatioChange >= 0
                    )
                )
                print("✅ 데이터 업데이트 완료 - \(displayDate)")
            } else {
                print("⚠️ requestDate·previousDate 모두 nil. 데이터 없음.")
                updatedTime = ""
                dashboardData = CryptoDashboardData(
                    bitcoin: BitcoinData(price: 0.0, change24h: 0.0, high24h: 0.0, low24h: 0.0, volume24h: 0.0, dominance: 0.0, updatedAt: ""),
                    fearGreed: FearGreedData(value: 0, label: "No data"),
                    openInterest: CryptoMetric(title: "Open Interest", subtitle: "Futures Market", value: "0.00M BTC", change: nil, changeIsPositive: nil),
                    longShortRatio: CryptoMetric(title: "Long/Short Ratio", subtitle: "Market Sentiment", value: "0.00", change: nil, changeIsPositive: nil)
                )
            }
        } catch {
            print("❌ API 호출 실패: \(error)")
            print("   에러 타입: \(type(of: error))")
            if let urlError = error as? URLError {
                print("   URL 에러 코드: \(urlError.code.rawValue)")
                print("   URL 에러 설명: \(urlError.localizedDescription)")
            }
            
            // API 호출 실패 시 데이터를 0으로 설정
            dashboardData = CryptoDashboardData(
                            bitcoin: BitcoinData(
                                price: 0.0,
                                change24h: 0.0,
                                high24h: 0.0,
                                low24h: 0.0,
                                volume24h: 0.0,
                                dominance: 0.0,
                                updatedAt: ""
                            ),
                fearGreed: FearGreedData(
                    value: 0,
                    label: "No data"
                ),
                openInterest: CryptoMetric(
                    title: "Open Interest",
                    subtitle: "Futures Market",
                    value: "0.00M BTC",
                    change: nil,
                    changeIsPositive: nil
                ),
                longShortRatio: CryptoMetric(
                    title: "Long/Short Ratio",
                    subtitle: "Market Sentiment",
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
    
    private func formatNumber(_ number: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func formatOpenInterest(_ value: Double) -> String {
        if value >= 1.0 {
            return String(format: "%.2fM BTC", value)
        } else {
            return String(format: "%.2f BTC", value * 1000000)
        }
    }
    
    private func getFearGreedLabel(_ value: Int) -> String {
        switch value {
        case 0...24:
            return "Extreme Fear"
        case 25...44:
            return "Fear"
        case 45...55:
            return "Neutral"
        case 56...75:
            return "Greed"
        case 76...100:
            return "Extreme Greed"
        default:
            return "Neutral"
        }
    }
}

// MARK: - Bitcoin Card
struct BitcoinCard: View {
    let data: BitcoinData
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                // Bitcoin Icon placeholder
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("B")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.accentColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(localization.cryptoMetric("Bitcoin (BTC)"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                }

                Spacer()
            }

            // Price
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(formatPrice(data.price))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(theme.primaryText)

                HStack(spacing: 4) {
                    Image(systemName: data.change24h >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ColorUtility.colorForCryptoChange(data.change24h))
                    Text("\(String(format: "%.2f", abs(data.change24h)))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ColorUtility.colorForCryptoChange(data.change24h))
                }
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
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}

// MARK: - Chart View Placeholder
struct ChartView: View {
    var body: some View {
        ZStack {
            // Simple upward trending line
            Path { path in
                path.move(to: CGPoint(x: 0, y: 50))
                path.addLine(to: CGPoint(x: 30, y: 45))
                path.addLine(to: CGPoint(x: 60, y: 35))
                path.addLine(to: CGPoint(x: 90, y: 25))
                path.addLine(to: CGPoint(x: 120, y: 15))
            }
            .stroke(Color.green, lineWidth: 2)
        }
    }
}

// MARK: - Metric Row
struct MetricRow: View {
    @ObservedObject var theme: ThemeManager
    let label: String
    let value: String
    var isPositive: Bool? = nil
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryText)
            
            Spacer()
            
            HStack(spacing: 4) {
                if let isPositive = isPositive {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(theme.tertiaryText)
                }
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPositive == true ? .green : theme.primaryText)
            }
        }
    }
}

// MARK: - Fear & Greed Card
struct FearGreedCard: View {
    let data: FearGreedData
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.cryptoMetric("Fear & Greed Index"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(data.value)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(colorForFearGreed(data.value))

                Text(localization.cryptoMetric(data.label))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorForFearGreed(data.value))
            }

            // Fear & Greed Scale
            VStack(spacing: 8) {
                // Scale bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background gradient
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.dangerColor)
                                .frame(width: geometry.size.width * 0.2)
                            Rectangle()
                                .fill(Color.warningColor)
                                .frame(width: geometry.size.width * 0.2)
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: geometry.size.width * 0.2)
                            Rectangle()
                                .fill(Color.successColor.opacity(0.7))
                                .frame(width: geometry.size.width * 0.2)
                            Rectangle()
                                .fill(Color.successColor)
                                .frame(width: geometry.size.width * 0.2)
                        }
                        .cornerRadius(4)

                        // Indicator (dark dot for light theme, white for dark)
                        Circle()
                            .fill(theme.theme == .dark ? Color.white : Color(white: 0.25))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                            .offset(x: geometry.size.width * CGFloat(data.value) / 100 - 7)
                    }
                }
                .frame(height: 8)

                // Labels
                HStack {
                    Text(localization.cryptoMetric("Extreme\nFear"))
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Text(localization.cryptoMetric("Fear"))
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                    Spacer()
                    Text(localization.cryptoMetric("Neutral"))
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                    Spacer()
                    Text(localization.cryptoMetric("Greed"))
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                    Spacer()
                    Text(localization.cryptoMetric("Extreme\nGreed"))
                        .font(.system(size: 10))
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
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

    // 공포탐욕지수에 따른 색깔
    private func colorForFearGreed(_ value: Int) -> Color {
        switch value {
        case 0...20:
            return .dangerColor  // 극도의 공포 (빨강)
        case 21...40:
            return .warningColor  // 공포 (주황)
        case 41...60:
            return .yellow  // 중립 (노랑)
        case 61...80:
            return .successColor.opacity(0.7)  // 탐욕 (연두)
        case 81...100:
            return .successColor  // 극도의 탐욕 (초록)
        default:
            return theme.primaryText
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let metric: CryptoMetric
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
                        .foregroundColor(theme.secondaryText)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.cryptoMetric(metric.title))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                
                Text(localization.cryptoMetric(metric.subtitle))
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // 값과 단위 분리 (예: "94762.48M BTC" → "94762.48M" + "BTC")
                let valueParts = metric.value.split(separator: " ", maxSplits: 1)
                let numberPart = String(valueParts.first ?? "")
                let unitPart = valueParts.count > 1 ? String(valueParts.last ?? "") : ""

                // 위: 숫자와 화살표
                HStack(spacing: 4) {
                    Text(numberPart)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primaryText)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(theme.tertiaryText)
                }

                // 아래: 단위와 변화율
                HStack(spacing: 8) {
                    if !unitPart.isEmpty {
                        Text(unitPart)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                    }

                    if let change = metric.change {
                        Text(change)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(colorForChangeValue(change, isPositive: metric.changeIsPositive ?? (change.contains("+") || change.contains("▲"))))
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

    private func colorForChangeValue(_ changeString: String, isPositive: Bool) -> Color {
        // changeString 예: "▲ +6.7%", "▼ -2.1%"
        let cleanValue = changeString
            .replacingOccurrences(of: "▲", with: "")
            .replacingOccurrences(of: "▼", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)

        if let percentage = Double(cleanValue) {
            let signedPercentage = isPositive ? percentage : -percentage
            return ColorUtility.colorForCryptoChange(signedPercentage)
        }

        return isPositive ? .successColor : .dangerColor
    }

    private func iconForMetric(_ title: String) -> String {
        switch title {
        case "New Addresses":
            return "doc.on.doc.fill"
        case "Open Interest":
            return "chart.line.uptrend.xyaxis"
        case "Long/Short Ratio":
            return "arrow.left.arrow.right"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - Bottom Tab Bar
struct BottomTabBar: View {
    @Binding var selectedTab: TabItem
    @ObservedObject var theme: ThemeManager
    var onAITap: (() -> Void)? = nil
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    if tab == .ai, let onAITap = onAITap {
                        onAITap()
                    } else {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconForTab(tab))
                            .font(.system(size: 20))
                            .foregroundColor(selectedTab == tab ? .green : theme.secondaryText)
                        
                        Text(localization.dashboard(tab.rawValue))
                            .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .green : theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 0)
        .background(
            Rectangle()
                .fill(theme.tabBarBackground)
        )
        .safeAreaPadding(.bottom) // Safe area 자동 처리
    }
    
    private func iconForTab(_ tab: TabItem) -> String {
        switch tab {
        case .crypto:
            return "target"
        case .macro:
            return "chart.bar.fill"
        case .ai:
            return "sparkles"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - Bitcoin Info Sheet
struct BitcoinInfoSheet: View {
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
                                Text("₿")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.orange)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.cryptoMetric("Bitcoin (BTC)"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is Bitcoin?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("Bitcoin is a decentralized digital currency that enables peer-to-peer transactions without the need for a central authority or intermediary. It was created in 2009 by an anonymous person or group using the pseudonym Satoshi Nakamoto."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Features"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "lock.shield.fill", title: localization.infoSheet("Decentralized"), description: localization.infoSheet("No central authority controls Bitcoin"))
                            InfoRow(icon: "network", title: localization.infoSheet("Peer-to-Peer"), description: localization.infoSheet("Direct transactions between users"))
                            InfoRow(icon: "eye.slash.fill", title: localization.infoSheet("Pseudonymous"), description: localization.infoSheet("Transactions are linked to addresses, not identities"))
                            InfoRow(icon: "infinity", title: localization.infoSheet("Limited Supply"), description: localization.infoSheet("Maximum of 21 million BTC will ever exist"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("Bitcoin uses blockchain technology, a distributed ledger that records all transactions. Miners validate transactions and add them to blocks, which are then added to the blockchain. This process ensures security and prevents double-spending."))
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

// MARK: - Fear & Greed Info Sheet
struct FearGreedInfoSheet: View {
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
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.cryptoMetric("Fear & Greed Index"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is the Fear & Greed Index?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("The Fear & Greed Index measures the emotions and sentiments of cryptocurrency investors. It ranges from 0 (Extreme Fear) to 100 (Extreme Greed) and helps identify when the market might be overbought or oversold."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Index Levels"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "exclamationmark.triangle.fill", title: localization.infoSheet("0-24: Extreme Fear"), description: localization.infoSheet("Investors are very worried, potential buying opportunity"))
                            InfoRow(icon: "exclamationmark.circle.fill", title: localization.infoSheet("25-44: Fear"), description: localization.infoSheet("Market sentiment is negative"))
                            InfoRow(icon: "minus.circle.fill", title: localization.infoSheet("45-55: Neutral"), description: localization.infoSheet("Balanced market sentiment"))
                            InfoRow(icon: "checkmark.circle.fill", title: localization.infoSheet("56-75: Greed"), description: localization.infoSheet("Investors are optimistic"))
                            InfoRow(icon: "flame.fill", title: localization.infoSheet("76-100: Extreme Greed"), description: localization.infoSheet("Market may be overbought, potential correction"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("The index combines multiple data sources including volatility, market momentum, social media sentiment, surveys, and Bitcoin dominance. When the index shows extreme fear, it might indicate a buying opportunity, while extreme greed could signal a potential market top."))
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

// MARK: - New Addresses Info Sheet
struct NewAddressesInfoSheet: View {
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
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.cryptoMetric("New Addresses"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What are New Addresses?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("New Addresses represents the number of unique Bitcoin addresses that received BTC for the first time in the last 24 hours. This metric helps gauge network growth and adoption."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "chart.line.uptrend.xyaxis", title: localization.infoSheet("Network Growth"), description: localization.infoSheet("Indicates increasing Bitcoin adoption"))
                            InfoRow(icon: "person.2.fill", title: localization.infoSheet("User Activity"), description: localization.infoSheet("Shows new participants entering the market"))
                            InfoRow(icon: "arrow.up.right.circle.fill", title: localization.infoSheet("Market Sentiment"), description: localization.infoSheet("High numbers suggest positive sentiment"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("When someone receives Bitcoin for the first time, a new address is created. Tracking these addresses helps measure the expansion of the Bitcoin network and can indicate growing interest in cryptocurrency. A rising number of new addresses typically suggests increased adoption and network growth."))
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

// MARK: - Open Interest Info Sheet
struct OpenInterestInfoSheet: View {
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
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.purple)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.cryptoMetric("Open Interest"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is Open Interest?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("Open Interest is the total number of outstanding derivative contracts (futures and options) that have not been settled. It's measured in BTC and represents the total value of active positions in the futures market."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "chart.bar.fill", title: localization.infoSheet("Market Activity"), description: localization.infoSheet("Shows total active positions in futures"))
                            InfoRow(icon: "waveform.path", title: localization.infoSheet("Liquidity Indicator"), description: localization.infoSheet("Higher OI suggests more market liquidity"))
                            InfoRow(icon: "exclamationmark.triangle.fill", title: localization.infoSheet("Price Volatility"), description: localization.infoSheet("Rapid changes can indicate market stress"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("Open Interest increases when new contracts are opened and decreases when contracts are closed or settled. It's a key metric for understanding market sentiment and potential price volatility in the derivatives market. High open interest can indicate strong market participation, while sudden decreases might signal position unwinding."))
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

// MARK: - Long/Short Ratio Info Sheet
struct LongShortRatioInfoSheet: View {
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
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.green)
                            )
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    // Title
                    Text(localization.cryptoMetric("Long/Short Ratio"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localization.infoSheet("What is Long/Short Ratio?"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(localization.infoSheet("Long/Short Ratio measures the proportion of traders holding long positions (betting on price increase) versus short positions (betting on price decrease) in the futures market."))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                        
                        Text(localization.infoSheet("Key Points"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "chart.bar.fill", title: localization.infoSheet("Market Sentiment"), description: localization.infoSheet("Shows trader expectations"))
                            InfoRow(icon: "arrow.up.circle.fill", title: localization.infoSheet("Ratio > 1.0"), description: localization.infoSheet("More longs than shorts (bullish)"))
                            InfoRow(icon: "arrow.down.circle.fill", title: localization.infoSheet("Ratio < 1.0"), description: localization.infoSheet("More shorts than longs (bearish)"))
                        }
                        
                        Text(localization.infoSheet("How It Works"))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        Text(localization.infoSheet("A ratio above 1.0 means more traders are betting on price increases (long positions) than decreases (short positions). This metric helps gauge market sentiment and can sometimes indicate potential price movements, though it's not a guarantee. Extreme ratios (very high or very low) can sometimes signal contrarian opportunities."))
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

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.orange)
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
    CryptoDashboardView()
        .environmentObject(ThemeManager.shared)
}


