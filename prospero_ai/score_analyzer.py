#
# score_analyzer.py - v5.0
# Prospero AI - Python 기반 점수 계산 + LLM 연결 해석 분석
#
# v5.0 개선사항:
# - Cross-indicator analysis (지표 간 관계 분석)
# - Signal rationale (신호 결정 근거)
# - Bullish/Bearish factors (상승/약세 요소 목록)
# - Confidence label + reason (신뢰도 판정)
# - Python 기반 경량 Confidence 계산
# - 향상된 프롬프트 (연결 해석 중심)

import json
import os
import math
from typing import Dict
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage

# ============================================================================
# 상수 및 설정
# ============================================================================

# Max adjustment values for regime (더 정교한 강도 기반 조정)
REGIME_ADJUSTMENTS_MAX = {
    "dip_buy": 6.0,          # 역발상 최고 매수 기회
    "trend_follow": 3.0,     # 추세 추종 시장
    "neutral": 0.0,
    "risk_off": -4.0,        # 위험회피 환경
    "euphoria": -6.0         # 고점 경고
}

# LLM System Prompt (연결 해석 중심)
SYSTEM_PROMPT = """당신은 기관투자자 산하 암호화폐 분석 애널리스트입니다.
이미 계산된 투자 점수에 기반하여 **연결된 정성적 분석**을 작성하세요.

[핵심 원칙]
- 점수는 절대 변경하지 마세요 (Python에서 확정됨)
- 지표 간의 관계와 충돌을 분석하세요
- 왜 이 신호(Buy/Hold/Sell)인지 명확히 설명하세요
- 신호를 뒷받침하는 / 반박하는 요소를 구분하세요
- 실제 지표값을 기반으로 작성 (점수 레이블만 아님)

[한글 용어 정의 - 반드시 이 용어를 사용하세요]
- BTC 추세 = BTC 변화율 (30일, 7일)
- 공포탐욕지수 = Fear & Greed Index
- 롱숏비율 = Long/Short Ratio
- 미결제약정 = Open Interest (OI)
  → "OI + 가격" 으로 표현할 때도 있음
  → "개방이자율", "개방 관심도" 같은 잘못된 표현 금지
- MVRV = Market Value to Realized Value (영문 그대로)
- 기준금리 = Interest Rate (Federal Funds Rate)
- 10년물금리 = 10-Year Treasury Yield
  → "10년물 국채수익률", "10년물 국채" 로도 표현 가능
- M2 통화량 = M2 Money Supply
- 달러인덱스 = Dollar Index (DXY)
  → "달러 인덱스" 로도 표현 가능
- 실업률 = Unemployment Rate
- CPI = Consumer Price Index (인플레이션)
- 펀딩비 = Funding Rate (선물 자금 조달 비율); 음수 = 숏 우위 = 역발상 매수
- 활성주소 = Active Addresses (BTC 네트워크 활성도)
- VIX = Volatility Index (공포지수); 낮을수록 안정
- WTI유가 = Oil Price (USD/배럴); 과도 상승 = 인플레이션 압박
- 금리차 = Yield Spread (T10Y2Y); 역전 = 경기침체 선행 신호
- 기대인플레이션 = Break-Even Inflation (10Y BE); 2% 근처 최적

[분석 패턴 예시]
- 공포탐욕지수 낮음 + BTC 하락 + 미결제약정 감소 => 레버리지 정리/저가 매수 신호
- BTC 상승 + 미결제약정 급증 => 레버리지 과열 (위험 신호)
- BTC 약함 + 거시경제 개선 => 하단 제한적 (상승 베이스)
- BTC 강함 + 고기준금리 + 강달러인덱스 => 랠리 취약성 (유동성 부족)
- 펀딩비 음수 + 공포탐욕지수 낮음 => 레버리지 정리 완료, 강한 역발상 신호
- VIX 급등 + 원유 고가 => 스태그플레이션 우려, 위험자산 회피
- 금리차 역전 + 기대인플레이션 상승 => 연준 딜레마, 긴축 유지 가능성

[응답 구조]
{
  "cross_indicator_analysis": "150-200자 지표 간 관계 분석 (현상+해석+의미, 가장 의미있는 2-3개 연관성 상세)",
  "cross_indicator_analysis_en": "150-200 chars. Detailed analysis of indicator relationships in English",

  "signal_rationale": "150-200자 '왜 이 신호인가' 명확한 설명 (근거 + 신호 도출 과정)",
  "signal_rationale_en": "150-200 chars. Clear explanation of why this signal was determined",

  "bullish_factors": ["상승 요소 1 (구체적 조건/수치)", "상승 요소 2", "상승 요소 3"],
  "bullish_factors_en": ["bullish factor 1 (specific conditions)", "bullish factor 2", "bullish factor 3"],
  "bearish_factors": ["약세 요소 1 (구체적 조건/수치)", "약세 요소 2"],
  "bearish_factors_en": ["bearish factor 1 (specific conditions)", "bearish factor 2"],

  "confidence_reason": "100-150자 신뢰도 설명 (얼마나 많은 지표가 일치하는가)",
  "confidence_reason_en": "100-150 chars. Explanation of why confidence is High/Medium/Low",

  "indicator_explanations": {
    "btc_trend": "현상+의미 2~3문장",
    "fear_greed": "...",
    "long_short": "...",
    "open_interest": "...",
    "mvrv": "...",
    "funding_rate": "...",
    "active_addresses": "...",
    "interest_rate": "...",
    "treasury10y": "...",
    "m2": "...",
    "dollar_index": "...",
    "unemployment": "...",
    "cpi": "...",
    "vix": "...",
    "oil_price": "...",
    "yield_spread": "...",
    "break_even_inflation": "...",
    "interaction": "..."
  },
  "indicator_explanations_en": { ... 동일 17개 ... }
}

[작성 원칙]
- cross_indicator_analysis: 가장 중요한 필드. 지표 간 관계를 구체적으로 설명. 150-200자 이상 작성.
  예: "BTC는 30일간 +5% 상승했으나 미결제약정은 -3% 감소. 이는 기존 롱 포지션 청산 신호. 동시에 공포탐욕지수가 35로 낮아 바닥권 자산 정리 국면. 거시경제는 기준금리 4.5% 유지로 약세 환경 지속."
- signal_rationale: "왜" 이 신호인가를 명확히. 150-200자.
  예: "총점 62점 + 강도 0.78 추세추종 국면. 암호화폐 지표는 긍정적(57점)이나 거시경제 약세(45점) 제약. 따라서 단기 Buy 신호이나 거시환경 회전 전까지 상승 제한적."
- bullish_factors / bearish_factors: 구체적인 수치와 조건 포함. 일반적 표현 피함.
- confidence_reason: 지표 일치도 명시. "12개 중 8개 상승 지지" 같은 구체적 표현.
"""

