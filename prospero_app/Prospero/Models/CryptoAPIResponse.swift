//
//  CryptoAPIResponse.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation

struct CryptoAPIResponse: Codable {
    let requestDate: String
    let previousDate: String
    let data: CryptoDataPair
}

struct CryptoDataPair: Codable {
    let requestDate: CryptoDataItem?
    let previousDate: CryptoDataItem?
}

struct CryptoDataItem: Codable {
    let date: String
    let btcPrice: Double?
    let longShortRatio: Double?
    let fearGreedIndex: Int?
    let openInterest: Double?
    let mvrv: Double?
    let fundingRate: Double?        // v3.0 신규
    let activeAddresses: Int?       // v3.0 신규

    enum CodingKeys: String, CodingKey {
        case date
        case btcPrice
        case longShortRatio
        case fearGreedIndex
        case openInterest
        case mvrv
        case fundingRate            // v3.0 신규
        case activeAddresses        // v3.0 신규
    }
}



