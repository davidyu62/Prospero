//
//  TrendChartView.swift
//  Prospero
//
//  지표의 과거 추세를 보여주는 라인 차트.
//  - .spark: 카드 내 인라인 미니 추세선 (축·범례 없음, 기울기 방향 색상)
//  - .full : 상세 시트용 전체 차트 (축·그리드·영역 그라데이션) — C3에서 확장
//  Swift Charts 사용 (iOS 16.2+).
//

import SwiftUI
import Charts

struct TrendChartView: View {
    enum Mode { case spark, full }

    /// 시계열 값 (오래된 → 최신 순)
    let values: [Double]
    /// 표시 모드
    var mode: Mode = .spark
    /// 강제 색상. nil이면 기울기 방향으로 자동 결정.
    var lineColor: Color? = nil
    /// 축 라벨 색상(.full 전용). 다크/라이트 대비 확보용. 미지정 시 기본 대비값.
    var axisColor: Color = Color.gray.opacity(0.9)
    /// 각 값에 대응하는 실제 날짜(values와 같은 개수, 오래된→최신). 지정 시 X축에 날짜 표기.
    var dates: [Date]? = nil
    /// X축 날짜 라벨 포맷(기본 "M/d"). 매크로 3개월 뷰는 월 단위("M월"/"MMM") 사용.
    var axisDateFormat: String = "M/d"
    /// Y축 범위 강제(예: 공포탐욕지수 0...100). nil이면 데이터로 자동 계산.
    var yDomainOverride: ClosedRange<Double>? = nil

    // 인덱스가 부여된 포인트
    private var points: [(index: Int, value: Double)] {
        values.enumerated().map { (index: $0.offset, value: $0.element) }
    }

    // X축에 날짜를 표기할 위치(인덱스). 양 끝 포함, 최대 4개 균등 배치.
    private var dateAxisIndices: [Int] {
        let n = values.count
        guard n > 1 else { return [0] }
        // 지점이 적으면(월별 등) 전부 표기, 많으면(일별) 4개로 균등 축약
        let marks = n <= 6 ? n : 4
        guard marks > 1 else { return [0] }
        let raw = (0..<marks).map { Int((Double($0) / Double(marks - 1) * Double(n - 1)).rounded()) }
        return Array(Set(raw)).sorted()
    }

    private func shortDate(_ i: Int) -> String {
        guard let dates, i >= 0, i < dates.count else { return "\(i)" }
        let f = DateFormatter()
        f.dateFormat = axisDateFormat
        f.locale = Locale(identifier: "en_US")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: dates[i])
    }

    // 기울기 방향(첫 값 대비 마지막 값)으로 라인 색상 결정
    private var trendColor: Color {
        if let lineColor { return lineColor }
        guard let first = values.first, let last = values.last else { return .gray }
        if last > first { return .successColor }
        if last < first { return .dangerColor }
        return Color.gray.opacity(0.7)
    }

    // 보기 좋은 Y축 범위 (위아래 패딩, 상수 데이터 보호)
    private var yBounds: ClosedRange<Double> {
        if let yDomainOverride { return yDomainOverride }
        guard let lo = values.min(), let hi = values.max() else { return 0...1 }
        if lo == hi {
            let pad = abs(lo) * 0.1 + 1
            return (lo - pad)...(hi + pad)
        }
        let pad = (hi - lo) * 0.15
        return (lo - pad)...(hi + pad)
    }

    var body: some View {
        if values.count < 2 {
            // 데이터 부족 시 레이아웃 높이만 유지
            Color.clear.frame(height: mode == .spark ? 32 : 200)
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points, id: \.index) { p in
                LineMark(
                    x: .value("Day", p.index),
                    y: .value("Value", p.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(trendColor)
                .lineStyle(StrokeStyle(lineWidth: mode == .spark ? 1.5 : 2, lineCap: .round))
            }

            // 마지막 점 강조
            if let last = points.last {
                PointMark(
                    x: .value("Day", last.index),
                    y: .value("Value", last.value)
                )
                .foregroundStyle(trendColor)
                .symbolSize(mode == .spark ? 18 : 40)
            }
        }
        .chartYScale(domain: yBounds)
        .chartXAxis {
            if mode == .full {
                if dates != nil {
                    // 실제 날짜 라벨(양 끝 + 중간, 최대 4개)
                    AxisMarks(values: dateAxisIndices) { value in
                        AxisGridLine().foregroundStyle(axisColor.opacity(0.25))
                        AxisTick().foregroundStyle(axisColor.opacity(0.5))
                        AxisValueLabel {
                            if let i = value.as(Int.self) {
                                Text(shortDate(i))
                                    .foregroundStyle(axisColor)
                                    .font(.system(size: 11, weight: .medium))
                            }
                        }
                    }
                } else {
                    AxisMarks {
                        AxisGridLine().foregroundStyle(axisColor.opacity(0.25))
                        AxisTick().foregroundStyle(axisColor.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(axisColor)
                            .font(.system(size: 11, weight: .medium))
                    }
                }
            }
        }
        .chartYAxis {
            if mode == .full {
                AxisMarks {
                    AxisGridLine().foregroundStyle(axisColor.opacity(0.25))
                    AxisTick().foregroundStyle(axisColor.opacity(0.5))
                    AxisValueLabel()
                        .foregroundStyle(axisColor)
                        .font(.system(size: 11, weight: .medium))
                }
            }
        }
        .frame(height: mode == .spark ? 32 : 200)
    }
}

/// 데이터 로드 전 표시하는 고정 크기 스켈레톤 카드 목록.
/// 샘플 데이터 대신 이걸 보여줘 값 깜빡임·카드 리사이즈를 방지한다.
struct DashboardLoadingPlaceholder: View {
    @ObservedObject var theme: ThemeManager
    let cardHeights: [CGFloat]
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(cardHeights.enumerated()), id: \.offset) { _, h in
                RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                    .fill(theme.cardBackground)
                    .frame(height: h)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.buttonCornerRadius)
                            .stroke(theme.cardBorderColor, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 20)
        .opacity(pulse ? 0.45 : 0.85)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