HUMAN_TEMPLATE = """[투자 점수 및 국면]
총점: {total_score}/100 ({signal_type})
기본점수: {base_score:.1f}
시장국면: {regime} (강도: {regime_strength:.2f})

[조정값]
국면조정: {regime_adjustment:+.1f}점
상호작용: {interaction_score:+.1f}점

[지표 점수 (17개)]
{indicator_scores_json}

[원본 데이터]
암호화폐: {crypto_data_json}
거시경제: {macro_data_json}

[필수 분석 항목]

1. **cross_indicator_analysis (한국어)**: 150-200자
   → 지표 간의 가장 의미있는 2-3개 관계를 분석하세요
   → 현상 + 해석 + 시장 의미를 명확하게
   예: "BTC는 상승했으나 OI는 감소 → 기존 포지션 청산. Fear&Greed 30 + OI감소 → Dip-buy 국면 신호."

2. **cross_indicator_analysis_en (English)**: 150-200 chars
   → Same structure in English

3. **signal_rationale (한국어)**: 150-200자
   → **왜** {signal_type} 신호인가를 명확하게 설명
   → 어떤 지표들이 이 신호를 결정했는가를 구체적으로
   예: "크립토 점수 75 + 매크로 45. 강한 크립토 대비 약한 매크로가 상승 제약 → Buy이나 매크로 반전 필요"

4. **signal_rationale_en (English)**: 150-200 chars

5. **bullish_factors (한국어)**: 2-4개 리스트
   → 각 요소마다 구체적인 조건/수치 포함
   예: ["BTC 30일 +12% 상승", "공포탐욕지수 35 (극도 공포)", "MVRV 1.2 (저평가)", "OI -5% 감소 (포지션 정리)"]

6. **bullish_factors_en (English)**: Same format

7. **bearish_factors (한국어)**: 2-4개 리스트
   → 신호를 약화시키는 요소들을 구체적으로

8. **bearish_factors_en (English)**: Same format

9. **confidence_reason (한국어)**: 100-150자
   → 신뢰도가 {confidence_label}인 이유를 명확하게
   → 지표 일치도를 수치로 제시 (예: "16개 중 12개 상승 지지")

10. **confidence_reason_en (English)**: 100-150 chars

11. **indicator_explanations (한국어)**: 17개 지표 각각 2~3문장
    - btc_trend, fear_greed, long_short, open_interest, mvrv, funding_rate, active_addresses, interest_rate, treasury10y, m2, dollar_index, unemployment, cpi, vix, oil_price, yield_spread, break_even_inflation, interaction

12. **indicator_explanations_en (English)**: 동일 17개

[중요]
- 모든 설명은 **실제 지표값**으로 근거 제시
- 점수 레이블(High/Low)만 사용하지 말 것
- 일반적인 표현 피하기 (예: "변동성이 높다" → "OI가 30% 증가했고 롱숏비율이 1.5로 상향")
- 각 필드는 정확히 JSON 형식으로 반환
- 빠진 필드 없이 모두 작성"""


# ============================================================================
# 연속 점수 계산 함수들 (기존 유지)
# ============================================================================

def _score_btc_trend(change30d: float, change7d: float) -> float:
    """BTC 30일 가격 추세 (0~10)"""
    t = -change30d / 20.0
    sigmoid = 1.0 / (1.0 + math.exp(-t))
    score = sigmoid * 10.0

    if change30d < -30 and change7d < -15:
        score = max(0, score - 1.0)

    return round(min(10, max(0, score)), 2)


def _score_fear_greed(current: float, avg30d: float) -> float:
    """공포탐욕지수 (0~18) - v3.0 배점 조정"""
    weighted = current * 0.6 + avg30d * 0.4
    inverted = 100.0 - weighted
    score = (inverted / 100.0) ** 0.8 * 18.0

    return round(min(18, max(0, score)), 2)


def _score_long_short(ratio: float) -> float:
    """롱숏비율 (0~14) - v3.0 배점 조정"""
    score = 14.0 * max(0.0, (1.5 - ratio) / (1.5 - 0.7))
    return round(min(14, max(0, score)), 2)


def _score_open_interest(price_change: float, oi_change: float) -> float:
    """OI + 가격 (0~8) - v3.0 배점 조정"""
    if price_change < 0 and oi_change < 0:
        base = 6.4  # 건강한 정리
    elif price_change > 0 and oi_change < 0:
        base = 4.8  # 숏커버링
    elif price_change > 0 and oi_change > 0:
        base = 4.0  # 레버리지 과열
    elif price_change < 0 and oi_change > 0:
        base = 1.6  # 숏 추가
    else:
        base = 4.0

    if abs(price_change) > 10 and abs(oi_change) > 10:
        base += 0.8 if base > 4 else -0.8

    return round(min(8, max(0, base)), 2)


