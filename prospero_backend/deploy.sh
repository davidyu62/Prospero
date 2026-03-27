#!/bin/bash

# 압축만 수행하는 배포 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📦 prospero_backend 압축 중..."

# 기존 zip 파일 삭제
rm -f prospero_backend.zip

# 필수 파일 압축
zip -q prospero_backend.zip \
    api_handler.py \
    dynamodb_reader.py

echo "✅ 완료: prospero_backend.zip ($(du -h prospero_backend.zip | cut -f1))"
