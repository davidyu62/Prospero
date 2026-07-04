//
//  CryptoDashboardData.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

struct BitcoinData {
    let price: Double
    let change24h: Double // percentage
    let high24h: Double
    let low24h: Double
    let volume24h: Double // in billions
    let dominance: Double // percentage
    let updatedAt: String
}

struct FearGreedData {
    let value: Int
    let label: String // "Greed", "Fear", etc.
}

struct CryptoMetric: Identifiable {
    let title: String
    let subtitle: String
    let value: String
    let change: String? // optional change indicator
    let changeIsPositive: Bool?
    let barProgress: Double?  // 진행 바 진행률 (0.0~1.0), nil이면 표시 안 함
    var rawValue: Double? = nil  // 값 연동 해석용 원시 수치 (nil이면 해석 표시 안 함)

    // 상세 시트 `.sheet(item:)` 식별용. 5개 지표 타이틀은 서로 겹치지 않음.
    var id: String { title }
}

struct CryptoDashboardData {
    let bitcoin: BitcoinData
    let fearGreed: FearGreedData
    let openInterest: CryptoMetric
    let longShortRatio: CryptoMetric
    let mvrv: CryptoMetric
    let fundingRate: CryptoMetric      // v3.0 신규
    let activeAddresses: CryptoMetric  // v3.0 신규

    // 로드 전 초기 자리표시자(중립 빈값). 스켈레톤에 가려 화면엔 안 보이며, 가짜 샘플 수치를 쓰지 않는다.
    static let empty = CryptoDashboardData(
        bitcoin: BitcoinData(price: 0, change24h: 0, high24h: 0, low24h: 0, volume24h: 0, dominance: 0, updatedAt: ""),
        fearGreed: FearGreedData(value: 0, label: ""),
        openInterest: CryptoMetric(title: "Open Interest", subtitle: "Futures Market", value: "—", change: nil, changeIsPositive: nil, barProgress: nil),
        longShortRatio: CryptoMetric(title: "Long/Short Ratio", subtitle: "Market Sentiment", value: "—", change: nil, changeIsPositive: nil, barProgress: nil),
        mvrv: CryptoMetric(title: "MVRV", subtitle: "Market Value/Realized Value", value: "—", change: nil, changeIsPositive: nil, barProgress: nil),
        fundingRate: CryptoMetric(title: "Funding Rate", subtitle: "Futures Market", value: "—", change: nil, changeIsPositive: nil, barProgress: nil),
        activeAddresses: CryptoMetric(title: "Active Addresses", subtitle: "Network Activity", value: "—", change: nil, changeIsPositive: nil, barProgress: nil)
    )
}

enum TabItem: String, CaseIterable {
    case crypto = "Crypto"
    case macro = "Macro"
    case ai = "AI"
    case settings = "Settings"
}

