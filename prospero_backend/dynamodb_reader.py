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
    Returns: {interestRate, treasury10y, cpi, m2, unemployment, dollarIndex, vix, oilPrice, yieldSpread, breakEvenInflation} 또는 None
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


def get_crypto_data_range(date: str, days: int = 30) -> dict:
    """
    TB_CRYPTO_DATA에서 특정 날짜(포함)부터 과거 days일 데이터 조회
    date: yyyyMMdd 형식, days: 조회 일수(기본 30)
    Returns: {dates: [], btcPrices: [], longShortRatios: [], fearGreedIndices: [], openInterests: [], mvrvs: [], fundingRates: [], activeAddresses: []}
             (오래된 날짜부터 정렬, 데이터가 있는 날짜만 포함)

    성능: date가 파티션 키이므로 날짜별 단일 Query로 조회한다.
    - boto3 클라이언트를 1회만 생성(반복 생성 오버헤드 제거)
    - 데이터 없는 날짜는 Scan 폴백 없이 건너뜀 → days=30도 기본 타임아웃 내 처리
    """
    from datetime import datetime, timedelta

    crypto_table, _ = get_table_names()
    client = boto3.client("dynamodb")

    data_list = []
    current_date = datetime.strptime(date, "%Y%m%d")

    for i in range(days):
        target_date = (current_date - timedelta(days=i)).strftime("%Y%m%d")
        try:
            resp = client.query(
                TableName=crypto_table,
                KeyConditionExpression="#date = :date",
                ExpressionAttributeNames={"#date": "date"},
                ExpressionAttributeValues={":date": {"S": target_date}},
                ScanIndexForward=False,  # timestamps 내림차순 → 최신 1건
                Limit=1,
            )
            items = resp.get("Items", [])
            if items:
                data_list.append(_item_to_crypto_with_date(target_date, items[0]))
        except Exception as e:
            print(f"[WARN] range Query 실패 date={target_date}: {e}")

    # 날짜 오름차순 정렬 (오래된 것부터)
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


def get_crypto_data_7days(date: str) -> dict:
    """하위 호환용: 7일 범위 조회 (get_crypto_data_range 위임)"""
    return get_crypto_data_range(date, 7)


def get_macro_data_range(date: str, days: int = 30) -> dict:
    """
    TB_MACRO_DATA에서 특정 날짜(포함)부터 과거 days일 데이터 조회.
    crypto와 동일하게 date가 파티션 키이므로 날짜별 단일 Query(클라이언트 1회 생성).
    Returns: {dates, interestRates, treasury10ys, cpis, m2s, unemployments, dollarIndices, vixs, oilPrices, yieldSpreads, breakEvenInflations}
             (오래된 날짜부터 정렬, 데이터 있는 날짜만 포함)
    """
    from datetime import datetime, timedelta

    _, macro_table = get_table_names()
    client = boto3.client("dynamodb")

    data_list = []
    current_date = datetime.strptime(date, "%Y%m%d")

    for i in range(days):
        target_date = (current_date - timedelta(days=i)).strftime("%Y%m%d")
        try:
            resp = client.query(
                TableName=macro_table,
                KeyConditionExpression="#date = :date",
                ExpressionAttributeNames={"#date": "date"},
                ExpressionAttributeValues={":date": {"S": target_date}},
                ScanIndexForward=False,
                Limit=1,
            )
            items = resp.get("Items", [])
            if items:
                data_list.append(_item_to_macro_with_date(target_date, items[0]))
        except Exception as e:
            print(f"[WARN] macro range Query 실패 date={target_date}: {e}")

    data_list.sort(key=lambda x: x["date"])

    return {
        "dates": [d["date"] for d in data_list],
        "interestRates": [d["interestRate"] for d in data_list],
        "treasury10ys": [d["treasury10y"] for d in data_list],
        "cpis": [d["cpi"] for d in data_list],
        "m2s": [d["m2"] for d in data_list],
        "unemployments": [d["unemployment"] for d in data_list],
        "dollarIndices": [d["dollarIndex"] for d in data_list],
        "vixs": [d["vix"] for d in data_list],
        "oilPrices": [d["oilPrice"] for d in data_list],
        "yieldSpreads": [d["yieldSpread"] for d in data_list],
        "breakEvenInflations": [d["breakEvenInflation"] for d in data_list],
    }


