#!/bin/bash
# Prospero_collector 압축 스크립트
set -e
cd "$(dirname "$0")"

echo "=== Prospero_collector 압축 중 ==="

# 1. 빌드 폴더 정리
rm -rf build
mkdir -p build

# 2. 의존성 설치 (requests만 - boto3는 Lambda 런타임에 포함)
#pip install requests -t build/ --upgrade --quiet

# 3. 소스 복사
cp lambda_function.py crypto_collector.py macro_collector.py dynamodb_writer.py build/

# 4. zip 생성
cd build
zip -r ../prospero_collector.zip .
cd ..

echo "=== prospero_collector.zip 생성 완료 ==="