def _score_interest_rate(rate_current: float, rate_30d_ago: float) -> float:
    """기준금리 (0~8) - v3.0 배점 조정"""
    if rate_current <= 1.0:
        level_score = 7.2
    elif rate_current <= 2.5:
        level_score = 7.2 - (rate_current - 1.0) / 1.5 * 2.4
    elif rate_current <= 4.0:
        level_score = 4.8 - (rate_current - 2.5) / 1.5 * 2.4
    elif rate_current <= 5.0:
        level_score = 2.4 - (rate_current - 4.0) * 1.6
    else:
        level_score = 0.8

    trend_adjustment = 0
    if rate_30d_ago != 0:
        if rate_current < rate_30d_ago:
            trend_adjustment = 0.8
        elif rate_current > rate_30d_ago:
            trend_adjustment = -0.8

    return round(min(8, max(0, level_score + trend_adjustment)), 2)


def _score_treasury10y(treasury10y: float) -> float:
    """10년물 금리 수준 (0~5) - v3.0 spread 조정 제거, 배점 조정"""
    if treasury10y < 3.0:
        level_score = 3.75
    elif treasury10y <= 4.0:
        level_score = 3.75 - (treasury10y - 3.0) / 1.0 * 0.625
    elif treasury10y <= 5.0:
        level_score = 3.125 - (treasury10y - 4.0) / 1.0 * 1.25
    else:
        level_score = 0.625

    return round(min(5, max(0, level_score)), 2)


def _score_m2(m2_current: float, m2_30d_ago: float) -> float:
    """M2 통화량 (0~6) - v3.0 배점 조정"""
    if m2_30d_ago == 0:
        return 3.0

    percent_change = ((m2_current - m2_30d_ago) / m2_30d_ago) * 100

    if percent_change > 1.0:
        score = 6.0
    elif percent_change > 0.3:
        score = 3.0 + (percent_change - 0.3) / 0.7 * 3.0
    elif percent_change >= 0:
        score = 1.5 + percent_change / 0.3 * 1.5
    else:
        score = max(0, 1.5 + percent_change * 1.5)

    return round(min(6, max(0, score)), 2)


def _score_dollar_index(dxy_current: float, dxy_30d_ago: float) -> float:
    """달러인덱스 (0~5) - v3.0 배점 조정"""
    if dxy_current < 95:
        level_score = 4.29
    elif dxy_current <= 100:
        level_score = 4.29 - (dxy_current - 95) / 5.0 * 0.714
    elif dxy_current <= 105:
        level_score = 3.57 - (dxy_current - 100) / 5.0 * 1.429
    elif dxy_current <= 110:
        level_score = 2.14 - (dxy_current - 105) / 5.0 * 1.429
    else:
        level_score = 0.0

    trend_adjustment = 0
    if dxy_30d_ago != 0 and dxy_current < dxy_30d_ago:
        trend_adjustment = 0.714
    elif dxy_30d_ago != 0 and dxy_current > dxy_30d_ago:
        trend_adjustment = -0.714

    return round(min(5, max(0, level_score + trend_adjustment)), 2)


def _score_unemployment(unemp_current: float, unemp_30d_ago: float) -> float:
    """실업률 (0~3) - v3.0 배점 조정"""
    change = unemp_current - unemp_30d_ago
    score = 1.875 - change * 2.25

    return round(min(3, max(0, score)), 2)


def _score_mvrv(mvrv_current: float, mvrv_avg30d: float) -> float:
    """MVRV - Market Value to Realized Value (0~4) - v3.0 배점 조정"""
    weighted = mvrv_current * 0.6 + mvrv_avg30d * 0.4

    if weighted <= 1.0:
        score = 4.0  # 저평가 - 매수 신호
    elif weighted <= 1.5:
        score = 4.0 - (weighted - 1.0) / 0.5 * 1.6  # 4.0 ~ 2.4
    elif weighted <= 2.0:
        score = 2.4 - (weighted - 1.5) / 0.5 * 1.6  # 2.4 ~ 0.8
    else:
        score = 0.0  # 고평가 - 매도 신호

    return round(min(4, max(0, score)), 2)


def _score_cpi(cpi_value: float) -> float:
    """CPI (0~2) - v3.0 배점 조정"""
    if cpi_value < 0 or cpi_value > 20:
        cpi_value = 2.5

    if cpi_value <= 2.0:
        score = 2.0
    elif cpi_value <= 4.5:
        score = 2.0 - (cpi_value - 2.0) / 2.5 * 2.0
    else:
        score = 0.0

    return round(min(2, max(0, score)), 2)


def _score_funding_rate(funding_rate: float) -> float:
    """펀딩비 역발상 점수 (0~4)

    funding_rate: decimal (예: -0.000008 = -0.0008%)
    음수(숏이 롱에게 지불) = 역발상 매수 신호 = 높은 점수
    """
    rate_pct = funding_rate * 100

    if rate_pct <= -0.05:
        score = 4.0
    elif rate_pct <= -0.01:
        score = 3.0 + ((-rate_pct - 0.01) / 0.04)
    elif rate_pct < 0:
        score = 2.5 + ((-rate_pct) / 0.01) * 0.5
    elif rate_pct == 0:
        score = 2.0
    elif rate_pct <= 0.01:
        score = 2.0 - (rate_pct / 0.01) * 1.0
    elif rate_pct <= 0.05:
        score = 1.0 - ((rate_pct - 0.01) / 0.04)
    else:
        score = 0.0

    return round(min(4, max(0, score)), 2)


