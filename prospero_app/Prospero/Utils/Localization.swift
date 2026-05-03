//
//  Localization.swift
//  Prospero
//
//  Created on $(date)
//

import Foundation
import SwiftUI

class Localization {
    static let shared = Localization()
    
    @AppStorage("selectedLanguage") var language: String = "ENG"
    
    private init() {}
    
    // MARK: - Common
    func common(_ key: String) -> String {
        switch language {
        case "KOR":
            switch key {
            case "Updated": return "업데이트"
            case "Done": return "완료"
            case "Error": return "오류"
            case "Failed to load": return "로드 실패"
            case "Ad Not Ready": return "광고 준비 안 됨"
            case "OK": return "확인"
            case "Ad Loading Message": return "광고를 불러오는 중입니다. 잠시 후 다시 시도해주세요."
            default: return key
            }
        default:
            switch key {
            case "Ad Not Ready": return "Ad Not Ready"
            case "Ad Loading Message": return "The ad is still loading. Please try again in a moment."
            default: return key
            }
        }
    }
    
    // MARK: - Dashboard
    func dashboard(_ key: String) -> String {
        switch language {
        case "KOR":
            switch key {
            case "Crypto Dashboard": return "암호화폐 대시보드"
            case "Macro Dashboard": return "거시경제 대시보드"
            case "AI": return "AI"
            case "AI Analysis": return "AI Insight"
            case "AI Analysis Description": return "Crypto와 Macro 데이터를 분석하여 투자 점수를 제공합니다."
            case "Settings": return "설정"
            case "Language": return "언어"
            default: return key
            }
        default:
            switch key {
            case "AI Analysis Description": return "Analyze Crypto and Macro data to provide investment scores."
            case "AI Analysis": return "AI Insight"
            default: return key
            }
        }
    }

    // MARK: - AI Analysis
    func ai(_ key: String) -> String {
        switch language {
        case "KOR":
            switch key {
            case "Analyzing data...": return "데이터를 분석 중입니다..."
            case "Failed to Load Data": return "데이터 로드 실패"
            case "Unable to load data.": return "데이터를 불러올 수 없습니다."
            case "Investment Signal": return "투자 신호"
            case "Investment Signal Analysis": return "투자 신호 분석"
            case "Crypto Indicators": return "암호화폐 지표"
            case "Macro Indicators": return "거시경제 지표"
            case "Market Indicators": return "시장 지표"
            case "Score Summary": return "점수 분류"
            case "Fear & Greed": return "공포탐욕지수"
            case "Long/Short Ratio": return "롱숏비율"
            case "Exchange Balance": return "거래소잔고"
            case "Open Interest": return "미결제 약정"
            case "OI + Price": return "미결제 약정"
            case "MVRV": return "MVRV"
            case "BTC Trend": return "BTC 추세"
            case "Interest Rate": return "기준금리"
            case "Treasury 10Y": return "10년물 국채수익률"
            case "M2 Supply": return "M2 통화량"
            case "Dollar Index": return "달러인덱스"
            case "Unemployment": return "실업률"
            case "CPI": return "소비자물가지수"
            case "Interaction": return "종합 환경"
            case "Investment Rationale": return "투자 근거"
            case "Unable to calculate score.": return "점수를 계산할 수 없습니다."
            default: return key
            }
        default:
            switch key {
            case "Analyzing data...": return "Analyzing data..."
            case "Failed to Load Data": return "Failed to Load Data"
            case "Unable to load data.": return "Unable to load data."
            case "Investment Signal": return "Investment Signal"
            case "Investment Signal Analysis": return "Investment Signal Analysis"
            case "Crypto Indicators": return "Crypto Indicators"
            case "Macro Indicators": return "Macro Indicators"
            case "Market Indicators": return "Market Indicators"
            case "Score Summary": return "Score Summary"
            case "Open Interest": return "Open Interest"
            case "Treasury 10Y": return "Treasury 10Y"
            case "Unemployment": return "Unemployment"
            case "Investment Rationale": return "Investment Rationale"
            case "Unable to calculate score.": return "Unable to calculate score."
            case "CPI": return "CPI"
            default: return key
            }
        }
    }
    
    // MARK: - Crypto Metrics
    func cryptoMetric(_ key: String) -> String {
        // 1. 지표 ID로 IndicatorManager에서 조회
        if let indicator = IndicatorManager.shared.getIndicator(key) {
            return language == "KOR" ? indicator.koreanName : indicator.englishName
        }

        // 2. 영어 제목 → 지표 ID 매핑 (MetricCard에서 영어 제목을 전달할 때)
        let titleToIdMap: [String: String] = [
            "Open Interest": "openInterest",
            "Long/Short Ratio": "longShortRatio",
            "MVRV": "mvrv",
            "Funding Rate": "fundingRate",
            "Active Addresses": "activeAddresses"
        ]

        if let indicatorId = titleToIdMap[key], let indicator = IndicatorManager.shared.getIndicator(indicatorId) {
            return language == "KOR" ? indicator.koreanName : indicator.englishName
        }

        switch language {
        case "KOR":
            switch key {
            case "Price": return "가격"
            case "Last 24h": return "최근 24시간"
            case "Extreme Fear": return "극도의 공포"
            case "Fear": return "공포"
            case "Neutral": return "중립"
            case "Greed": return "탐욕"
            case "Extreme Greed": return "극도의 탐욕"
            case "Extreme\nFear": return "극도의\n공포"
            case "Extreme\nGreed": return "극도의\n탐욕"
            default: return key
            }
        default:
            return key
        }
    }
    
