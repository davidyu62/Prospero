"""
Prospero_collector - DynamoDB reader (API용)
TB_CRYPTO_DATA, TB_MACRO_DATA에서 날짜별로 조회
"""

import os
from typing import Any, Optional

import boto3


def get_table_names() -> tuple[str, str]:
    """환경변수에서 테이블 이름 조회"""
    crypto = os.environ.get("DYNAMODB_CRYPTO_TABLE", "TB_CRYPTO_DATA")
    macro = os.environ.get("DYNAMODB_MACRO_TABLE", "TB_MACRO_DATA")
    return crypto, macro


def get_crypto_data_by_date(date: str) -> Optional[dict]:
    """
    TB_CRYPTO_DATA에서 특정 날짜 데이터 조회
    date: yyyyMMdd 형식
    Returns: {btcPrice, longShortRatio, exchangeBalance, fearGreedIndex, openInterest, newAddresses} 또는 None
    """
    crypto_table, _ = get_table_names()
    item = _query_latest_by_date(crypto_table, date)
    if not item:
        return None
    return _item_to_crypto(item)


def get_macro_data_by_date(date: str) -> Optional[dict]:
    """
    TB_MACRO_DATA에서 특정 날짜 데이터 조회
    date: yyyyMMdd 형식
    Returns: {interestRate, treasury10y, cpi, m2, unemployment, dollarIndex} 또는 None
    """
    _, macro_table = get_table_names()
    item = _query_latest_by_date(macro_table, date)
    if not item:
        return None
    return _item_to_macro(item)


def _query_latest_by_date(table_name: str, date: str) -> Optional[dict]:
    """
    date로 Query, timestamps 내림차순 정렬 후 최신 1건 반환
    """
    try:
        client = boto3.client("dynamodb")
        resp = client.query(
            TableName=table_name,
            KeyConditionExpression="#date = :date",
            ExpressionAttributeNames={"#date": "date"},
            ExpressionAttributeValues={":date": {"S": date}},
            ScanIndexForward=False,  # 내림차순
            Limit=1,
        )
        items = resp.get("Items", [])
        if items:
            return items[0]
        return None
    except Exception as e:
        print(f"[ERROR] DynamoDB 조회 실패 ({table_name}): {e}")
        return None


def _n_to_float(av: dict) -> Optional[float]:
    """DynamoDB N 타입을 float으로 변환"""
    if not av or "N" not in av:
        return None
    try:
        return float(av["N"])
    except (ValueError, TypeError):
        return None


def _n_to_int(av: dict) -> Optional[int]:
    """DynamoDB N 타입을 int로 변환"""
    if not av or "N" not in av:
        return None
    try:
        return int(float(av["N"]))
    except (ValueError, TypeError):
        return None


def _item_to_crypto(item: dict) -> dict:
    """DynamoDB 아이템을 CryptoData dict로 변환"""
    return {
        "btcPrice": _n_to_float(item.get("btcPrice")),
        "longShortRatio": _n_to_float(item.get("longShortRatio")),
        "exchangeBalance": _n_to_float(item.get("exchangeBalance")),
        "fearGreedIndex": _n_to_int(item.get("fearGreedIndex")),
        "openInterest": _n_to_float(item.get("openInterest")),
        "newAddresses": int(v) if (v := _n_to_float(item.get("newAddresses"))) is not None else None,
    }


def _item_to_macro(item: dict) -> dict:
    """DynamoDB 아이템을 MacroData dict로 변환"""
    return {
        "interestRate": _n_to_float(item.get("interestRate")),
        "treasury10y": _n_to_float(item.get("treasury10y")),
        "cpi": _n_to_float(item.get("cpi")),
        "m2": _n_to_float(item.get("m2")),
        "unemployment": _n_to_float(item.get("unemployment")),
        "dollarIndex": _n_to_float(item.get("dollarIndex")),
    }
