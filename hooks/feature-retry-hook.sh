#!/bin/bash
# hooks/feature-retry-hook.sh
# Stop hook for feature implementation with per-task auto-retry

set -euo pipefail

STATE_FILE=".claude/shipspec-feature-retry.local.md"

# Exit early if no feature retry active - BEFORE consuming stdin
# (Multiple hooks share stdin; inactive hooks must not consume it)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Only read stdin if this hook is active
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Parse YAML frontmatter only (not prompt body)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

# Extract fields from frontmatter
TASK_ATTEMPT=$(echo "$FRONTMATTER" | grep '^task_attempt:' | sed 's/task_attempt: *//' || echo "")
MAX_ATTEMPTS=$(echo "$FRONTMATTER" | grep '^max_task_attempts:' | sed 's/max_task_attempts: *//' || echo "")
FEATURE=$(echo "$FRONTMATTER" | grep '^feature:' | sed 's/feature: *//' || echo "")
TASK_ID=$(echo "$FRONTMATTER" | grep '^current_task_id:' | sed 's/current_task_id: *//' || echo "")
TASKS_COMPLETED=$(echo "$FRONTMATTER" | grep '^tasks_completed:' | sed 's/tasks_completed: *//' || echo "")
TOTAL_TASKS=$(echo "$FRONTMATTER" | grep '^total_tasks:' | sed 's/total_tasks: *//' || echo "")

# Extract prompt (everything after the closing ---)
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")

# Validate numeric fields
if [[ ! "$TASK_ATTEMPT" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Feature retry: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'task_attempt' field is not a valid number (got: '$TASK_ATTEMPT')" >&2
  echo "   Run /cancel-feature-retry or delete the file manually" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ATTEMPTS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Feature retry: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'max_task_attempts' field is not a valid number (got: '$MAX_ATTEMPTS')" >&2
  echo "   Run /cancel-feature-retry or delete the file manually" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Validate prompt text exists
if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️ Feature retry: State file corrupted or incomplete" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: No prompt text found after frontmatter" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     - State file was manually edited" >&2
  echo "     - File was corrupted during writing" >&2
  echo "" >&2
  echo "   Run /cancel-feature-retry or delete the file manually" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Validate transcript exists and has content
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️ Feature retry: Transcript not found, allowing exit" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo "⚠️ Feature retry: No assistant messages in transcript, allowing exit" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️ Feature retry: Failed to extract last assistant message" >&2
  rm -f "$STATE_FILE"
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
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for completion markers
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

# Max attempts check for current task (0 means unlimited)
if [[ $MAX_ATTEMPTS -gt 0 ]] && [[ $TASK_ATTEMPT -ge $MAX_ATTEMPTS ]]; then
  echo "⚠️ Feature retry: Max attempts ($MAX_ATTEMPTS) reached for $TASK_ID" >&2
  echo "   Run /cancel-feature-retry to clear state if needed" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Increment attempt
NEXT_ATTEMPT=$((TASK_ATTEMPT + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^task_attempt: .*/task_attempt: $NEXT_ATTEMPT/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
MAX_DISPLAY="$MAX_ATTEMPTS"
if [[ "$MAX_ATTEMPTS" == "0" ]]; then
  MAX_DISPLAY="unlimited"
fi

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
