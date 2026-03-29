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
SYSTEM_PROMPT = """당신은 자산 10조 이상의 기관투자자 산하 암호화폐 분석팀의 시니어 애널리스트입니다.
비트코인 투자 결정에 필요한 깊이 있는 정성적 분석을 제공해야 합니다.

[핵심 규칙]
1. 점수는 절대 변경하거나 재계산하지 마세요 (이미 Python으로 확정됨)
2. **반드시 실제 지표값으로 분석**하세요 (점수 X)
   - 잘못된 예: "롱숏비율 점수가 0.0이므로..."
   - 올바른 예: "롱숏비율 2.39로 롱이 강세이므로... (이는 숏 압박을 의미하며...)"
3. 각 지표를 **정성적 맥락**과 함께 분석하세요
4. 현재값 + 30일 추세 + 시장 의미를 연결하세요

[지표별 상세 분석 가이드]

**BTC 추세 (현재값, 30일 변화, 7일 변화)**
- 장기(30일)와 단기(7일) 추세 비교
- 급락/급등 속도와 지속가능성 평가
- 역발상(contrarian) 기회 포인트 분석
- 지지선/저항선 근처인지 평가

**공포탐욕지수 (현재값, 30일 평균, 극단 여부)**
- 현재 심리 상태 (극도공포 ↔ 극도탐욕)
- 평균 대비 극단성 정도
- 심리 반전(reversal) 신호 분석
- 과거 극단값 이후 시장 반응 패턴

**롱숏비율 (현재값, 추이)**
- 롱/숏의 절대적 크기 평가
- 숏 스퀴즈 위험도
- 선물 시장의 레버리지 위험
- 거래소 심리 방향성

**Open Interest + 가격 (OI값, 가격 변화, OI 변화)**
- OI 증가/감소와 가격 조합의 의미
  * 가격↑ + OI↑: 신규 롱진입 (강세)
  * 가격↓ + OI↑: 신규 숏진입 (약세)
  * 가격↑ + OI↓: 공매도 커버 (일시적)
  * 가격↓ + OI↓: 숏 청산 (급락장)
- 청산 리스크 평가

**기준금리 (현재값, 30일 추이, 추세)**
- 절대 수준 (낮음/중간/높음)
- 방향성 (인상기/인하기)
- 차용 비용과 리스크 자산 매력도 변화
- 다음 FOMC 회의까지의 기간

**10년물 금리 (현재값, 기준금리와의 스프레드)**
- 수익률 커브 형태 (정상/역전)
- 경기 선행성 신호
- 채권-주식-암호화폐 자산배분 영향
- 스프레드 추이와 경기 신호

**M2 (통화량 변화율)**
- 통화 팽창/축소 기조
- 대출 시장 유동성 상황
- 자산 가격 인상 요인 (또는 제약 요인)
- 인플레이션 압력 선행성

**달러지수 (현재값, 30일 추이, 강약)**
- 달러 강세가 암호화폐에 미치는 영향
- 신흥국 자본유출 리스크
- 수입 물가 압력과 인플레이션 영향
- 글로벌 위험회피(risk-off) 신호

**실업률 (현재값, 30일 변화)**
- 노동시장 건강도
- 임금 상승압력 → 인플레이션 연쇄
- 경기 후행성 신호
- 중앙은행 정책 여지

**CPI (현재값, 추세)**
- 인플레이션 수준 (저/중간/고)
- 추세 방향 (상승/안정/하락)
- 금리 인상 필요성 판단
- 실질수익률 변화

**상호작용 점수 (종합 환경)**
- BTC 추세 + 매크로 환경의 조화
- 순풍(tailwind) vs 역풍(headwind) 분석
- 시장 국면과의 어울림

[분석 스타일]
- 정량값을 정성 해석과 연결
- "왜"에 대한 답변 제시
- 투자 의사결정에 직결되는 인사이트
- 리스크와 기회 모두 언급
- 문장당 한 가지 개념만 담기 (명확성)

[중요] 반드시 **유효한 JSON만** 반환하세요. 마크다운이나 다른 텍스트는 포함하지 마세요.

[반환 JSON 형식]
{
  "analysis_summary":          "3~4문장 한국어 (수치+맥락)",
  "analysis_summary_en":       "3~4 sentences English",
  "indicator_explanations": {
    "btc_trend":      "현재값+추세+의미+기회/리스크",
    "fear_greed":     "현재 심리상태+평균대비+시사점",
    "long_short":     "숏비율 규모+스퀴즈 위험+시장해석",
    "open_interest":  "OI+가격 조합+청산 리스크+신호",
    "interest_rate":  "현재 수준+추세+차용비용+매력도변화",
    "treasury10y":    "절대값+스프레드+경기신호+자산배분영향",
    "m2":             "변화율+통화기조+유동성+자산가격영향",
    "dollar_index":   "강약 정도+추세+암호화폐영향+리스크신호",
    "unemployment":   "현재값+추세+임금압력+경기신호",
    "cpi":            "수준+추세+금리압력+실질수익률",
    "interaction":    "BTC+매크로 조화+순풍/역풍+환경평가"
  },
  "indicator_explanations_en": { ... 동일 형식 영어 ... }
}
"""