def _score_active_addresses(current: int, avg30d: float) -> float:
    """활성 주소 수 점수 (0~2)

    30일 평균 대비 변화율로 평가
    증가 = 네트워크 활성도 상승 = 긍정적
    """
    if avg30d <= 0:
        return 1.0

    change_pct = (current - avg30d) / avg30d * 100

    if change_pct >= 10:
        score = 2.0
    elif change_pct >= 0:
        score = 1.0 + change_pct / 10
    elif change_pct >= -10:
        score = 1.0 - abs(change_pct) / 10 * 0.5
    else:
        score = max(0, 0.5 - (abs(change_pct) - 10) / 10 * 0.5)

    return round(min(2, max(0, score)), 2)


def _score_vix(vix: float) -> float:
    """VIX 변동성지수 점수 (0~4)

    낮을수록 위험자산(크립토) 우호 환경
    """
    if vix <= 15:
        score = 4.0
    elif vix <= 20:
        score = 4.0 - (vix - 15) / 5 * 1.0
    elif vix <= 25:
        score = 3.0 - (vix - 20) / 5 * 1.0
    elif vix <= 30:
        score = 2.0 - (vix - 25) / 5 * 1.5
    elif vix <= 40:
        score = 0.5 - (vix - 30) / 10 * 0.5
    else:
        score = 0.0

    return round(min(4, max(0, score)), 2)


def _score_oil_price(oil_price: float) -> float:
    """WTI 원유가격 점수 (0~2)

    적정가(60~80 USD): 경기 건강 신호
    과도하게 높음(90+): 인플레이션 압박
    """
    if 60 <= oil_price <= 80:
        score = 2.0
    elif 50 <= oil_price < 60:
        score = 1.5 + (oil_price - 50) / 10 * 0.5
    elif 80 < oil_price <= 90:
        score = 2.0 - (oil_price - 80) / 10 * 0.5
    elif 40 <= oil_price < 50:
        score = 1.0 + (oil_price - 40) / 10 * 0.5
    elif 90 < oil_price <= 100:
        score = 1.5 - (oil_price - 90) / 10 * 0.5
    elif oil_price < 40:
        score = max(0, 1.0 - (40 - oil_price) / 20)
    else:
        score = max(0, 1.0 - (oil_price - 100) / 20)

    return round(min(2, max(0, score)), 2)


def _score_yield_spread(yield_spread: float) -> float:
    """T10Y2Y 금리차 점수 (0~3)

    양수(정상): 경기 확장 기대
    음수(역전): 경기침체 선행 신호
    """
    if yield_spread >= 1.5:
        score = 3.0
    elif yield_spread >= 0.5:
        score = 2.5 + (yield_spread - 0.5) / 1.0 * 0.5
    elif yield_spread >= 0.0:
        score = 1.5 + yield_spread / 0.5 * 1.0
    elif yield_spread >= -0.5:
        score = 1.5 - abs(yield_spread) / 0.5 * 0.5
    elif yield_spread >= -1.5:
        score = 1.0 - (abs(yield_spread) - 0.5) / 1.0 * 0.5
    else:
        score = max(0, 0.5 - (abs(yield_spread) - 1.5) * 0.3)

    return round(min(3, max(0, score)), 2)


def _score_break_even_inflation(bei: float) -> float:
    """기대인플레이션(10Y BE) 점수 (0~2)

    Fed 목표 2% 근처가 최적
    높을수록 긴축 압박
    """
    if 1.8 <= bei <= 2.3:
        score = 2.0
    elif 2.3 < bei <= 2.5:
        score = 2.0 - (bei - 2.3) / 0.2 * 0.5
    elif 1.5 <= bei < 1.8:
        score = 2.0 - (1.8 - bei) / 0.3 * 0.5
    elif 2.5 < bei <= 3.0:
        score = 1.5 - (bei - 2.5) / 0.5 * 1.0
    elif 1.0 <= bei < 1.5:
        score = 1.5 - (1.5 - bei) / 0.5 * 1.0
    elif bei > 3.0:
        score = max(0, 0.5 - (bei - 3.0) * 0.5)
    else:
        score = 0.0

    return round(min(2, max(0, score)), 2)


# ============================================================================
# Regime Detection with Strength (v4.1 개선)
# ============================================================================

def detect_regime(crypto_values: Dict, macro_values: Dict) -> Dict:
    """시장 국면 감지 + 강도 계산

    Returns:
        {
            "regime": "dip_buy" | "trend_follow" | "risk_off" | "euphoria" | "neutral",
            "strength": 0.0~1.0 (확률값)
        }
    """
    btc_change30d = crypto_values.get("btc_change30d", 0)
    fear_greed = crypto_values.get("fear_greed_current", 50)
    oi_change30d = crypto_values.get("oi_change30d", 0)
    interest_rate = macro_values.get("interest_rate_current", 3.0)
    dxy_current = macro_values.get("dxy_current", 100)
    dxy_30d_ago = macro_values.get("dxy_30d_ago", 100)

    dxy_trend = dxy_current - dxy_30d_ago

    # Dip Buy: BTC 급락 + 극도 공포 + OI 감소 + DXY 안정
    dip_buy_score = 0.0
    if btc_change30d < -15:
        dip_buy_score += 0.3
    if fear_greed < 30:
        dip_buy_score += 0.3
    if oi_change30d < 0:
        dip_buy_score += 0.2
    if dxy_trend <= 1:
        dip_buy_score += 0.2
    dip_buy_strength = min(1.0, dip_buy_score)

    # Euphoria: BTC 급등 + 극도 탐욕 + OI 증가
    euphoria_score = 0.0
    if btc_change30d > 25:
        euphoria_score += 0.35
    if fear_greed > 75:
        euphoria_score += 0.35
    if oi_change30d > 15:
        euphoria_score += 0.3
    euphoria_strength = min(1.0, euphoria_score)

    # Risk Off: 고금리 + 강달러 + 달러 상승 추세
    risk_off_score = 0.0
    if interest_rate > 4.5:
        risk_off_score += 0.3
    if dxy_current > 103:
        risk_off_score += 0.3
    if dxy_trend > 1:
        risk_off_score += 0.4
    risk_off_strength = min(1.0, risk_off_score)

    # Trend Follow: BTC 중등 상승 + 공포탐욕 중립 상향
    trend_follow_score = 0.0
    if 5 < btc_change30d < 30:
        trend_follow_score += 0.3
    if 50 <= fear_greed <= 75:
        trend_follow_score += 0.3
    if 0 <= oi_change30d <= 20:
        trend_follow_score += 0.4
    trend_follow_strength = min(1.0, trend_follow_score)

    # Regime 결정 (가장 높은 score)
    scores = {
        "dip_buy": dip_buy_strength,
        "euphoria": euphoria_strength,
        "risk_off": risk_off_strength,
        "trend_follow": trend_follow_strength,
        "neutral": 0.5  # 기본값
    }

    regime = max(scores, key=scores.get)
    strength = scores[regime]

    # neutral로 갈 조건 (모든 강도가 약함)
    if strength < 0.4:
        regime = "neutral"
        strength = 0.5

    return {"regime": regime, "strength": strength}


