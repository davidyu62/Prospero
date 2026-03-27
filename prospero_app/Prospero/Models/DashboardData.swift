//
//  DashboardData.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

struct CryptoData {
    let bitcoin: Double
    let fearAndGreed: Int
    let newAccounts: Double // in millions
    let exchangeInflow: Double
}

struct MacroData {
    let usInterestRate: Double
    let dollarIndex: Double
    let goldPrice: Double
    let oilWTI: Double
}

struct DashboardData {
    let crypto: CryptoData
    let macro: MacroData
    let lastUpdate: Date
    
    static let sample = DashboardData(
        crypto: CryptoData(
            bitcoin: 106350,
            fearAndGreed: 73,
            newAccounts: 1.25,
            exchangeInflow: 3600
        ),
        macro: MacroData(
            usInterestRate: 5.255,
            dollarIndex: 106.7,
            goldPrice: 2330,
            oilWTI: 81.9
        ),
        lastUpdate: Date()
    )
}

enum TimeFrame: String, CaseIterable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case oneYear = "1Y"
}

