#
# result_writer.py
# Prospero AI
#
# 분석 결과를 TB_AI_INSIGHT 테이블에 저장

import boto3
import json
from datetime import datetime
from typing import Dict, Optional

class ResultWriter:
    def __init__(self, region: str = "ap-northeast-2"):
        self.dynamodb = boto3.client("dynamodb", region_name=region)
        self.table_name = "TB_AI_INSIGHT"

    def write_analysis(self, date: str, analysis_result: Dict) -> None:
        """
        계산된 투자 점수 및 분석 결과를 TB_AI_INSIGHT 테이블에 저장

        Args:
            date: "yyyyMMdd" 형식의 날짜
            analysis_result: ScoreAnalyzer로부터의 분석 결과 Dict
        """
        try:
            # DynamoDB 항목 구성
            item = self._build_dynamodb_item(date, analysis_result)

            # PutItem 호출
            self.dynamodb.put_item(
                TableName=self.table_name,
                Item=item
            )

            print(f"✅ 분석 결과 저장 완료 (날짜: {date}, 총점: {analysis_result['total_score']:.1f})")

        except Exception as e:
            print(f"❌ 분석 결과 저장 실패: {e}")
            raise

    def _build_dynamodb_item(self, date: str, analysis_result: Dict) -> Dict:
        """
        Python Dict를 DynamoDB 형식으로 변환

        DynamoDB 저장 형식: {\"attributeName\": {\"S\": \"value\"}, \"num\": {\"N\": \"123.45\"}}
        """
        item = {
            # 파티션 키
            "date": {"S": date},

            # 종합 점수 (v4.0)
            "total_score": {"N": str(analysis_result["total_score"])},
            "base_score": {"N": str(analysis_result["base_score"])},
            "regime": {"S": analysis_result["regime"]},
            "regime_adjustment": {"N": str(analysis_result["regime_adjustment"])},

            # 신호
            "signal_type": {"S": analysis_result["signal_type"]},
            "signal_color": {"S": analysis_result["signal_color"]},

            # 지표별 점수 (v4.0 - 11개 지표)
            "btc_trend_score": {"N": str(analysis_result["btc_trend_score"])},
            "fear_greed_score": {"N": str(analysis_result["fear_greed_score"])},
            "long_short_score": {"N": str(analysis_result["long_short_score"])},
            "open_interest_score": {"N": str(analysis_result["open_interest_score"])},
            "interest_rate_score": {"N": str(analysis_result["interest_rate_score"])},
            "treasury10y_score": {"N": str(analysis_result["treasury10y_score"])},
            "m2_score": {"N": str(analysis_result["m2_score"])},
            "dollar_index_score": {"N": str(analysis_result["dollar_index_score"])},
            "unemployment_score": {"N": str(analysis_result["unemployment_score"])},
            "cpi_score": {"N": str(analysis_result["cpi_score"])},
            "interaction_score": {"N": str(analysis_result["interaction_score"])},

            # 분석 내용 (한국어)
            "analysis_summary": {"S": analysis_result["analysis_summary"]},
            "indicator_explanations": {"S": json.dumps(analysis_result["indicator_explanations"], ensure_ascii=False)},

            # 분석 내용 (영어)
            "analysis_summary_en": {"S": analysis_result["analysis_summary_en"]},
            "indicator_explanations_en": {"S": json.dumps(analysis_result["indicator_explanations_en"], ensure_ascii=False)},

            # 타임스탬프
            "created_at": {"S": datetime.utcnow().isoformat() + "Z"}
        }

        return item

    def read_analysis(self, date: str) -> Optional[Dict]:
        """
        저장된 분석 결과를 조회

        Args:
            date: "yyyyMMdd" 형식의 날짜

        Returns:
            분석 결과 Dict 또는 없으면 None
        """
        try:
            response = self.dynamodb.get_item(
                TableName=self.table_name,
                Key={"date": {"S": date}}
            )

            if "Item" not in response:
                return None

            return self._parse_dynamodb_item(response["Item"])

        except Exception as e:
            print(f"❌ 분석 결과 조회 실패: {e}")
            raise

    def _parse_dynamodb_item(self, item: Dict) -> Dict:
        """
        DynamoDB 형식 {S, N, NULL, BOOL, M, L, SS, NS, BS} → Python Dict로 변환
        """
        result = {}
        for key, value in item.items():
            if "S" in value:
                result[key] = value["S"]
            elif "N" in value:
                num_str = value["N"]
                if "." in num_str:
                    result[key] = float(num_str)
                else:
                    result[key] = int(num_str)
            elif "NULL" in value:
                result[key] = None
            elif "BOOL" in value:
                result[key] = value["BOOL"]
            elif "M" in value:
                # Map 타입 재귀 처리
                result[key] = self._parse_dynamodb_item(value["M"])
            elif "L" in value:
                # List 타입 처리
                result[key] = [self._parse_dynamodb_item({"v": item})["v"] for item in value["L"]]
            elif "SS" in value:
                # String Set
                result[key] = set(value["SS"])
            elif "NS" in value:
                # Number Set
                result[key] = {float(n) if "." in n else int(n) for n in value["NS"]}
            elif "BS" in value:
                # Binary Set
                result[key] = set(value["BS"])
        return result
