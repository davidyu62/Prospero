//
//  IndicatorInterpretation.swift
//  Prospero
//
//  지표의 "현재 값 + 추세 방향"을 사람이 읽을 수 있는 1줄 해석으로 변환한다.
//  - 정적 교육 설명(InfoSheet)과 달리, 오늘 값/방향이 무슨 의미인지 동적으로 알려준다.
//  - 백엔드 변경 없이 클라이언트 로컬 임계값 매핑으로 동작한다.
//

import SwiftUI

// MARK: - 해석 성향

/// 지표 해석의 시장 성향. 색상/아이콘은 여기서 일괄 결정한다.
enum IndicatorSentiment {
    case bullish   // 강세 우호
    case bearish   // 약세 우호
    case warning   // 과열/과매도 등 주의
    case neutral   // 중립

    var color: Color {
        switch self {
        case .bullish: return .successColor
        case .bearish: return .dangerColor
        case .warning: return .warningColor
        case .neutral: return .darkSecondaryText
        }
    }

    /// 1줄 해석 앞에 붙는 방향 기호
    var symbol: String {
        switch self {
        case .bullish: return "↗"
        case .bearish: return "↘"
        case .warning: return "⚡"
        case .neutral: return "→"
        }
    }
}

/// 추세 방향(전일 대비 또는 30일 기울기). C1에서는 전일 대비로 채운다.
enum TrendDirection {
    case up, down, flat
}

/// 해석 결과
struct IndicatorInterpretation {
    let text: String
    let sentiment: IndicatorSentiment
}

// MARK: - 해석 엔진

enum IndicatorInterpreter {

    /// 지표 키. CryptoMetric.title 및 별도 지표(fearGreed 등)를 식별한다.
    enum Key: String {
        case fearGreed
        case mvrv
        case longShortRatio
        case openInterest
        case fundingRate
        case activeAddresses
        case btcPrice
        // 매크로 지표 (rawValue가 JSON id와 동일)
        case interestRate
        case treasury10y
        case cpi
        case m2
        case unemployment
        case dollarIndex
        case vix
        case oilPrice
        case yieldSpread
        case breakEvenInflation

        /// IndicatorMetadata.json의 지표 id (설명 조회용). rawValue와 다른 키만 매핑.
        var metadataId: String {
            switch self {
            case .fearGreed: return "fearGreedIndex"
            default: return rawValue  // 나머지(크립토 5종·btcPrice·매크로 10종)는 JSON id와 동일
            }
        }
    }

    /// CryptoMetric.title → Key 매핑 (영문 타이틀 기준)
    static func key(forTitle title: String) -> Key? {
        switch title {
        case "MVRV": return .mvrv
        case "Long/Short Ratio": return .longShortRatio
        case "Open Interest": return .openInterest
        case "Funding Rate": return .fundingRate
        case "Active Addresses": return .activeAddresses
        case "Bitcoin (BTC)": return .btcPrice
        case "Fear & Greed Index": return .fearGreed
        // 매크로
        case "Interest Rate": return .interestRate
        case "10Y Treasury": return .treasury10y
        case "CPI": return .cpi
        case "M2 Money Supply": return .m2
        case "Unemployment": return .unemployment
        case "Dollar Index": return .dollarIndex
        case "VIX": return .vix
        case "Oil Price": return .oilPrice
        case "Yield Spread": return .yieldSpread
        case "Break-Even Inflation": return .breakEvenInflation
        default: return nil
        }
    }

    private static func kor(_ language: String) -> Bool { language == "KOR" }

    /// 핵심 진입점
    static func interpret(_ key: Key, value: Double, trend: TrendDirection, language: String) -> IndicatorInterpretation {
        switch key {
        case .fearGreed:      return fearGreed(value, trend, language)
        case .mvrv:           return mvrv(value, trend, language)
        case .longShortRatio: return longShort(value, trend, language)
        case .openInterest:   return openInterest(value, trend, language)
        case .fundingRate:    return fundingRate(value, trend, language)
        case .activeAddresses:return activeAddresses(value, trend, language)
        case .btcPrice:       return price(value, trend, language)
        case .interestRate:   return interestRate(value, trend, language)
        case .treasury10y:    return treasury10y(value, trend, language)
        case .cpi:            return cpi(value, trend, language)
        case .m2:             return m2(value, trend, language)
        case .unemployment:   return unemployment(value, trend, language)
        case .dollarIndex:    return dollarIndex(value, trend, language)
        case .vix:            return vix(value, trend, language)
        case .oilPrice:       return oilPrice(value, trend, language)
        case .yieldSpread:    return yieldSpread(value, trend, language)
        case .breakEvenInflation: return breakEven(value, trend, language)
        }
    }

    // MARK: - 지표별 규칙

