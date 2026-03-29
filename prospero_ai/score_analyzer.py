#
# score_analyzer.py - v4.0
# Prospero AI - Python 기반 점수 계산 + LLM 설명 분리
#
# 주요 변경:
# - Python 함수로 연속 점수 계산 (deterministic, 재현 가능)
# - Regime detection 추가 (5가지 시장 국면)
# - LLM은 설명 텍스트만 생성

import json
import os
import math
from typing import Dict, Optional, Tuple
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage

# ============================================================================
# 상수 및 설정
# ============================================================================

REGIME_ADJUSTMENTS = {
    "dip_buy": 3.0,       # 역발상 최고 매수 기회
    "trend_follow": 1.5,  # 추세 추종 시장
    "neutral": 0.0,
    "risk_off": -2.0,     # 위험회피 환경
    "euphoria": -3.0      # 고점 경고
}

# LLM System Prompt (설명만 생성)
SYSTEM_PROMPT = """당신은 비트코인 투자 분석 전문가입니다.
아래에 이미 계산된 투자 점수, 시장 국면(Regime), 원시 지표 데이터가 제공됩니다.

핵심 규칙:
- 점수는 절대 변경하거나 재계산하지 마세요 (이미 Python으로 확정됨)
- 각 지표의 현재 상황과 투자 시사점을 구체적 수치와 함께 설명하세요
- 시장 국면(regime)을 고려하여 analysis_summary를 작성하세요

[반환 JSON 형식 - 설명 텍스트 필드만]
{
  "analysis_summary":          "한국어 2~3문장 (구체적 수치 포함, 시장 국면 반영)",
  "analysis_summary_en":       "English 2~3 sentences",
  "indicator_explanations": {
    "btc_trend":      "BTC 30일 추세와 역발상 기회 분석",
    "fear_greed":     "공포탐욕지수 현재 상황과 시사점",
    "long_short":     "롱숏비율이 나타내는 시장 심리",
    "open_interest":  "OI와 가격 조합의 의미",
    "interest_rate":  "기준금리 수준과 추세 영향",
    "treasury10y":    "10년물 금리와 경기 신호",
    "m2":             "M2 통화량 변화의 영향",
    "dollar_index":   "달러 강약의 의미",
    "unemployment":   "실업률 추세의 경제 신호",
    "cpi":            "인플레이션 수준의 의미",
    "interaction":    "종합 환경 평가"
  },
  "indicator_explanations_en": { ... 동일 키, 영어 설명 ... }
}
"""

HUMAN_TEMPLATE = """[계산된 투자 점수]
Total Score: {total_score}/100 ({signal_type})
Base Score: {base_score}/100
Regime: {regime}
Regime Adjustment: {regime_adjustment:+.1f}
Interaction Score: {interaction_score:+.1f}

[세부 지표 점수]
{indicator_scores_json}

[크립토 데이터 (최근 30일)]
{crypto_data_json}

[거시경제 데이터 (최근 30일)]
{macro_data_json}

위 데이터를 바탕으로 각 지표에 대한 설명과 종합 분석을 작성하세요.
점수는 절대 변경하지 마세요."""


# ============================================================================
# 연속 점수 계산 함수들
# ============================================================================

def _score_btc_trend(change30d: float, change7d: float) -> float:
    """BTC 30일 가격 추세 역발상 점수 (0~10)

    역발상 전략: 급락할수록 높은 점수
    - 변화율 기반 역 sigmoid
    - 급락 속도 penalty 적용
    """
    # 역 sigmoid: -40% → ~8.5점, 0% → 5점, +40% → ~1.5점
    t = -change30d / 20.0
    sigmoid = 1.0 / (1.0 + math.exp(-t))
    score = sigmoid * 10.0

    # 급락 속도 penalty (과도한 낙폭 방지)
    if change30d < -30 and change7d < -15:
        score = max(0, score - 1.0)

    return round(min(10, max(0, score)), 2)


