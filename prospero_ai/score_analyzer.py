#
# score_analyzer.py
# Prospero AI
#
# LangChain + ChatGPT를 사용한 투자 점수 계산 및 분석

import json
import os
from typing import Dict, Optional
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import JsonOutputParser

# 투자 공식 System Prompt (v2.0)
SYSTEM_PROMPT = """당신은 비트코인 투자 분석 전문가입니다. 역발상(Contrarian) 전략 + 30일 추세 기반으로
제공된 공식에 따라 정확히 점수를 계산하고 상세한 분석을 작성하세요.

[투자 점수 공식 v2.0 - 총 100점]

★ 크립토 지표 (55점)
1. BTC 30일 가격 추세 역발상 (10점):
   - 30일 변화율 기반 역발상 구간
   - 급락(-30% 이상): 8점, 하락(-15~-30%): 7점, 약하락(-5~-15%): 6점
   - 횡보(±5%): 5점, 상승(+5~+20%): 4점, 강상승(+20~+40%): 3점, 급등(+40% 이상): 1점

2. 공포탐욕지수 30일 추세 반영 (20점):
   - 현재값×0.6 + 30일평균×0.4 가중평균 적용
   - 극도공포(0~15): 20점, 공포(16~30): 17점, 약공포(31~45): 13점
   - 중립(46~55): 10점, 탐욕(56~70): 6점, 강탐욕(71~85): 3점, 극탐욕(86~100): 0점

3. 롱숏비율 (15점):
   - ≤0.90 → 15점, 0.91-1.00 → 12점, 1.01-1.20 → 8점, 1.21-1.50 → 4점, >1.50 → 0점

4. OI + 가격 방향 (10점):
   - 가격↓OI↓ → 10점, 가격↑OI↓ → 6점, 가격↑OI↑ → 5점, 가격↓OI↑ → 3점, 중립 → 5점

★ 매크로 지표 (40점)
5. 기준금리 + 추세 (10점):
   - 수준별 기본점수: ≤1% → 9점, 1-2.5% → 8점, 2.5-4% → 6점, 4-5% → 3점, >5% → 1점
   - 30일 추세 보정: 하락추세 +1점, 상승추세 -1점

6. 10년물 국채금리 + 장단기 스프레드 (8점):
   - 수준별 기본점수: <3% → 6점, 3-4% → 5점, 4-5% → 3점, >5% → 1점
   - 스프레드 보정: 역전(<0%) → -1~-2점, 플랫(0~0.5%) → 0점, 정상(>0.5%) → +1점

7. M2 변화율 (8점):
   - >+1.0% → 8점, +0.3~+1.0% → 6점, 0~+0.3% → 4점, -0.3~0% → 2점, <-0.3% → 0점

8. 달러인덱스 + 추세 (7점):
   - 수준별 기본점수: <95 → 6점, 95-100 → 5점, 100-105 → 3점, 105-110 → 1점, ≥110 → 0점
   - 30일 추세 보정: 약세추세 +1점, 강세추세 -1점

9. 실업률 30일 변화 (4점):
   - 급상승(>+0.5%p) → 1점, 완만상승(0~+0.5%p) → 2점, 보합 → 3점
   - 하락(-0.5~0%) → 3점, 급하락(<-0.5%p) → 4점

10. CPI (3점):
    - <2% → 3점, 2-3% → 2점, 3-4.5% → 1점, ≥4.5% → 0점

★ 상호작용 점수 (5점)
11. BTC 방향 × 매크로 환경:
    - BTC 하락 + 긍정매크로(≥55%) → +5점 (역발상 최고 매수)
    - BTC 상승 + 긍정매크로 → +3점
    - BTC 하락/상승 + 중립매크로 → +2점
    - BTC 상승 + 부정매크로(<45%) → -3점 (경고)
    - BTC 하락 + 부정매크로 → 0점 (낙폭 과대 방지)

★ 신호 해석
- 75-100: Strong Buy (강력 매수) - strong_buy
- 58-74: Buy (매수) - buy
- 38-57: Hold (관망) - hold
- 22-37: Partial Sell (부분 매도) - partial_sell
- 0-21: Strong Sell (강력 매도) - strong_sell

[응답 JSON 형식 (필수)]
반드시 아래 형식의 JSON을 반환하세요:
{
  "total_score": (0~100의 숫자),
  "signal_type": "Strong Buy|Buy|Hold|Partial Sell|Strong Sell",
  "signal_color": "strong_buy|buy|hold|partial_sell|strong_sell",
  "crypto_score": (0~55의 숫자),
  "macro_score": (0~40의 숫자),
  "btc_trend_score": (0~10의 숫자),
  "fear_greed_score": (0~20의 숫자),
  "long_short_score": (0~15의 숫자),
  "open_interest_score": (0~10의 숫자),
  "interest_rate_score": (0~10의 숫자),
  "treasury10y_score": (0~8의 숫자),
  "m2_score": (0~8의 숫자),
  "dollar_index_score": (0~7의 숫자),
  "unemployment_score": (0~4의 숫자),
  "cpi_score": (0~3의 숫자),
  "interaction_score": (-3~5의 숫자),
  "analysis_summary": "한국어 2~3문장 종합분석 (구체적 수치 포함: BTC 추세, 주요 매크로 지표, 투자 시사점)",
  "analysis_summary_en": "English 2~3 sentence comprehensive analysis (include specific figures: BTC trend, key macro indicators, investment implication)",
  "indicator_explanations": {
    "btc_trend": "BTC 30일 추세에 따른 역발상 매수기회 분석 (구체적 낙폭 또는 상승폭 포함)",
    "fear_greed": "공포탐욕지수 현재값과 30일 추세의 시사점",
    "long_short": "롱숏비율이 나타내는 시장 심리와 향후 방향성",
    "open_interest": "가격과 OI 조합이 시사하는 시장 구조",
    "interest_rate": "기준금리 수준과 추세가 유동성에 미치는 영향",
    "treasury10y": "10년물 금리 수준과 장단기 역전 여부의 경기 전망",
    "m2": "M2 증감이 암호화폐 수요에 미치는 영향",
    "dollar_index": "달러인덱스 강약이 신흥자산 수요에 미치는 영향",
    "unemployment": "실업률 추세가 FED 정책 전환을 시사하는 정도",
    "cpi": "인플레이션 수준이 금리 인상 압박에 미치는 정도",
    "interaction": "BTC 가격 추세와 매크로 환경의 일치 여부가 신호의 신뢰도에 미치는 영향"
  },
  "indicator_explanations_en": {
    "btc_trend": "Analysis of contrarian buying opportunities based on 30-day BTC trend (include specific decline or rise percentage)",
    "fear_greed": "Implication of current Fear & Greed Index value and 30-day trend",
    "long_short": "Market sentiment indicated by Long/Short ratio and directional outlook",
    "open_interest": "Market structure implications from price-OI combination",
    "interest_rate": "Impact of Fed Funds Rate level and trend on liquidity",
    "treasury10y": "Economic outlook from 10-year Treasury level and yield curve inversion",
    "m2": "Impact of M2 growth/decline on cryptocurrency demand",
    "dollar_index": "Impact of dollar strength/weakness on emerging asset demand",
    "unemployment": "Degree to which unemployment trend signals Fed policy pivot",
    "cpi": "Degree to which inflation level puts upward pressure on rates",
    "interaction": "How alignment of BTC trend and macro environment affects signal reliability"
  }
}
"""