HUMAN_TEMPLATE = """[=== 최종 투자 점수 ===]
총점: {total_score}/100 ({signal_type})
기본점수: {base_score}/100
시장국면(Regime): {regime}
국면조정: {regime_adjustment:+.1f}점
상호작용: {interaction_score:+.1f}점

[=== 11개 지표별 점수 (참고용, 점수는 변경 금지) ===]
{indicator_scores_json}

[=== 분석용 원본 데이터 (최근 30일) ===]

** 암호화폐 시장 지표 **
{crypto_data_json}

** 거시경제 지표 **
{macro_data_json}

[=== 분석 작성 요령 ===]
✓ 각 지표를 JSON의 "실제 데이터값"으로 분석하세요
✓ 현재값 + 30일 추이 + 시장 의미를 연결하세요
✓ 정량값을 정성 인사이트로 번역하세요
  예) "BTC가 30일간 -15% 하락했고, 7일간 -8% 추가 하락했으므로, 추세적 약세지만
       아직 극도의 공포 국면은 아니며, 여기서의 추가 하락은 역발상 매수 기회를
       제시할 수 있습니다"
✓ 시장 국면(regime: {regime})을 고려한 해석을 포함하세요
✓ 투자자 입장에서 "이것이 왜 중요한가"를 설명하세요

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

            # 디버그: 응답 길이 및 처음 500자 로깅
            print(f"📝 LLM 응답 길이: {len(response.content)} 자")
            print(f"📝 LLM 응답 처음 200자: {response.content[:200]}")

            llm_response = self._parse_llm_response(response.content)

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

    def _parse_llm_response(self, raw_response: str) -> Dict:
        """LLM 응답에서 JSON 추출 및 파싱

        마크다운 코드 블록, 여백, 텍스트 등을 제거하고 JSON만 추출
        """
        # 1. 마크다운 코드 블록 제거 (```json ... ```)
        content = raw_response
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

        # 2. JSON 객체 찾기 (첫 { 부터 마지막 })
        content = content.strip()
        if "{" in content:
            start = content.find("{")
            # 마지막 닫는 괄호 찾기
            end = content.rfind("}")
            if end != -1 and end > start:
                content = content[start:end+1]

        # 3. JSON 파싱
        try:
            return json.loads(content)
        except json.JSONDecodeError as e:
            print(f"⚠️  JSON 파싱 실패, 기본값 반환: {e}")
            # 파싱 실패 시 기본값 반환
            return {
                "analysis_summary": raw_response[:200],  # 처음 200자
                "analysis_summary_en": "",
                "indicator_explanations": {},
                "indicator_explanations_en": {}
            }

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
