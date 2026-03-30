#
# score_analyzer.py - v4.1
# Prospero AI - Python 기반 점수 계산 + LLM 설명 분리
#
# v4.1 개선사항:
# - base_score와 normalized scores 분리
# - regime strength 추가 (확률적 국면 판단)
# - interaction_score 영향력 축소 (±3)
# - CPI 계산 명확화
# - 결과 검증 통합
# - LLM 프롬프트 경량화

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

# LLM System Prompt (설명만, 간결하게)
SYSTEM_PROMPT = """당신은 기관투자자 산하 암호화폐 분석 애널리스트입니다.
아래의 이미 계산된 투자 점수와 시장 국면에 대해 정성적 분석을 작성하세요.

[핵심]
- 점수는 절대 변경하지 마세요 (이미 Python에서 확정)
- **실제 지표값**으로 분석하세요 (점수가 아님)
- 현재값 + 30일 추이 + 시장 의미를 연결하세요

[길이 기준]
- analysis_summary: 3~5문장 한국어
- analysis_summary_en: 3~5 sentences English
- 각 indicator_explanations: 2~4문장 (현상+의미)

[반환 JSON - 설명 텍스트만]
{
  "analysis_summary": "...",
  "analysis_summary_en": "...",
  "indicator_explanations": {
    "btc_trend": "...",
    "fear_greed": "...",
    ...
  },
  "indicator_explanations_en": { ... }
}
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

위 정보를 바탕으로 3~5문장의 종합 분석과 각 지표별 2~4문장 설명을 작성하세요."""


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


# ============================================================================
# ScoreAnalyzer 클래스
# ============================================================================

class ScoreAnalyzer:
    def __init__(self, model: str = "gpt-4-turbo"):
        self.llm = ChatOpenAI(model=model, temperature=0.7)

    def analyze(self, date: str, crypto_data_json: str, macro_data_json: str) -> Dict:
        """종합 분석 (인터페이스 유지)"""

        # 1. 데이터 파싱
        crypto_dict = json.loads(crypto_data_json)
        macro_dict = json.loads(macro_data_json)

        # 2. 지표 점수 계산
        indicator_scores = self.calculate_indicator_scores(crypto_dict, macro_dict)

        # 3. 시장 국면 감지 (strength 포함)
        regime_result = detect_regime(crypto_dict, macro_dict)
        regime = regime_result["regime"]
        regime_strength = regime_result["strength"]

        # 4. 조정값 계산
        regime_adjustment = REGIME_ADJUSTMENTS_MAX.get(regime, 0) * regime_strength
        interaction_score = calculate_interaction_score(
            crypto_dict.get("btc_change30d", 0),
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
            indicator_scores["open_interest_score"]
        ])
        crypto_score_normalized = (crypto_score_raw / 50.0) * 100  # 0~50 범위를 0~100으로

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

        # 9. LLM 설명 생성
        indicator_scores_json = json.dumps(indicator_scores, indent=2, ensure_ascii=False)

        human_msg = HUMAN_TEMPLATE.format(
            total_score=final_score,
            signal_type=signal_type,
            base_score=base_score_raw,
            regime=regime,
            regime_strength=regime_strength,
            regime_adjustment=regime_adjustment,
            interaction_score=interaction_score,
            indicator_scores_json=indicator_scores_json,
            crypto_data_json=crypto_data_json,
            macro_data_json=macro_data_json
        )

        messages = [
            SystemMessage(content=SYSTEM_PROMPT),
            HumanMessage(content=human_msg)
        ]

        response = self.llm.invoke(messages)
        llm_response = self._parse_llm_response(response.content)

        # 10. 결과 구성
        result = {
            # 핵심 점수
            "total_score": final_score,
            "base_score": round(base_score_raw, 1),
            "crypto_score": round(crypto_score_raw, 1),
            "macro_score": round(macro_score_raw, 1),
            "crypto_score_normalized": round(crypto_score_normalized, 1),
            "macro_score_normalized": round(macro_score_normalized, 1),

            # 신호
            "signal_type": signal_type,
            "signal_color": signal_color,

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

            # 분석 설명
            "analysis_summary": llm_response.get("analysis_summary", ""),
            "analysis_summary_en": llm_response.get("analysis_summary_en", ""),
            "indicator_explanations": llm_response.get("indicator_explanations", {}),
            "indicator_explanations_en": llm_response.get("indicator_explanations_en", {}),

            # 메타데이터
            "date": date
        }

        # 11. 결과 검증
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

    def _parse_llm_response(self, raw_response: str) -> Dict:
        """LLM 응답에서 JSON 추출"""
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
            return json.loads(content)
        except json.JSONDecodeError as e:
            print(f"⚠️  JSON 파싱 실패: {e}")
            return {
                "analysis_summary": raw_response[:150],
                "analysis_summary_en": "",
                "indicator_explanations": {},
                "indicator_explanations_en": {}
            }

    def _validate_result(self, result: Dict) -> None:
        """결과 검증"""
        required_keys = [
            "total_score", "signal_type", "signal_color",
            "btc_trend_score", "fear_greed_score", "long_short_score",
            "open_interest_score", "interest_rate_score", "treasury10y_score",
            "m2_score", "dollar_index_score", "unemployment_score", "cpi_score",
            "regime", "regime_strength", "base_score",
            "crypto_score_normalized", "macro_score_normalized",
            "analysis_summary", "analysis_summary_en",
            "indicator_explanations", "indicator_explanations_en"
        ]

        for key in required_keys:
            if key not in result:
                raise ValueError(f"필수 필드 누락: {key}")

        if not (0 <= result["total_score"] <= 100):
            raise ValueError(f"총점 범위 오류: {result['total_score']}")

        valid_signals = ["Strong Buy", "Buy", "Hold", "Partial Sell", "Strong Sell"]
        if result["signal_type"] not in valid_signals:
            raise ValueError(f"잘못된 신호: {result['signal_type']}")
