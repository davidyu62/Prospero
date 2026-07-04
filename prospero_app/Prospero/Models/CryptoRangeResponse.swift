//
//  CryptoRangeResponse.swift
//  Prospero
//
//  30일(기본) 범위 조회 응답 모델.
//  백엔드 GET /api/crypto-data/db/range?date=&days= 의 지표별 배열 응답.
//  각 배열은 오래된 날짜 → 최신 날짜 순으로 정렬되어 있다.
//

import Foundation

struct CryptoRangeResponse: Codable {
    let dates: [String]
    let btcPrices: [Double]
    let longShortRatios: [Double]
    let fearGreedIndices: [Double]   // JSON 정수 배열이지만 Double로 디코딩(차트용)
    let openInterests: [Double]
    let mvrvs: [Double]
    let fundingRates: [Double]
    let activeAddresses: [Double]
}
