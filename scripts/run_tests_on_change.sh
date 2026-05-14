#!/usr/bin/env bash

# Claude Code hooks: PostToolUse
# 파일 수정 후 해당 컴포넌트 테스트 자동 실행

# stdin JSON에서 변경된 파일 경로 추출
FILE_PATH=$(cat - | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null)

# 프로젝트 루트 디렉터리
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# prospero_boot 파일 수정 감지
if [[ "$FILE_PATH" == *"prospero_boot"* ]]; then
  echo "🧪 prospero_boot 테스트 실행..."
  cd "$PROJECT_ROOT/prospero_boot"

  if ! mvn test -q 2>&1; then
    echo ""
    echo "❌ 테스트 실패. 위 오류를 확인하고 수정 필요"
    exit 2
  fi

  echo "✅ 모든 테스트 통과"
  exit 0
fi

# 다른 컴포넌트는 아직 테스트 미설정 (향후 확장)
exit 0
