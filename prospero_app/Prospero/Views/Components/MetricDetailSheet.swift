//
//  MetricDetailSheet.swift
//  Prospero
//
//  지표 카드 탭 시 뜨는 통합 상세 시트.
//  [차트 | 설명] 세그먼트로 30일 추세 차트와 지표 설명을 한 곳에 모은다.
//  - 차트: TrendChartView(.full) + 7/30일 토글 + 최저·평균·최고 요약
//  - 설명: IndicatorMetadata.json 정의 + 방향(상승/하락)별 동적 해석
//  기존 개별 InfoSheet(크립토·매크로)를 대체한다.
//

import SwiftUI

/// 상세 시트가 필요로 하는 지표 최소 인터페이스. CryptoMetric·MacroMetric 공용.
protocol DetailableMetric: Identifiable {
    var title: String { get }
    var subtitle: String { get }
    var value: String { get }
    var rawValue: Double? { get }
    var changeIsPositive: Bool? { get }
}

extension CryptoMetric: DetailableMetric {}
extension MacroMetric: DetailableMetric {}

struct MetricDetailSheet: View {
    let metric: any DetailableMetric
    let history: [Double]?          // 30일 실데이터(없으면 스텁)
    var isMacro: Bool = false       // 지표명 로컬라이즈 도메인(크립토/매크로) 구분
    var endDate: Date? = nil        // 히스토리 마지막 지점의 실제 날짜(X축 날짜 표기용)
    var historyDates: [Date]? = nil // 실데이터 각 지점의 실제 날짜(values와 정렬). 매크로 월별 등 비연속 지점용.
    @ObservedObject var theme: ThemeManager

    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "ENG"

    // 도메인별 지표명/부제 로컬라이즈
    private var displayName: String {
        isMacro ? localization.macroMetric(metric.title) : localization.cryptoMetric(metric.title)
    }
    private var displaySubtitle: String {
        isMacro ? localization.macroMetric(metric.subtitle) : localization.cryptoMetric(metric.subtitle)
    }

    @State private var segment: Segment = .chart
    @State private var range: RangeOption = .month

    enum Segment: Hashable { case chart, explanation }
    enum RangeOption: Int, CaseIterable { case week = 7, month = 30 }

    private var kor: Bool { selectedLanguage == "KOR" }
    private var localization: Localization {
        Localization.shared.language = selectedLanguage
        return Localization.shared
    }

    private var key: IndicatorInterpreter.Key? {
        IndicatorInterpreter.key(forTitle: metric.title)
    }

    // 실데이터 사용 여부(2점 이상이면 실데이터)
    private var usingRealData: Bool { (history?.count ?? 0) >= 2 }

    // 매크로는 최근 6개월 월별(6개 지점), 크립토는 30일 뷰. (스텁 폴백 시 생성 지점 수)
    private var historyDays: Int { isMacro ? 6 : 30 }

    // 전체 히스토리. 실데이터 우선, 없으면 스텁. (크립토) 7일 뷰는 뒤에서 7개를 잘라 씀.
    private var fullHistory: [Double]? {
        if let history, history.count >= 2 { return history }
        guard let key, let raw = metric.rawValue else { return nil }
        return CryptoHistoryProvider.history(for: key, current: raw, days: historyDays)
    }
    private var shownHistory: [Double] {
        guard let h = fullHistory else { return [] }
        if isMacro { return h }  // 매크로는 3개월 전체(토글 없음)
        return range == .week ? Array(h.suffix(7)) : h
    }

    // X축 날짜 라벨 포맷 — 매크로는 월 단위, 크립토는 월/일
    private var axisDateFormat: String { isMacro ? (kor ? "M월" : "MMM") : "M/d" }