    // MARK: - Macro Metrics
    func macroMetric(_ key: String) -> String {
        // 1. 지표 ID로 IndicatorManager에서 조회
        if let indicator = IndicatorManager.shared.getIndicator(key) {
            return language == "KOR" ? indicator.koreanName : indicator.englishName
        }

        // 2. 영어 제목 → 지표 ID 매핑 (MetricCard에서 영어 제목을 전달할 때)
        let titleToIdMap: [String: String] = [
            "Interest Rate": "interestRate",
            "10Y Treasury": "treasury10y",
            "M2 Money Supply": "m2",
            "Dollar Index": "dollarIndex",
            "Unemployment": "unemployment",
            "CPI": "cpi",
            "VIX": "vix",
            "Oil Price": "oilPrice",
            "Yield Spread": "yieldSpread",
            "Break-Even Inflation": "breakEvenInflation"
        ]

        if let indicatorId = titleToIdMap[key], let indicator = IndicatorManager.shared.getIndicator(indicatorId) {
            return language == "KOR" ? indicator.koreanName : indicator.englishName
        }

        switch language {
        case "KOR":
            switch key {
            case "Yield": return "수익률"
            case "Rate": return "비율"
            default: return key
            }
        default:
            return key
        }
    }
    
    // MARK: - Settings
    func settings(_ key: String) -> String {
        switch language {
        case "KOR":
            switch key {
            case "Language": return "언어"
            case "Theme": return "테마"
            case "ENG": return "영어"
            case "KOR": return "한국어"
            case "Dark": return "다크"
            case "Light": return "라이트"
            default: return key
            }
        default:
            return key
        }
    }
    
