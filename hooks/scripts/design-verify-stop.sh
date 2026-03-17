#!/usr/bin/env bash
# Stop hook: Stitch design pipeline verification loop
#
# When phase is "verify", checks if <promise>DESIGN_VERIFIED</promise>
# appeared in the transcript. If not, re-injects verification prompt.
#
# State file: .claude/stitch-design-pipeline.local.md (YAML frontmatter)

set -euo pipefail

# --- Config ---
STATE_FILE=".claude/stitch-design-pipeline.local.md"
COMPLETION_PROMISE="DESIGN_VERIFIED"
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

# Defaults
ITERATION="${ITERATION:-0}"
MAX_ITER="${MAX_ITER:-$DEFAULT_MAX_ITERATIONS}"

# --- Guard: only act during verify phase ---
if [ "$PHASE" != "verify" ]; then
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
cat <<'HOOK_OUTPUT'
{
  "decision": "block",
  "reason": "디자인 검증 루프를 계속합니다.\n\n1. Read .claude/stitch-design-pipeline.local.md → 남은 gaps 확인\n2. gaps > 0: Stitch MCP edit_screens로 누락분 수정 또는 generate_screen_from_text로 재생성 → Phase 5 재검증\n3. gaps == 0: <promise>DESIGN_VERIFIED</promise> 출력\n\nreferences/workflows-design.md Phase 5 절차를 따르세요."
}
HOOK_OUTPUT
