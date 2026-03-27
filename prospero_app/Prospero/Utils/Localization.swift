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
            case "AI Analysis": return "AI 분석"
            case "AI Analysis Description": return "Crypto와 Macro 데이터를 분석하여 투자 점수를 제공합니다."
            case "Settings": return "설정"
            case "Language": return "언어"
            default: return key
            }
        default:
            switch key {
            case "AI Analysis Description": return "Analyze Crypto and Macro data to provide investment scores."
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
            case "Open Interest": return "개방 관심도"
            case "OI + Price": return "OI + 가격"
            case "Interest Rate": return "기준금리"
            case "M2 Supply": return "M2 통화량"
            case "Dollar Index": return "달러인덱스"
            case "CPI": return "소비자물가지수"
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
            case "Investment Rationale": return "Investment Rationale"
            case "Unable to calculate score.": return "Unable to calculate score."
            case "CPI": return "CPI"
            default: return key
            }
        }
    }
    
    // MARK: - Crypto Metrics
    func cryptoMetric(_ key: String) -> String {
        switch language {
        case "KOR":
            switch key {
            case "Bitcoin (BTC)": return "비트코인 (BTC)"
            case "Price": return "가격"
            case "Fear & Greed Index": return "공포탐욕 지수"
            case "Market Sentiment": return "시장 심리"
            case "New Addresses": return "신규 주소"
            case "Last 24h": return "최근 24시간"
            case "Open Interest": return "미결제 약정"
            case "Futures Market": return "선물 시장"
            case "Long/Short Ratio": return "롱/숏 비율"
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
        switch language {
        case "KOR":
            switch key {
            case "Interest Rate": return "금리"
            case "Federal Funds Rate": return "연방기금금리"
            case "10Y Treasury": return "10년물 국채"
            case "Yield": return "수익률"
            case "CPI": return "소비자물가지수"
            case "Consumer Price Index": return "소비자물가지수"
            case "M2 Money Supply": return "M2 통화량"
            case "Billions USD": return "십억 달러"
            case "Unemployment": return "실업률"
            case "Rate": return "비율"
            case "Dollar Index": return "달러 인덱스"
            case "DXY": return "DXY"
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
            case "Market Sentiment": return "시장 심리"
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