    // X축 실제 날짜. 실데이터면 응답의 실제 날짜(매크로=월별 6개), 스텁이면 endDate에서 파생.
    private var shownDates: [Date]? {
        // 실데이터: 응답 날짜 배열 사용(values와 정렬)
        if usingRealData, let hd = historyDates, hd.count == (history?.count ?? -1), hd.count >= 2 {
            if isMacro { return hd }
            return range == .week ? Array(hd.suffix(7)) : hd
        }
        // 스텁 폴백
        guard let end = endDate else { return nil }
        let n = shownHistory.count
        guard n >= 2 else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        if isMacro {
            // 각 달 1일 (오래된→최신)
            let comps = cal.dateComponents([.year, .month], from: end)
            let firstOfThisMonth = cal.date(from: comps) ?? end
            return (0..<n).map { k in
                cal.date(byAdding: .month, value: -(n - 1 - k), to: firstOfThisMonth) ?? firstOfThisMonth
            }
        }
        return (0..<n).map { i in cal.date(byAdding: .day, value: -(n - 1 - i), to: end) ?? end }
    }

    // 공포탐욕지수는 Y축 0~100 고정
    private var yDomainOverride: ClosedRange<Double>? {
        key == .fearGreed ? 0...100 : nil
    }

    private func interpretation(_ trend: TrendDirection) -> IndicatorInterpretation? {
        guard let key, let raw = metric.rawValue else { return nil }
        return IndicatorInterpreter.interpret(key, value: raw, trend: trend, language: selectedLanguage)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    Picker("", selection: $segment) {
                        Text(kor ? "차트" : "Chart").tag(Segment.chart)
                        Text(kor ? "설명" : "About").tag(Segment.explanation)
                    }
                    .pickerStyle(.segmented)

                    if segment == .chart {
                        chartSection
                    } else {
                        explanationSection
                    }
                }
                .padding(20)
            }
            .background(theme.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.common("Done")) { dismiss() }
                        .foregroundColor(.accentColor)
                }
            }
        }
        // 세그먼트 피커 등 시스템 컨트롤은 기기의 colorScheme을 따라 그려지는데,
        // 앱은 ThemeManager로 다크/라이트를 자체 관리하므로 기기 설정과 앱 테마가
        // 어긋나면(예: 기기 다크 + 앱 라이트) 세그먼트 선택 텍스트 대비가 나빠진다.
        // 시트 전체에 앱 테마를 강제해 시스템 컨트롤도 앱 테마 외형으로 그려지게 한다.
        .preferredColorScheme(theme.theme == .dark ? .dark : .light)
    }

    // MARK: - 헤더 (이름 · 현재값 · 1줄 해석)

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(theme.cardIconBackground)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    Text(displaySubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                Text(metric.value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.primaryText)
            }
        }
    }

    // MARK: - 차트 탭

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 7일 / 30일 토글 (매크로는 6개월 월 단위 고정이라 토글 숨김)
            if !isMacro {
                Picker("", selection: $range) {
                    Text(kor ? "7일" : "7D").tag(RangeOption.week)
                    Text(kor ? "30일" : "30D").tag(RangeOption.month)
                }
                .pickerStyle(.segmented)
            } else {
                HStack {
                    Text(kor ? "최근 6개월" : "Last 6 Months")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.secondaryText)
                    Spacer()
                }
            }

            if chartSeries.values.count >= 2 {
                TrendChartView(values: chartSeries.values, mode: .full, axisColor: theme.primaryText.opacity(0.85), dates: chartSeries.dates, axisDateFormat: axisDateFormat, yDomainOverride: yDomainOverride)

                if let s = stats {
                    HStack(spacing: 0) {
                        statCell(kor ? "최저" : "Low", s.min)
                        divider
                        statCell(kor ? "평균" : "Avg", s.avg)
                        divider
                        statCell(kor ? "최고" : "High", s.max)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                            .fill(theme.cardBackground)
                    )
                }

                if !usingRealData {
                    Text(kor ? "* 추세 데이터는 준비 중이며 현재는 예시 값입니다." : "* Trend data is a placeholder for now.")
                        .font(.system(size: 11))
                        .foregroundColor(theme.tertiaryText)
                }
            } else {
                Text(kor ? "추세 데이터를 불러올 수 없습니다." : "Trend data unavailable.")
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
    }

    // 차트에 실제로 그릴 (값, 날짜). 매크로는 결측(0)을 제거해 값이 있는 달만 표시.
    private var chartSeries: (values: [Double], dates: [Date]?) {
        let vals = shownHistory
        let ds = shownDates
        guard isMacro else { return (vals, ds) }
        guard let ds = ds, ds.count == vals.count else {
            let filtered = vals.filter { $0 != 0 }
            return filtered.count >= 2 ? (filtered, nil) : (vals, ds)
        }
        var fv: [Double] = []
        var fd: [Date] = []
        for (v, d) in zip(vals, ds) where v != 0 {
            fv.append(v)
            fd.append(d)
        }
        return fv.count >= 2 ? (fv, fd) : (vals, ds)  // 다 걸러지면 원본 유지
    }

    private var stats: (min: Double, avg: Double, max: Double)? {
        let h = chartSeries.values
        guard !h.isEmpty else { return nil }
        return (h.min()!, h.reduce(0, +) / Double(h.count), h.max()!)
    }

    private func statCell(_ label: String, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.secondaryText)
            Text(formatNumber(value))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.primaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 0.5, height: 28)
    }

    // MARK: - 설명 탭

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            let metadataId = key?.metadataId ?? ""
            let definition = IndicatorManager.shared.getExplanation(metadataId, language: selectedLanguage)

            if !definition.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(kor ? "정의" : "Definition")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                    Text(definition)
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                        .lineSpacing(4)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(kor ? "방향의 의미" : "What direction means")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                if let up = interpretation(.up) {
                    directionRow(symbol: "↗", label: kor ? "상승·증가 시" : "When rising", interp: up)
                }
                if let down = interpretation(.down) {
                    directionRow(symbol: "↘", label: kor ? "하락·감소 시" : "When falling", interp: down)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func directionRow(symbol: String, label: String, interp: IndicatorInterpretation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(interp.sentiment.color)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.primaryText)
                Text(interp.text)
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                .fill(theme.cardBackground)
        )
    }

    // MARK: - 헬퍼

    // 지표별 아이콘 (MetricCard와 동일 규칙)
    private var iconName: String {
        switch metric.title {
        case "Open Interest":     return "chart.line.uptrend.xyaxis"
        case "Long/Short Ratio":  return "arrow.left.arrow.right"
        case "MVRV":              return "chart.bar.fill"
        case "Funding Rate":      return "percent"
        case "Active Addresses":  return "network"
        case "Bitcoin (BTC)":     return "bitcoinsign.circle.fill"
        case "Fear & Greed Index":return "gauge.with.needle"
        // 매크로
        case "Interest Rate":     return "percent"
        case "10Y Treasury":      return "chart.line.uptrend.xyaxis"
        case "CPI":               return "chart.bar.fill"
        case "M2 Money Supply":   return "dollarsign.circle.fill"
        case "Unemployment":      return "person.2.fill"
        case "Dollar Index":      return "dollarsign.square.fill"
        case "VIX":               return "bolt.fill"
        case "Oil Price":         return "drop.fill"
        case "Yield Spread":      return "arrow.up.arrow.down"
        case "Break-Even Inflation": return "chart.line.downtrend.xyaxis"
        default:                  return "chart.xyaxis.line"
        }
    }

    // 단위가 제각각이라 크기에 맞춰 간결하게 표기
    private func formatNumber(_ v: Double) -> String {
        let a = abs(v)
        if a >= 1_000_000 { return String(format: "%.2fM", v / 1_000_000) }
        if a >= 1_000 { return String(format: "%.1fK", v / 1_000) }
        if a >= 10 { return String(format: "%.1f", v) }
        if a >= 1 { return String(format: "%.2f", v) }
        return String(format: "%.4f", v)
    }
}
