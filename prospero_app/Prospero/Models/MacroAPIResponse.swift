//
//  MacroAPIResponse.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

struct MacroAPIResponse: Codable {
    let requestDate: String
    let previousDate: String
    let data: MacroDataPair
}

struct MacroDataPair: Codable {
    let requestDate: MacroDataItem?
    let previousDate: MacroDataItem?
}

struct MacroDataItem: Codable {
    let date: String
    let interestRate: Double?
    let treasury10y: Double?
    let cpi: Double?
    let m2: Double?
    let unemployment: Double?
    let dollarIndex: Double?
    let vix: Double?                   // v3.0 신규
    let oilPrice: Double?              // v3.0 신규
    let yieldSpread: Double?           // v3.0 신규
    let breakEvenInflation: Double?    // v3.0 신규

    enum CodingKeys: String, CodingKey {
        case date
        case interestRate
        case treasury10y
        case cpi
        case m2
        case unemployment
        case dollarIndex
        case vix                       // v3.0 신규
        case oilPrice                  // v3.0 신규
        case yieldSpread               // v3.0 신규
        case breakEvenInflation        // v3.0 신규
    }
}