def _score_fear_greed(current: float, avg30d: float) -> float:
    """공포탐욕지수 + 30일 추세 점수 (0~20)

    가중평균 + 비선형 역방향:
    - current*0.6 + avg30d*0.4
    - 극단값 강조 (비선형)
    """
    weighted = current * 0.6 + avg30d * 0.4  # 0~100
    inverted = 100 - weighted                 # 100=극도공포, 0=극도탐욕

    # 제곱근 스케일로 극단값 강조
    score = (inverted / 100.0) ** 0.8 * 20.0

    return round(min(20, max(0, score)), 2)


def _score_long_short(ratio: float) -> float:
    """롱숏비율 점수 (0~15)

    비율이 낮을수록 좋음 (숏 우위 = 바닥 신호):
    - ≤0.7 → 15점
    - ≥1.5 → 0점
    - 선형 보간
    """
    if ratio <= 0.7:
        return 15.0
    elif ratio >= 1.5:
        return 0.0
    else:
        return round(15.0 * (1.5 - ratio) / (1.5 - 0.7), 2)


def _score_open_interest(price_change: float, oi_change: float) -> float:
    """OI + 가격 방향 점수 (0~10)

    4가지 조합 + 변화량 크기로 세밀 조정:
    - 가격↓OI↓: 8.0 (건강한 정리)
    - 가격↑OI↓: 6.0 (숏커버링)
    - 가격↑OI↑: 5.0 (레버리지 증가)
    - 가격↓OI↑: 2.0 (숏 추가)
    """
    if price_change < 0 and oi_change < 0:
        base = 8.0
    elif price_change > 0 and oi_change < 0:
        base = 6.0
    elif price_change > 0 and oi_change > 0:
        base = 5.0
    elif price_change < 0 and oi_change > 0:
        base = 2.0
    else:
        base = 5.0

    # 변화량 크기에 따라 ±1 조정
    if abs(price_change) > 10 and abs(oi_change) > 10:
        base += 1.0 if base > 5 else -1.0

    return round(min(10, max(0, base)), 2)


def _score_interest_rate(rate_current: float, rate_30d_ago: float) -> float:
    """기준금리 + 30일 추세 점수 (0~10)

    연속 구간 보간 + 추세 보정:
    - 수준: ≤1%→9, ~2.5%→6~9, ~4%→3~6, ~5%→1~3, >5%→1
    - 추세: 인하 +1, 인상 -1
    """
    # 수준 기반 연속 점수
    if rate_current <= 1.0:
        level_score = 9.0
    elif rate_current <= 2.5:
        level_score = 6.0 + 3.0 * (2.5 - rate_current) / (2.5 - 1.0)
    elif rate_current <= 4.0:
        level_score = 3.0 + 3.0 * (4.0 - rate_current) / (4.0 - 2.5)
    elif rate_current <= 5.0:
        level_score = 1.0 + 2.0 * (5.0 - rate_current) / (5.0 - 4.0)
    else:
        level_score = 1.0

    # 30일 추세 보정
    if rate_30d_ago and rate_current < rate_30d_ago:
        trend_adj = 1.0
    elif rate_30d_ago and rate_current > rate_30d_ago:
        trend_adj = -1.0
    else:
        trend_adj = 0.0

    return round(min(10, max(0, level_score + trend_adj)), 2)


def _score_treasury10y(treasury10y: float, interest_rate: float) -> float:
    """10년물 국채금리 + 장단기 스프레드 점수 (0~8)

    수준 + 스프레드(경기침체 신호):
    - 수준: <3%→6, 3~4%→5~6, 4~5%→3~5, >5%→1
    - 스프레드: >0.5%→+1, 0~0.5%→0, -1~0%→-1, <-1%→-2
    """
    # 수준 기반
    if treasury10y < 3.0:
        level_score = 6.0
    elif treasury10y <= 4.0:
        level_score = 5.0 + (4.0 - treasury10y) / (4.0 - 3.0)
    elif treasury10y <= 5.0:
        level_score = 3.0 + 2.0 * (5.0 - treasury10y) / (5.0 - 4.0)
    else:
        level_score = 1.0

    # 스프레드 보정
    spread = treasury10y - interest_rate
    if spread > 0.5:
        spread_adj = 1.0
    elif spread > 0:
        spread_adj = 0.0
    elif spread > -1.0:
        spread_adj = -1.0
    else:
        spread_adj = -2.0

    return round(min(8, max(0, level_score + spread_adj)), 2)


