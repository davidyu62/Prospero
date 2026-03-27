"""
Prospero_collector - Lambda handler
크립토/매크로 데이터 수집 후 DynamoDB에 저장
"""

import os
from datetime import datetime

import boto3

# .env 로드 (로컬 실행 시)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from crypto_collector import get_crypto_data
from macro_collector import get_macro_data
from dynamodb_writer import save_data


def get_fred_api_key() -> str:
    """
    FRED API 키 조회
    1. 환경변수 FRED_API_KEY
    2. SSM Parameter Store (FRED_API_KEY_PARAM)
    """
    key = os.environ.get("FRED_API_KEY")
    if key:
        return key

    param_name = os.environ.get("FRED_API_KEY_PARAM", "/prospero/fred-api-key")
    try:
        client = boto3.client("ssm")
        resp = client.get_parameter(Name=param_name, WithDecryption=True)
        return resp["Parameter"]["Value"]
    except Exception as e:
        print(f"[WARN] SSM에서 FRED API 키 조회 실패: {e}")
        return ""


def lambda_handler(event, context):
    """
    Lambda 핸들러
    event: EventBridge Scheduled Event 또는 수동 호출
    """
    # 대상 날짜 (오늘 또는 event에서 지정)
    target_date = _get_target_date(event)
    date_str = target_date.strftime("%Y%m%d")

    print(f"[INFO] Prospero_collector 실행 시작 - 날짜: {date_str}")

    try:
        # 1. 크립토 데이터 조회
        crypto_data = get_crypto_data(date_str)
        print(f"[INFO] 크립토 데이터 조회 완료: {crypto_data is not None}")

        # 2. 매크로 데이터 조회
        fred_key = get_fred_api_key()
        macro_data = get_macro_data(date_str, fred_key)
        print(f"[INFO] 매크로 데이터 조회 완료: {macro_data is not None}")

        # 3. DynamoDB 저장
        result = save_data(date_str, crypto_data, macro_data)
        print(f"[INFO] 저장 결과: {result}")

        return {
            "statusCode": 200,
            "body": {
                "date": date_str,
                "crypto_saved": result["crypto_saved"],
                "macro_saved": result["macro_saved"],
            },
        }
    except Exception as e:
        print(f"[ERROR] 배치 실행 실패: {e}")
        raise


def _get_target_date(event: dict) -> datetime:
    """대상 날짜 결정 (event 입력 또는 오늘)"""
    if event and isinstance(event, dict):
        if "date" in event:
            # "20241201" 형식
            date_str = str(event["date"])
            return datetime.strptime(date_str, "%Y%m%d")
        if "targetDate" in event:
            # "2024-12-01" 형식
            date_str = str(event["targetDate"])
            return datetime.strptime(date_str, "%Y-%m-%d")
    return datetime.now()


# 로컬 실행용 (python lambda_function.py)
if __name__ == "__main__":
    # 로컬 테스트
    result = lambda_handler({}, None)
    print("Result:", result)
