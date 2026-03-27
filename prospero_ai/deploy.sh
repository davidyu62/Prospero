#!/bin/bash
#
# deploy.sh
# Prospero AI
#
# prospero-ai Lambda 함수 배포 스크립트

set -e

# 설정
FUNCTION_NAME="${1:-prospero-ai}"
REGION="ap-northeast-2"
RUNTIME="python3.11"
TIMEOUT="60"
MEMORY="256"

echo "📦 prospero-ai Lambda 배포 시작"
echo "================================"
echo "함수명: $FUNCTION_NAME"
echo "리전: $REGION"
echo "런타임: $RUNTIME"
echo "타임아웃: ${TIMEOUT}초"
echo "메모리: ${MEMORY}MB"
echo "================================"

# 1. 필요한 패키지 설치 (Lambda = Amazon Linux x86_64용으로 설치)
# Mac에서 pip install하면 pydantic_core 등이 Mac용으로 빌드되어 Lambda에서 ImportError 발생하므로
# --platform manylinux2014_x86_64 로 Linux x86_64 휠을 받아야 함
echo ""
echo "📥 Python 패키지 설치 (Lambda 호환: manylinux x86_64)..."
mkdir -p build
pip3 install -r requirements.txt --target build/ \
  --platform manylinux2014_x86_64 \
  --python-version 3.11 \
  --only-binary=:all: \
  --upgrade \
  --quiet

# 2. 소스 파일 복사
echo "📄 소스 파일 복사..."
cp lambda_function.py build/
cp data_fetcher.py build/
cp score_analyzer.py build/
cp result_writer.py build/

# 3. ZIP 파일 생성
echo "📦 ZIP 파일 생성..."
cd build
zip -r prospero_ai.zip . -q
cd ..
mv build/prospero_ai.zip .

# 4. 임시 파일 정리 (build만 삭제, ZIP은 유지)
echo ""
echo "🧹 임시 파일 정리..."
rm -rf build

# 5. 완료
echo ""
echo "✅ ZIP 파일 생성 완료!"
ls -lh prospero_ai.zip
