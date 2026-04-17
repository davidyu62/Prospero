import requests
from datetime import datetime, timedelta, timezone

end_time = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
start_time = (datetime.now(timezone.utc) - timedelta(days=2)).strftime("%Y-%m-%dT%H:%M:%SZ")

url = "https://community-api.coinmetrics.io/v4/timeseries/asset-metrics"
params = {
    "assets": "btc",
    "metrics": "CapMVRVCur,CapMrktCurUSD",
    "frequency": "1d",
    "start_time": start_time,
    "end_time": end_time,
    "page_size": 10,
}

res = requests.get(url, params=params)
data = res.json()

if "data" in data and data["data"]:
    latest = data["data"][-1]
    mvrv = float(latest.get("CapMVRVCur", 0))
    market_cap = float(latest.get("CapMrktCurUSD", 0))

    # MVRV 해석
    if mvrv > 3.5:
        signal = "🔴 과열 (역사적 고점 구간)"
    elif mvrv > 2.0:
        signal = "🟡 주의 (수익 실현 구간)"
    elif mvrv > 1.0:
        signal = "🟢 적정 (건강한 상승)"
    else:
        signal = "🔵 저평가 (역사적 매수 구간)"

    print(f"날짜:       {latest['time'][:10]}")
    print(f"MVRV:       {mvrv:.4f}")
    print(f"시가총액:   ${market_cap:,.0f}")
    print(f"신호:       {signal}")
else:
    print("에러:", data)