    // MARK: - Info Sheets
    func infoSheet(_ key: String) -> String {
        switch language {
        case "KOR":
            switch key {
            // Common
            case "What is": return "이것은 무엇인가요?"
            case "Key Features": return "주요 특징"
            case "Key Points": return "주요 포인트"
            case "How It Works": return "작동 원리"
            
            // Bitcoin
            case "What is Bitcoin?": return "비트코인이란 무엇인가요?"
            case "Bitcoin is a decentralized digital currency that enables peer-to-peer transactions without the need for a central authority or intermediary. It was created in 2009 by an anonymous person or group using the pseudonym Satoshi Nakamoto.": return "비트코인은 중앙 기관이나 중개자 없이 개인 간 거래를 가능하게 하는 탈중앙화 디지털 화폐입니다. 2009년 사토시 나카모토라는 가명을 사용한 익명의 개인 또는 그룹에 의해 만들어졌습니다."
            case "Decentralized": return "탈중앙화"
            case "No central authority controls Bitcoin": return "중앙 기관이 비트코인을 통제하지 않습니다"
            case "Peer-to-Peer": return "개인 간 거래"
            case "Direct transactions between users": return "사용자 간 직접 거래"
            case "Pseudonymous": return "익명성"
            case "Transactions are linked to addresses, not identities": return "거래는 신원이 아닌 주소와 연결됩니다"
            case "Limited Supply": return "제한된 공급량"
            case "Maximum of 21 million BTC will ever exist": return "최대 2,100만 개의 BTC만 존재할 수 있습니다"
            case "Bitcoin uses blockchain technology, a distributed ledger that records all transactions. Miners validate transactions and add them to blocks, which are then added to the blockchain. This process ensures security and prevents double-spending.": return "비트코인은 모든 거래를 기록하는 분산 원장인 블록체인 기술을 사용합니다. 채굴자들이 거래를 검증하고 블록에 추가한 후 블록체인에 추가합니다. 이 과정은 보안을 보장하고 이중 지불을 방지합니다."
            
            // Fear & Greed
            case "What is the Fear & Greed Index?": return "공포탐욕 지수란 무엇인가요?"
            case "The Fear & Greed Index measures the emotions and sentiments of cryptocurrency investors. It ranges from 0 (Extreme Fear) to 100 (Extreme Greed) and helps identify when the market might be overbought or oversold.": return "공포탐욕 지수는 암호화폐 투자자들의 감정과 심리를 측정합니다. 0(극도의 공포)부터 100(극도의 탐욕)까지 범위를 가지며, 시장이 과매수 또는 과매도 상태일 때를 식별하는 데 도움이 됩니다."
            case "Index Levels": return "지수 수준"
            case "0-24: Extreme Fear": return "0-24: 극도의 공포"
            case "Investors are very worried, potential buying opportunity": return "투자자들이 매우 걱정하고 있으며, 잠재적 매수 기회"
            case "25-44: Fear": return "25-44: 공포"
            case "Market sentiment is negative": return "시장 심리가 부정적입니다"
            case "45-55: Neutral": return "45-55: 중립"
            case "Balanced market sentiment": return "균형 잡힌 시장 심리"
            case "56-75: Greed": return "56-75: 탐욕"
            case "Investors are optimistic": return "투자자들이 낙관적입니다"
            case "76-100: Extreme Greed": return "76-100: 극도의 탐욕"
            case "Market may be overbought, potential correction": return "시장이 과매수 상태일 수 있으며, 잠재적 조정 가능성"
            case "The index combines multiple data sources including volatility, market momentum, social media sentiment, surveys, and Bitcoin dominance. When the index shows extreme fear, it might indicate a buying opportunity, while extreme greed could signal a potential market top.": return "이 지수는 변동성, 시장 모멘텀, 소셜 미디어 심리, 설문조사, 비트코인 지배력 등 여러 데이터 소스를 결합합니다. 지수가 극도의 공포를 보이면 매수 기회를 나타낼 수 있으며, 극도의 탐욕은 잠재적인 시장 정점을 신호할 수 있습니다."
            
            // New Addresses
            case "What are New Addresses?": return "신규 주소란 무엇인가요?"
            case "New Addresses represents the number of unique Bitcoin addresses that received BTC for the first time in the last 24 hours. This metric helps gauge network growth and adoption.": return "신규 주소는 최근 24시간 동안 처음으로 BTC를 받은 고유 비트코인 주소의 수를 나타냅니다. 이 지표는 네트워크 성장과 채택을 측정하는 데 도움이 됩니다."
            case "Network Growth": return "네트워크 성장"
            case "Indicates increasing Bitcoin adoption": return "비트코인 채택 증가를 나타냅니다"
            case "User Activity": return "사용자 활동"
            case "Shows new participants entering the market": return "시장에 진입하는 새로운 참여자를 보여줍니다"
            case "Market Sentiment": return "시장 심리"
            case "High numbers suggest positive sentiment": return "높은 수치는 긍정적인 심리를 시사합니다"
            case "When someone receives Bitcoin for the first time, a new address is created. Tracking these addresses helps measure the expansion of the Bitcoin network and can indicate growing interest in cryptocurrency. A rising number of new addresses typically suggests increased adoption and network growth.": return "누군가 처음으로 비트코인을 받으면 새로운 주소가 생성됩니다. 이러한 주소를 추적하면 비트코인 네트워크의 확장을 측정하고 암호화폐에 대한 관심 증가를 나타낼 수 있습니다. 신규 주소 수의 증가는 일반적으로 채택 증가와 네트워크 성장을 시사합니다."
            
            // Open Interest
            case "What is Open Interest?": return "미결제 약정이란 무엇인가요?"
            case "Open Interest is the total number of outstanding derivative contracts (futures and options) that have not been settled. It's measured in BTC and represents the total value of active positions in the futures market.": return "미결제 약정은 결제되지 않은 미결제 파생상품 계약(선물 및 옵션)의 총 수입니다. BTC로 측정되며 선물 시장의 활성 포지션 총 가치를 나타냅니다."
            case "Market Activity": return "시장 활동"
            case "Shows total active positions in futures": return "선물의 총 활성 포지션을 보여줍니다"
            case "Liquidity Indicator": return "유동성 지표"
            case "Higher OI suggests more market liquidity": return "높은 미결제 약정은 더 많은 시장 유동성을 시사합니다"
            case "Price Volatility": return "가격 변동성"
            case "Rapid changes can indicate market stress": return "급격한 변화는 시장 스트레스를 나타낼 수 있습니다"
            case "Open Interest increases when new contracts are opened and decreases when contracts are closed or settled. It's a key metric for understanding market sentiment and potential price volatility in the derivatives market. High open interest can indicate strong market participation, while sudden decreases might signal position unwinding.": return "미결제 약정은 새로운 계약이 열릴 때 증가하고 계약이 종료되거나 결제될 때 감소합니다. 이는 파생상품 시장에서 시장 심리와 잠재적 가격 변동성을 이해하는 핵심 지표입니다. 높은 미결제 약정은 강한 시장 참여를 나타낼 수 있으며, 갑작스러운 감소는 포지션 청산을 신호할 수 있습니다."
            
            // Long/Short Ratio
            case "What is Long/Short Ratio?": return "롱/숏 비율이란 무엇인가요?"
            case "Long/Short Ratio measures the proportion of traders holding long positions (betting on price increase) versus short positions (betting on price decrease) in the futures market.": return "롱/숏 비율은 선물 시장에서 롱 포지션(가격 상승에 베팅)을 보유한 트레이더와 숏 포지션(가격 하락에 베팅)을 보유한 트레이더의 비율을 측정합니다."
            case "Shows trader expectations": return "트레이더의 기대를 보여줍니다"
            case "Ratio > 1.0": return "비율 > 1.0"
            case "More longs than shorts (bullish)": return "숏보다 롱이 많음 (강세)"
            case "Ratio < 1.0": return "비율 < 1.0"
            case "More shorts than longs (bearish)": return "롱보다 숏이 많음 (약세)"
            case "A ratio above 1.0 means more traders are betting on price increases (long positions) than decreases (short positions). This metric helps gauge market sentiment and can sometimes indicate potential price movements, though it's not a guarantee. Extreme ratios (very high or very low) can sometimes signal contrarian opportunities.": return "1.0보다 높은 비율은 가격 하락(숏 포지션)보다 가격 상승(롱 포지션)에 베팅하는 트레이더가 더 많다는 의미입니다. 이 지표는 시장 심리를 측정하는 데 도움이 되며 때로는 잠재적 가격 움직임을 나타낼 수 있지만 보장은 아닙니다. 극단적인 비율(매우 높거나 매우 낮음)은 때로는 역추세 기회를 신호할 수 있습니다."
            
            // Interest Rate
            case "What is the Federal Funds Rate?": return "연방기금금리란 무엇인가요?"
            case "The Federal Funds Rate is the interest rate at which depository institutions (banks) lend reserve balances to other depository institutions overnight. It's set by the Federal Reserve and is one of the most important economic indicators.": return "연방기금금리는 예금 기관(은행)이 다른 예금 기관에 일일 단위로 준비금 잔액을 대출하는 이자율입니다. 연준이 설정하며 가장 중요한 경제 지표 중 하나입니다."
            case "Rate Increases": return "금리 상승"
            case "Tightens monetary policy, slows economic growth": return "통화 정책을 긴축하고 경제 성장을 둔화시킵니다"
            case "Rate Decreases": return "금리 하락"
            case "Loosens monetary policy, stimulates growth": return "통화 정책을 완화하고 성장을 자극합니다"
            case "Market Impact": return "시장 영향"
            case "Affects borrowing costs and investment decisions": return "차입 비용과 투자 결정에 영향을 미칩니다"
            case "The Federal Reserve adjusts the federal funds rate to influence economic activity. When rates rise, borrowing becomes more expensive, which can slow inflation but also economic growth. When rates fall, borrowing becomes cheaper, stimulating spending and investment. This rate directly impacts mortgage rates, credit card rates, and other consumer loans.": return "연준은 경제 활동에 영향을 미치기 위해 연방기금금리를 조정합니다. 금리가 상승하면 차입이 더 비싸져 인플레이션을 둔화시킬 수 있지만 경제 성장도 둔화시킬 수 있습니다. 금리가 하락하면 차입이 더 저렴해져 지출과 투자를 자극합니다. 이 금리는 모기지 금리, 신용카드 금리 및 기타 소비자 대출에 직접적인 영향을 미칩니다."
            
            // Treasury 10Y
            case "What is the 10-Year Treasury Yield?": return "10년물 국채 수익률이란 무엇인가요?"
            case "The 10-Year Treasury Yield is the return on investment for the U.S. government's 10-year bond. It's considered a benchmark for long-term interest rates and is closely watched as an indicator of economic expectations.": return "10년물 국채 수익률은 미국 정부의 10년 만기 채권에 대한 투자 수익률입니다. 장기 금리의 기준으로 간주되며 경제 기대의 지표로 면밀히 관찰됩니다."
            case "Rising Yields": return "수익률 상승"
            case "Often signals economic growth expectations": return "종종 경제 성장 기대를 신호합니다"
            case "Falling Yields": return "수익률 하락"
            case "May indicate economic concerns or flight to safety": return "경제 우려나 안전 자산 선호를 나타낼 수 있습니다"
            case "Risk-Free Rate": return "무위험 수익률"
            case "Used as benchmark for other investments": return "다른 투자의 기준으로 사용됩니다"
            case "When investors buy Treasury bonds, they're lending money to the U.S. government. The yield represents the return they receive. Higher yields typically indicate stronger economic growth expectations or inflation concerns. Lower yields may suggest economic uncertainty or deflationary pressures. The 10-year yield is particularly important as it influences mortgage rates, corporate borrowing costs, and stock valuations.": return "투자자들이 국채를 구매하면 미국 정부에 돈을 빌려주는 것입니다. 수익률은 그들이 받는 수익을 나타냅니다. 높은 수익률은 일반적으로 더 강한 경제 성장 기대나 인플레이션 우려를 나타냅니다. 낮은 수익률은 경제 불확실성이나 디플레이션 압력을 시사할 수 있습니다. 10년물 수익률은 모기지 금리, 기업 차입 비용 및 주식 가치 평가에 영향을 미치기 때문에 특히 중요합니다."
            
            // CPI
            case "What is CPI?": return "CPI란 무엇인가요?"
            case "The Consumer Price Index (CPI) measures the average change over time in the prices paid by urban consumers for a market basket of consumer goods and services. It's the most widely used indicator of inflation.": return "소비자물가지수(CPI)는 도시 소비자가 소비재 및 서비스 시장 바구니에 대해 지불하는 가격의 시간에 따른 평균 변화를 측정합니다. 가장 널리 사용되는 인플레이션 지표입니다."
            case "Rising CPI": return "CPI 상승"
            case "Indicates inflation - prices are increasing": return "인플레이션을 나타냅니다 - 가격이 상승하고 있습니다"
            case "Falling CPI": return "CPI 하락"
            case "Indicates deflation - prices are decreasing": return "디플레이션을 나타냅니다 - 가격이 하락하고 있습니다"
            case "Target Rate": return "목표 수준"
            case "Central banks typically target 2% inflation": return "중앙은행은 일반적으로 2% 인플레이션을 목표로 합니다"
            case "The CPI tracks price changes for a basket of goods and services that represents what typical consumers buy, including food, housing, transportation, medical care, and more. When CPI rises, it means consumers need to spend more to buy the same goods, indicating inflation. Central banks use CPI data to make monetary policy decisions. High inflation erodes purchasing power, while deflation can signal economic weakness.": return "CPI는 일반 소비자가 구매하는 것을 나타내는 상품 및 서비스 바구니의 가격 변화를 추적하며, 식품, 주거, 교통, 의료 등을 포함합니다. CPI가 상승하면 소비자가 같은 상품을 구매하는 데 더 많은 돈을 써야 한다는 의미이며, 이는 인플레이션을 나타냅니다. 중앙은행은 통화 정책 결정을 위해 CPI 데이터를 사용합니다. 높은 인플레이션은 구매력을 침식하는 반면, 디플레이션은 경제 약화를 신호할 수 있습니다."
            
            // M2
            case "What is M2 Money Supply?": return "M2 통화량이란 무엇인가요?"
            case "M2 is a measure of the money supply that includes cash, checking deposits, savings deposits, money market securities, and other time deposits. It represents the total amount of money available in the economy for spending and investment.": return "M2는 현금, 당좌 예금, 저축 예금, 금융 시장 증권 및 기타 정기 예금을 포함하는 통화 공급량 측정치입니다. 경제에서 지출 및 투자에 사용 가능한 총 금액을 나타냅니다."
            case "Increasing M2": return "M2 증가"
            case "More money in circulation, can fuel inflation": return "유통되는 돈이 더 많아져 인플레이션을 촉진할 수 있습니다"
            case "Decreasing M2": return "M2 감소"
            case "Less money available, may slow economic activity": return "사용 가능한 돈이 줄어들어 경제 활동이 둔화될 수 있습니다"
            case "Economic Indicator": return "경제 지표"
            case "Reflects monetary policy and economic health": return "통화 정책과 경제 건강을 반영합니다"
            case "M2 includes all forms of money that are easily accessible for spending. When the Federal Reserve increases the money supply (through quantitative easing or other measures), M2 rises. This can stimulate economic activity but may also lead to inflation if it grows too quickly. Conversely, a shrinking M2 can indicate tighter monetary policy or economic contraction. It's measured in billions of U.S. dollars.": return "M2는 지출에 쉽게 접근할 수 있는 모든 형태의 돈을 포함합니다. 연준이 통화 공급량을 증가시키면(양적 완화나 기타 조치를 통해) M2가 상승합니다. 이것은 경제 활동을 자극할 수 있지만 너무 빠르게 성장하면 인플레이션으로 이어질 수 있습니다. 반대로 M2의 축소는 더 긴축적인 통화 정책이나 경제 수축을 나타낼 수 있습니다. 십억 달러 단위로 측정됩니다."
            
            // Unemployment
            case "What is the Unemployment Rate?": return "실업률이란 무엇인가요?"
            case "The Unemployment Rate measures the percentage of the labor force that is jobless and actively seeking employment. It's a key indicator of economic health and labor market conditions.": return "실업률은 일자리가 없고 적극적으로 취업을 구하는 노동력의 비율을 측정합니다. 경제 건강과 노동 시장 상황의 핵심 지표입니다."
            case "Low Unemployment": return "낮은 실업률"
            case "Strong economy, tight labor market": return "강한 경제, 긴축된 노동 시장"
            case "High Unemployment": return "높은 실업률"
            case "Weak economy, excess labor supply": return "약한 경제, 과잉 노동 공급"
            case "Natural Rate": return "자연 실업률"
            case "Typically around 4-5% in healthy economies": return "건강한 경제에서는 일반적으로 약 4-5%"
            case "The unemployment rate is calculated by dividing the number of unemployed people by the total labor force (employed + unemployed). A low unemployment rate indicates a strong job market and healthy economy, but extremely low rates can lead to wage inflation. High unemployment suggests economic weakness and can lead to reduced consumer spending. The Federal Reserve considers unemployment when setting monetary policy, as it relates to both inflation and economic growth.": return "실업률은 실업자 수를 총 노동력(취업자 + 실업자)으로 나누어 계산합니다. 낮은 실업률은 강한 일자리 시장과 건강한 경제를 나타내지만, 극도로 낮은 비율은 임금 인플레이션으로 이어질 수 있습니다. 높은 실업률은 경제 약화를 시사하며 소비자 지출 감소로 이어질 수 있습니다. 연준은 인플레이션과 경제 성장 모두와 관련이 있기 때문에 통화 정책을 설정할 때 실업률을 고려합니다."
            
            // VIX
            case "What is the VIX?": return "VIX란 무엇인가요?"
            case "The VIX (Volatility Index), also known as the 'Fear Index,' measures the market's expectation of 30-day volatility based on S&P 500 index option prices. It's a key gauge of investor fear and market uncertainty.": return "VIX(공포지수)는 S&P 500 지수 옵션 가격을 기반으로 한 30일 변동성에 대한 시장의 기대를 측정합니다. 투자자의 두려움과 시장 불확실성의 핵심 지표입니다."
            case "Low VIX (≤15)": return "낮은 VIX (≤15)"
            case "Low fear, stable markets, bullish sentiment": return "낮은 공포, 안정적 시장, 강세 심리"
            case "High VIX (>30)": return "높은 VIX (>30)"
            case "High fear, volatile markets, risk-off sentiment": return "높은 공포, 변동성 높은 시장, 위험 회피 심리"
            case "Market Indicator": return "시장 지표"
            case "Inverse correlation with stock market performance": return "주식 시장 성과와의 역 상관관계"
            case "The VIX is derived from the implied volatility of S&P 500 index options, representing what traders expect about future market swings. When investors are confident, the VIX stays low; when uncertainty increases, the VIX rises sharply. A VIX below 15 typically indicates complacency and strong risk appetite. A spike above 30 signals panic and flight to safety. Crypto markets often move in inverse correlation with the VIX - when traditional markets stabilize (VIX falls), capital may flow back to risk assets like crypto.": return "VIX는 S&P 500 지수 옵션의 내재 변동성에서 도출되며, 미래 시장 변동에 대한 트레이더들의 예상을 나타냅니다. 투자자들이 자신감 있을 때 VIX는 낮게 유지되고, 불확실성이 증가할 때 VIX는 급격히 상승합니다. 15 이하의 VIX는 일반적으로 안주와 강한 위험 선호를 나타냅니다. 30 이상의 급등은 공황과 안전 자산 선호를 신호합니다. 암호화폐 시장은 종종 VIX와 역 상관관계로 움직입니다 - 전통 시장이 안정화될 때(VIX 하락), 자본이 암호화폐 같은 위험 자산으로 다시 흘러들 수 있습니다."

            // Oil Price
            case "What is Oil Price?": return "원유가격이란 무엇인가요?"
            case "The Oil Price (WTI Crude) is the cost per barrel of West Texas Intermediate crude oil, a primary benchmark for global oil prices. It reflects supply-demand dynamics and geopolitical factors that impact the global economy.": return "원유가격(WTI 유종)은 글로벌 유가의 주요 벤치마크인 웨스트텍사스 중질유의 배럴당 가격입니다. 글로벌 경제에 영향을 미치는 공급-수요 역학과 지정학적 요인을 반영합니다."
            case "Optimal Range ($60-80)": return "최적 범위 ($60-80)"
            case "Stable prices support economic growth": return "안정적 가격은 경제 성장을 지원합니다"
            case "High Oil Prices (>$90)": return "높은 유가 (>$90)"
            case "Inflation pressure, reduces consumer spending": return "인플레이션 압력, 소비자 지출 감소"
            case "Low Oil Prices (<$50)": return "낮은 유가 (<$50)"
            case "Economic weakness signal, deflationary pressure": return "경제 약세 신호, 디플레이션 압력"
            case "Oil prices impact inflation, transportation costs, and manufacturing expenses across the economy. High oil prices can trigger stagflation (high inflation with weak growth), while low prices may indicate recession fears. The price is driven by OPEC production decisions, geopolitical events, supply disruptions, and global economic growth expectations. For crypto investors, elevated oil prices often correlate with inflation concerns that drive investment in alternative assets like Bitcoin.": return "유가는 경제 전반에 걸쳐 인플레이션, 운송비, 제조 비용에 영향을 미칩니다. 높은 유가는 스태그플레이션(높은 인플레이션과 약한 성장)을 촉발할 수 있으며, 낮은 가격은 경기 침체 우려를 나타낼 수 있습니다. 가격은 OPEC 생산 결정, 지정학적 사건, 공급 차질 및 글로벌 경제 성장 기대에 의해 결정됩니다. 암호화폐 투자자들에게는 높은 유가가 비트코인 같은 대체 자산에 대한 투자를 촉진하는 인플레이션 우려와 상관관계가 있습니다."

            // Yield Spread
            case "What is Yield Spread?": return "금리차란 무엇인가요?"
            case "The Yield Spread (T10Y2Y) is the difference between 10-year and 2-year U.S. Treasury yields. It's a critical indicator of economic expectations and is often used as a recession predictor when the curve inverts (negative spread).": return "금리차(T10Y2Y)는 10년물과 2년물 미국 국채 수익률의 차이입니다. 경제 기대의 중요한 지표이며, 수익률 곡선이 역전(음수 스프레드)될 때 경기 침체 예측기로 자주 사용됩니다."
            case "Positive Spread (>0.5%)": return "양의 스프레드 (>0.5%)"
            case "Normal curve, economic growth expected": return "정상 곡선, 경제 성장 예상"
            case "Negative Spread (<0%)": return "음의 스프레드 (<0%)"
            case "Inverted curve, recession warning signal": return "역전된 곡선, 경기 침체 경고 신호"
            case "Recession Predictor": return "경기 침체 예측기"
            case "Inversion has preceded most U.S. recessions": return "역전은 대부분의 미국 경기 침체 앞서 발생했습니다"
            case "Normally, longer-term bonds have higher yields than shorter-term bonds (positive spread). When short-term rates rise above long-term rates due to expected future economic weakness, the curve inverts. This inversion has been a reliable predictor of recession: every inversion in the past 50 years has preceded a downturn. For crypto markets, yield curve inversion often triggers risk-off sentiment, but it can also precede monetary policy shifts (rate cuts) that eventually support alternative assets.": return "일반적으로 장기 채권의 수익률이 단기 채권보다 높습니다(양의 스프레드). 예상되는 미래 경제 약세로 인해 단기 금리가 장기 금리를 초과할 때, 곡선이 역전됩니다. 이 역전은 경기 침체의 신뢰할 수 있는 예측기입니다: 지난 50년간 모든 역전이 경기 침체를 앞서 발생했습니다. 암호화폐 시장의 경우, 수익률 곡선 역전은 종종 위험 회피 심리를 촉발하지만, 결국 대체 자산을 지원하는 통화 정책 변화(금리 인하)를 선행할 수도 있습니다."

            // Break-Even Inflation
            case "What is Break-Even Inflation?": return "기대인플레이션이란 무엇인가요?"
            case "Break-Even Inflation (10Y BE) is the market's expectation of average inflation over the next 10 years, derived from the difference between nominal Treasury yields and TIPS (Treasury Inflation-Protected Securities) yields. It reflects investor inflation expectations.": return "기대인플레이션(10Y BE)은 명목 국채 수익률과 TIPS(국채 인플레이션 연동채) 수익률의 차이에서 도출된 향후 10년 평균 인플레이션에 대한 시장의 기대입니다. 투자자의 인플레이션 기대를 반영합니다."
            case "Optimal Range (1.8-2.3%)": return "최적 범위 (1.8-2.3%)"
            case "Fed target achieved, stable growth": return "연준 목표 달성, 안정적 성장"
            case "Above 2.5%": return "2.5% 이상"
            case "Inflation concerns, may trigger policy tightening": return "인플레이션 우려, 정책 긴축 유발 가능"
            case "Below 1.5%": return "1.5% 미만"
            case "Deflation fears, economic weakness signal": return "디플레이션 우려, 경제 약세 신호"
            case "Market participants buy TIPS to protect against inflation, creating a spread with nominal Treasuries. This spread reflects inflation expectations. When expectations rise above the Fed's 2% target, the central bank may maintain hawkish policies to contain inflation, which pressures risk assets. Conversely, when expectations fall below target, it may signal demand weakness or impending rate cuts. For crypto investors, elevated inflation expectations can support Bitcoin as an inflation hedge, while deflation fears typically trigger broad risk-off sentiment.": return "시장 참여자들은 인플레이션으로부터 보호하기 위해 TIPS를 구매하여 명목 국채와의 스프레드를 만듭니다. 이 스프레드는 인플레이션 기대를 반영합니다. 기대가 연준의 2% 목표를 초과하면, 중앙은행은 인플레이션을 억제하기 위해 매파적 정책을 유지할 수 있으며, 이는 위험 자산에 압박을 줍니다. 반대로 기대가 목표 이하로 떨어지면, 수요 약화나 임박한 금리 인하를 신호할 수 있습니다. 암호화폐 투자자들에게는 높은 인플레이션 기대가 인플레이션 헤지 수단으로서 비트코인을 지원할 수 있으며, 디플레이션 우려는 일반적으로 광범위한 위험 회피 심리를 촉발합니다."

            // Dollar Index
            case "What is the Dollar Index?": return "달러 인덱스란 무엇인가요?"
            case "The U.S. Dollar Index (DXY) measures the value of the U.S. dollar against a basket of foreign currencies, including the Euro, Japanese Yen, British Pound, Canadian Dollar, Swedish Krona, and Swiss Franc. It's a key indicator of dollar strength.": return "미국 달러 인덱스(DXY)는 유로, 일본 엔, 영국 파운드, 캐나다 달러, 스웨덴 크로나, 스위스 프랑을 포함한 외국 통화 바구니에 대한 미국 달러의 가치를 측정합니다. 달러 강도의 핵심 지표입니다."
            case "Rising DXY": return "DXY 상승"
            case "Strong dollar, makes imports cheaper": return "강한 달러, 수입품을 더 저렴하게 만듭니다"
            case "Falling DXY": return "DXY 하락"
            case "Weak dollar, makes exports more competitive": return "약한 달러, 수출을 더 경쟁력 있게 만듭니다"
            case "Global Impact": return "글로벌 영향"
            case "Affects international trade and commodity prices": return "국제 무역과 원자재 가격에 영향을 미칩니다"
            case "The Dollar Index is calculated as a weighted geometric mean of the dollar's value against the basket of currencies. A value above 100 means the dollar is stronger than the baseline (set in 1973), while below 100 means it's weaker. A strong dollar makes U.S. exports more expensive but imports cheaper, while a weak dollar has the opposite effect. The index is closely watched by traders, investors, and policymakers as it impacts global trade, commodity prices (which are often priced in dollars), and emerging market economies.": return "달러 인덱스는 통화 바구니에 대한 달러 가치의 가중 기하 평균으로 계산됩니다. 100보다 높은 값은 달러가 기준선(1973년 설정)보다 강하다는 의미이며, 100보다 낮은 값은 약하다는 의미입니다. 강한 달러는 미국 수출을 더 비싸게 만들지만 수입을 더 저렴하게 만드는 반면, 약한 달러는 반대 효과를 가집니다. 이 지수는 글로벌 무역, 원자재 가격(종종 달러로 표시됨), 신흥 시장 경제에 영향을 미치기 때문에 트레이더, 투자자 및 정책 입안자들이 면밀히 관찰합니다."

            // Funding Rate
            case "What is Funding Rate?": return "펀딩비란 무엇인가요?"
            case "Funding Rate is the periodic interest that traders with leveraged positions pay to each other in the futures market. It keeps perpetual futures prices aligned with spot prices and reflects the market's sentiment about future price direction.": return "펀딩비는 선물 시장에서 레버리지 포지션을 보유한 트레이더들이 서로에게 지불하는 주기적 이자입니다. 무기한 선물 가격을 현물 가격과 일치시키고 미래 가격 방향에 대한 시장의 심리를 반영합니다."
            case "Positive Rate": return "양의 펀딩비"
            case "Longs pay shorts (market bullish), contrarian signal": return "롱이 숏에 지불 (시장 강세), 역추세 신호"
            case "Negative Rate": return "음의 펀딩비"
            case "Shorts pay longs (market bearish), potential bounce": return "숏이 롱에 지불 (시장 약세), 반등 가능성"
            case "Extreme Rates": return "극단적 펀딩비"
            case "Very high rates indicate overlevered positions": return "매우 높은 비율은 과도한 레버리지 포지션을 나타냅니다"
            case "Traders pay funding rates every 8 hours on Binance. When rates are positive and high, long traders pay a lot to maintain positions, creating a contrarian signal that shorts are being squeezed out. When rates are negative, short traders pay longs, suggesting oversold conditions. Monitoring funding rates helps traders identify potential reversals and extreme market conditions.": return "트레이더들은 바이낸스에서 8시간마다 펀딩비를 지불합니다. 비율이 양수이고 높을 때, 롱 트레이더들은 포지션을 유지하기 위해 많은 비용을 지불하여 숏이 청산되고 있다는 역추세 신호를 만듭니다. 비율이 음수일 때, 숏 트레이더들이 롱에 지불하므로 과매도 상태를 시사합니다. 펀딩비를 모니터링하면 트레이더들이 잠재적 반전과 극단적 시장 상황을 식별하는 데 도움이 됩니다."

            // Active Addresses
            case "What are Active Addresses?": return "활성주소란 무엇인가요?"
            case "Active Addresses measures the number of unique Bitcoin addresses that had some activity (sending or receiving BTC) in the last 24 hours. It's a key indicator of Bitcoin network adoption and usage intensity.": return "활성주소는 지난 24시간 동안 어떤 활동(BTC 송수신)을 한 고유한 비트코인 주소의 수를 측정합니다. 비트코인 네트워크 채택과 사용 강도의 핵심 지표입니다."
            case "Rising Addresses": return "증가하는 주소"
            case "Increasing network adoption and activity": return "증가하는 네트워크 채택 및 활동"
            case "Falling Addresses": return "감소하는 주소"
            case "Decreasing network usage, potential weakness": return "감소하는 네트워크 사용, 약세 신호"
            case "Network Health": return "네트워크 건강"
            case "Reflects actual Bitcoin transaction volume": return "실제 비트코인 거래량을 반영합니다"
            case "Each address represents a unique wallet or participant on the network. Rising active addresses suggest growing network adoption and user engagement. When compared to the 30-day average, surges in active addresses can indicate capitulation (panic selling) or renewed interest. This metric is useful for confirming market movements - price increases with rising addresses suggest genuine growth, while price increases with falling addresses may be driven by speculation rather than real adoption.": return "각 주소는 네트워크의 고유한 지갑 또는 참여자를 나타냅니다. 증가하는 활성주소는 증가하는 네트워크 채택과 사용자 참여를 시사합니다. 30일 평균과 비교할 때, 활성주소의 급증은 시장 포기(공황 매도) 또는 새로운 관심을 나타낼 수 있습니다. 이 지표는 시장 움직임을 확인하는 데 유용합니다 - 증가하는 주소와 함께 가격 상승은 진정한 성장을 시사하는 반면, 감소하는 주소와 함께 가격 상승은 실제 채택보다는 투기로 인한 것일 수 있습니다."

            // MVRV
            case "What is MVRV?": return "MVRV란 무엇인가요?"
            case "MVRV (Market Value to Realized Value) is a ratio that compares the current market value of Bitcoin to its realized value. Market value is the current market cap (price × supply), while realized value represents the average price at which all bitcoins were last moved on-chain.": return "MVRV(시장가치/실현가치)는 현재 비트코인의 시장 가치를 실현 가치와 비교하는 비율입니다. 시장 가치는 현재 시가총액(가격 × 공급량)이고, 실현 가치는 모든 비트코인이 마지막으로 체인상에서 이동된 평균 가격을 나타냅니다."
            case "MVRV > 1.0": return "MVRV > 1.0"
            case "Market cap above average cost basis (profit)": return "시장 가치가 평균 매수가보다 높음 (수익)"
            case "MVRV < 1.0": return "MVRV < 1.0"
            case "Market cap below average cost basis (loss)": return "시장 가치가 평균 매수가보다 낮음 (손실)"
            case "Market Top Indicator": return "시장 고점 신호"
            case "Extreme MVRV readings can indicate overheated markets": return "극도의 MVRV 수치는 과열된 시장을 나타낼 수 있습니다"
            case "Value Accumulation": return "가치 축적"
            case "Low MVRV suggests long-term holders at a loss": return "낮은 MVRV는 손실을 본 장기 보유자를 시사합니다"
            case "MVRV is calculated by dividing the current market cap by the realized cap. When MVRV is high (above 3-4), the market may be overheated with investors holding significant profits, which historically has preceded market corrections. Conversely, when MVRV is low (below 1), it suggests that most holders are underwater, potentially indicating a market bottom or buying opportunity. MVRV helps identify periods when long-term investors are most likely to take profits or when capitulation is occurring.": return "MVRV는 현재 시가총액을 실현 가치로 나누어 계산합니다. MVRV가 높을 때(3-4 이상), 투자자들이 상당한 수익을 보유한 과열된 시장일 수 있으며, 역사적으로 시장 조정이 뒤따랐습니다. 반대로 MVRV가 낮을 때(1 미만), 대부분의 보유자가 손실을 본 상태를 시사하며, 이는 시장 바닥이나 매수 기회를 나타낼 수 있습니다. MVRV는 장기 투자자들이 이익을 실현할 가능성이 가장 높거나 시장 포기(capitulation)가 발생하는 시기를 식별하는 데 도움이 됩니다."

            default: return key
            }
        default:
            return key
        }
    }
}

// MARK: - View Extension
extension View {
    func localized(_ key: String, category: LocalizationCategory = .common) -> String {
        let localization = Localization.shared
        switch category {
        case .common:
            return localization.common(key)
        case .dashboard:
            return localization.dashboard(key)
        case .cryptoMetric:
            return localization.cryptoMetric(key)
        case .macroMetric:
            return localization.macroMetric(key)
        case .settings:
            return localization.settings(key)
        }
    }
}

enum LocalizationCategory {
    case common
    case dashboard
    case cryptoMetric
    case macroMetric
    case settings
}

