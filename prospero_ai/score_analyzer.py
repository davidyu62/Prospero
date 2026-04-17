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

[분석 패턴 예시]
- Fear & Greed 낮음 + BTC 하락 + OI 감소 => Deleveraging/Dip-buy 신호
- BTC 상승 + OI 급증 => Leverage-driven (취약성 있음)
- BTC 약함 + Macro 개선 => 하단 제한적 (상승 베이스)
- BTC 강함 + 고금리 + 강달러 => Rally 취약성 (유동성 미흡)

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
    "interest_rate": "...",
    "treasury10y": "...",
    "m2": "...",
    "dollar_index": "...",
    "unemployment": "...",
    "cpi": "...",
    "interaction": "..."
  },
  "indicator_explanations_en": { ... 동일 11개 ... }
}

[작성 원칙]
- cross_indicator_analysis: 가장 중요한 필드. 지표 간 관계를 구체적으로 설명. 150-200자 이상 작성.
  예: "BTC는 30일간 +5% 상승했으나 OI는 -3% 감소. 이는 기존 롱 포지션 청산 신호. 동시에 공포탐욕지수가 35로 낮아 바닥권 자산 정리 국면. 매크로는 금리 4.5% 유지로 약세 환경 지속."
- signal_rationale: "왜" 이 신호인가를 명확히. 150-200자.
  예: "총점 62점 + 강도 0.78 Trend-follow 국면. 크립토 지표는 긍정적(57점)이나 매크로 약세(45점) 제약. 따라서 단기 Buy 신호이나 거시환경 회전 전까지 상승 제한적."
- bullish_factors / bearish_factors: 구체적인 수치와 조건 포함. 일반적 표현 피함.
- confidence_reason: 지표 일치도 명시. "11개 중 7개 상승 지지" 같은 구체적 표현.
"""

HUMAN_TEMPLATE = """[투자 점수 및 국면]
총점: {total_score}/100 ({signal_type})
기본점수: {base_score:.1f}
시장국면: {regime} (강도: {regime_strength:.2f})

[조정값]
국면조정: {regime_adjustment:+.1f}점
상호작용: {interaction_score:+.1f}점

[지표 점수 (11개)]
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
   → 지표 일치도를 수치로 제시 (예: "11개 중 8개 상승 지지")

10. **confidence_reason_en (English)**: 100-150 chars

11. **indicator_explanations (한국어)**: 11개 지표 각각 2~3문장
    - btc_trend, fear_greed, long_short, open_interest, interest_rate, treasury10y, m2, dollar_index, unemployment, cpi, interaction

12. **indicator_explanations_en (English)**: 동일 11개

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
    """공포탐욕지수 (0~20)"""
    weighted = current * 0.6 + avg30d * 0.4
    inverted = 100.0 - weighted
    score = (inverted / 100.0) ** 0.8 * 20.0

    return round(min(20, max(0, score)), 2)


def _score_long_short(ratio: float) -> float:
    """롱숏비율 (0~15)"""
    score = 15.0 * max(0.0, (1.5 - ratio) / (1.5 - 0.7))
    return round(min(15, max(0, score)), 2)


def _score_open_interest(price_change: float, oi_change: float) -> float:
    """OI + 가격 (0~10)"""
    if price_change < 0 and oi_change < 0:
        base = 8.0  # 건강한 정리
    elif price_change > 0 and oi_change < 0:
        base = 6.0  # 숏커버링
    elif price_change > 0 and oi_change > 0:
        base = 5.0  # 레버리지 과열
    elif price_change < 0 and oi_change > 0:
        base = 2.0  # 숏 추가
    else:
        base = 5.0

    if abs(price_change) > 10 and abs(oi_change) > 10:
        base += 1.0 if base > 5 else -1.0

    return round(min(10, max(0, base)), 2)


