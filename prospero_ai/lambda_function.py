#
# lambda_function.py
# Prospero AI
#
# Lambda 함수 진입점 - 일일 스케줄러로 실행되어 투자 점수 계산 및 저장

import os
import json
from datetime import datetime, timedelta
from data_fetcher import DataFetcher
from score_analyzer import ScoreAnalyzer
from result_writer import ResultWriter


def lambda_handler(event, context):
    """
    AWS Lambda 진입점

    EventBridge 스케줄러로부터 매일 UTC 05:00에 호출됨
    (event와 context는 무시하고 시스템 시간 사용)

    Returns:
        {
            \"statusCode\": 200,
            \"body\": \"점수 계산 및 저장 완료\"
        }
    """
    try:
        print("🚀 Prospero AI Lambda 시작")

        # 1. 분석 대상 날짜 결정
        today = datetime.utcnow()
        analysis_date = today.strftime("%Y%m%d")
        print(f"📅 분석 날짜: {analysis_date}")

        # 2. DynamoDB에서 30일치 데이터 조회
        print("📥 DynamoDB에서 데이터 조회 중...")
        fetcher = DataFetcher()
        raw_data = fetcher.get_30day_data(analysis_date)

        # 3. LLM용 포맷팅
        formatted_data = fetcher.format_for_llm(raw_data)

        # 4. ChatGPT를 통한 점수 계산
        print("🤖 ChatGPT를 통한 분석 중...")
        analyzer = ScoreAnalyzer()
        analysis_result = analyzer.analyze(
            date=analysis_date,
            crypto_data_json=formatted_data["crypto_data_json"],
            macro_data_json=formatted_data["macro_data_json"]
        )

        # 5. 결과를 DynamoDB에 저장
        print("💾 결과를 DynamoDB에 저장 중...")
        writer = ResultWriter()
        writer.write_analysis(analysis_date, analysis_result)

        # 6. 성공 응답 (저장 완료 메시지만)
        response = {
            "statusCode": 200,
            "body": json.dumps({
                "message": "점수 계산 및 저장 완료",
                "date": analysis_date
            }, ensure_ascii=False)
        }

        print("✅ Prospero AI Lambda 완료")
        return response

    except Exception as e:
        import traceback
        print(f"❌ 오류 발생: {e}")
        print(traceback.format_exc())
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "traceback": traceback.format_exc()
            }, ensure_ascii=False)
        }


# 로컬 테스트용
if __name__ == "__main__":
    result = lambda_handler({}, {})
    print("\n=== Lambda 실행 결과 ===")
    print(json.dumps(json.loads(result["body"]), indent=2, ensure_ascii=False))
