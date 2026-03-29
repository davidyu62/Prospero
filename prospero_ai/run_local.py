#!/usr/bin/env python3
#
# run_local.py
# Prospero AI
#
# 로컬 환경에서 투자 점수 계산 테스트

import os
import sys
import json
from datetime import datetime
from dotenv import load_dotenv

# .env 파일에서 환경변수 로드
load_dotenv()

from data_fetcher import DataFetcher
from score_analyzer import ScoreAnalyzer
from result_writer import ResultWriter


def main():
    """로컬 테스트 실행"""
    # 명령줄 인자에서 날짜 받기 (기본값: 오늘)
    if len(sys.argv) > 1:
        test_date = sys.argv[1]
    else:
        test_date = datetime.utcnow().strftime("%Y%m%d")

    print(f"\n{'='*60}")
    print(f"🚀 Prospero AI 로컬 테스트")
    print(f"{'='*60}")
    print(f"분석 날짜: {test_date}")
    print(f"{'='*60}\n")

    try:
        # 1. 데이터 조회
        print("📥 Step 1: DynamoDB에서 30일치 데이터 조회")
        print("-" * 60)
        fetcher = DataFetcher()
        raw_data = fetcher.get_30day_data(test_date)

        # 크립토 데이터 미리보기
        if raw_data["crypto"]:
            first_date = list(raw_data["crypto"].keys())[0]
            print(f"✅ 크립토 데이터 샘플 ({first_date}):")
            print(f"   BTC 가격: {raw_data['crypto'][first_date].get('btcPrice', 'N/A')}")
            print(f"   공포탐욕지수: {raw_data['crypto'][first_date].get('fearGreedIndex', 'N/A')}")
            print(f"   롱/숏 비율: {raw_data['crypto'][first_date].get('longShortRatio', 'N/A')}")

        # 매크로 데이터 미리보기
        if raw_data["macro"]:
            first_date = list(raw_data["macro"].keys())[0]
            print(f"✅ 매크로 데이터 샘플 ({first_date}):")
            print(f"   기준금리: {raw_data['macro'][first_date].get('interestRate', 'N/A')}%")
            print(f"   CPI: {raw_data['macro'][first_date].get('cpi', 'N/A')}%")
            print(f"   달러인덱스: {raw_data['macro'][first_date].get('dollarIndex', 'N/A')}")

        # 2. 포맷팅
        print("\n📋 Step 2: LLM 프롬프트 포맷팅")
        print("-" * 60)
        formatted_data = fetcher.format_for_llm(raw_data)
        print(f"✅ 크립토 데이터 JSON 길이: {len(formatted_data['crypto_data_json'])} 자")
        print(f"✅ 매크로 데이터 JSON 길이: {len(formatted_data['macro_data_json'])} 자")

        # 3. ChatGPT 분석
        print("\n🤖 Step 3: ChatGPT를 통한 점수 계산")
        print("-" * 60)

        # OpenAI API 키 확인
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            print("❌ OPENAI_API_KEY 환경변수가 설정되지 않았습니다.")
            print("   .env 파일에 OPENAI_API_KEY를 추가하거나")
            print("   export OPENAI_API_KEY=sk-... 로 설정하세요.")
            sys.exit(1)

        analyzer = ScoreAnalyzer()
        analysis_result = analyzer.analyze(
            date=test_date,
            crypto_data_json=formatted_data["crypto_data_json"],
            macro_data_json=formatted_data["macro_data_json"]
        )

        # 4. 결과 출력
        print("\n📊 Step 4: 분석 결과")
        print("-" * 60)
        print(f"✅ 총점: {analysis_result['total_score']:.1f}/100")
        print(f"✅ 신호: {analysis_result['signal_type']} ({analysis_result['signal_color']})")
        print(f"✅ 기본점수: {analysis_result['base_score']:.1f}/100")
        print(f"✅ 시장국면(Regime): {analysis_result['regime']}")
        print(f"✅ 국면 조정: {analysis_result['regime_adjustment']:+.1f}점")
        print(f"✅ 상호작용 점수: {analysis_result['interaction_score']:+.1f}점")
        print(f"\n지표별 점수 (11개):")
        print(f"  - BTC 추세: {analysis_result['btc_trend_score']:.2f}/10")
        print(f"  - 공포탐욕지수: {analysis_result['fear_greed_score']:.2f}/20")
        print(f"  - 롱숏비율: {analysis_result['long_short_score']:.2f}/15")
        print(f"  - OI+가격: {analysis_result['open_interest_score']:.2f}/10")
        print(f"  - 기준금리: {analysis_result['interest_rate_score']:.2f}/10")
        print(f"  - 10년물금리: {analysis_result['treasury10y_score']:.2f}/8")
        print(f"  - M2: {analysis_result['m2_score']:.2f}/8")
        print(f"  - 달러인덱스: {analysis_result['dollar_index_score']:.2f}/7")
        print(f"  - 실업률: {analysis_result['unemployment_score']:.2f}/4")
        print(f"  - CPI: {analysis_result['cpi_score']:.2f}/3")
        print(f"  - 상호작용: {analysis_result['interaction_score']:.2f}/5")
        print(f"\n종합 분석:")
        print(f"  {analysis_result['analysis_summary']}")

        # 5. DynamoDB 저장 (선택사항)
        print("\n💾 Step 5: DynamoDB 저장 (선택사항)")
        print("-" * 60)
        save_choice = input("결과를 DynamoDB에 저장하시겠습니까? (y/n): ").strip().lower()
        if save_choice == 'y':
            writer = ResultWriter()
            writer.write_analysis(test_date, analysis_result)
            print("✅ DynamoDB 저장 완료")
        else:
            print("⏭️  저장을 건너뜁니다.")

        # 6. 전체 결과 JSON 출력
        print("\n" + "="*60)
        print("📄 전체 분석 결과 (JSON)")
        print("="*60)
        print(json.dumps(analysis_result, indent=2, ensure_ascii=False))

    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
