#!/bin/bash
# hooks/feature-retry-hook.sh
# Stop hook for feature implementation with per-task auto-retry

STATE_FILE=".claude/shipspec-feature-retry.local.md"

# Exit early if no feature retry active - BEFORE consuming stdin
# (Multiple hooks share stdin; inactive hooks must not consume it)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Only read stdin if this hook is active
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Parse YAML frontmatter
TASK_ATTEMPT=$(grep "^task_attempt:" "$STATE_FILE" | sed 's/task_attempt: //')
MAX_ATTEMPTS=$(grep "^max_task_attempts:" "$STATE_FILE" | sed 's/max_task_attempts: //')
FEATURE=$(grep "^feature:" "$STATE_FILE" | sed 's/feature: //')
TASK_ID=$(grep "^current_task_id:" "$STATE_FILE" | sed 's/current_task_id: //')
TASKS_COMPLETED=$(grep "^tasks_completed:" "$STATE_FILE" | sed 's/tasks_completed: //')
TOTAL_TASKS=$(grep "^total_tasks:" "$STATE_FILE" | sed 's/total_tasks: //')

# Validate numeric fields
if [[ ! "$TASK_ATTEMPT" =~ ^[0-9]+$ ]] || [[ ! "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Corrupted state file, cleaning up" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for completion marker in last assistant message
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
  LAST_OUTPUT=$(echo "$LAST_ASSISTANT" | jq -r '
    .message.content |
    map(select(.type == "text")) |
    map(.text) |
    join("\n")
  ' 2>/dev/null)

  # Feature task complete - allow exit to continue to next task
  if echo "$LAST_OUTPUT" | grep -q '<feature-task-complete>VERIFIED</feature-task-complete>'; then
    rm -f "$STATE_FILE"
    exit 0
  fi

  # Task blocked - allow exit, needs manual intervention
  if echo "$LAST_OUTPUT" | grep -q '<feature-task-complete>BLOCKED</feature-task-complete>'; then
    rm -f "$STATE_FILE"
    exit 0
  fi

  # Feature complete marker - all tasks done
  if echo "$LAST_OUTPUT" | grep -q '<feature-complete>'; then
    rm -f "$STATE_FILE"
    exit 0
  fi
fi

# Max attempts check for current task
if [[ $TASK_ATTEMPT -ge $MAX_ATTEMPTS ]]; then
  echo "⚠️ Max attempts ($MAX_ATTEMPTS) reached for $TASK_ID" >&2
  # Don't delete state - let user decide (skip, abort, manual fix)
  exit 0
fi

# Increment attempt
NEXT_ATTEMPT=$((TASK_ATTEMPT + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^task_attempt: .*/task_attempt: $NEXT_ATTEMPT/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
SYSTEM_MSG="🔄 **Feature Implementation: Task Retry**

**Feature:** $FEATURE
**Task:** $TASK_ID (Attempt $NEXT_ATTEMPT/$MAX_ATTEMPTS)
**Progress:** $TASKS_COMPLETED/$TOTAL_TASKS tasks completed

Previous attempt did not pass all acceptance criteria.
Review what failed and fix the implementation."

# Return block decision
jq -n \
  --arg prompt "Continue implementing $TASK_ID for feature $FEATURE. Fix the failing criteria, then verify." \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
