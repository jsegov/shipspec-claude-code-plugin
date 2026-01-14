#!/bin/bash
# hooks/feature-retry-hook.sh
# Stop hook for feature implementation with per-task auto-retry

set -euo pipefail

POINTER_FILE=".shipspec/active-loop.local.json"
EXPECTED_LOOP_TYPE="feature-retry"

# Exit early if no pointer file - BEFORE consuming stdin
# (Multiple hooks share stdin; inactive hooks must not consume it)
if [[ ! -f "$POINTER_FILE" ]]; then
  exit 0
fi

# Parse pointer file (JSON) to get loop type and state path
LOOP_TYPE=$(jq -r '.loop_type // empty' "$POINTER_FILE" 2>/dev/null || echo "")
STATE_FILE=$(jq -r '.state_path // empty' "$POINTER_FILE" 2>/dev/null || echo "")
FEATURE=$(jq -r '.feature // empty' "$POINTER_FILE" 2>/dev/null || echo "")

# Exit if this hook's loop type is not active
if [[ "$LOOP_TYPE" != "$EXPECTED_LOOP_TYPE" ]]; then
  exit 0
fi

# Exit if state file doesn't exist (stale pointer)
if [[ -z "$STATE_FILE" ]] || [[ ! -f "$STATE_FILE" ]]; then
  echo "⚠️ Feature retry: Pointer references non-existent state file" >&2
  rm -f "$POINTER_FILE"  # Clean up stale pointer
  exit 0
fi

# Only read stdin if this hook is active
INPUT=$(cat)

# Check if stdin was already consumed by another hook
if [[ -z "$INPUT" ]]; then
  echo "⚠️ Feature retry: No stdin received (likely consumed by another active hook)" >&2
  echo "   State file preserved for next session" >&2
  exit 0  # Exit without deleting state - loop continues next time
fi

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Parse state file (JSON)
TASK_ATTEMPT=$(jq -r '.task_attempt // 0' "$STATE_FILE" 2>/dev/null || echo "0")
MAX_ATTEMPTS=$(jq -r '.max_task_attempts // 5' "$STATE_FILE" 2>/dev/null || echo "5")
TASK_ID=$(jq -r '.current_task_id // empty' "$STATE_FILE" 2>/dev/null || echo "")
TASKS_COMPLETED=$(jq -r '.tasks_completed // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.total_tasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# Get prompt from TASKS.json
TASKS_FILE=".shipspec/planning/$FEATURE/TASKS.json"
if [[ -f "$TASKS_FILE" ]]; then
  PROMPT_TEXT=$(jq -r --arg id "$TASK_ID" '.tasks[$id].prompt // empty' "$TASKS_FILE" 2>/dev/null || echo "")
else
  PROMPT_TEXT=""
fi

# Validate numeric fields
if [[ ! "$TASK_ATTEMPT" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Feature retry: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'task_attempt' field is not a valid number (got: '$TASK_ATTEMPT')" >&2
  echo "   Run /cancel-feature-retry or delete the file manually" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

if [[ ! "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Feature retry: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'max_task_attempts' field is not a valid number (got: '$MAX_ATTEMPTS')" >&2
  echo "   Run /cancel-feature-retry or delete the file manually" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Validate prompt text exists
if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️ Feature retry: Could not retrieve task prompt" >&2
  echo "   Task ID: $TASK_ID" >&2
  echo "   TASKS.json: $TASKS_FILE" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     - TASKS.json was deleted or moved" >&2
  echo "     - Task ID doesn't exist in TASKS.json" >&2
  echo "" >&2
  echo "   Run /cancel-feature-retry or delete the state file manually" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Validate transcript exists and has content
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️ Feature retry: Transcript not found, allowing exit" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo "⚠️ Feature retry: No assistant messages in transcript, allowing exit" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️ Feature retry: Failed to extract last assistant message" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Parse with error handling
LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>&1) || true

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "⚠️ Feature retry: Assistant message contained no text" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Check for completion markers
# Feature task complete - allow exit to continue to next task
if echo "$LAST_OUTPUT" | grep -q '<feature-task-complete>VERIFIED</feature-task-complete>'; then
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Task blocked - allow exit, needs manual intervention
if echo "$LAST_OUTPUT" | grep -q '<feature-task-complete>BLOCKED</feature-task-complete>'; then
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Feature complete marker - all tasks done
if echo "$LAST_OUTPUT" | grep -q '<feature-complete>'; then
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Max attempts check for current task (0 means unlimited)
if [[ $MAX_ATTEMPTS -gt 0 ]] && [[ $TASK_ATTEMPT -ge $MAX_ATTEMPTS ]]; then
  echo "⚠️ Feature retry: Max attempts ($MAX_ATTEMPTS) reached for $TASK_ID" >&2
  echo "   Run /cancel-feature-retry to clear state if needed" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Increment attempt in state file (JSON)
NEXT_ATTEMPT=$((TASK_ATTEMPT + 1))
jq --argjson attempt "$NEXT_ATTEMPT" '.task_attempt = $attempt' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

# Build context-aware system message
MAX_DISPLAY="$MAX_ATTEMPTS"
if [[ "$MAX_ATTEMPTS" == "0" ]]; then
  MAX_DISPLAY="unlimited"
fi

# All retries are post-verification failures (verification always runs before hook triggers)
SYSTEM_MSG="🔄 **Feature Implementation: Task Retry**

**Feature:** $FEATURE
**Task:** $TASK_ID (Attempt $NEXT_ATTEMPT/$MAX_DISPLAY)
**Progress:** $TASKS_COMPLETED/$TOTAL_TASKS tasks completed

Previous attempt did not pass all acceptance criteria.
Review what failed and fix the implementation."

# Return block decision - feed original prompt back for another attempt
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
