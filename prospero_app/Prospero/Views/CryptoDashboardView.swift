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
    @State private var dashboardData = CryptoDashboardData.empty
    @State private var selectedTab: TabItem = .crypto
    @State private var isLoading = false
    @State private var isDataLoaded = false               // 첫 실데이터 로드 완료 여부(로드 전 스켈레톤 표시)
    @State private var errorMessage: String?
    @State private var selectedMetric: CryptoMetric?      // 모든 지표 카드 → 통합 상세 시트
    @State private var histories: [String: [Double]] = [:] // 지표 key.rawValue → 30일 실데이터(없으면 스텁 폴백)
    @State private var historyEndDate: Date? = nil          // 30일 히스토리 마지막 날짜(X축 날짜 표기용)
    @State private var historyDates: [Date] = []            // 30일 실제 날짜(오래된→최신, X축용)
    @State private var updatedTime: String = ""
    @State private var showAdNotReadyAlert = false
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    // Bitcoin·공포탐욕 카드를 통합 상세 시트(MetricDetailSheet)에 태우기 위한 래퍼.
    // 타이틀은 IndicatorInterpreter.key(forTitle:) 매핑과 일치해야 한다.
    private var bitcoinMetric: CryptoMetric {
        let b = dashboardData.bitcoin
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        let priceStr = f.string(from: NSNumber(value: b.price)) ?? "\(b.price)"
        return CryptoMetric(
            title: "Bitcoin (BTC)",
            subtitle: "Price",
            value: "$\(priceStr)",
            change: nil,
            changeIsPositive: b.change24h >= 0,
            barProgress: nil,
            rawValue: b.price
        )
    }

    private var fearGreedMetric: CryptoMetric {
        let fg = dashboardData.fearGreed
        return CryptoMetric(
            title: "Fear & Greed Index",
            subtitle: "Market Sentiment",
            value: "\(fg.value)",
            change: nil,
            changeIsPositive: nil,
            barProgress: nil,
            rawValue: Double(fg.value)
        )
    }

    // 지표 카드의 30일 실데이터 조회(없으면 nil → 카드가 스텁으로 폴백)
    private func history(for metric: CryptoMetric) -> [Double]? {
        guard let key = IndicatorInterpreter.key(forTitle: metric.title) else { return nil }
        return histories[key.rawValue]
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

                                if isDataLoaded {
                                    // Bitcoin Card
                                    BitcoinCard(data: dashboardData.bitcoin, fearGreed: dashboardData.fearGreed, history: histories["btcPrice"], theme: theme)
                                        .padding(.horizontal, 20)
                                        .onTapGesture {
                                            selectedMetric = bitcoinMetric
                                        }

                                    // Fear & Greed Index Card
                                    FearGreedCard(data: dashboardData.fearGreed, history: histories["fearGreed"], theme: theme)
                                        .padding(.horizontal, 20)
                                        .onTapGesture {
                                            selectedMetric = fearGreedMetric
                                        }

                                    // Small Metric Cards
                                    VStack(spacing: 12) {
                                        MetricCard(metric: dashboardData.openInterest, history: history(for: dashboardData.openInterest), theme: theme)
                                            .onTapGesture {
                                                selectedMetric = dashboardData.openInterest
                                            }
                                        MetricCard(metric: dashboardData.longShortRatio, history: history(for: dashboardData.longShortRatio), theme: theme)
                                            .onTapGesture {
                                                selectedMetric = dashboardData.longShortRatio
                                            }
                                        MetricCard(metric: dashboardData.mvrv, history: history(for: dashboardData.mvrv), theme: theme)
                                            .onTapGesture {
                                                selectedMetric = dashboardData.mvrv
                                            }
                                        MetricCard(metric: dashboardData.fundingRate, history: history(for: dashboardData.fundingRate), theme: theme)
                                            .onTapGesture {
                                                selectedMetric = dashboardData.fundingRate
                                            }
                                        MetricCard(metric: dashboardData.activeAddresses, history: history(for: dashboardData.activeAddresses), theme: theme)
                                            .onTapGesture {
                                                selectedMetric = dashboardData.activeAddresses
                                            }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 24) // 마지막 카드와 탭바 사이 최소 여백
                                } else if let error = errorMessage {
                                    Text("Error: \(error)")
                                        .foregroundColor(.red)
                                        .padding()
                                } else {
                                    // 로드 전: 샘플 대신 고정 크기 스켈레톤(깜빡임·리사이즈 방지)
                                    DashboardLoadingPlaceholder(theme: theme, cardHeights: [150, 132, 96, 96, 96, 96, 96])
                                        .padding(.top, 8)
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
                
                // Bottom Tab Bar (화면 하단에 고정)
                BottomTabBar(selectedTab: $selectedTab, theme: theme, onAITap: {
                    // 광고 노출/전환 시간 동안 AI 데이터를 미리 로드해 진입 시 즉시 표시
                    AIView.prefetchIntoCache()
                    // 마지막 광고 노출 후 2시간이 지났으면 리워드 광고 표시, 아니면 바로 진입
                    if RewardedAdManager.shared.shouldShowAd() {
                        RewardedAdManager.shared.showAd(
                            onFinish: { selectedTab = .ai },
                            onAdNotReady: { selectedTab = .ai }
                        )
                    } else {
                        selectedTab = .ai
                    }
                })
            }
        }
        .task {
            // 초기 시간 설정
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            updatedTime = timeFormatter.string(from: Date())
            // 앱 시작 시 Crypto 탭이 기본 선택되므로 Crypto 데이터만 로드(세션 내 1회)
            if selectedTab == .crypto && !isDataLoaded {
                await loadCryptoData()
            }
        }
        .onChange(of: selectedTab) { newTab in
            // 탭 재진입 시엔 이미 로드된 데이터를 그대로 유지(재로딩·값 변동 방지). 최초 1회만 로드.
            Task {
                if newTab == .crypto && !isDataLoaded {
                    await loadCryptoData()
                }
            }
        }
        .sheet(item: $selectedMetric) { metric in
            MetricDetailSheet(metric: metric, history: history(for: metric), endDate: historyEndDate, historyDates: historyDates.isEmpty ? nil : historyDates, theme: theme)
        }
        .alert(localization.common("Ad Not Ready"), isPresented: $showAdNotReadyAlert) {
            Button(localization.common("OK"), role: .cancel) {}
        } message: {
            Text(localization.common("Ad Loading Message"))
        }
    }
    
    // 30일 범위 데이터를 받아 지표 key별 배열로 저장한다. 실패하면 비워 카드가 스텁으로 폴백.
    private func loadHistory(endDate: String) async {
        // 실패(스텁 폴백) 시에도 X축 날짜가 나오도록 요청 종료일을 먼저 설정
        let fmt0 = DateFormatter()
        fmt0.dateFormat = "yyyyMMdd"
        fmt0.timeZone = TimeZone(identifier: "UTC")
        historyEndDate = fmt0.date(from: endDate)
        do {
            let r = try await CryptoAPIService.shared.fetchCryptoRange(date: endDate, days: 30)
            var h: [String: [Double]] = [:]
            func put(_ key: IndicatorInterpreter.Key, _ arr: [Double]) {
                if arr.count >= 2 { h[key.rawValue] = arr }  // 최소 2점 이상만 사용
            }
            put(.btcPrice, r.btcPrices)
            put(.fearGreed, r.fearGreedIndices)
            put(.openInterest, r.openInterests)
            put(.longShortRatio, r.longShortRatios)
            put(.mvrv, r.mvrvs)
            put(.fundingRate, r.fundingRates.map { $0 * 100 })  // 카드 rawValue와 동일한 퍼센트 단위
            put(.activeAddresses, r.activeAddresses)
            histories = h
            // X축 날짜 표기용 실제 날짜 배열 + 종료일
            historyDates = r.dates.compactMap { fmt0.date(from: $0) }
            if let last = historyDates.last { historyEndDate = last }
            print("✅ 30일 범위 데이터 로드 완료 - \(r.dates.count)일")
        } catch {
            print("⚠️ 30일 범위 데이터 로드 실패 → 스텁 폴백: \(error)")
            histories = [:]
            historyDates = []
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
                let mvrvValue = data.mvrv ?? 1.0
                let fundingRateValue = data.fundingRate ?? -0.015  // v3.0 신규
                let fundingRateChange = (previousData?.fundingRate ?? -0.015) - fundingRateValue  // v3.0 신규
                let activeAddressesValue = data.activeAddresses ?? 750000  // v3.0 신규
                let activeAddressesChange = calculatePercentageChange(
                    current: Double(data.activeAddresses ?? 750000),
                    previous: Double(previousData?.activeAddresses ?? 750000)
                )  // v3.0 신규

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
                        changeIsPositive: openInterestChange >= 0,
                        barProgress: min(max(openInterestValue / 150000.0, 0.0), 1.0),
                        rawValue: openInterestValue
                    ),
                    longShortRatio: CryptoMetric(
                        title: "Long/Short Ratio",
                        subtitle: "Market Sentiment",
                        value: String(format: "%.2f", longShortRatioValue),
                        change: formatChange(longShortRatioChange),
                        changeIsPositive: longShortRatioChange >= 0,
                        barProgress: longShortRatioValue / (1.0 + longShortRatioValue),
                        rawValue: longShortRatioValue
                    ),
                    mvrv: CryptoMetric(
                        title: "MVRV",
                        subtitle: "Market Value/Realized Value",
                        value: String(format: "%.4f", mvrvValue),
                        change: nil,
                        changeIsPositive: nil,
                        barProgress: min(max((mvrvValue - 0.5) / 2.0, 0.0), 1.0),
                        rawValue: mvrvValue
                    ),
                    fundingRate: CryptoMetric(
                        title: "Funding Rate",
                        subtitle: "Futures Market",
                        value: String(format: "%.4f%%", fundingRateValue * 100),
                        change: fundingRateChange != 0 ? String(format: "%+.4f%%", fundingRateChange * 100) : nil,
                        changeIsPositive: fundingRateChange < 0,
                        barProgress: nil,
                        rawValue: fundingRateValue * 100
                    ),
                    activeAddresses: CryptoMetric(
                        title: "Active Addresses",
                        subtitle: "Network Activity",
                        value: formatNumber(Int64(activeAddressesValue)),
                        change: formatChange(activeAddressesChange),
                        changeIsPositive: activeAddressesChange >= 0,
                        barProgress: nil,
                        rawValue: Double(activeAddressesValue)
                    )
                )
                print("✅ 데이터 업데이트 완료 - \(displayDate)")
                isDataLoaded = true   // 실데이터 표시 시작(스켈레톤 종료)

                // 30일 추세 실데이터 로드(실패 시 스텁 폴백)
                await loadHistory(endDate: displayDate)
            } else {
                print("⚠️ requestDate·previousDate 모두 nil. 데이터 없음.")
                updatedTime = ""
                dashboardData = CryptoDashboardData(
                    bitcoin: BitcoinData(price: 0.0, change24h: 0.0, high24h: 0.0, low24h: 0.0, volume24h: 0.0, dominance: 0.0, updatedAt: ""),
                    fearGreed: FearGreedData(value: 0, label: "No data"),
                    openInterest: CryptoMetric(title: "Open Interest", subtitle: "Futures Market", value: "0.00M BTC", change: nil, changeIsPositive: nil, barProgress: nil),
                    longShortRatio: CryptoMetric(
                        title: "Long/Short Ratio",
                        subtitle: "Market Sentiment",
                        value: "0.00",
                        change: nil,
                        changeIsPositive: nil,
                        barProgress: nil
                    ),
                    mvrv: CryptoMetric(
                        title: "MVRV",
                        subtitle: "Market Value/Realized Value",
                        value: "0.0000",
                        change: nil,
                        changeIsPositive: nil,
                        barProgress: nil
                    ),
                    fundingRate: CryptoMetric(title: "Funding Rate", subtitle: "Futures Market", value: "0.0000%", change: nil, changeIsPositive: nil, barProgress: nil),
                    activeAddresses: CryptoMetric(title: "Active Addresses", subtitle: "Network Activity", value: "0", change: nil, changeIsPositive: nil, barProgress: nil)
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
                    changeIsPositive: nil,
                    barProgress: nil
                ),
                longShortRatio: CryptoMetric(
                    title: "Long/Short Ratio",
                    subtitle: "Market Sentiment",
                    value: "0.00",
                    change: nil,
                    changeIsPositive: nil,
                    barProgress: nil
                ),
                mvrv: CryptoMetric(
                    title: "MVRV",
                    subtitle: "Market Value/Realized Value",
                    value: "0.0000",
                    change: nil,
                    changeIsPositive: nil,
                    barProgress: nil
                ),
                fundingRate: CryptoMetric(title: "Funding Rate", subtitle: "Futures Market", value: "0.0000%", change: nil, changeIsPositive: nil, barProgress: nil),
                activeAddresses: CryptoMetric(title: "Active Addresses", subtitle: "Network Activity", value: "0", change: nil, changeIsPositive: nil, barProgress: nil)
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
    let fearGreed: FearGreedData?
    var history: [Double]? = nil   // 30일 가격 실데이터(없으면 스텁)
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    // 실데이터 우선, 없으면 스텁
    private var priceHistory: [Double] {
        if let history, history.count >= 2 { return history }
        return CryptoHistoryProvider.history(for: .btcPrice, current: data.price, days: 30)
    }

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

            // Price & Fear Greed Badge
            VStack(alignment: .leading, spacing: 8) {
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

                // 30일 가격 추세 스파크라인 (실데이터 우선, 없으면 스텁)
                TrendChartView(values: priceHistory, mode: .spark)
                    .padding(.top, 4)

                // 공포탐욕 지수 미니 배지
                if let fearGreed = fearGreed {
                    let badgeColor = fearGreedColor(fearGreed.value)
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(badgeColor)
                                .frame(width: 6, height: 6)
                            Text("\(fearGreed.value) \(fearGreed.label)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(badgeColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(badgeColor.opacity(0.15))
                        )
                    }
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

    private func fearGreedColor(_ value: Int) -> Color {
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
    var history: [Double]? = nil   // 30일 지수 실데이터(없으면 스텁)
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    // 실데이터 우선, 없으면 스텁
    private var indexHistory: [Double] {
        if let history, history.count >= 2 { return history }
        return CryptoHistoryProvider.history(for: .fearGreed, current: Double(data.value), days: 30)
    }
    
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

            // 30일 추세 스파크라인 (실데이터 우선, 없으면 스텁)
            TrendChartView(values: indexHistory, mode: .spark)

            // 값 연동 1줄 해석
            let interp = IndicatorInterpreter.interpret(.fearGreed, value: Double(data.value), trend: .flat, language: selectedLanguage)
            HStack(spacing: 6) {
                Text(interp.sentiment.symbol)
                    .font(.system(size: 12, weight: .bold))
                Text(interp.text)
                    .font(.system(size: 11.5, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundColor(interp.sentiment.color)
            .padding(.top, 2)
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
    var history: [Double]? = nil   // 30일 실데이터(없으면 스텁)
    @ObservedObject var theme: ThemeManager
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"
    
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
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
                            .foregroundColor(colorForMetricIcon(metric.title, metric.change, metric.changeIsPositive, metric.barProgress))
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

            // 30일 추세 스파크라인 (매핑된 지표) — 없으면 기존 진행 바
            if let spark = sparkline {
                TrendChartView(values: spark, mode: .spark)
            } else if let barProgress = metric.barProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 배경 바
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.08))

                        // 진행 바
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForBarProgress(metric.title, barProgress))
                            .frame(width: geometry.size.width * barProgress)
                    }
                }
                .frame(height: 3)
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

    // 값 연동 해석 (rawValue + 전일 대비 추세 기반). 매핑 없는 지표는 nil → 표시 안 함.
    private var interpretation: IndicatorInterpretation? {
        guard let key = IndicatorInterpreter.key(forTitle: metric.title),
              let raw = metric.rawValue else { return nil }
        let trend: TrendDirection = metric.changeIsPositive == nil
            ? .flat
            : (metric.changeIsPositive! ? .up : .down)
        return IndicatorInterpreter.interpret(key, value: raw, trend: trend, language: selectedLanguage)
    }

    // 30일 추세 스파크라인 데이터. 실데이터(history) 우선, 없으면 스텁 폴백.
    private var sparkline: [Double]? {
        guard let key = IndicatorInterpreter.key(forTitle: metric.title),
              let raw = metric.rawValue else { return nil }
        if let history, history.count >= 2 { return history }
        return CryptoHistoryProvider.history(for: key, current: raw, days: 30)
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
        case "Open Interest":
            return "chart.line.uptrend.xyaxis"
        case "Long/Short Ratio":
            return "arrow.left.arrow.right"
        case "MVRV":
            return "chart.bar.fill"
        case "Funding Rate":
            return "percent"
        case "Active Addresses":
            return "network"
        default:
            return "circle.fill"
        }
    }

    private func colorForMetricIcon(_ title: String, _ change: String?, _ changeIsPositive: Bool?, _ barProgress: Double?) -> Color {
        switch title {
        case "Open Interest":
            if let progress = barProgress {
                return progress >= 0.5 ? .successColor : .warningColor
            }
            return .blue
        case "Long/Short Ratio":
            if let progress = barProgress {
                return progress >= 0.5 ? .successColor : .dangerColor
            }
            return .blue
        case "MVRV":
            if let progress = barProgress {
                return progress >= 0.5 ? .successColor : .warningColor
            }
            return .blue
        case "Funding Rate":
            // 펀딩비: 음수(숏 우위) = 좋음 = 초록색
            if let change = change {
                let isNegative = change.contains("▼") || change.contains("-")
                return isNegative ? .successColor : .dangerColor
            }
            return .blue
        case "Active Addresses":
            // 활성주소: 상승 = 좋음
            if let isPositive = changeIsPositive {
                return isPositive ? .successColor : .warningColor
            }
            return .blue
        default:
            return .blue
        }
    }

    private func colorForBarProgress(_ title: String, _ progress: Double) -> Color {
        switch title {
        case "Open Interest":
            // Open Interest: 상승/하락 표시 (0.5 기준)
            return progress >= 0.5 ? .successColor : .warningColor
        case "Long/Short Ratio":
            // Long/Short Ratio: 롱/숏 분포 표시 (0.5 기준)
            return progress >= 0.5 ? .successColor : .dangerColor
        default:
            return .blue
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
                    VStack(spacing: 6) {
                        Image(systemName: iconForTab(tab))
                            .font(.system(size: 21))
                            .foregroundColor(selectedTab == tab ? .green : theme.secondaryText)

                        Text(localization.dashboard(tab.rawValue))
                            .font(.system(size: 13.5, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .green : theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8.4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16.8)
        .padding(.bottom, 0)
        .background(
            Rectangle()
                .fill(theme.tabBarBackground)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
        }
        .ignoresSafeArea(edges: .bottom)
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