def _score_interest_rate(rate_current: float, rate_30d_ago: float) -> float:
    """기준금리 (0~10)"""
    if rate_current <= 1.0:
        level_score = 9.0
    elif rate_current <= 2.5:
        level_score = 9.0 - (rate_current - 1.0) / 1.5 * 3.0
    elif rate_current <= 4.0:
        level_score = 6.0 - (rate_current - 2.5) / 1.5 * 3.0
    elif rate_current <= 5.0:
        level_score = 3.0 - (rate_current - 4.0) * 2.0
    else:
        level_score = 1.0

    trend_adjustment = 0
    if rate_30d_ago != 0:
        if rate_current < rate_30d_ago:
            trend_adjustment = 1.0
        elif rate_current > rate_30d_ago:
            trend_adjustment = -1.0

    return round(min(10, max(0, level_score + trend_adjustment)), 2)


def _score_treasury10y(treasury10y: float, interest_rate: float) -> float:
    """10년물 금리 (0~8)"""
    if treasury10y < 3.0:
        level_score = 6.0
    elif treasury10y <= 4.0:
        level_score = 6.0 - (treasury10y - 3.0) / 1.0
    elif treasury10y <= 5.0:
        level_score = 5.0 - (treasury10y - 4.0) / 1.0 * 2.0
    else:
        level_score = 1.0

    spread = treasury10y - interest_rate
    if spread > 0.5:
        spread_adjustment = 1.0
    elif spread >= 0:
        spread_adjustment = 0.0
    elif spread >= -1.0:
        spread_adjustment = -1.0
    else:
        spread_adjustment = -2.0

    return round(min(8, max(0, level_score + spread_adjustment)), 2)


def _score_m2(m2_current: float, m2_30d_ago: float) -> float:
    """M2 통화량 (0~8)"""
    if m2_30d_ago == 0:
        return 4.0

    percent_change = ((m2_current - m2_30d_ago) / m2_30d_ago) * 100

    if percent_change > 1.0:
        score = 8.0
    elif percent_change > 0.3:
        score = 4.0 + (percent_change - 0.3) / 0.7 * 4.0
    elif percent_change >= 0:
        score = 2.0 + percent_change / 0.3 * 2.0
    else:
        score = max(0, 2.0 + percent_change * 2.0)

    return round(min(8, max(0, score)), 2)


def _score_dollar_index(dxy_current: float, dxy_30d_ago: float) -> float:
    """달러인덱스 (0~7)"""
    if dxy_current < 95:
        level_score = 6.0
    elif dxy_current <= 100:
        level_score = 6.0 - (dxy_current - 95) / 5.0
    elif dxy_current <= 105:
        level_score = 5.0 - (dxy_current - 100) / 5.0 * 2.0
    elif dxy_current <= 110:
        level_score = 3.0 - (dxy_current - 105) / 5.0 * 2.0
    else:
        level_score = 0.0

    trend_adjustment = 0
    if dxy_30d_ago != 0 and dxy_current < dxy_30d_ago:
        trend_adjustment = 1.0
    elif dxy_30d_ago != 0 and dxy_current > dxy_30d_ago:
        trend_adjustment = -1.0

    return round(min(7, max(0, level_score + trend_adjustment)), 2)


def _score_unemployment(unemp_current: float, unemp_30d_ago: float) -> float:
    """실업률 (0~4)"""
    change = unemp_current - unemp_30d_ago
    score = 2.5 - change * 3.0

    return round(min(4, max(0, score)), 2)


def _score_mvrv(mvrv_current: float, mvrv_avg30d: float) -> float:
    """MVRV - Market Value to Realized Value (0~5)"""
    weighted = mvrv_current * 0.6 + mvrv_avg30d * 0.4

    if weighted <= 1.0:
        score = 5.0  # 저평가 - 매수 신호
    elif weighted <= 1.5:
        score = 5.0 - (weighted - 1.0) / 0.5 * 2.0  # 5.0 ~ 3.0
    elif weighted <= 2.0:
        score = 3.0 - (weighted - 1.5) / 0.5 * 2.0  # 3.0 ~ 1.0
    else:
        score = 0.0  # 고평가 - 매도 신호

    return round(min(5, max(0, score)), 2)


