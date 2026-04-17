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

struct CryptoMetric {
    let title: String
    let subtitle: String
    let value: String
    let change: String? // optional change indicator
    let changeIsPositive: Bool?
    let barProgress: Double?  // 진행 바 진행률 (0.0~1.0), nil이면 표시 안 함
}

struct CryptoDashboardData {
    let bitcoin: BitcoinData
    let fearGreed: FearGreedData
    let openInterest: CryptoMetric
    let longShortRatio: CryptoMetric
    let mvrv: CryptoMetric

    // ⚠️ 임시 샘플 데이터 - API 호출 실패 시에만 사용됩니다
    static let sample = CryptoDashboardData(
        bitcoin: BitcoinData(
            price: 42350.67,
            change24h: 2.58,
            high24h: 42800.23,
            low24h: 41350.91,
            volume24h: 23.5,
            dominance: 52.4,
            updatedAt: "Updated Just now • Live"
        ),
        fearGreed: FearGreedData(
            value: 72,
            label: "Greed"
        ),
        openInterest: CryptoMetric(
            title: "Open Interest",
            subtitle: "Futures Market",
            value: "4.5M BTC",
            change: "▲ +6.7%",
            changeIsPositive: true,
            barProgress: 0.45
        ),
        longShortRatio: CryptoMetric(
            title: "Long/Short Ratio",
            subtitle: "Market Sentiment",
            value: "1.23",
            change: "▲ +2.1%",
            changeIsPositive: true,
            barProgress: 0.55
        ),
        mvrv: CryptoMetric(
            title: "MVRV",
            subtitle: "Market Value/Realized Value",
            value: "1.45",
            change: nil,
            changeIsPositive: nil,
            barProgress: 0.45
        )
    )
}

enum TabItem: String, CaseIterable {
    case crypto = "Crypto"
    case macro = "Macro"
    case ai = "AI"
    case settings = "Settings"
}