    // 공포·탐욕 지수 (0~100)
    private static func fearGreed(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case ..<25:
            return .init(text: k ? "극단적 공포 · 과매도 구간 → 역발상 매수 관점" : "Extreme fear · oversold → contrarian buy zone", sentiment: .warning)
        case 25..<45:
            return .init(text: k ? "공포 구간 · 투자심리 위축" : "Fear zone · weak sentiment", sentiment: .bearish)
        case 45..<55:
            return .init(text: k ? "중립 구간 · 방향성 모색" : "Neutral · seeking direction", sentiment: .neutral)
        case 55..<75:
            return .init(text: k ? "탐욕 구간 · 위험선호 강화" : "Greed zone · risk-on", sentiment: t == .up ? .warning : .bullish)
        default:
            return .init(text: k ? "극단적 탐욕 · 과열 → 단기 조정 주의" : "Extreme greed · overheated → watch for pullback", sentiment: .warning)
        }
    }

    // MVRV (시가총액/실현가치)
    private static func mvrv(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case ..<1.0:
            return .init(text: k ? "저평가 구간 · 바닥권 매수 우위" : "Undervalued · accumulation zone", sentiment: .bullish)
        case 1.0..<2.4:
            let trendNote = t == .up ? (k ? " · 상승 추세" : " · uptrend") : ""
            return .init(text: (k ? "적정~중립 구간" : "Fair / neutral zone") + trendNote, sentiment: t == .up ? .bullish : .neutral)
        case 2.4..<3.2:
            return .init(text: k ? "고평가 주의 · 차익실현 압력" : "Elevated · profit-taking risk", sentiment: .warning)
        default:
            return .init(text: k ? "과열 구간 · 고점 경계" : "Overheated · cycle-top risk", sentiment: .bearish)
        }
    }

    // 롱/숏 비율
    private static func longShort(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case 1.5...:
            return .init(text: k ? "롱 과밀 · 롱 스퀴즈 주의" : "Crowded longs · squeeze risk", sentiment: .warning)
        case 1.05..<1.5:
            return .init(text: t == .down ? (k ? "롱 우위 약화 → 차익실현 압력" : "Long bias fading → profit-taking")
                                           : (k ? "롱 우위 · 강세 포지셔닝" : "Long bias · bullish positioning"),
                         sentiment: t == .down ? .bearish : .bullish)
        case 0.95..<1.05:
            return .init(text: k ? "롱·숏 균형 · 방향성 중립" : "Balanced · neutral positioning", sentiment: .neutral)
        default:
            return .init(text: k ? "숏 우위 · 역발상 반등 가능" : "Short bias · contrarian bounce risk", sentiment: .warning)
        }
    }

    // 미결제약정 — 절대 구간보다 추세가 핵심
    private static func openInterest(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "미결제약정 증가 · 추세 강도 확대" : "Rising OI · trend conviction up", sentiment: .bullish)
        case .down: return .init(text: k ? "미결제약정 감소 · 포지션 청산" : "Falling OI · positions unwinding", sentiment: .bearish)
        case .flat: return .init(text: k ? "미결제약정 보합 · 관망세" : "Flat OI · wait-and-see", sentiment: .neutral)
        }
    }

    // 펀딩비(%) — 음수면 숏이 비용을 지불(역발상 매수)
    private static func fundingRate(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case 0.05...:
            return .init(text: k ? "펀딩비 과열 · 롱 비용 부담" : "High funding · crowded longs", sentiment: .warning)
        case 0.0..<0.05:
            return .init(text: k ? "양(+) 펀딩 · 롱 우위" : "Positive funding · long bias", sentiment: .neutral)
        default:
            return .init(text: k ? "음(−) 펀딩 · 숏 우위 → 역발상 매수 관점" : "Negative funding · short bias → contrarian buy", sentiment: .bullish)
        }
    }

    // 활성 주소 — 추세 기반(네트워크 활동)
    private static func activeAddresses(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "활성 주소 증가 · 네트워크 사용 확대" : "Rising addresses · adoption up", sentiment: .bullish)
        case .down: return .init(text: k ? "활성 주소 감소 · 활동 둔화" : "Falling addresses · activity slowing", sentiment: .bearish)
        case .flat: return .init(text: k ? "활성 주소 보합" : "Flat network activity", sentiment: .neutral)
        }
    }

    // 가격 — 추세 기반
    private static func price(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "상승 추세" : "Uptrend", sentiment: .bullish)
        case .down: return .init(text: k ? "하락 추세" : "Downtrend", sentiment: .bearish)
        case .flat: return .init(text: k ? "횡보" : "Sideways", sentiment: .neutral)
        }
    }

    // MARK: - 매크로 지표 규칙
    // ⚠️ 매크로는 "위험자산(주식·암호화폐) 관점"의 강세/약세로 해석한다.

    // 기준금리(%) — 인상=긴축(위험자산 약세)
    private static func interestRate(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "금리 인상 · 긴축 → 위험자산 부담" : "Rate hike · tightening → risk-off", sentiment: .bearish)
        case .down: return .init(text: k ? "금리 인하 · 완화 → 위험자산 우호" : "Rate cut · easing → risk-on", sentiment: .bullish)
        case .flat: return .init(text: k ? "금리 동결 · 관망" : "Rates on hold · wait-and-see", sentiment: .neutral)
        }
    }

    // 10년물 국채 수익률(%) — 상승=밸류에이션 부담
    private static func treasury10y(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "장기금리 상승 · 밸류에이션 부담" : "Long yields up · valuation pressure", sentiment: .bearish)
        case .down: return .init(text: k ? "장기금리 하락 · 위험선호 우호" : "Long yields down · risk-on", sentiment: .bullish)
        case .flat: return .init(text: k ? "장기금리 보합" : "Long yields flat", sentiment: .neutral)
        }
    }

    // 소비자물가지수(%, 전년比) — 높으면 긴축 압력
    private static func cpi(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case 4.0...:
            return .init(text: k ? "고인플레이션 · 강한 긴축 압력" : "High inflation · strong tightening pressure", sentiment: .bearish)
        case 2.5..<4.0:
            return t == .up ? .init(text: k ? "인플레 재상승 · 긴축 우려" : "Inflation reaccelerating · tightening risk", sentiment: .bearish)
                            : .init(text: k ? "인플레 둔화 조짐" : "Inflation cooling", sentiment: .bullish)
        default:
            return .init(text: k ? "인플레 안정 · 완화 여지" : "Inflation contained · room to ease", sentiment: .bullish)
        }
    }

    // M2 통화량 — 증가=유동성 확대
    private static func m2(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "통화량 증가 · 유동성 확대" : "M2 rising · liquidity expanding", sentiment: .bullish)
        case .down: return .init(text: k ? "통화량 감소 · 유동성 긴축" : "M2 falling · liquidity tightening", sentiment: .bearish)
        case .flat: return .init(text: k ? "통화량 보합" : "M2 flat", sentiment: .neutral)
        }
    }

    // 실업률(%) — 상승=경기 둔화
    private static func unemployment(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "실업률 상승 · 경기 둔화 신호" : "Unemployment up · slowdown signal", sentiment: .bearish)
        case .down: return .init(text: k ? "실업률 하락 · 경기 견조" : "Unemployment down · resilient economy", sentiment: .bullish)
        case .flat: return .init(text: k ? "실업률 보합" : "Unemployment flat", sentiment: .neutral)
        }
    }

    // 달러 인덱스(DXY) — 강달러=위험자산·원자재 부담
    private static func dollarIndex(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "강달러 · 위험자산·원자재 부담" : "Strong dollar · pressure on risk assets", sentiment: .bearish)
        case .down: return .init(text: k ? "약달러 · 위험자산 우호" : "Weak dollar · risk-on", sentiment: .bullish)
        case .flat: return .init(text: k ? "달러 보합" : "Dollar flat", sentiment: .neutral)
        }
    }

    // VIX(변동성지수) — 값 구간 기반
    private static func vix(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case ..<15:
            return .init(text: k ? "저변동성 · 안정 · 위험선호" : "Low volatility · calm · risk-on", sentiment: .bullish)
        case 15..<25:
            return .init(text: k ? "보통 변동성 · 중립" : "Moderate volatility · neutral", sentiment: .neutral)
        case 25..<35:
            return .init(text: k ? "변동성 확대 · 위험회피 경계" : "Rising volatility · caution", sentiment: .warning)
        default:
            return .init(text: k ? "공포 국면 · 급락 위험" : "Fear regime · crash risk", sentiment: .bearish)
        }
    }

    // 유가(WTI) — 상승=인플레·비용 압력
    private static func oilPrice(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch t {
        case .up:   return .init(text: k ? "유가 상승 · 인플레·비용 압력" : "Oil up · inflation/cost pressure", sentiment: .warning)
        case .down: return .init(text: k ? "유가 하락 · 인플레 완화" : "Oil down · easing inflation", sentiment: .bullish)
        case .flat: return .init(text: k ? "유가 보합" : "Oil flat", sentiment: .neutral)
        }
    }

    // 장단기 금리차(T10Y2Y, %) — 역전=침체 경고
    private static func yieldSpread(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case ..<0:
            return .init(text: k ? "장단기 금리 역전 · 침체 경고" : "Yield curve inverted · recession warning", sentiment: .bearish)
        case 0..<0.5:
            return .init(text: k ? "완만한 정상화 구간" : "Mild normalization", sentiment: .neutral)
        default:
            return .init(text: k ? "정상 · 경기 확장 신호" : "Normal curve · expansion signal", sentiment: .bullish)
        }
    }

    // 기대인플레이션(10Y BE, %) — 2% 근처가 최적
    private static func breakEven(_ v: Double, _ t: TrendDirection, _ lang: String) -> IndicatorInterpretation {
        let k = kor(lang)
        switch v {
        case 2.5...:
            return .init(text: k ? "기대인플레 과열 · 긴축 우려" : "Elevated inflation expectations · tightening risk", sentiment: .warning)
        case 1.5..<2.5:
            return .init(text: k ? "안정적 기대인플레(≈2%)" : "Anchored expectations (≈2%)", sentiment: .bullish)
        default:
            return .init(text: k ? "기대인플레 둔화 · 디플레 우려" : "Falling expectations · deflation risk", sentiment: .bearish)
        }
    }
}
