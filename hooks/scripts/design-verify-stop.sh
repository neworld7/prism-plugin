#!/usr/bin/env bash
# Stop hook: Loom design pipeline verification loop
#
# When phase is "verify", checks if <promise>DESIGN_VERIFIED</promise>
# appeared in the transcript. If not, re-injects verification prompt.
#
# State file: .claude/loom-design-pipeline.local.md (YAML frontmatter)

set -euo pipefail

# --- Config ---
STATE_FILE=".claude/loom-design-pipeline.local.md"
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
  # --- Direction loop (inner) ---
  TOTAL_DIRECTIONS=$(get_field "total_directions")
  if [ -n "$TOTAL_DIRECTIONS" ] && [ "$TOTAL_DIRECTIONS" -gt 1 ]; then
    DIRECTION_INDEX=$(get_field "direction_index")
    DIRECTION_INDEX="${DIRECTION_INDEX:-0}"
    CURRENT_DIRECTION=$(get_field "direction")
    ALL_DIRECTIONS=$(get_field "all_directions")
    COMPLETED_DIRS=$(get_field "completed_directions")

    if [ -z "$COMPLETED_DIRS" ]; then
      NEW_COMPLETED_DIRS="$CURRENT_DIRECTION"
    else
      NEW_COMPLETED_DIRS="${COMPLETED_DIRS}|${CURRENT_DIRECTION}"
    fi

    NEXT_DIR_INDEX=$((DIRECTION_INDEX + 1))

    if [ "$NEXT_DIR_INDEX" -lt "$TOTAL_DIRECTIONS" ]; then
      # Next direction exists — advance direction
      NEXT_DIRECTION=$(echo "$ALL_DIRECTIONS" | cut -d'|' -f$((NEXT_DIR_INDEX + 1)))

      sed -i '' "s/^phase:.*/phase: generation/" "$STATE_FILE"
      sed -i '' "s/^direction:.*/direction: ${NEXT_DIRECTION}/" "$STATE_FILE"
      sed -i '' "s/^direction_index:.*/direction_index: ${NEXT_DIR_INDEX}/" "$STATE_FILE"
      sed -i '' "s/^iteration:.*/iteration: 0/" "$STATE_FILE"
      if grep -q "^completed_directions:" "$STATE_FILE"; then
        sed -i '' "s/^completed_directions:.*/completed_directions: ${NEW_COMPLETED_DIRS}/" "$STATE_FILE"
      else
        sed -i '' "/^---$/a\\
completed_directions: ${NEW_COMPLETED_DIRS}" "$STATE_FILE"
      fi

      cat <<HOOK_OUTPUT
{
  "decision": "block",
  "reason": "Direction '${CURRENT_DIRECTION}' 검증 완료! (${NEXT_DIR_INDEX}/${TOTAL_DIRECTIONS})\\n\\n다음 Direction: '${NEXT_DIRECTION}'\\n\\n1. Read .claude/loom-design-pipeline.local.md → 현재 direction 확인\\n2. .loom/directions/${NEXT_DIRECTION}/DESIGN.md → ./DESIGN.md 복원 또는 D2 실행\\n3. .loom/directions/${NEXT_DIRECTION}/prompts.md 로드\\n4. Skill(stitch-design)으로 디자인 생성\\n5. 생성 완료 후 phase를 verify로 변경\\n\\nreferences/workflows.md Design Pipeline 절차를 따르세요."
}
HOOK_OUTPUT
      exit 0
    fi

    # Last direction — update completed_directions, reset direction_index
    sed -i '' "s/^direction_index:.*/direction_index: 0/" "$STATE_FILE"
    if grep -q "^completed_directions:" "$STATE_FILE"; then
      sed -i '' "s/^completed_directions:.*/completed_directions: ${NEW_COMPLETED_DIRS}/" "$STATE_FILE"
    else
      sed -i '' "/^---$/a\\
completed_directions: ${NEW_COMPLETED_DIRS}" "$STATE_FILE"
    fi
    # Reset direction to first for next feature
    FIRST_DIRECTION=$(echo "$ALL_DIRECTIONS" | cut -d'|' -f1)
    sed -i '' "s/^direction:.*/direction: ${FIRST_DIRECTION}/" "$STATE_FILE"

    # Fall through to feature transition logic below
  fi

  ALL_FEATURES=$(get_field "all_features")
  if [ -z "$ALL_FEATURES" ]; then
    rm -f "$STATE_FILE"
    echo '{"decision": "allow"}'
    exit 0
  fi

  # --- All mode: advance to next feature ---
  CURRENT_INDEX=$(get_field "current_index")
  CURRENT_INDEX="${CURRENT_INDEX:-0}"
  CURRENT_FEATURE=$(get_field "feature")
  COMPLETED=$(get_field "completed_features")
  TOTAL=$(echo "$ALL_FEATURES" | awk -F'|' '{print NF}')

  NEXT_INDEX=$((CURRENT_INDEX + 1))
  NEXT_FEATURE=$(echo "$ALL_FEATURES" | cut -d'|' -f$((NEXT_INDEX + 1)))

  if [ -z "$COMPLETED" ]; then
    NEW_COMPLETED="$CURRENT_FEATURE"
  else
    NEW_COMPLETED="${COMPLETED}|${CURRENT_FEATURE}"
  fi

  if [ -z "$NEXT_FEATURE" ]; then
    rm -f "$STATE_FILE"
    echo '{"decision": "allow"}'
    exit 0
  fi

  # Transition to next feature: phase→generation, iteration→0
  sed -i '' "s/^phase:.*/phase: generation/" "$STATE_FILE"
  sed -i '' "s/^feature:.*/feature: ${NEXT_FEATURE}/" "$STATE_FILE"
  sed -i '' "s/^current_index:.*/current_index: ${NEXT_INDEX}/" "$STATE_FILE"
  sed -i '' "s/^iteration:.*/iteration: 0/" "$STATE_FILE"
  if grep -q "^completed_features:" "$STATE_FILE"; then
    sed -i '' "s/^completed_features:.*/completed_features: ${NEW_COMPLETED}/" "$STATE_FILE"
  else
    sed -i '' "/^---$/a\\
completed_features: ${NEW_COMPLETED}" "$STATE_FILE"
  fi

  cat <<HOOK_OUTPUT
{
  "decision": "block",
  "reason": "Feature '${CURRENT_FEATURE}' 디자인 검증 완료! (${NEXT_INDEX}/${TOTAL})\\n\\n다음 Feature: '${NEXT_FEATURE}'\\n\\n1. Read .claude/loom-design-pipeline.local.md → 현재 feature 확인\\n2. analysis.md에서 '${NEXT_FEATURE}' Feature 프롬프트 로드\\n3. Skill(stitch-design)으로 '${NEXT_FEATURE}' 디자인 생성 (Phase D3)\\n4. 생성 완료 후 phase를 verify로 변경하고 검증 시작\\n\\nreferences/workflows.md Phase D3 절차를 따르세요."
}
HOOK_OUTPUT
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
  "reason": "디자인 검증 루프를 계속합니다.\n\n1. Read .claude/loom-design-pipeline.local.md → 남은 gaps 확인\n2. gaps > 0: Skill(stitch-design)으로 누락분 수정 또는 재생성 → Phase D4 재검증\n3. gaps == 0: <promise>DESIGN_VERIFIED</promise> 출력\n\nreferences/workflows.md Phase D4 절차를 따르세요."
}
HOOK_OUTPUT