def _score_m2(m2_current: float, m2_30d_ago: float) -> float:
    """M2 통화량 변화율 점수 (0~8)

    30일 변화율 기반 연속 점수:
    - >+1% → 8점
    - +0.3~+1% → 4~8 선형
    - 0~+0.3% → 2~4 선형
    - <0% → 0~2 선형
    """
    if m2_30d_ago == 0:
        return 4.0

    change_pct = (m2_current - m2_30d_ago) / m2_30d_ago * 100

    if change_pct > 1.0:
        return 8.0
    elif change_pct > 0.3:
        return 4.0 + (change_pct - 0.3) / (1.0 - 0.3) * 4.0
    elif change_pct > 0:
        return 2.0 + change_pct / 0.3 * 2.0
    else:
        return max(0, 2.0 + change_pct / 0.3 * 2.0)


def _score_dollar_index(dxy_current: float, dxy_30d_ago: float) -> float:
    """달러인덱스 + 30일 추세 점수 (0~7)

    연속 레벨 + 약세 추세:
    - 수준: <95→6, 95~100→5~6, 100~105→3~5, 105~110→1~3, ≥110→0
    - 추세: 약세(하락) +1, 강세(상승) -1
    """
    # 수준 기반
    if dxy_current < 95:
        level_score = 6.0
    elif dxy_current <= 100:
        level_score = 5.0 + (100 - dxy_current) / (100 - 95)
    elif dxy_current <= 105:
        level_score = 3.0 + 2.0 * (105 - dxy_current) / (105 - 100)
    elif dxy_current <= 110:
        level_score = 1.0 + 2.0 * (110 - dxy_current) / (110 - 105)
    else:
        level_score = 0.0

    # 30일 추세 보정
    if dxy_30d_ago and dxy_current < dxy_30d_ago:
        trend_adj = 1.0
    elif dxy_30d_ago and dxy_current > dxy_30d_ago:
        trend_adj = -1.0
    else:
        trend_adj = 0.0

    return round(min(7, max(0, level_score + trend_adj)), 2)


def _score_unemployment(unemp_current: float, unemp_30d_ago: float) -> float:
    """실업률 30일 변화 점수 (0~4)

    30일 변화량 기반 선형 보간:
    - 변화 = +0.5%p → 1점
    - 변화 = 0 → 2.5점
    - 변화 = -0.5%p → 4점
    """
    if unemp_30d_ago is None:
        return 2.5

    change = unemp_current - unemp_30d_ago
    clamped = max(-0.5, min(0.5, change))
    score = 2.5 - clamped * 3.0

    return round(min(4, max(0, score)), 2)


def _score_cpi(cpi_value: float) -> float:
    """CPI (소비자물가지수) 점수 (0~3)

    연율 기반 연속:
    - ≤2% → 3점
    - 2~4.5% → 0~3 선형
    - >4.5% → 0점
    """
    if cpi_value <= 2.0:
        return 3.0
    elif cpi_value <= 4.5:
        return 3.0 * (4.5 - cpi_value) / (4.5 - 2.0)
    else:
        return 0.0


# ============================================================================
# 지표 계산 및 종합 함수
# ============================================================================