def calculate_interaction_score(btc_change30d: float, macro_scores: Dict) -> float:
    """상호작용 점수 (±3) - 축소된 역할

    BTC 방향성 x Macro 환경만 고려
    """
    macro_total = sum(macro_scores.values())
    macro_ratio = (macro_total / 40.0) * 100  # 0~40 범위를 0~100으로

    if btc_change30d < 0 and macro_ratio >= 55:
        interaction = 3.0   # 약세인데 매크로 강함 = 매수 신호
    elif btc_change30d > 0 and macro_ratio >= 55:
        interaction = 1.5   # 강세+매크로 강함 = 약한 추가 상승
    elif 45 <= macro_ratio < 55:
        interaction = 0.5   # 중립 환경
    elif btc_change30d > 0 and macro_ratio < 45:
        interaction = -2.0  # 강세인데 매크로 약함 = 취약
    else:
        interaction = 0.0

    return round(interaction, 2)


def compute_confidence_label(indicator_scores: Dict, final_score: float, regime_strength: float) -> Dict:
    """경량의 Confidence 판정 (High / Medium / Low)

    지표들이 최종 신호 방향과 일치하는 정도를 평가
    Returns: {"label": "High" | "Medium" | "Low", "aligned_count": int, "conflicted_count": int}
    """
    # 신호 방향 판정
    if final_score >= 58:
        signal_direction = "bullish"
    elif final_score >= 38:
        signal_direction = "neutral"
    else:
        signal_direction = "bearish"

    # 각 지표의 방향 판정 (각 지표 max의 절반 기준) - v3.0 신규 지표 포함
    crypto_bullish = [
        indicator_scores.get("btc_trend_score", 5) > 5,
        indicator_scores.get("fear_greed_score", 9) > 9,        # 18/2=9
        indicator_scores.get("long_short_score", 7) > 7,
        indicator_scores.get("open_interest_score", 4) > 4,      # 8/2=4
        indicator_scores.get("funding_rate_score", 2) > 2,       # NEW: 4/2=2
        indicator_scores.get("active_addresses_score", 1) > 1,   # NEW: 2/2=1
    ]

    macro_bullish = [
        indicator_scores.get("interest_rate_score", 4) > 4,      # 8/2=4
        indicator_scores.get("treasury10y_score", 2.5) > 2.5,    # 5/2=2.5
        indicator_scores.get("m2_score", 3) > 3,                 # 6/2=3
        indicator_scores.get("dollar_index_score", 2.5) > 2.5,   # 5/2=2.5
        indicator_scores.get("unemployment_score", 1.5) > 1.5,   # 3/2=1.5
        indicator_scores.get("cpi_score", 1) > 1,                # 2/2=1
        indicator_scores.get("vix_score", 2) > 2,                # NEW: 4/2=2
        indicator_scores.get("oil_price_score", 1) > 1,          # NEW: 2/2=1
        indicator_scores.get("yield_spread_score", 1.5) > 1.5,   # NEW: 3/2=1.5
        indicator_scores.get("break_even_inflation_score", 1) > 1, # NEW: 2/2=1
    ]

    all_bullish = crypto_bullish + macro_bullish
    bullish_count = sum(all_bullish)
    total_indicators = len(all_bullish)
    bearish_count = total_indicators - bullish_count

    # 신호 방향과 지표 일치도 평가
    if signal_direction == "bullish":
        alignment = bullish_count / total_indicators
    elif signal_direction == "bearish":
        alignment = bearish_count / total_indicators
    else:
        alignment = 0.5  # 중립: 일치도 50%

    # Regime strength도 고려 (강도가 약하면 confidence 낮음)
    strength_factor = regime_strength  # 0.0~1.0

    # 최종 confidence
    combined_confidence = (alignment * 0.7 + strength_factor * 0.3)

    if combined_confidence >= 0.65:
        label = "High"
    elif combined_confidence >= 0.45:
        label = "Medium"
    else:
        label = "Low"

    return {
        "label": label,
        "aligned_count": bullish_count if signal_direction == "bullish" else bearish_count,
        "conflicted_count": bearish_count if signal_direction == "bullish" else bullish_count,
        "alignment_ratio": round(alignment, 2),
        "strength_factor": round(strength_factor, 2)
    }


# ============================================================================
# 헬퍼 함수
# ============================================================================

def _ensure_field(obj: Dict, key: str, default_value) -> None:
    """Dict에 필드가 없으면 기본값으로 설정 (In-place)"""
    if key not in obj or obj[key] is None:
        obj[key] = default_value


# ============================================================================
# ScoreAnalyzer 클래스
# ============================================================================

