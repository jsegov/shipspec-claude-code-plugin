#!/bin/bash
# hooks/task-loop-hook.sh
# Stop hook for automatic task verification retry loop

STATE_FILE=".claude/shipspec-task-loop.local.md"

# Exit early if no active loop - BEFORE consuming stdin
# (Multiple hooks share stdin; inactive hooks must not consume it)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Only read stdin if this hook is active
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Parse YAML frontmatter
ITERATION=$(grep "^iteration:" "$STATE_FILE" | sed 's/iteration: //')
MAX_ITERATIONS=$(grep "^max_iterations:" "$STATE_FILE" | sed 's/max_iterations: //')
FEATURE=$(grep "^feature:" "$STATE_FILE" | sed 's/feature: //')
TASK_ID=$(grep "^task_id:" "$STATE_FILE" | sed 's/task_id: //')

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]] || [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Corrupted state file, cleaning up" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for completion marker in last assistant message (like ralph does)
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
  LAST_OUTPUT=$(echo "$LAST_ASSISTANT" | jq -r '
    .message.content |
    map(select(.type == "text")) |
    map(.text) |
    join("\n")
  ' 2>/dev/null)

  # Check for completion marker
  if echo "$LAST_OUTPUT" | grep -q '<task-loop-complete>VERIFIED</task-loop-complete>'; then
    rm -f "$STATE_FILE"
    exit 0  # Allow exit - task verified
  fi

  if echo "$LAST_OUTPUT" | grep -q '<task-loop-complete>BLOCKED</task-loop-complete>'; then
    rm -f "$STATE_FILE"
    exit 0  # Allow exit - task blocked, needs manual intervention
  fi

  if echo "$LAST_OUTPUT" | grep -q '<task-loop-complete>INCOMPLETE</task-loop-complete>'; then
    rm -f "$STATE_FILE"
    exit 0  # Allow exit - task incomplete, needs manual fixes
  fi

  if echo "$LAST_OUTPUT" | grep -q '<task-loop-complete>MISALIGNED</task-loop-complete>'; then
    rm -f "$STATE_FILE"
    exit 0  # Allow exit - implementation misaligned with planning
  fi
fi

# Max iterations check
if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "⚠️ Max iterations ($MAX_ITERATIONS) reached for $TASK_ID" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Increment iteration
NEXT_ITERATION=$((ITERATION + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
SYSTEM_MSG="🔄 **Task Loop: Attempt $NEXT_ITERATION/$MAX_ITERATIONS**

Previous attempt did not pass all acceptance criteria.

**Task:** $TASK_ID
**Feature:** $FEATURE

Review what failed and continue implementation. When done, run task-verifier to check completion."

# Return block decision - feed prompt back for another attempt
jq -n \
  --arg prompt "Continue implementing $TASK_ID. Fix any issues, then verify the task is complete." \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
