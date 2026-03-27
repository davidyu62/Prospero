//
//  MacroDashboardData.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

struct MacroMetric {
    let title: String
    let subtitle: String
    let value: String
    let change: String? // optional change indicator
    let changeIsPositive: Bool?
}

struct MacroDashboardData {
    let interestRate: MacroMetric
    let treasury10y: MacroMetric
    let cpi: MacroMetric
    let m2: MacroMetric
    let unemployment: MacroMetric
    let dollarIndex: MacroMetric
    
    // ⚠️ 임시 샘플 데이터 - API 호출 실패 시에만 사용됩니다
    static let sample = MacroDashboardData(
        interestRate: MacroMetric(
            title: "Interest Rate",
            subtitle: "Federal Funds Rate",
            value: "5.25%",
            change: "▲ +0.25%",
            changeIsPositive: true
        ),
        treasury10y: MacroMetric(
            title: "10Y Treasury",
            subtitle: "Yield",
            value: "4.25%",
            change: "▲ +0.10%",
            changeIsPositive: true
        ),
        cpi: MacroMetric(
            title: "CPI",
            subtitle: "Consumer Price Index",
            value: "3.26%",
            change: "▼ -0.1%",
            changeIsPositive: false
        ),
        m2: MacroMetric(
            title: "M2 Money Supply",
            subtitle: "Billions USD",
            value: "21,000",
            change: "▲ +100",
            changeIsPositive: true
        ),
        unemployment: MacroMetric(
            title: "Unemployment",
            subtitle: "Rate",
            value: "3.7%",
            change: "▼ -0.1%",
            changeIsPositive: false
        ),
        dollarIndex: MacroMetric(
            title: "Dollar Index",
            subtitle: "DXY",
            value: "106.7",
            change: "▲ +0.5",
            changeIsPositive: true
        )
    )
}



