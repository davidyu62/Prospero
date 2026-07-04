//
//  MacroDashboardData.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

struct MacroMetric: Identifiable {
    let title: String
    let subtitle: String
    let value: String
    let change: String? // optional change indicator
    let changeIsPositive: Bool?
    var rawValue: Double? = nil  // 값 연동 해석용 원시 수치 (nil이면 해석 표시 안 함)

    // 상세 시트 `.sheet(item:)` 식별용. 10개 지표 타이틀은 서로 겹치지 않음.
    var id: String { title }
}

struct MacroDashboardData {
    let interestRate: MacroMetric
    let treasury10y: MacroMetric
    let cpi: MacroMetric
    let m2: MacroMetric
    let unemployment: MacroMetric
    let dollarIndex: MacroMetric
    let vix: MacroMetric              // v3.0 신규
    let oilPrice: MacroMetric         // v3.0 신규
    let yieldSpread: MacroMetric      // v3.0 신규
    let breakEvenInflation: MacroMetric // v3.0 신규
    
    // 로드 전 초기 자리표시자(중립 빈값). 스켈레톤에 가려 화면엔 안 보이며, 가짜 샘플 수치를 쓰지 않는다.
    static let empty = MacroDashboardData(
        interestRate: MacroMetric(title: "Interest Rate", subtitle: "Federal Funds Rate", value: "—", change: nil, changeIsPositive: nil),
        treasury10y: MacroMetric(title: "10Y Treasury", subtitle: "Yield", value: "—", change: nil, changeIsPositive: nil),
        cpi: MacroMetric(title: "CPI", subtitle: "Consumer Price Index", value: "—", change: nil, changeIsPositive: nil),
        m2: MacroMetric(title: "M2 Money Supply", subtitle: "Billions USD", value: "—", change: nil, changeIsPositive: nil),
        unemployment: MacroMetric(title: "Unemployment", subtitle: "Rate", value: "—", change: nil, changeIsPositive: nil),
        dollarIndex: MacroMetric(title: "Dollar Index", subtitle: "DXY", value: "—", change: nil, changeIsPositive: nil),
        vix: MacroMetric(title: "VIX", subtitle: "Volatility Index", value: "—", change: nil, changeIsPositive: nil),
        oilPrice: MacroMetric(title: "Oil Price", subtitle: "WTI Crude (USD/Barrel)", value: "—", change: nil, changeIsPositive: nil),
        yieldSpread: MacroMetric(title: "Yield Spread", subtitle: "T10Y2Y", value: "—", change: nil, changeIsPositive: nil),
        breakEvenInflation: MacroMetric(title: "Break-Even Inflation", subtitle: "10Y BE", value: "—", change: nil, changeIsPositive: nil)
    )
}