def detect_regime(crypto_values: Dict, macro_values: Dict) -> str:
    """시장 국면 탐지 (Regime Detection)

    Returns: "dip_buy" | "trend_follow" | "risk_off" | "euphoria" | "neutral"

    판단 기준:
    - dip_buy: BTC 급락 + 공포 극단
    - euphoria: BTC 급등 + 탐욕 극단 + OI 급증
    - risk_off: 고금리 + 강달러
    - trend_follow: BTC 상승 + 탐욕 + 매크로 긍정
    - neutral: 나머지
    """
    btc_change30d = crypto_values.get("btc_change30d", 0)
    fear_greed = crypto_values.get("fear_greed_current", 50)
    oi_change30d = crypto_values.get("oi_change30d", 0)

    interest_rate = macro_values.get("interest_rate_current", 4.5)
    dxy_current = macro_values.get("dxy_current", 100)
    dxy_30d_ago = macro_values.get("dxy_30d_ago", 100)

    # Regime 판정 (우선순위 순서)
    if btc_change30d < -15 and fear_greed < 30:
        return "dip_buy"

    if btc_change30d > 20 and fear_greed > 70 and oi_change30d > 20:
        return "euphoria"

    if interest_rate > 5.0 and dxy_current > 104 and dxy_current > dxy_30d_ago:
        return "risk_off"

    if btc_change30d > 5 and fear_greed > 50:
        return "trend_follow"

    return "neutral"


def calculate_interaction_score(btc_change30d: float, macro_total_score: float) -> float:
    """종합 환경 보정 점수 (±5점)

    BTC 가격 추세 × 매크로 환경:
    - BTC 하락 + 매크로 긍정(≥55%): +5 (역발상 최고)
    - BTC 상승 + 매크로 긍정: +3
    - 중립 매크로: +2
    - BTC 상승 + 매크로 부정: -3
    - BTC 하락 + 매크로 부정: 0
    """
    macro_ratio = macro_total_score / 40.0 * 100  # 0~100%

    if btc_change30d < 0 and macro_ratio >= 55:
        return 5.0
    elif btc_change30d > 0 and macro_ratio >= 55:
        return 3.0
    elif 45 <= macro_ratio < 55:
        return 2.0
    elif btc_change30d > 0 and macro_ratio < 45:
        return -3.0
    else:
        return 0.0


# ============================================================================
# ScoreAnalyzer 클래스
# ============================================================================

