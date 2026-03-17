#!/usr/bin/env bash
# Stop hook: Stitch design-to-code verification loop
#
# When phase is "code_verify", checks if <promise>CODE_VERIFIED</promise>
# appeared in the transcript. If not, re-injects verification prompt.
#
# State file: .claude/stitch-implement-pipeline.local.md (YAML frontmatter)

set -euo pipefail

# --- Config ---
STATE_FILE=".claude/stitch-implement-pipeline.local.md"
COMPLETION_PROMISE="CODE_VERIFIED"
DEFAULT_MAX_ITERATIONS=5

# --- Read hook input from stdin ---
INPUT=$(cat)

# --- Guard: state file must exist ---
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# --- Parse state file frontmatter ---
get_field() {
  local field="$1"
  sed -n '/^---$/,/^---$/p' "$STATE_FILE" | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//"
}

PHASE=$(get_field "phase")
SESSION_ID=$(get_field "session_id")
ITERATION=$(get_field "iteration")
MAX_ITER=$(get_field "max_iterations")
TARGET_STACK=$(get_field "target_stack")

# Defaults
ITERATION="${ITERATION:-0}"
MAX_ITER="${MAX_ITER:-$DEFAULT_MAX_ITERATIONS}"
TARGET_STACK="${TARGET_STACK:-flutter}"

# --- Guard: only act during code_verify phase ---
if [ "$PHASE" != "code_verify" ]; then
  exit 0
fi

# --- Guard: session_id match (if set) ---
if [ -n "$SESSION_ID" ]; then
  CURRENT_SESSION=$(echo "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)
  if [ -n "$CURRENT_SESSION" ] && [ "$CURRENT_SESSION" != "$SESSION_ID" ]; then
    exit 0
  fi
fi

# --- Check for completion promise in transcript ---
if echo "$INPUT" | grep -q "<promise>${COMPLETION_PROMISE}</promise>" 2>/dev/null; then
  rm -f "$STATE_FILE"
  echo '{"decision": "allow"}'
  exit 0
fi

# --- Check iteration limit ---
NEXT_ITER=$((ITERATION + 1))
if [ "$NEXT_ITER" -gt "$MAX_ITER" ]; then
  sed -i '' "s/^phase:.*/phase: done_max_iter/" "$STATE_FILE" 2>/dev/null || true
  echo '{"decision": "allow"}'
  exit 0
fi

# --- Update iteration count in state file ---
if grep -q "^iteration:" "$STATE_FILE"; then
  sed -i '' "s/^iteration:.*/iteration: ${NEXT_ITER}/" "$STATE_FILE"
else
  sed -i '' "/^---$/a\\
iteration: ${NEXT_ITER}" "$STATE_FILE"
fi

# --- Re-inject verification prompt ---
cat <<HOOK_OUTPUT
{
  "decision": "block",
  "reason": "코드 검증 루프를 계속합니다.\\n\\n1. Read .claude/stitch-implement-pipeline.local.md → 남은 화면과 차이 확인\\n2. Stitch MCP get_screen + web_fetch로 디자인 스크린샷 수집\\n3. 구현 코드 스크린샷 촬영 (${TARGET_STACK})\\n4. diffs > 0: 코드 수정 → Phase 5 재검증\\n5. diffs == 0 (또는 LOW만 남음): <promise>CODE_VERIFIED</promise> 출력\\n\\nreferences/workflows-implement.md Phase 5 절차를 따르세요."
}
HOOK_OUTPUT
