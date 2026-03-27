"""
Prospero_collector - Crypto data collector
크립토 데이터 조회 (Binance, Alternative.me)
"""

from datetime import datetime
from decimal import Decimal
from typing import Optional

import requests


def get_crypto_data(date: str) -> Optional[dict]:
    """
    크립토 데이터 조회
    date: yyyyMMdd 형식
    Returns: {btcPrice, longShortRatio, exchangeBalance, fearGreedIndex, openInterest}
    """
    try:
        btc_price = _get_btc_price()
        long_short_ratio = _get_long_short_ratio()
        exchange_balance = _get_exchange_balance()
        fear_greed_index = _get_fear_greed_index()
        open_interest = _get_open_interest()

        print(f"\n[INFO] 크립토 데이터 수집 결과:")
        print(f"  btcPrice: {btc_price if btc_price is not None else '없음'}")
        print(f"  longShortRatio: {long_short_ratio if long_short_ratio is not None else '없음'}")
        print(f"  exchangeBalance: {exchange_balance if exchange_balance is not None else '없음'}")
        print(f"  fearGreedIndex: {fear_greed_index if fear_greed_index is not None else '없음'}")
        print(f"  openInterest: {open_interest if open_interest is not None else '없음'}\n")

        result = {}
        if btc_price is not None:
            result["btcPrice"] = btc_price
        if long_short_ratio is not None:
            result["longShortRatio"] = long_short_ratio
        if exchange_balance is not None:
            result["exchangeBalance"] = exchange_balance
        if fear_greed_index is not None:
            result["fearGreedIndex"] = fear_greed_index
        if open_interest is not None:
            result["openInterest"] = open_interest

        return result if result else None
    except Exception as e:
        print(f"[ERROR] Crypto 데이터 조회 실패: {e}")
        return None


def _get_btc_price() -> Optional[Decimal]:
    """Binance API - BTC 가격 (USD)"""
    try:
        r = requests.get(
            "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT",
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()
        if "price" in data:
            result = Decimal(str(data["price"])).quantize(Decimal("0.01"))
            print(f"[INFO] BTC Price 조회 성공: {result}")
            return result
        else:
            print(f"[WARN] BTC Price: 응답에 price 키 없음. 응답: {data}")
    except Exception as e:
        print(f"[WARN] BTC 가격 조회 실패: {e}")
    return None


def _get_long_short_ratio() -> Optional[Decimal]:
    """Binance Futures API - 글로벌 롱/숏 비율"""
    try:
        r = requests.get(
            "https://fapi.binance.com/futures/data/globalLongShortAccountRatio?symbol=BTCUSDT&period=5m&limit=1",
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()
        if data and isinstance(data, list) and len(data) > 0:
            item = data[0]
            ratio = item.get("longShortRatio")
            if ratio:
                result = Decimal(str(ratio)).quantize(Decimal("0.0001"))
                print(f"[INFO] Long/Short Ratio 조회 성공: {result}")
                return result
            else:
                print(f"[WARN] Long/Short Ratio: 응답에 longShortRatio 키 없음. 응답: {item}")
        else:
            print(f"[WARN] Long/Short Ratio: 응답이 빈 리스트 또는 형식 오류. 응답: {data}")
    except Exception as e:
        print(f"[WARN] Long/Short Ratio 조회 실패: {e}")
    return None


def _get_exchange_balance() -> Optional[Decimal]:
    """거래소 잔고 - API 미연동, 실제 데이터 없음"""
    print("[WARN] Exchange Balance: API 미연동 (CryptoQuant/Glassnode 연동 필요), 0으로 저장")
    return Decimal("0")


def _get_fear_greed_index() -> Optional[int]:
    """Alternative.me - Fear & Greed Index"""
    try:
        r = requests.get("https://api.alternative.me/fng/", timeout=10)
        r.raise_for_status()
        data = r.json()
        if "data" in data and data["data"]:
            value = data["data"][0].get("value")
            if value:
                result = int(value)
                print(f"[INFO] Fear & Greed Index 조회 성공: {result}")
                return result
            else:
                print(f"[WARN] Fear & Greed Index: 응답에 value 키 없음. 응답: {data['data'][0]}")
        else:
            print(f"[WARN] Fear & Greed Index: 응답에 data 필드 없음 또는 빈 리스트. 응답: {data}")
    except Exception as e:
        print(f"[WARN] Fear & Greed Index 조회 실패: {e}")
    return None


def _get_open_interest() -> Optional[Decimal]:
    """Binance Futures API - 미결제 약정 (BTC 단위)"""
    try:
        r = requests.get(
            "https://fapi.binance.com/fapi/v1/openInterest?symbol=BTCUSDT",
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()
        if "openInterest" in data:
            raw = data["openInterest"]
            result = Decimal(str(raw)).quantize(Decimal("0.01"))
            print(f"[INFO] Open Interest 조회 성공 (BTC): {result}")
            return result
        else:
            print(f"[WARN] Open Interest: 응답에 openInterest 키 없음. 응답: {data}")
    except Exception as e:
        print(f"[WARN] Open Interest 조회 실패: {e}")
    return None
