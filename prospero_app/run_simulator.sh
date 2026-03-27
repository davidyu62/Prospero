#!/bin/bash

# iOS 시뮬레이터 실행 스크립트
# 사용법: ./run_simulator.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR"

echo "🚀 Prospero 앱 시뮬레이터 실행 중..."
echo ""

# Xcode 프로젝트 열기
if [ -f "$PROJECT_DIR/Prospero.xcodeproj/project.pbxproj" ]; then
    echo "📱 Xcode 프로젝트 열기..."
    open "$PROJECT_DIR/Prospero.xcodeproj"
    
    echo ""
    echo "✅ Xcode가 열렸습니다!"
    echo ""
    echo "다음 단계:"
    echo "1. Xcode 상단에서 'iPhone 15 Pro' (또는 원하는 모델) 선택"
    echo "2. ⌘ + R 키를 누르거나 ▶️ 버튼 클릭"
    echo "3. 시뮬레이터가 자동으로 열리고 앱이 실행됩니다"
    echo ""
    echo "💡 팁: 시뮬레이터 사용법은 SIMULATOR_GUIDE.md를 참조하세요"
else
    echo "❌ 오류: Xcode 프로젝트를 찾을 수 없습니다."
    echo "   경로: $PROJECT_DIR/Prospero.xcodeproj"
    exit 1
fi


