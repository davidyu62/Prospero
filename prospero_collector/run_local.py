#!/usr/bin/env python3
"""
Prospero_collector - 로컬 실행 스크립트
Lambda 없이 직접 실행 (로컬 개발/테스트용)
"""

import os
import sys
from datetime import datetime

# 프로젝트 루트를 path에 추가
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# .env 로드 (python-dotenv 있으면)
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from crypto_collector import get_crypto_data
from macro_collector import get_macro_data
from dynamodb_writer import save_data


def main():
    # 대상 날짜 (인자 또는 오늘)
    if len(sys.argv) > 1:
        date_str = sys.argv[1]  # yyyyMMdd
        try:
            datetime.strptime(date_str, "%Y%m%d")
        except ValueError:
            print(f"Usage: python run_local.py [yyyyMMdd]")
            sys.exit(1)
    else:
        date_str = datetime.now().strftime("%Y%m%d")

    print(f"[INFO] Prospero_collector 로컬 실행 - 날짜: {date_str}")

    # FRED API 키
    fred_key = os.environ.get("FRED_API_KEY", "")
    if not fred_key:
        print("[WARN] FRED_API_KEY 환경변수가 없습니다. 매크로 데이터는 조회되지 않습니다.")

    # 1. 크립토 데이터 조회
    crypto_data = get_crypto_data(date_str)
    print(f"[INFO] 크립토 데이터: {crypto_data}")

    # 2. 매크로 데이터 조회
    macro_data = get_macro_data(date_str, fred_key)
    print(f"[INFO] 매크로 데이터: {macro_data}")

    # 3. DynamoDB 저장
    result = save_data(date_str, crypto_data, macro_data)
    print(f"[INFO] 저장 결과: {result}")


if __name__ == "__main__":
    main()