HUMAN_TEMPLATE = """다음 최근 30일 시장 데이터를 기반으로 오늘({date}) 비트코인 투자 점수를 계산하세요.

[크립토 데이터 (최근 30일, yyyyMMdd 기준)]
{crypto_data_json}

[거시경제 데이터 (최근 30일, yyyyMMdd 기준)]
{macro_data_json}

공식에 정확히 따라 점수를 계산하고, 위 JSON 형식으로 상세한 분석 결과를 반환하세요.

분석 작성 시 다음을 필수 포함:
1. analysis_summary: 한국어로 BTC 가격 추세, 주요 매크로 지표 현황, 투자 시사점을 구체적 수치와 함께 2~3문장으로 작성
2. analysis_summary_en: 영어로 같은 내용을 2~3문장으로 작성
3. indicator_explanations: 각 지표의 한국어 설명을 구체적이고 실무적으로 작성
4. indicator_explanations_en: 각 지표의 영어 설명 작성

정확한 점수 계산과 함께 실질적인 투자 판단 기준을 제시하세요."""


class ScoreAnalyzer:
    def __init__(self, openai_api_key: Optional[str] = None, model: str = "gpt-4o-mini"):
        """
        LangChain + ChatGPT 기반 점수 계산기 초기화

        Args:
            openai_api_key: OpenAI API 키 (없으면 환경변수 OPENAI_API_KEY 사용)
            model: 사용할 ChatGPT 모델 (기본값: gpt-4o-mini)
        """
        api_key = openai_api_key or os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OpenAI API 키가 설정되지 않았습니다.")

        self.llm = ChatOpenAI(
            model_name=model,
            temperature=0,  # 결정론적 결과
            openai_api_key=api_key
        )

        # Prompt 템플릿 구성
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", SYSTEM_PROMPT),
            ("human", HUMAN_TEMPLATE)
        ])

        # JSON 파서
        self.parser = JsonOutputParser()

    def analyze(self, date: str, crypto_data_json: str, macro_data_json: str) -> Dict:
        """
        LangChain을 통한 투자 점수 계산

        Args:
            date: "yyyyMMdd" 형식의 분석 날짜
            crypto_data_json: JSON 문자열 형식의 크립토 데이터
            macro_data_json: JSON 문자열 형식의 거시경제 데이터

        Returns:
            계산된 점수 및 분석 결과 Dict
        """
        print(f"🤖 ChatGPT를 통한 점수 계산 시작 (날짜: {date})...")

        try:
            # Prompt 구성 (직접 문자열 포맷팅)
            human_msg = HUMAN_TEMPLATE.format(
                date=date,
                crypto_data_json=crypto_data_json,
                macro_data_json=macro_data_json
            )

            # LLM 호출
            from langchain_core.messages import SystemMessage, HumanMessage
            messages = [
                SystemMessage(content=SYSTEM_PROMPT),
                HumanMessage(content=human_msg)
            ]
            response = self.llm.invoke(messages)
            response_text = response.content

            print(f"✅ ChatGPT 응답 수신")
            print(f"📄 응답 미리보기: {response_text[:200]}...")

            # JSON 파싱
            result = self._parse_json_response(response_text)

            # 검증
            self._validate_result(result)
            print(f"✅ 점수 계산 완료: {result['total_score']:.1f}점 ({result['signal_type']})")

            return result

        except Exception as e:
            print(f"❌ 점수 계산 실패: {e}")
            raise

    def _parse_json_response(self, response_text: str) -> Dict:
        """
        ChatGPT 응답에서 JSON을 파싱 (다양한 형식 지원)
        """
        try:
            # 1. 직접 JSON 파싱 시도
            return json.loads(response_text)
        except json.JSONDecodeError:
            pass

        # 2. 마크다운 코드 블록 제거
        if "```json" in response_text:
            json_str = response_text.split("```json")[1].split("```")[0].strip()
            try:
                return json.loads(json_str)
            except json.JSONDecodeError:
                pass

        if "```" in response_text:
            try:
                json_str = response_text.split("```")[1].split("```")[0].strip()
                return json.loads(json_str)
            except json.JSONDecodeError:
                pass

        # 3. JSON 객체 {} 찾기
        start_idx = response_text.find("{")
        if start_idx == -1:
            raise ValueError(f"JSON 객체를 찾을 수 없음: {response_text[:100]}")

        # 끝에서부터 } 찾기 (중첩된 객체 처리)
        end_idx = response_text.rfind("}")
        if end_idx == -1 or end_idx <= start_idx:
            raise ValueError(f"JSON 객체 끝을 찾을 수 없음: {response_text[:100]}")

        json_str = response_text[start_idx:end_idx + 1].strip()

        try:
            return json.loads(json_str)
        except json.JSONDecodeError as e:
            print(f"⚠️  JSON 파싱 실패, 원본 응답: {response_text[:300]}")
            raise ValueError(f"JSON 파싱 실패: {str(e)}")

    def _validate_result(self, result: Dict) -> None:
        """
        LLM 응답 유효성 검증
        """
        required_keys = [
            "total_score", "signal_type", "signal_color",
            "crypto_score", "macro_score",
            "btc_trend_score", "fear_greed_score", "long_short_score",
            "open_interest_score", "interest_rate_score", "treasury10y_score", "m2_score",
            "dollar_index_score", "unemployment_score", "cpi_score", "interaction_score",
            "analysis_summary", "analysis_summary_en",
            "indicator_explanations", "indicator_explanations_en"
        ]

        for key in required_keys:
            if key not in result:
                raise ValueError(f"필수 필드 누락: {key}")

        # 점수 범위 검증
        if not (0 <= result["total_score"] <= 100):
            raise ValueError(f"총점 범위 오류: {result['total_score']}")
        if not (0 <= result["crypto_score"] <= 55):
            raise ValueError(f"크립토 점수 범위 오류: {result['crypto_score']}")
        if not (0 <= result["macro_score"] <= 40):
            raise ValueError(f"매크로 점수 범위 오류: {result['macro_score']}")
        if not (-3 <= result["interaction_score"] <= 5):
            raise ValueError(f"상호작용 점수 범위 오류: {result['interaction_score']}")

        # 신호 타입 검증
        valid_signals = ["Strong Buy", "Buy", "Hold", "Partial Sell", "Strong Sell"]
        if result["signal_type"] not in valid_signals:
            raise ValueError(f"잘못된 신호 타입: {result['signal_type']}")
