#
# data_fetcher.py
# Prospero AI
#
# DynamoDB에서 최근 30일치 암호화폐 및 거시경제 데이터를 조회

import boto3
import json
from datetime import datetime, timedelta
from typing import Dict, Optional

class DataFetcher:
    def __init__(self, region: str = "ap-northeast-2"):
        self.dynamodb = boto3.client("dynamodb", region_name=region)
        self.crypto_table = "TB_CRYPTO_DATA"
        self.macro_table = "TB_MACRO_DATA"

    def generate_date_list(self, end_date: str, days: int = 30) -> list:
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
                else:
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
                else:
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
        DynamoDB 형식 {S, N, NULL, BOOL, M, L, SS, NS, BS} → Python dict 변환
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

    def get_30day_data(self, date_str: str) -> Dict[str, any]:
        """
        주어진 날짜 기준 최근 30일치 크립토 및 거시경제 데이터 조회

        Args:
            date_str: "yyyyMMdd" 형식의 날짜 문자열

        Returns:
            {
                "date": "20250304",
                "crypto": {date: {...}, ...},
                "macro": {date: {...}, ...}
            }
        """
        dates = self.generate_date_list(date_str, days=30)
        print(f"🔍 조회 대상 날짜: {dates}")

        crypto_data = self.fetch_crypto_data(dates)
        macro_data = self.fetch_macro_data(dates)

        # 크립토 데이터 검증
        if not crypto_data:
            raise ValueError(f"❌ TB_CRYPTO_DATA 조회 실패: 30일치 데이터 중 하나도 없음")

        # 매크로 데이터 검증
        if not macro_data:
            raise ValueError(f"❌ TB_MACRO_DATA 조회 실패: 30일치 데이터 중 하나도 없음")

        # 두 테이블의 조회된 날짜 비교
        crypto_dates = set(crypto_data.keys())
        macro_dates = set(macro_data.keys())

        missing_crypto_dates = set(dates) - crypto_dates
        missing_macro_dates = set(dates) - macro_dates

        if missing_crypto_dates:
            print(f"⚠️  TB_CRYPTO_DATA 누락 날짜: {missing_crypto_dates}")
        if missing_macro_dates:
            print(f"⚠️  TB_MACRO_DATA 누락 날짜: {missing_macro_dates}")

        # 최소 데이터 요구: 30일 중 최소 20일 이상 필요
        min_required_days = 20
        if len(crypto_dates) < min_required_days:
            raise ValueError(f"❌ TB_CRYPTO_DATA 불충분: {len(crypto_dates)}일/30일 (최소 {min_required_days}일 필요)")

        if len(macro_dates) < min_required_days:
            raise ValueError(f"❌ TB_MACRO_DATA 불충분: {len(macro_dates)}일/30일 (최소 {min_required_days}일 필요)")

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
        crypto_data = data.get("crypto", {})
        macro_data = data.get("macro", {})

        # 필수 필드 검증
        required_crypto_fields = ["btcPrice", "fearGreedIndex", "longShortRatio", "openInterest"]
        required_macro_fields = ["interestRate", "treasury10y", "cpi", "m2", "unemployment", "dollarIndex"]

        # 각 날짜별 크립토 데이터 검증
        for date, crypto_item in crypto_data.items():
            missing_fields = [f for f in required_crypto_fields if f not in crypto_item or crypto_item[f] is None]
            if missing_fields:
                raise ValueError(f"❌ TB_CRYPTO_DATA 필수 필드 누락 ({date}): {missing_fields}")

        # 각 날짜별 매크로 데이터 검증
        for date, macro_item in macro_data.items():
            missing_fields = [f for f in required_macro_fields if f not in macro_item or macro_item[f] is None]
            if missing_fields:
                raise ValueError(f"❌ TB_MACRO_DATA 필수 필드 누락 ({date}): {missing_fields}")

        crypto_str = json.dumps(crypto_data, indent=2, ensure_ascii=False)
        macro_str = json.dumps(macro_data, indent=2, ensure_ascii=False)

        print(f"✅ 데이터 검증 완료: 크립토 {len(crypto_data)}일, 매크로 {len(macro_data)}일")

        return {
            "crypto_data_json": crypto_str,
            "macro_data_json": macro_str
        }
