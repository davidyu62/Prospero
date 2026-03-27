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

    enum CodingKeys: String, CodingKey {
        case date
        case btcPrice
        case longShortRatio
        case fearGreedIndex
        case openInterest
    }
}



