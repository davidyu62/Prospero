"""
Prospero API - API Gateway Lambda 핸들러
앱에서 호출: /api/crypto-data/db/date-with-previous, /api/macro-data/db/date-with-previous
"""

import json
from datetime import datetime, timedelta

from dynamodb_reader import get_crypto_data_by_date, get_macro_data_by_date


CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
}


def lambda_handler(event, context):
    """
    API Gateway Lambda Proxy Integration
    event: { httpMethod, path, queryStringParameters }
    """
    try:
        # CORS preflight
        if event.get("httpMethod") == "OPTIONS":
            return _response(200, {})

        path = event.get("path", "")
        params = event.get("queryStringParameters") or {}
        date = params.get("date")

        # 경로별 분기
        if "/api/crypto-data/db/date-with-previous" in path:
            return _handle_crypto_date_with_previous(date)
        if "/api/macro-data/db/date-with-previous" in path:
            return _handle_macro_date_with_previous(date)

        return _response(404, {"error": "Not Found"})

    except Exception as e:
        print(f"[ERROR] API 처리 실패: {e}")
        return _response(500, {"error": str(e)})


def _handle_crypto_date_with_previous(date: str):
    """크립토 데이터: 요청 날짜 + 전날"""
    if not date or len(date) != 8:
        return _response(400, {"error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."})

    prev_date = (datetime.strptime(date, "%Y%m%d") - timedelta(days=1)).strftime("%Y%m%d")

    request_data = get_crypto_data_by_date(date)
    previous_data = get_crypto_data_by_date(prev_date)

    body = {
        "requestDate": date,
        "previousDate": prev_date,
        "data": {
            "requestDate": _crypto_to_item(date, request_data),
            "previousDate": _crypto_to_item(prev_date, previous_data),
        },
    }
    return _response(200, body)


def _handle_macro_date_with_previous(date: str):
    """매크로 데이터: 요청 날짜 + 전날"""
    if not date or len(date) != 8:
        return _response(400, {"error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."})

    prev_date = (datetime.strptime(date, "%Y%m%d") - timedelta(days=1)).strftime("%Y%m%d")

    request_data = get_macro_data_by_date(date)
    previous_data = get_macro_data_by_date(prev_date)

    body = {
        "requestDate": date,
        "previousDate": prev_date,
        "data": {
            "requestDate": _macro_to_item(date, request_data),
            "previousDate": _macro_to_item(prev_date, previous_data),
        },
    }
    return _response(200, body)


def _crypto_to_item(date: str, data: dict | None) -> dict | None:
    if not data:
        return None
    return {
        "date": date,
        "btcPrice": data.get("btcPrice"),
        "longShortRatio": data.get("longShortRatio"),
        "exchangeBalance": data.get("exchangeBalance"),
        "fearGreedIndex": data.get("fearGreedIndex"),
        "openInterest": data.get("openInterest"),
        "newAddresses": data.get("newAddresses"),
    }


def _macro_to_item(date: str, data: dict | None) -> dict | None:
    if not data:
        return None
    return {
        "date": date,
        "interestRate": data.get("interestRate"),
        "treasury10y": data.get("treasury10y"),
        "cpi": data.get("cpi"),
        "m2": data.get("m2"),
        "unemployment": data.get("unemployment"),
        "dollarIndex": data.get("dollarIndex"),
    }


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": json.dumps(body, ensure_ascii=False),
    }
