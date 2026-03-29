//
//  InvestmentScore.swift
//  Prospero
//
//  투자 점수 데이터 모델 (계산은 백엔드 Lambda에서 수행)

import Foundation

// MARK: - 지표별 설명 (한국어)
struct IndicatorExplanations: Codable {
    let btcTrend: String
    let fearGreed: String
    let longShort: String
    let openInterest: String
    let interestRate: String
    let treasury10y: String
    let m2: String
    let dollarIndex: String
    let unemployment: String
    let cpi: String
    let interaction: String

    enum CodingKeys: String, CodingKey {
        case btcTrend = "btc_trend"
        case fearGreed = "fear_greed"
        case longShort = "long_short"
        case openInterest = "open_interest"
        case interestRate = "interest_rate"
        case treasury10y = "treasury10y"
        case m2
        case dollarIndex = "dollar_index"
        case unemployment
        case cpi
        case interaction
    }
}

// MARK: - 지표별 설명 (영어)
struct IndicatorExplanationsEn: Codable {
    let btcTrend: String
    let fearGreed: String
    let longShort: String
    let openInterest: String
    let interestRate: String
    let treasury10y: String
    let m2: String
    let dollarIndex: String
    let unemployment: String
    let cpi: String
    let interaction: String

    enum CodingKeys: String, CodingKey {
        case btcTrend = "btc_trend"
        case fearGreed = "fear_greed"
        case longShort = "long_short"
        case openInterest = "open_interest"
        case interestRate = "interest_rate"
        case treasury10y = "treasury10y"
        case m2
        case dollarIndex = "dollar_index"
        case unemployment
        case cpi
        case interaction
    }
}

// MARK: - AI 분석 응답 모델 (v3.0 - LLM 자유 판단 방식)
struct AIAnalysisResponse: Codable {
    let date: String
    let totalScore: Double
    let signalType: String
    let signalColor: String
    let btcTrendScore: Double
    let fearGreedScore: Double
    let longShortScore: Double
    let openInterestScore: Double
    let interestRateScore: Double
    let treasury10yScore: Double
    let m2Score: Double
    let dollarIndexScore: Double
    let unemploymentScore: Double
    let cpiScore: Double
    let interactionScore: Double
    let analysisSummary: String
    let analysisSummaryEn: String
    let indicatorExplanations: IndicatorExplanations
    let indicatorExplanationsEn: IndicatorExplanationsEn

    enum CodingKeys: String, CodingKey {
        case date
        case totalScore = "total_score"
        case signalType = "signal_type"
        case signalColor = "signal_color"
        case btcTrendScore = "btc_trend_score"
        case fearGreedScore = "fear_greed_score"
        case longShortScore = "long_short_score"
        case openInterestScore = "open_interest_score"
        case interestRateScore = "interest_rate_score"
        case treasury10yScore = "treasury10y_score"
        case m2Score = "m2_score"
        case dollarIndexScore = "dollar_index_score"
        case unemploymentScore = "unemployment_score"
        case cpiScore = "cpi_score"
        case interactionScore = "interaction_score"
        case analysisSummary = "analysis_summary"
        case analysisSummaryEn = "analysis_summary_en"
        case indicatorExplanations = "indicator_explanations"
        case indicatorExplanationsEn = "indicator_explanations_en"
    }
}
