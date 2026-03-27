"""
Prospero_collector - Macro data collector
매크로 경제 데이터 조회 (FRED API)
"""

from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional

import requests

FRED_SERIES = {
    "interestRate": "FEDFUNDS",      # 미국 금리
    "treasury10y": "DGS10",          # 10년물 국채 금리
    "cpi": "CPIAUCSL",               # CPI
    "m2": "M2SL",                    # M2 통화량
    "unemployment": "UNRATE",        # 실업률
    "dollarIndex": "DTWEXBGS",       # 달러 인덱스
}


def get_macro_data(date: str, fred_api_key: str) -> Optional[dict]:
    """
    매크로 데이터 조회
    date: yyyyMMdd 형식
    fred_api_key: FRED API 키
    Returns: {interestRate, treasury10y, cpi, m2, unemployment, dollarIndex}
    """
    if not fred_api_key:
        print("[WARN] FRED API 키가 없습니다.")
        return None

    try:
        formatted_date = f"{date[:4]}-{date[4:6]}-{date[6:8]}"

        result = {}
        for attr_name, series_id in FRED_SERIES.items():
            value = _get_fred_data(series_id, formatted_date, fred_api_key)
            if value is not None:
                quantized = value.quantize(Decimal("0.01"))
                result[attr_name] = quantized
                print(f"[INFO] {attr_name} ({series_id}) 조회 성공: {value} → {quantized}")
            else:
                print(f"[WARN] {attr_name} ({series_id}): 데이터 없음")

        print(f"\n[INFO] 매크로 데이터 수집 결과: {result}\n")
        return result if result else None
    except Exception as e:
        print(f"[ERROR] Macro 데이터 조회 실패: {e}")
        return None


def _get_fred_data(series_id: str, date: str, api_key: str) -> Optional[Decimal]:
    """
    FRED API에서 데이터 조회
    - 해당 날짜 데이터가 있으면 사용 (휴일/주말이면 없을 수 있음)
    - 없으면 최근 60일 범위에서 최신 관측값 사용 (fallback)
    """
    try:
        # 1) 먼저 해당 날짜만 조회
        value = _fetch_fred_single_date(series_id, date, api_key)
        if value is not None:
            return value

        # 2) fallback: 최근 60일 범위에서 최신 값 조회 (주말/휴일·월별 시리즈 대응)
        start = (datetime.strptime(date, "%Y-%m-%d") - timedelta(days=60)).strftime("%Y-%m-%d")
        value = _fetch_fred_date_range(series_id, start, date, api_key)
        return value

    except Exception as e:
        print(f"[WARN] FRED 데이터 조회 실패 ({series_id}): {e}")
        return None


def _fetch_fred_single_date(series_id: str, date: str, api_key: str) -> Optional[Decimal]:
    """해당 날짜 데이터만 조회"""
    url = (
        f"https://api.stlouisfed.org/fred/series/observations"
        f"?series_id={series_id}&api_key={api_key}&file_type=json"
        f"&observation_start={date}&observation_end={date}"
        f"&sort_order=desc&limit=1"
    )
    r = requests.get(url, timeout=15)
    r.raise_for_status()
    data = r.json()
    observations = data.get("observations", [])
    if not observations:
        return None
    return _parse_observation(observations[0])


def _fetch_fred_date_range(series_id: str, start: str, end: str, api_key: str) -> Optional[Decimal]:
    """날짜 범위에서 최신 관측값 조회 (주말/휴일 시 이전 영업일 데이터)"""
    url = (
        f"https://api.stlouisfed.org/fred/series/observations"
        f"?series_id={series_id}&api_key={api_key}&file_type=json"
        f"&observation_start={start}&observation_end={end}"
        f"&sort_order=desc&limit=1"
    )
    r = requests.get(url, timeout=15)
    r.raise_for_status()
    data = r.json()
    observations = data.get("observations", [])
    if not observations:
        return None
    return _parse_observation(observations[0])


def _parse_observation(obs: dict) -> Optional[Decimal]:
    value_str = obs.get("value")
    if not value_str or value_str == "." or not str(value_str).strip():
        return None
    try:
        return Decimal(str(value_str))
    except Exception:
        return None
