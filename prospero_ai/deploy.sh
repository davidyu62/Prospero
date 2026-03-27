#!/bin/bash

# 압축만 수행하는 배포 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 prospero_ai 압축 중..."

# 기존 zip 파일 삭제
rm -f prospero_ai.zip

# 필수 파일 압축
zip -q prospero_ai.zip \
    lambda_function.py \
    score_analyzer.py \
    data_fetcher.py \
    result_writer.py

echo "✅ 완료: prospero_ai.zip ($(du -h prospero_ai.zip | cut -f1))"