class ScoreAnalyzer:
    def __init__(self, openai_api_key: Optional[str] = None, model: str = "gpt-4o-mini"):
        """LangChain + ChatGPT 기반 점수 분석기 초기화

        Args:
            openai_api_key: OpenAI API 키
            model: ChatGPT 모델명
        """
        api_key = openai_api_key or os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OpenAI API 키가 설정되지 않았습니다.")

        self.llm = ChatOpenAI(
            model_name=model,
            temperature=0,
            openai_api_key=api_key
        )

    def analyze(self, date: str, crypto_data_json: str, macro_data_json: str) -> Dict:
        """투자 점수 계산 및 분석

        Args:
            date: "yyyyMMdd" 형식 날짜
            crypto_data_json: 크립토 데이터 JSON 문자열
            macro_data_json: 거시경제 데이터 JSON 문자열

        Returns:
            점수 + 설명 포함 Dict
        """
        print(f"🤖 점수 분석 시작 (날짜: {date})...")

        try:
            # 1. 데이터 파싱
            crypto_raw = json.loads(crypto_data_json)
            macro_raw = json.loads(macro_data_json)

            # 2. 날짜 정렬 및 값 추출
            sorted_crypto_dates = sorted(crypto_raw.keys())
            sorted_macro_dates = sorted(macro_raw.keys())

            if not sorted_crypto_dates or not sorted_macro_dates:
                raise ValueError("데이터가 비어있습니다.")

            latest_crypto_date = sorted_crypto_dates[-1]
            oldest_crypto_date = sorted_crypto_dates[0]
            latest_macro_date = sorted_macro_dates[-1]
            oldest_macro_date = sorted_macro_dates[0]

            crypto_current = crypto_raw.get(latest_crypto_date, {})
            crypto_old = crypto_raw.get(oldest_crypto_date, {})
            macro_current = macro_raw.get(latest_macro_date, {})
            macro_old = macro_raw.get(oldest_macro_date, {})

            # 3. 30일 평균 계산 (fear_greed)
            fear_greed_values = [v.get("fearGreedIndex", 50) for v in crypto_raw.values()]
            fear_greed_avg = sum(fear_greed_values) / len(fear_greed_values) if fear_greed_values else 50

            # 4. BTC 및 OI 변화율 계산
            btc_current = crypto_current.get("btcPrice", 0)
            btc_old = crypto_old.get("btcPrice", 0)
            btc_change30d = (btc_current - btc_old) / btc_old * 100 if btc_old else 0

            btc_7d_ago_date = sorted_crypto_dates[-8] if len(sorted_crypto_dates) >= 8 else sorted_crypto_dates[0]
            btc_7d_ago = crypto_raw.get(btc_7d_ago_date, {}).get("btcPrice", btc_current)
            btc_change7d = (btc_current - btc_7d_ago) / btc_7d_ago * 100 if btc_7d_ago else 0

            oi_current = crypto_current.get("openInterest", 0)
            oi_old = crypto_old.get("openInterest", 0)
            oi_change30d = (oi_current - oi_old) / oi_old * 100 if oi_old else 0

            # 5. 지표별 Python 점수 계산
            indicator_scores = {}

            # 크립토 지표
            indicator_scores["btc_trend_score"] = _score_btc_trend(btc_change30d, btc_change7d)
            indicator_scores["fear_greed_score"] = _score_fear_greed(
                crypto_current.get("fearGreedIndex", 50),
                fear_greed_avg
            )
            indicator_scores["long_short_score"] = _score_long_short(crypto_current.get("longShortRatio", 1.0))
            indicator_scores["open_interest_score"] = _score_open_interest(btc_change30d, oi_change30d)

            # 매크로 지표
            interest_rate_current = macro_current.get("interestRate", 4.5)
            interest_rate_30d = macro_old.get("interestRate", interest_rate_current)
            indicator_scores["interest_rate_score"] = _score_interest_rate(interest_rate_current, interest_rate_30d)
            indicator_scores["treasury10y_score"] = _score_treasury10y(
                macro_current.get("treasury10y", 4.0),
                interest_rate_current
            )
            indicator_scores["m2_score"] = _score_m2(
                macro_current.get("m2", 0),
                macro_old.get("m2", 0)
            )
            dxy_current = macro_current.get("dollarIndex", 100)
            dxy_30d = macro_old.get("dollarIndex", 100)
            indicator_scores["dollar_index_score"] = _score_dollar_index(dxy_current, dxy_30d)
            indicator_scores["unemployment_score"] = _score_unemployment(
                macro_current.get("unemployment", 4.0),
                macro_old.get("unemployment", 4.0)
            )
            indicator_scores["cpi_score"] = _score_cpi(macro_current.get("cpi", 2.5) / 100 * 12)

            # 6. Regime 탐지
            crypto_values = {
                "btc_change30d": btc_change30d,
                "fear_greed_current": crypto_current.get("fearGreedIndex", 50),
                "oi_change30d": oi_change30d
            }
            macro_values = {
                "interest_rate_current": interest_rate_current,
                "dxy_current": dxy_current,
                "dxy_30d_ago": dxy_30d
            }
            regime = detect_regime(crypto_values, macro_values)

            # 7. 기본 점수 합산
            crypto_score = sum([v for k, v in indicator_scores.items() if k in [
                "btc_trend_score", "fear_greed_score", "long_short_score", "open_interest_score"
            ]])
            macro_score = sum([v for k, v in indicator_scores.items() if k in [
                "interest_rate_score", "treasury10y_score", "m2_score",
                "dollar_index_score", "unemployment_score", "cpi_score"
            ]])
            base_score = crypto_score + macro_score

            # 8. Regime 기반 조정
            regime_adjustment = REGIME_ADJUSTMENTS.get(regime, 0.0)

            # 9. 상호작용 점수
            interaction_score = calculate_interaction_score(btc_change30d, macro_score)

            # 10. 최종 점수
            total_score = round(min(100, max(0, base_score + regime_adjustment + interaction_score)), 1)
            indicator_scores["interaction_score"] = interaction_score

            # 11. 신호 타입 결정
            if total_score >= 75:
                signal_type = "Strong Buy"
                signal_color = "strong_buy"
            elif total_score >= 58:
                signal_type = "Buy"
                signal_color = "buy"
            elif total_score >= 38:
                signal_type = "Hold"
                signal_color = "hold"
            elif total_score >= 22:
                signal_type = "Partial Sell"
                signal_color = "partial_sell"
            else:
                signal_type = "Strong Sell"
                signal_color = "strong_sell"

            # 12. LLM에 설명 요청 (점수는 절대 계산하지 않도록)
            indicator_scores_json = json.dumps(indicator_scores, indent=2, ensure_ascii=False)
            human_msg = HUMAN_TEMPLATE.format(
                total_score=total_score,
                signal_type=signal_type,
                base_score=base_score,
                regime=regime,
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
            llm_response = json.loads(response.content)

            # 13. 결과 병합
            result = {
                "date": date,
                "total_score": total_score,
                "signal_type": signal_type,
                "signal_color": signal_color,
                "btc_trend_score": indicator_scores["btc_trend_score"],
                "fear_greed_score": indicator_scores["fear_greed_score"],
                "long_short_score": indicator_scores["long_short_score"],
                "open_interest_score": indicator_scores["open_interest_score"],
                "interest_rate_score": indicator_scores["interest_rate_score"],
                "treasury10y_score": indicator_scores["treasury10y_score"],
                "m2_score": indicator_scores["m2_score"],
                "dollar_index_score": indicator_scores["dollar_index_score"],
                "unemployment_score": indicator_scores["unemployment_score"],
                "cpi_score": indicator_scores["cpi_score"],
                "interaction_score": indicator_scores["interaction_score"],
                "regime": regime,
                "base_score": round(base_score, 1),
                "regime_adjustment": regime_adjustment,
                "analysis_summary": llm_response.get("analysis_summary", ""),
                "analysis_summary_en": llm_response.get("analysis_summary_en", ""),
                "indicator_explanations": llm_response.get("indicator_explanations", {}),
                "indicator_explanations_en": llm_response.get("indicator_explanations_en", {})
            }

            print(f"✅ 점수 계산 완료: {total_score:.1f}점 ({signal_type}) [Regime: {regime}]")
            return result

        except Exception as e:
            print(f"❌ 점수 계산 실패: {e}")
            raise

    def _validate_result(self, result: Dict) -> None:
        """LLM 응답 검증"""
        required_keys = [
            "total_score", "signal_type", "signal_color",
            "btc_trend_score", "fear_greed_score", "long_short_score",
            "open_interest_score", "interest_rate_score", "treasury10y_score",
            "m2_score", "dollar_index_score", "unemployment_score", "cpi_score",
            "interaction_score", "regime", "base_score", "regime_adjustment",
            "analysis_summary", "analysis_summary_en",
            "indicator_explanations", "indicator_explanations_en"
        ]

        for key in required_keys:
            if key not in result:
                raise ValueError(f"필수 필드 누락: {key}")

        # 점수 범위 검증
        if not (0 <= result["total_score"] <= 100):
            raise ValueError(f"총점 범위 오류: {result['total_score']}")

        # 신호 타입 검증
        valid_signals = ["Strong Buy", "Buy", "Hold", "Partial Sell", "Strong Sell"]
        if result["signal_type"] not in valid_signals:
            raise ValueError(f"잘못된 신호 타입: {result['signal_type']}")
