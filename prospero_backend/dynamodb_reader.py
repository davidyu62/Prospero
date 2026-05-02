"""
Prospero Backend - DynamoDB reader
TB_CRYPTO_DATA, TB_MACRO_DATA에서 날짜별로 조회
"""

import os
from typing import Optional

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
    Returns: {btcPrice, longShortRatio, fearGreedIndex, openInterest, mvrv, fundingRate, activeAddresses} 또는 None
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
    Returns: {interestRate, treasury10y, cpi, m2, unemployment, dollarIndex, vix, goldPrice, oilPrice, yieldSpread, breakEvenInflation} 또는 None
    """
    _, macro_table = get_table_names()
    item = _query_latest_by_date(macro_table, date)
    if not item:
        return None
    return _item_to_macro(item)


def _query_latest_by_date(table_name: str, date: str) -> Optional[dict]:
    """
    date로 Query, timestamps 내림차순 정렬 후 최신 1건 반환.
    Query 실패 시(키 스키마 불일치 등) Scan으로 date 필터 후 최신 1건 반환.
    """
    client = boto3.client("dynamodb")
    # 1) Query 시도 (파티션 키가 date인 경우)
    try:
        resp = client.query(
            TableName=table_name,
            KeyConditionExpression="#date = :date",
            ExpressionAttributeNames={"#date": "date"},
            ExpressionAttributeValues={":date": {"S": date}},
            ScanIndexForward=False,
            Limit=1,
        )
        items = resp.get("Items", [])
        if items:
            print(f"[INFO] DynamoDB Query 성공 ({table_name}) date={date}")
            return items[0]
    except Exception as e:
        print(f"[WARN] DynamoDB Query 실패 ({table_name}) date={date}: {e}")
    # 2) 폴백: Scan으로 date 필터
    try:
        resp = client.scan(
            TableName=table_name,
            FilterExpression="#date = :date",
            ExpressionAttributeNames={"#date": "date"},
            ExpressionAttributeValues={":date": {"S": date}},
            Limit=100,
        )
        items = resp.get("Items", [])
        if not items:
            print(f"[INFO] DynamoDB Scan 결과 없음 ({table_name}) date={date}")
            return None
        # timestamps 기준 최신 1건
        latest = max(items, key=lambda x: x.get("timestamps", {}).get("S", ""))
        print(f"[INFO] DynamoDB Scan 폴백 성공 ({table_name}) date={date}")
        return latest
    except Exception as e:
        print(f"[ERROR] DynamoDB Scan 실패 ({table_name}): {e}")
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
        "fearGreedIndex": _n_to_int(item.get("fearGreedIndex")),
        "openInterest": _n_to_float(item.get("openInterest")),
        "mvrv": _n_to_float(item.get("mvrv")),
        "fundingRate": _n_to_float(item.get("fundingRate")),
        "activeAddresses": _n_to_int(item.get("activeAddresses")),
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
        "vix": _n_to_float(item.get("vix")),
        "goldPrice": _n_to_float(item.get("goldPrice")),
        "oilPrice": _n_to_float(item.get("oilPrice")),
        "yieldSpread": _n_to_float(item.get("yieldSpread")),
        "breakEvenInflation": _n_to_float(item.get("breakEvenInflation")),
    }


def get_ai_analysis_by_date(date: str) -> Optional[dict]:
    """
    TB_AI_INSIGHT에서 특정 날짜 AI 분석 데이터 조회
    date: yyyyMMdd 형식
    Returns: 전체 분석 결과 dict 또는 None
    """
    try:
        client = boto3.client("dynamodb")
        resp = client.get_item(
            TableName="TB_AI_INSIGHT",
            Key={"date": {"S": date}}
        )
        item = resp.get("Item")
        if not item:
            print(f"[INFO] AI 분석 데이터 없음: {date}")
            return None
        return _item_to_ai_analysis(item)
    except Exception as e:
        print(f"[ERROR] DynamoDB AI 데이터 조회 실패: {e}")
        return None


def _item_to_ai_analysis(item: dict) -> dict:
    """DynamoDB 아이템을 AI 분석 결과 dict로 변환 (v2.0)"""
    import json

    def _s_to_str(av: dict) -> Optional[str]:
        if not av or "S" not in av:
            return None
        return av["S"]

    # indicator_explanations JSON 파싱 (한국어)
    explanations_str = _s_to_str(item.get("indicator_explanations"))
    explanations = {}
    if explanations_str:
        try:
            explanations = json.loads(explanations_str)
        except:
            explanations = {}

    # indicator_explanations_en JSON 파싱 (영어)
    explanations_en_str = _s_to_str(item.get("indicator_explanations_en"))
    explanations_en = {}
    if explanations_en_str:
        try:
            explanations_en = json.loads(explanations_en_str)
        except:
            explanations_en = {}

    # v5.0 신규 필드들 파싱
    bullish_factors_str = _s_to_str(item.get("bullish_factors"))
    bullish_factors = []
    if bullish_factors_str:
        try:
            bullish_factors = json.loads(bullish_factors_str)
            if not isinstance(bullish_factors, list):
                bullish_factors = []
        except:
            bullish_factors = []

    bullish_factors_en_str = _s_to_str(item.get("bullish_factors_en"))
    bullish_factors_en = []
    if bullish_factors_en_str:
        try:
            bullish_factors_en = json.loads(bullish_factors_en_str)
            if not isinstance(bullish_factors_en, list):
                bullish_factors_en = []
        except:
            bullish_factors_en = []

    bearish_factors_str = _s_to_str(item.get("bearish_factors"))
    bearish_factors = []
    if bearish_factors_str:
        try:
            bearish_factors = json.loads(bearish_factors_str)
            if not isinstance(bearish_factors, list):
                bearish_factors = []
        except:
            bearish_factors = []

    bearish_factors_en_str = _s_to_str(item.get("bearish_factors_en"))
    bearish_factors_en = []
    if bearish_factors_en_str:
        try:
            bearish_factors_en = json.loads(bearish_factors_en_str)
            if not isinstance(bearish_factors_en, list):
                bearish_factors_en = []
        except:
            bearish_factors_en = []

    return {
        "date": _s_to_str(item.get("date")) or "",
        "total_score": _n_to_float(item.get("total_score")) or 0,
        "signal_type": _s_to_str(item.get("signal_type")) or "",
        "signal_color": _s_to_str(item.get("signal_color")) or "",
        "confidence_label": _s_to_str(item.get("confidence_label")) or "Medium",
        "crypto_score": _n_to_float(item.get("crypto_score")) or 0,
        "macro_score": _n_to_float(item.get("macro_score")) or 0,
        "btc_trend_score": _n_to_float(item.get("btc_trend_score")) or 0,
        "fear_greed_score": _n_to_float(item.get("fear_greed_score")) or 0,
        "long_short_score": _n_to_float(item.get("long_short_score")) or 0,
        "open_interest_score": _n_to_float(item.get("open_interest_score")) or 0,
        "mvrv_score": _n_to_float(item.get("mvrv_score")) or 0,
        "interest_rate_score": _n_to_float(item.get("interest_rate_score")) or 0,
        "treasury10y_score": _n_to_float(item.get("treasury10y_score")) or 0,
        "m2_score": _n_to_float(item.get("m2_score")) or 0,
        "dollar_index_score": _n_to_float(item.get("dollar_index_score")) or 0,
        "unemployment_score": _n_to_float(item.get("unemployment_score")) or 0,
        "cpi_score": _n_to_float(item.get("cpi_score")) or 0,
        "interaction_score": _n_to_float(item.get("interaction_score")) or 0,
        # v5.0 신규 필드들
        "cross_indicator_analysis": _s_to_str(item.get("cross_indicator_analysis")) or "",
        "cross_indicator_analysis_en": _s_to_str(item.get("cross_indicator_analysis_en")) or "",
        "signal_rationale": _s_to_str(item.get("signal_rationale")) or "",
        "signal_rationale_en": _s_to_str(item.get("signal_rationale_en")) or "",
        "bullish_factors": bullish_factors,
        "bullish_factors_en": bullish_factors_en,
        "bearish_factors": bearish_factors,
        "bearish_factors_en": bearish_factors_en,
        "confidence_reason": _s_to_str(item.get("confidence_reason")) or "",
        "confidence_reason_en": _s_to_str(item.get("confidence_reason_en")) or "",
        # 기존 필드
        "indicator_explanations": explanations,
        "indicator_explanations_en": explanations_en,
    }


def get_crypto_data_7days(date: str) -> dict:
    """
    TB_CRYPTO_DATA에서 특정 날짜부터 과거 7일 데이터 조회
    date: yyyyMMdd 형식
    Returns: {dates: [], btcPrices: [], fearGreedIndices: [], openInterests: [], mvrvs: [], fundingRates: [], activeAddresses: []}
    """
    from datetime import datetime, timedelta

    crypto_table, _ = get_table_names()

    # 7일 데이터 조회
    data_list = []
    current_date = datetime.strptime(date, "%Y%m%d")

    for i in range(7):
        target_date = (current_date - timedelta(days=i)).strftime("%Y%m%d")
        item = _query_latest_by_date(crypto_table, target_date)
        if item:
            data_list.append(_item_to_crypto_with_date(target_date, item))

    # 날짜 역순 정렬 (오래된 것부터)
    data_list.sort(key=lambda x: x["date"])

    # 각 지표별로 리스트로 변환
    return {
        "dates": [d["date"] for d in data_list],
        "btcPrices": [d["btcPrice"] for d in data_list],
        "longShortRatios": [d["longShortRatio"] for d in data_list],
        "fearGreedIndices": [d["fearGreedIndex"] for d in data_list],
        "openInterests": [d["openInterest"] for d in data_list],
        "mvrvs": [d["mvrv"] for d in data_list],
        "fundingRates": [d["fundingRate"] for d in data_list],
        "activeAddresses": [d["activeAddresses"] for d in data_list],
    }


def _item_to_crypto_with_date(date: str, item: dict) -> dict:
    """DynamoDB 아이템을 CryptoData dict로 변환 (date 포함)"""
    return {
        "date": date,
        "btcPrice": _n_to_float(item.get("btcPrice")) or 0,
        "longShortRatio": _n_to_float(item.get("longShortRatio")) or 0,
        "fearGreedIndex": _n_to_int(item.get("fearGreedIndex")) or 0,
        "openInterest": _n_to_float(item.get("openInterest")) or 0,
        "mvrv": _n_to_float(item.get("mvrv")) or 0,
        "fundingRate": _n_to_float(item.get("fundingRate")) or 0,
        "activeAddresses": _n_to_int(item.get("activeAddresses")) or 0,
    }
