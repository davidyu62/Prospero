#!/bin/bash

# 압축만 수행하는 배포 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 prospero_ai 압축 중..."

# 기존 파일 정리
rm -f prospero_ai.zip
rm -rf build

# 디렉토리 생성
mkdir -p build

# 1. requirements.txt에서 패키지 설치
echo "📥 Python 패키지 설치..."
pip3 install -r requirements.txt --target build/ \
  --platform manylinux2014_x86_64 \
  --python-version 3.11 \
  --only-binary=:all: \
  --quiet 2>/dev/null || pip3 install -r requirements.txt --target build/ --quiet

# 2. 소스 파일 복사
echo "📄 소스 파일 복사..."
cp lambda_function.py build/
cp score_analyzer.py build/
cp data_fetcher.py build/
cp result_writer.py build/

# 3. ZIP 파일 생성
echo "🗜️  ZIP 파일 생성..."
cd build
zip -r prospero_ai.zip . -q
cd ..
mv build/prospero_ai.zip .

# 4. 임시 파일 정리
rm -rf build

echo "✅ 완료: prospero_ai.zip ($(du -h prospero_ai.zip | cut -f1))"
