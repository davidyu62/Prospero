"""
Prospero_collector - DynamoDB writer
TB_CRYPTO_DATA, TB_MACRO_DATA에 PutItem
"""

import os
from datetime import datetime
from decimal import Decimal
from typing import Any, Optional

import boto3


def get_table_names() -> tuple[str, str]:
    """환경변수에서 테이블 이름 조회"""
    crypto = os.environ.get("DYNAMODB_CRYPTO_TABLE", "TB_CRYPTO_DATA")
    macro = os.environ.get("DYNAMODB_MACRO_TABLE", "TB_MACRO_DATA")
    return crypto, macro


def save_crypto_data(date: str, crypto_data: dict) -> bool:
    """TB_CRYPTO_DATA에 저장"""
    crypto_table, _ = get_table_names()
    item = _build_crypto_item(date, crypto_data)
    return _put_item(crypto_table, item)


def save_macro_data(date: str, macro_data: dict) -> bool:
    """TB_MACRO_DATA에 저장"""
    _, macro_table = get_table_names()
    item = _build_macro_item(date, macro_data)
    return _put_item(macro_table, item)


def save_data(date: str, crypto_data: Optional[dict], macro_data: Optional[dict]) -> dict:
    """
    크립토/매크로 데이터를 DynamoDB에 저장
    Returns: {crypto_saved: bool, macro_saved: bool}
    """
    result = {"crypto_saved": False, "macro_saved": False}

    if crypto_data:
        result["crypto_saved"] = save_crypto_data(date, crypto_data)
    else:
        print("[INFO] 크립토 데이터가 없어 저장하지 않습니다.")

    if macro_data:
        result["macro_saved"] = save_macro_data(date, macro_data)
    else:
        print("[INFO] 매크로 데이터가 없어 저장하지 않습니다.")

    return result


def _build_timestamp() -> str:
    """ISO 형식 타임스탬프 (yyyy-MM-ddTHH:mm:ss)"""
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S")


def _decimal_to_dynamo(value: Any) -> Any:
    """Python Decimal/number를 DynamoDB 형식으로 변환"""
    if value is None:
        return None
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, (int, float)):
        return str(value)
    return value


def _build_crypto_item(date: str, data: dict) -> dict:
    """CryptoData를 DynamoDB 아이템으로 변환"""
    item = {
        "date": {"S": date},
        "timestamps": {"S": _build_timestamp()},
    }

    print(f"[DEBUG] _build_crypto_item 입력 데이터: {list(data.keys())}")
    for key, value in data.items():
        if value is not None:
            converted = _decimal_to_dynamo(value)
            item[key] = {"N": converted}
            if key in ['fundingRate', 'activeAddresses']:
                print(f"[DEBUG]   {key}: {value} → {{'N': '{converted}'}}")

    return item


def _build_macro_item(date: str, data: dict) -> dict:
    """MacroData를 DynamoDB 아이템으로 변환"""
    item = {
        "date": {"S": date},
        "timestamps": {"S": _build_timestamp()},
    }

    for key, value in data.items():
        if value is not None:
            item[key] = {"N": _decimal_to_dynamo(value)}

    return item


def _put_item(table_name: str, item: dict) -> bool:
    """DynamoDB PutItem 실행"""
    try:
        # 디버그: 저장할 아이템 내용 로깅
        print(f"[DEBUG] {table_name} 저장 전 아이템 필드: {list(item.keys())}")

        # 수치형 필드들 상세 로깅
        if table_name == "TB_CRYPTO_DATA":
            for key in ['fundingRate', 'activeAddresses']:
                if key in item:
                    print(f"[DEBUG]   {key}: {item[key]}")
                else:
                    print(f"[DEBUG]   {key}: 없음")

        client = boto3.client("dynamodb")
        response = client.put_item(TableName=table_name, Item=item)
        print(f"[INFO] {table_name} 저장 완료: {item.get('date', {}).get('S', '')} (ResponseMetadata: {response.get('ResponseMetadata', {}).get('HTTPStatusCode')})")
        return True
    except Exception as e:
        print(f"[ERROR] DynamoDB 저장 실패 ({table_name}): {e}")
        import traceback
        traceback.print_exc()
        return False
