#!/usr/bin/env python3
"""
Prospero Backend - 로컬 테스트
크립토 데이터 전체 조회 및 매크로 데이터 전체 조회 확인
"""

import os
import sys
from datetime import datetime
from decimal import Decimal

# .env 로드
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from dynamodb_reader import (
    get_crypto_data_by_date,
    get_macro_data_by_date,
)


def main():
    """로컬 테스트 실행"""
    # 대상 날짜 (인자 또는 오늘)
    if len(sys.argv) > 1:
        date_str = sys.argv[1]  # yyyyMMdd
        try:
            datetime.strptime(date_str, "%Y%m%d")
        except ValueError:
            print(f"Usage: python test_local.py [yyyyMMdd]")
            sys.exit(1)
    else:
        date_str = datetime.now().strftime("%Y%m%d")

    print(f"\n[INFO] Prospero Backend 로컬 테스트 - 날짜: {date_str}\n")

    # 1. 크립토 데이터 조회
    print("=" * 60)
    print("1️⃣  크립토 데이터 전체 조회")
    print("=" * 60)
    crypto_data = get_crypto_data_by_date(date_str)

    if crypto_data:
        print(f"\n✅ 크립토 데이터 조회 성공 (필드: {len(crypto_data)}개)\n")
        for key, value in sorted(crypto_data.items()):
            if isinstance(value, Decimal):
                print(f"  {key:20s}: {value} (Decimal)")
            else:
                print(f"  {key:20s}: {value} ({type(value).__name__})")

        # 필드 검증 (v3.0 신규 필드 포함)
        expected_fields = {
            'btcPrice', 'longShortRatio', 'exchangeBalance', 'fearGreedIndex',
            'openInterest', 'mvrv', 'fundingRate', 'activeAddresses'
        }
        actual_fields = set(crypto_data.keys())
        missing = expected_fields - actual_fields
        extra = actual_fields - expected_fields

        print(f"\n📋 필드 검증:")
        print(f"  예상 필드: {expected_fields}")
        print(f"  실제 필드: {actual_fields}")
        if missing:
            print(f"  ❌ 누락된 필드: {missing}")
        if extra:
            print(f"  ℹ️ 추가 필드: {extra}")
        if not missing and not extra:
            print(f"  ✅ 모든 필드 정상")
    else:
        print(f"\n❌ 크립토 데이터 없음\n")

    # 2. 매크로 데이터 조회
    print("\n" + "=" * 60)
    print("2️⃣  매크로 데이터 전체 조회")
    print("=" * 60)
    macro_data = get_macro_data_by_date(date_str)

    if macro_data:
        print(f"\n✅ 매크로 데이터 조회 성공 (필드: {len(macro_data)}개)\n")
        for key, value in sorted(macro_data.items()):
            if isinstance(value, Decimal):
                print(f"  {key:25s}: {value} (Decimal)")
            else:
                print(f"  {key:25s}: {value} ({type(value).__name__})")

        # 필드 검증 (v3.0 신규 필드 포함)
        expected_fields = {
            'interestRate', 'treasury10y', 'cpi', 'm2', 'unemployment',
            'dollarIndex', 'vix', 'oilPrice', 'yieldSpread', 'breakEvenInflation'
        }
        actual_fields = set(macro_data.keys())
        missing = expected_fields - actual_fields
        extra = actual_fields - expected_fields

        print(f"\n📋 필드 검증:")
        print(f"  예상 필드: {expected_fields}")
        print(f"  실제 필드: {actual_fields}")
        if missing:
            print(f"  ❌ 누락된 필드: {missing}")
        if extra:
            print(f"  ℹ️ 추가 필드: {extra}")
        if not missing and not extra:
            print(f"  ✅ 모든 필드 정상")
    else:
        print(f"\n❌ 매크로 데이터 없음\n")

    # 3. 종합 결과
    print("\n" + "=" * 60)
    print("📊 종합 결과")
    print("=" * 60)
    if crypto_data and macro_data:
        print("✅ 크립토 데이터: OK")
        print("✅ 매크로 데이터: OK")
        print("\n🎉 모든 데이터 조회 성공!")
    elif crypto_data:
        print("✅ 크립토 데이터: OK")
        print("❌ 매크로 데이터: 없음")
    elif macro_data:
        print("❌ 크립토 데이터: 없음")
        print("✅ 매크로 데이터: OK")
    else:
        print("❌ 크립토 데이터: 없음")
        print("❌ 매크로 데이터: 없음")
        print("\n⚠️ 두 데이터 모두 조회 불가")

    print()


if __name__ == "__main__":
    main()
