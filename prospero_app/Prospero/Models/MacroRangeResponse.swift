//
//  MacroRangeResponse.swift
//  Prospero
//
//  거시경제 30일(기본) 범위 조회 응답 모델.
//  백엔드 GET /api/macro-data/db/range?date=&days= 의 지표별 배열 응답.
//  각 배열은 오래된 날짜 → 최신 날짜 순.
//

import Foundation

struct MacroRangeResponse: Codable {
    let dates: [String]
    let interestRates: [Double]
    let treasury10ys: [Double]
    let cpis: [Double]
    let m2s: [Double]
    let unemployments: [Double]
    let dollarIndices: [Double]
    let vixs: [Double]
    let oilPrices: [Double]
    let yieldSpreads: [Double]
    let breakEvenInflations: [Double]
}