def _score_cpi(cpi_value: float) -> float:
    """CPI (0~3) - 명확한 형식 처리"""
    # cpi_value는 백분율로 제공된다고 가정 (예: 2.5 = 2.5%)
    # 데이터 검증: 만약 cpi_value가 0과 100 사이가 아니면 기본값 사용
    if cpi_value < 0 or cpi_value > 20:
        cpi_value = 2.5  # 기본값

    if cpi_value <= 2.0:
        score = 3.0
    elif cpi_value <= 4.5:
        score = 3.0 - (cpi_value - 2.0) / 2.5 * 3.0
    else:
        score = 0.0

    return round(min(3, max(0, score)), 2)


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

    # 각 지표의 방향 판정 (점수 > 5 = 호의적)
    crypto_bullish = [
        indicator_scores.get("btc_trend_score", 5) > 5,
        indicator_scores.get("fear_greed_score", 10) > 10,
        indicator_scores.get("long_short_score", 7) > 7,
        indicator_scores.get("open_interest_score", 5) > 5,
    ]

    macro_bullish = [
        indicator_scores.get("interest_rate_score", 5) > 5,
        indicator_scores.get("treasury10y_score", 4) > 4,
        indicator_scores.get("m2_score", 4) > 4,
        indicator_scores.get("dollar_index_score", 3.5) > 3.5,
        indicator_scores.get("unemployment_score", 2) > 2,
        indicator_scores.get("cpi_score", 1.5) > 1.5,
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

        # 4. 조정값 계산
        regime_adjustment = REGIME_ADJUSTMENTS_MAX.get(regime, 0) * regime_strength
        interaction_score = calculate_interaction_score(
            crypto_current.get("btc_change30d", 0),
            {k: v for k, v in indicator_scores.items() if k.endswith("_score") and k in [
                "interest_rate_score", "treasury10y_score", "m2_score",
                "dollar_index_score", "unemployment_score", "cpi_score"
            ]}
        )

        # 5. Normalized 점수 계산
        crypto_score_raw = sum([
            indicator_scores["btc_trend_score"],
            indicator_scores["fear_greed_score"],
            indicator_scores["long_short_score"],
            indicator_scores["open_interest_score"],
            indicator_scores["mvrv_score"]
        ])
        crypto_score_normalized = (crypto_score_raw / 55.0) * 100  # 0~55 범위를 0~100으로

        macro_score_raw = sum([
            indicator_scores["interest_rate_score"],
            indicator_scores["treasury10y_score"],
            indicator_scores["m2_score"],
            indicator_scores["dollar_index_score"],
            indicator_scores["unemployment_score"],
            indicator_scores["cpi_score"]
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
                macro_current.get("treasury10y", 4.0),
                macro_current.get("interest_rate_current", 3.0)
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

            # 필수 12개 지표
            required_indicators = [
                "btc_trend", "fear_greed", "long_short", "open_interest", "mvrv",
                "interest_rate", "treasury10y", "m2", "dollar_index",
                "unemployment", "cpi", "interaction"
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

            # 기본값 반환 (v5.0 모든 필드 포함, analysis_summary 제거)
            required_indicators = [
                "btc_trend", "fear_greed", "long_short", "open_interest", "mvrv",
                "interest_rate", "treasury10y", "m2", "dollar_index",
                "unemployment", "cpi", "interaction"
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
        # 기본 필드
        required_keys = [
            "total_score", "signal_type", "signal_color",
            "btc_trend_score", "fear_greed_score", "long_short_score",
            "open_interest_score", "interest_rate_score", "treasury10y_score",
            "m2_score", "dollar_index_score", "unemployment_score", "cpi_score",
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