class ScoreAnalyzer:
    def __init__(self, model: str = "gpt-4-turbo"):
        self.llm = ChatOpenAI(model=model, temperature=0.7)

    def analyze(self, date: str, crypto_data_json: str, macro_data_json: str, score_data: Dict = None) -> Dict:
        """종합 분석

        Args:
            score_data: format_for_analyzer()가 반환한 current/30d_ago 형식 데이터.
                        없으면 crypto_data_json을 날짜별 형식으로 직접 파싱 시도.
        """

        # 1. 점수 계산용 데이터 결정
        if score_data:
            crypto_dict = score_data["crypto"]
            macro_dict = score_data["macro"]
        else:
            crypto_dict = json.loads(crypto_data_json)
            macro_dict = json.loads(macro_data_json)

        # 2. 지표 점수 계산
        indicator_scores = self.calculate_indicator_scores(crypto_dict, macro_dict)

        # 3. 시장 국면 감지 (current 레벨 데이터 전달)
        crypto_current = crypto_dict.get("current", crypto_dict)
        macro_current = macro_dict.get("current", macro_dict)
        regime_result = detect_regime(crypto_current, macro_current)
        regime = regime_result["regime"]
        regime_strength = regime_result["strength"]

        # 4. 조정값 계산 (v3.0 신규 지표 포함)
        regime_adjustment = REGIME_ADJUSTMENTS_MAX.get(regime, 0) * regime_strength
        interaction_score = calculate_interaction_score(
            crypto_current.get("btc_change30d", 0),
            {k: v for k, v in indicator_scores.items() if k.endswith("_score") and k in [
                "interest_rate_score", "treasury10y_score", "m2_score",
                "dollar_index_score", "unemployment_score", "cpi_score",
                "vix_score", "oil_price_score", "yield_spread_score",   # NEW
                "break_even_inflation_score"                             # NEW
            ]}
        )

        # 5. Normalized 점수 계산 (v3.0 신규 지표 포함)
        crypto_score_raw = sum([
            indicator_scores["btc_trend_score"],
            indicator_scores["fear_greed_score"],
            indicator_scores["long_short_score"],
            indicator_scores["open_interest_score"],
            indicator_scores["mvrv_score"],
            indicator_scores["funding_rate_score"],       # NEW
            indicator_scores["active_addresses_score"],   # NEW
        ])
        crypto_score_normalized = (crypto_score_raw / 60.0) * 100  # 0~60 범위를 0~100으로

        macro_score_raw = sum([
            indicator_scores["interest_rate_score"],
            indicator_scores["treasury10y_score"],
            indicator_scores["m2_score"],
            indicator_scores["dollar_index_score"],
            indicator_scores["unemployment_score"],
            indicator_scores["cpi_score"],
            indicator_scores["vix_score"],                    # NEW
            indicator_scores["oil_price_score"],              # NEW
            indicator_scores["yield_spread_score"],           # NEW
            indicator_scores["break_even_inflation_score"],   # NEW
        ])
        macro_score_normalized = (macro_score_raw / 40.0) * 100  # 0~40 범위를 0~100으로

        # 6. Base Score (정규화된 지표의 합)
        base_score_raw = crypto_score_raw + macro_score_raw

        # 7. Final Score
        final_score = base_score_raw + regime_adjustment + interaction_score
        final_score = round(min(100, max(0, final_score)), 1)

        # 8. 신호 결정
        signal_type, signal_color = self._determine_signal(final_score)

        # 9. Confidence 계산 (Python 기반, 경량)
        confidence_result = compute_confidence_label(indicator_scores, final_score, regime_strength)
        confidence_label = confidence_result["label"]

        # 10. LLM 설명 생성 (연결 해석 중심)
        indicator_scores_json = json.dumps(indicator_scores, indent=2, ensure_ascii=False)

        human_msg = HUMAN_TEMPLATE.format(
            total_score=final_score,
            signal_type=signal_type,
            base_score=base_score_raw,
            regime=regime,
            regime_strength=regime_strength,
            regime_adjustment=regime_adjustment,
            interaction_score=interaction_score,
            confidence_label=confidence_label,
            indicator_scores_json=indicator_scores_json,
            crypto_data_json=crypto_data_json,
            macro_data_json=macro_data_json
        )

        messages = [
            SystemMessage(content=SYSTEM_PROMPT),
            HumanMessage(content=human_msg)
        ]

        response = self.llm.invoke(messages)
        llm_response = self._parse_llm_response(response.content, confidence_label)

        # 11. 결과 구성
        result = {
            # 핵심 점수
            "total_score": final_score,
            "base_score": round(base_score_raw, 1),
            "crypto_score": round(crypto_score_raw, 1),
            "macro_score": round(macro_score_raw, 1),
            "crypto_score_normalized": round(crypto_score_normalized, 1),
            "macro_score_normalized": round(macro_score_normalized, 1),

            # 신호 및 신뢰도
            "signal_type": signal_type,
            "signal_color": signal_color,
            "confidence_label": confidence_label,
            "confidence_aligned_count": confidence_result["aligned_count"],
            "confidence_conflicted_count": confidence_result["conflicted_count"],

            # 국면 및 조정
            "regime": regime,
            "regime_strength": round(regime_strength, 2),
            "regime_adjustment": round(regime_adjustment, 1),
            "interaction_score": round(interaction_score, 2),
            "adjustments": {
                "regime_adjustment": round(regime_adjustment, 1),
                "interaction_score": round(interaction_score, 2)
            },

            # 지표 점수
            **indicator_scores,

            # 분석 설명 (v5.0: 연결 해석 중심, analysis_summary 제거)
            "cross_indicator_analysis": llm_response.get("cross_indicator_analysis", ""),
            "cross_indicator_analysis_en": llm_response.get("cross_indicator_analysis_en", ""),
            "signal_rationale": llm_response.get("signal_rationale", ""),
            "signal_rationale_en": llm_response.get("signal_rationale_en", ""),
            "bullish_factors": llm_response.get("bullish_factors", []),
            "bullish_factors_en": llm_response.get("bullish_factors_en", []),
            "bearish_factors": llm_response.get("bearish_factors", []),
            "bearish_factors_en": llm_response.get("bearish_factors_en", []),
            "confidence_reason": llm_response.get("confidence_reason", ""),
            "confidence_reason_en": llm_response.get("confidence_reason_en", ""),
            "indicator_explanations": llm_response.get("indicator_explanations", {}),
            "indicator_explanations_en": llm_response.get("indicator_explanations_en", {}),

            # 메타데이터
            "date": date
        }

        # 12. 결과 검증
        self._validate_result(result)

        return result

    def calculate_indicator_scores(self, crypto_dict: Dict, macro_dict: Dict) -> Dict:
        """11개 지표 점수 계산"""

        crypto_current = crypto_dict.get("current", {})
        crypto_30d_ago = crypto_dict.get("30d_ago", {})

        macro_current = macro_dict.get("current", {})
        macro_30d_ago = macro_dict.get("30d_ago", {})

        btc_change30d = crypto_current.get("btc_change30d", 0)
        btc_change7d = crypto_current.get("btc_change7d", 0)

        return {
            "date": crypto_dict.get("date", ""),
            "btc_trend_score": _score_btc_trend(btc_change30d, btc_change7d),
            "fear_greed_score": _score_fear_greed(
                crypto_current.get("fear_greed_current", 50),
                crypto_current.get("fear_greed_avg30d", 50)
            ),
            "long_short_score": _score_long_short(
                crypto_current.get("long_short_ratio", 1.0)
            ),
            "open_interest_score": _score_open_interest(
                crypto_current.get("open_interest_change", 0),
                crypto_current.get("open_interest_change30d", 0)
            ),
            "interest_rate_score": _score_interest_rate(
                macro_current.get("interest_rate_current", 3.0),
                macro_30d_ago.get("interest_rate", 3.0)
            ),
            "treasury10y_score": _score_treasury10y(
                macro_current.get("treasury10y", 4.0)
            ),
            "m2_score": _score_m2(
                macro_current.get("m2", 22000),
                macro_30d_ago.get("m2", 22000)
            ),
            "dollar_index_score": _score_dollar_index(
                macro_current.get("dxy_current", 100),
                macro_30d_ago.get("dxy", 100)
            ),
            "unemployment_score": _score_unemployment(
                macro_current.get("unemployment_current", 4.0),
                macro_30d_ago.get("unemployment", 4.0)
            ),
            "cpi_score": _score_cpi(
                macro_current.get("cpi", 2.5)
            ),
            "mvrv_score": _score_mvrv(
                crypto_current.get("mvrv_current", 1.0),
                crypto_current.get("mvrv_avg30d", 1.0)
            ),
            # v3.0 신규 지표 6개
            "funding_rate_score": _score_funding_rate(
                float(crypto_current.get("funding_rate", 0.0) or 0.0)
            ),
            "active_addresses_score": _score_active_addresses(
                int(float(crypto_current.get("active_addresses_current", 750000) or 750000)),
                float(crypto_current.get("active_addresses_avg30d", 750000) or 750000)
            ),
            "vix_score": _score_vix(
                float(macro_current.get("vix", 20.0) or 20.0)
            ),
            "oil_price_score": _score_oil_price(
                float(macro_current.get("oil_price", 70.0) or 70.0)
            ),
            "yield_spread_score": _score_yield_spread(
                float(macro_current.get("yield_spread", 0.5) or 0.5)
            ),
            "break_even_inflation_score": _score_break_even_inflation(
                float(macro_current.get("break_even_inflation", 2.3) or 2.3)
            ),
        }

    def _determine_signal(self, score: float) -> tuple:
        """점수에 따른 신호 결정"""
        if score >= 75:
            return ("Strong Buy", "buy")
        elif score >= 58:
            return ("Buy", "buy")
        elif score >= 38:
            return ("Hold", "hold")
        elif score >= 22:
            return ("Partial Sell", "sell")
        else:
            return ("Strong Sell", "sell")

    def _parse_llm_response(self, raw_response: str, confidence_label: str = "Medium") -> Dict:
        """LLM 응답에서 JSON 추출 (v5.0: 연결 해석 필드 포함)"""
        content = raw_response

        # 마크다운 코드 블록 제거
        if "```json" in content:
            start = content.find("```json") + 7
            end = content.find("```", start)
            if end != -1:
                content = content[start:end].strip()
        elif "```" in content:
            start = content.find("```") + 3
            end = content.find("```", start)
            if end != -1:
                content = content[start:end].strip()

        # JSON 객체 추출
        content = content.strip()
        if "{" in content:
            start = content.find("{")
            end = content.rfind("}")
            if end != -1 and end > start:
                content = content[start:end+1]

        # 파싱
        try:
            parsed = json.loads(content)

            # 필수 17개 지표 (v3.0: 6개 신규 추가)
            required_indicators = [
                "btc_trend", "fear_greed", "long_short", "open_interest", "mvrv",
                "funding_rate", "active_addresses",
                "interest_rate", "treasury10y", "m2", "dollar_index",
                "unemployment", "cpi",
                "vix", "oil_price", "yield_spread", "break_even_inflation",
                "interaction"
            ]

            # v5.0 신규 필드들 보완 (없으면 기본값)
            _ensure_field(parsed, "cross_indicator_analysis",
                         "주요 지표들 간의 관계를 분석했습니다. 현재 시장은 크립토와 매크로 환경의 상이한 신호를 보이고 있으며, 이로 인해 투자 신호에 제약이 발생하고 있습니다.")
            _ensure_field(parsed, "cross_indicator_analysis_en",
                         "Key indicators show mixed signals. Crypto fundamentals are positive while macro environment remains challenging, limiting upside potential.")
            _ensure_field(parsed, "signal_rationale",
                         "현재 총점 및 국면 강도를 고려한 결과 이 신호가 도출되었습니다. 크립토 지표의 강도와 매크로 환경의 제약을 균형있게 평가했습니다.")
            _ensure_field(parsed, "signal_rationale_en",
                         "This signal reflects the balance between strong crypto indicators and weak macro conditions. The regime strength modulates the signal intensity.")
            _ensure_field(parsed, "bullish_factors", ["상승 요소 1", "상승 요소 2"])
            _ensure_field(parsed, "bullish_factors_en", ["bullish factor 1", "bullish factor 2"])
            _ensure_field(parsed, "bearish_factors", ["약세 요소 1", "약세 요소 2"])
            _ensure_field(parsed, "bearish_factors_en", ["bearish factor 1", "bearish factor 2"])
            _ensure_field(parsed, "confidence_reason", f"신뢰도 {confidence_label} 판정에 대한 이유를 분석했습니다.")
            _ensure_field(parsed, "confidence_reason_en", f"Confidence level assessed as {confidence_label}.")

            # 11개 지표 설명 보완 (한국어)
            if "indicator_explanations" not in parsed:
                parsed["indicator_explanations"] = {}

            for indicator in required_indicators:
                if indicator not in parsed["indicator_explanations"]:
                    parsed["indicator_explanations"][indicator] = f"{indicator} 분석 데이터 (상세 분석 참고)"

            # 11개 지표 설명 보완 (영어)
            if "indicator_explanations_en" not in parsed:
                parsed["indicator_explanations_en"] = {}

            for indicator in required_indicators:
                if indicator not in parsed["indicator_explanations_en"]:
                    parsed["indicator_explanations_en"][indicator] = f"{indicator} analysis (see detailed data)"

            return parsed

        except json.JSONDecodeError as e:
            print(f"⚠️  JSON 파싱 실패: {e}")

            # 기본값 반환 (v5.0 모든 필드 포함, v3.0 6개 신규 지표 포함)
            required_indicators = [
                "btc_trend", "fear_greed", "long_short", "open_interest", "mvrv",
                "funding_rate", "active_addresses",
                "interest_rate", "treasury10y", "m2", "dollar_index",
                "unemployment", "cpi",
                "vix", "oil_price", "yield_spread", "break_even_inflation",
                "interaction"
            ]

            return {
                "cross_indicator_analysis": "지표 간 관계 분석을 수행했습니다. (상세 분석은 원본 응답 참고)",
                "cross_indicator_analysis_en": "Indicator relationship analysis performed. (See raw response for details)",
                "signal_rationale": "신호 근거 분석을 수행했습니다. (상세 분석은 원본 응답 참고)",
                "signal_rationale_en": "Signal rationale analysis performed. (See raw response for details)",
                "bullish_factors": ["상세 분석 참고"],
                "bullish_factors_en": ["See detailed analysis"],
                "bearish_factors": ["상세 분석 참고"],
                "bearish_factors_en": ["See detailed analysis"],
                "confidence_reason": f"신뢰도 {confidence_label}로 판정되었습니다. (상세 설명은 원본 응답 참고)",
                "confidence_reason_en": f"Confidence level: {confidence_label}. (See raw response for details)",
                "indicator_explanations": {ind: f"{ind} analysis (see raw response)" for ind in required_indicators},
                "indicator_explanations_en": {ind: f"{ind} analysis (see raw response)" for ind in required_indicators}
            }

    def _validate_result(self, result: Dict) -> None:
        """결과 검증 (v5.0: 연결 해석 필드 포함, analysis_summary 제거)"""
        # 기본 필드 (v3.0: 6개 신규 점수 필드 추가)
        required_keys = [
            "total_score", "signal_type", "signal_color",
            "btc_trend_score", "fear_greed_score", "long_short_score",
            "open_interest_score", "mvrv_score",
            "funding_rate_score", "active_addresses_score",
            "interest_rate_score", "treasury10y_score",
            "m2_score", "dollar_index_score", "unemployment_score", "cpi_score",
            "vix_score", "oil_price_score", "yield_spread_score", "break_even_inflation_score",
            "regime", "regime_strength", "base_score",
            "crypto_score_normalized", "macro_score_normalized",
            "indicator_explanations", "indicator_explanations_en",
            "confidence_label"
        ]

        # v5.0 신규 필드 (analysis_summary 제거)
        v5_keys = [
            "cross_indicator_analysis", "cross_indicator_analysis_en",
            "signal_rationale", "signal_rationale_en",
            "bullish_factors", "bullish_factors_en",
            "bearish_factors", "bearish_factors_en",
            "confidence_reason", "confidence_reason_en"
        ]

        all_required = required_keys + v5_keys

        for key in all_required:
            if key not in result:
                raise ValueError(f"필수 필드 누락: {key}")

        # 범위 검증
        if not (0 <= result["total_score"] <= 100):
            raise ValueError(f"총점 범위 오류: {result['total_score']}")

        valid_signals = ["Strong Buy", "Buy", "Hold", "Partial Sell", "Strong Sell"]
        if result["signal_type"] not in valid_signals:
            raise ValueError(f"잘못된 신호: {result['signal_type']}")

        valid_confidence = ["High", "Medium", "Low"]
        if result["confidence_label"] not in valid_confidence:
            raise ValueError(f"잘못된 신뢰도: {result['confidence_label']}")

        # 리스트 필드 검증
        for list_field in ["bullish_factors", "bullish_factors_en", "bearish_factors", "bearish_factors_en"]:
            if not isinstance(result[list_field], list):
                raise ValueError(f"{list_field}는 리스트여야 합니다")
            if len(result[list_field]) == 0:
                raise ValueError(f"{list_field}은 최소 1개 항목이 필요합니다")