def get_macro_data_monthly(date: str, months: int = 6) -> dict:
    """
    TB_MACRO_DATA에서 최근 months개월의 '각 달 1일' 데이터만 조회.
    예: date=20260703, months=6 → 2/1, 3/1, 4/1, 5/1, 6/1, 7/1 (6개 지점).
    매크로 지표는 월 단위로 갱신되므로 월별 1일 6개만 조회해 Query 수를 크게 줄인다.
    1일 데이터가 없으면 같은 달 2~3일로 폴백.
    Returns: get_macro_data_range와 동일한 dict 형태(오래된 날짜부터 정렬).
    """
    from datetime import datetime

    _, macro_table = get_table_names()
    client = boto3.client("dynamodb")

    end = datetime.strptime(date, "%Y%m%d")
    year, month = end.year, end.month

    # 최근 months개월의 (연, 월) 목록 — 오래된 달부터
    targets = []
    for k in range(months):
        m = month - k
        y = year
        while m <= 0:
            m += 12
            y -= 1
        targets.append((y, m))
    targets.reverse()

    data_list = []
    for (y, m) in targets:
        # 해당 달 1일 우선, 없으면 2~3일 폴백
        for d in (1, 2, 3):
            target_date = f"{y:04d}{m:02d}{d:02d}"
            try:
                resp = client.query(
                    TableName=macro_table,
                    KeyConditionExpression="#date = :date",
                    ExpressionAttributeNames={"#date": "date"},
                    ExpressionAttributeValues={":date": {"S": target_date}},
                    ScanIndexForward=False,
                    Limit=1,
                )
                items = resp.get("Items", [])
                if items:
                    data_list.append(_item_to_macro_with_date(target_date, items[0]))
                    break
            except Exception as e:
                print(f"[WARN] macro monthly Query 실패 date={target_date}: {e}")

    data_list.sort(key=lambda x: x["date"])

    return {
        "dates": [d["date"] for d in data_list],
        "interestRates": [d["interestRate"] for d in data_list],
        "treasury10ys": [d["treasury10y"] for d in data_list],
        "cpis": [d["cpi"] for d in data_list],
        "m2s": [d["m2"] for d in data_list],
        "unemployments": [d["unemployment"] for d in data_list],
        "dollarIndices": [d["dollarIndex"] for d in data_list],
        "vixs": [d["vix"] for d in data_list],
        "oilPrices": [d["oilPrice"] for d in data_list],
        "yieldSpreads": [d["yieldSpread"] for d in data_list],
        "breakEvenInflations": [d["breakEvenInflation"] for d in data_list],
    }


def _item_to_macro_with_date(date: str, item: dict) -> dict:
    """DynamoDB 아이템을 MacroData dict로 변환 (date 포함, 누락값 0)"""
    return {
        "date": date,
        "interestRate": _n_to_float(item.get("interestRate")) or 0,
        "treasury10y": _n_to_float(item.get("treasury10y")) or 0,
        "cpi": _n_to_float(item.get("cpi")) or 0,
        "m2": _n_to_float(item.get("m2")) or 0,
        "unemployment": _n_to_float(item.get("unemployment")) or 0,
        "dollarIndex": _n_to_float(item.get("dollarIndex")) or 0,
        "vix": _n_to_float(item.get("vix")) or 0,
        "oilPrice": _n_to_float(item.get("oilPrice")) or 0,
        "yieldSpread": _n_to_float(item.get("yieldSpread")) or 0,
        "breakEvenInflation": _n_to_float(item.get("breakEvenInflation")) or 0,
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
