#
# data_fetcher.py
# Prospero AI
#
# DynamoDB에서 최근 7일치 암호화폐 및 거시경제 데이터를 조회

import boto3
import json
from datetime import datetime, timedelta
from typing import Dict, Optional

class DataFetcher:
    def __init__(self, region: str = "ap-northeast-2"):
        self.dynamodb = boto3.client("dynamodb", region_name=region)
        self.crypto_table = "TB_CRYPTO_DATA"
        self.macro_table = "TB_MACRO_DATA"

    def generate_date_list(self, end_date: str, days: int = 7) -> list:
        """
        날짜 문자열(yyyyMMdd)에서 역순으로 N일치 날짜 생성
        예: "20250304"에서 시작하면 ["20250304", "20250303", ..., "20250226"]
        """
        end = datetime.strptime(end_date, "%Y%m%d")
        dates = []
        for i in range(days):
            date_obj = end - timedelta(days=i)
            dates.append(date_obj.strftime("%Y%m%d"))
        return dates

    def fetch_crypto_data(self, dates: list) -> Dict[str, Dict]:
        """
        TB_CRYPTO_DATA에서 여러 날짜의 데이터를 개별 Query로 조회

        Returns: {date: {btcPrice, fearGreedIndex, ...}}
        """
        crypto_data = {}

        for date in dates:
            try:
                # Query 시도: date 파티션 키로 조회 (최신 1건)
                response = self.dynamodb.query(
                    TableName=self.crypto_table,
                    KeyConditionExpression="#date = :date",
                    ExpressionAttributeNames={"#date": "date"},
                    ExpressionAttributeValues={":date": {"S": date}},
                    ScanIndexForward=False,  # 최신순
                    Limit=1
                )

                items = response.get("Items", [])
                if items:
                    item = items[0]
                    date_str = item["date"]["S"]
                    crypto_data[date_str] = self._parse_dynamodb_item(item)
                    continue

                # Scan 폴백: Query가 결과를 못 찾으면 Scan으로 date 필터
                response = self.dynamodb.scan(
                    TableName=self.crypto_table,
                    FilterExpression="#date = :date",
                    ExpressionAttributeNames={"#date": "date"},
                    ExpressionAttributeValues={":date": {"S": date}},
                    Limit=100
                )

                items = response.get("Items", [])
                if items:
                    # timestamps 기준 최신 1건
                    latest = max(items, key=lambda x: x.get("timestamps", {}).get("S", ""))
                    date_str = latest["date"]["S"]
                    crypto_data[date_str] = self._parse_dynamodb_item(latest)

            except Exception as e:
                print(f"⚠️  {date} 크립토 데이터 조회 실패: {e}")
                # 한 날짜 실패해도 계속 진행
                continue

        print(f"📊 크립토 데이터 조회: {len(crypto_data)}개 항목 반환")
        return crypto_data

    def fetch_macro_data(self, dates: list) -> Dict[str, Dict]:
        """
        TB_MACRO_DATA에서 여러 날짜의 데이터를 개별 Query로 조회

        Returns: {date: {interestRate, cpi, ...}}
        """
        macro_data = {}

        for date in dates:
            try:
                # Query 시도: date 파티션 키로 조회 (최신 1건)
                response = self.dynamodb.query(
                    TableName=self.macro_table,
                    KeyConditionExpression="#date = :date",
                    ExpressionAttributeNames={"#date": "date"},
                    ExpressionAttributeValues={":date": {"S": date}},
                    ScanIndexForward=False,  # 최신순
                    Limit=1
                )

                items = response.get("Items", [])
                if items:
                    item = items[0]
                    date_str = item["date"]["S"]
                    macro_data[date_str] = self._parse_dynamodb_item(item)
                    continue

                # Scan 폴백: Query가 결과를 못 찾으면 Scan으로 date 필터
                response = self.dynamodb.scan(
                    TableName=self.macro_table,
                    FilterExpression="#date = :date",
                    ExpressionAttributeNames={"#date": "date"},
                    ExpressionAttributeValues={":date": {"S": date}},
                    Limit=100
                )

                items = response.get("Items", [])
                if items:
                    # timestamps 기준 최신 1건
                    latest = max(items, key=lambda x: x.get("timestamps", {}).get("S", ""))
                    date_str = latest["date"]["S"]
                    macro_data[date_str] = self._parse_dynamodb_item(latest)

            except Exception as e:
                print(f"⚠️  {date} 거시경제 데이터 조회 실패: {e}")
                # 한 날짜 실패해도 계속 진행
                continue

        print(f"📊 거시경제 데이터 조회: {len(macro_data)}개 항목 반환")
        return macro_data

    def _parse_dynamodb_item(self, item: Dict) -> Dict:
        """
        DynamoDB 형식 {S: "value", N: "number"} → Python dict 변환
        """
        result = {}
        for key, value in item.items():
            if "S" in value:
                result[key] = value["S"]
            elif "N" in value:
                num_str = value["N"]
                # 정수인지 실수인지 판단
                if "." in num_str:
                    result[key] = float(num_str)
                else:
                    result[key] = int(num_str)
        return result

    def get_7day_data(self, date_str: str) -> Dict[str, any]:
        """
        주어진 날짜 기준 최근 7일치 크립토 및 거시경제 데이터 조회

        Args:
            date_str: "yyyyMMdd" 형식의 날짜 문자열

        Returns:
            {
                "date": "20250304",
                "crypto": {date: {...}, ...},
                "macro": {date: {...}, ...}
            }
        """
        dates = self.generate_date_list(date_str, days=7)
        print(f"🔍 조회 대상 날짜: {dates}")

        crypto_data = self.fetch_crypto_data(dates)
        macro_data = self.fetch_macro_data(dates)

        return {
            "date": date_str,
            "crypto": crypto_data,
            "macro": macro_data
        }

    def format_for_llm(self, data: Dict) -> Dict[str, str]:
        """
        LLM(ChatGPT)에 전달할 형식으로 데이터 포맷팅
        JSON 문자열로 변환하여 프롬프트에 주입 가능하게
        """
        crypto_str = json.dumps(data["crypto"], indent=2, ensure_ascii=False)
        macro_str = json.dumps(data["macro"], indent=2, ensure_ascii=False)

        return {
            "crypto_data_json": crypto_str,
            "macro_data_json": macro_str
        }
