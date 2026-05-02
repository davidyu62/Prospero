"""
Prospero API - API Gateway Lambda 핸들러
앱에서 호출: /api/crypto-data/db/date-with-previous, /api/macro-data/db/date-with-previous
"""

import json
from datetime import datetime, timedelta

from dynamodb_reader import (
    get_crypto_data_by_date,
    get_macro_data_by_date,
    get_ai_analysis_by_date,
    get_crypto_data_7days,
)


CORS_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
}


def lambda_handler(event, context):
    """
    API Gateway Lambda Proxy Integration + Lambda URL
    API Gateway: { httpMethod, path, queryStringParameters }
    Lambda URL: { requestContext.http.{method, path}, queryStringParameters }
    """
    try:
        # API Gateway와 Lambda URL 두 형식 모두 지원
        http_method = event.get("httpMethod") or event.get("requestContext", {}).get("http", {}).get("method", "")
        path = event.get("path") or event.get("requestContext", {}).get("http", {}).get("path", "")
        params = event.get("queryStringParameters") or {}
        date = params.get("date")

        # CORS preflight
        if http_method == "OPTIONS":
            return _response(200, {})

        # DEBUG
        print(f"[DEBUG] path={path}, date={date}, httpMethod={http_method}")

        # 경로별 분기
        if "/api/crypto-data/7days" in path:
            return _handle_crypto_7days(date)
        if "/api/crypto-data/today" in path:
            return _handle_crypto_today()
        if "/api/crypto-data/db/date-with-previous" in path:
            return _handle_crypto_date_with_previous(date)
        if "/api/crypto-data/db/date" in path:
            return _handle_crypto_by_date(date)
        if "/api/macro-data/today" in path:
            return _handle_macro_today()
        if "/api/macro-data/db/date-with-previous" in path:
            return _handle_macro_date_with_previous(date)
        if "/api/macro-data/db/date" in path:
            return _handle_macro_by_date(date)
        if "/api/ai-analysis/date" in path:
            return _handle_ai_analysis_date(date)

        return _response(404, {"error": "Not Found"})

    except Exception as e:
        print(f"[ERROR] API 처리 실패: {e}")
        return _response(500, {"error": str(e)})


def _handle_crypto_today():
    """오늘의 크립토 데이터"""
    today = datetime.now().strftime("%Y%m%d")
    data = get_crypto_data_by_date(today)

    if not data:
        return _response(404, {"error": "오늘의 크립토 데이터가 없습니다."})

    return _response(200, _crypto_to_item(today, data))


def _handle_crypto_by_date(date: str):
    """특정 날짜의 크립토 데이터"""
    if not date or len(date) != 8:
        return _response(400, {"error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."})

    data = get_crypto_data_by_date(date)

    if not data:
        return _response(404, {"error": f"해당 날짜({date})의 크립토 데이터가 없습니다."})

    return _response(200, _crypto_to_item(date, data))


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


def _handle_macro_today():
    """오늘의 매크로 데이터"""
    today = datetime.now().strftime("%Y%m%d")
    data = get_macro_data_by_date(today)

    if not data:
        return _response(404, {"error": "오늘의 매크로 데이터가 없습니다."})

    return _response(200, _macro_to_item(today, data))


def _handle_macro_by_date(date: str):
    """특정 날짜의 매크로 데이터"""
    if not date or len(date) != 8:
        return _response(400, {"error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."})

    data = get_macro_data_by_date(date)

    if not data:
        return _response(404, {"error": f"해당 날짜({date})의 매크로 데이터가 없습니다."})

    return _response(200, _macro_to_item(date, data))


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
        "fearGreedIndex": data.get("fearGreedIndex"),
        "openInterest": data.get("openInterest"),
        "mvrv": data.get("mvrv"),
        "fundingRate": data.get("fundingRate"),
        "activeAddresses": data.get("activeAddresses"),
    }


def _handle_ai_analysis_date(date: str):
    """AI 분석 데이터 조회"""
    if not date or len(date) != 8:
        return _response(400, {"error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."})

    analysis_data = get_ai_analysis_by_date(date)

    if not analysis_data:
        return _response(404, {"error": "해당 날짜의 AI 분석 데이터가 없습니다."})

    return _response(200, analysis_data)


def _handle_crypto_7days(date: str):
    """암호화폐 데이터 7일 조회"""
    if not date or len(date) != 8:
        return _response(400, {"error": "날짜 형식이 올바르지 않습니다. yyyyMMdd 형식으로 입력해주세요."})

    data_7days = get_crypto_data_7days(date)

    if not data_7days or not data_7days["dates"]:
        return _response(404, {"error": "해당 날짜의 암호화폐 데이터가 없습니다."})

    return _response(200, data_7days)


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
        "vix": data.get("vix"),
        "oilPrice": data.get("oilPrice"),
        "yieldSpread": data.get("yieldSpread"),
        "breakEvenInflation": data.get("breakEvenInflation"),
    }


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": CORS_HEADERS,
        "body": json.dumps(body, ensure_ascii=False),
    }
