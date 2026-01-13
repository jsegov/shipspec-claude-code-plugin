#!/bin/bash
# hooks/task-loop-hook.sh
# Stop hook for automatic task verification retry loop

set -euo pipefail

STATE_FILE=".claude/shipspec-task-loop.local.md"

# Exit early if no active loop - BEFORE consuming stdin
# (Multiple hooks share stdin; inactive hooks must not consume it)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Only read stdin if this hook is active
INPUT=$(cat)

# Check if stdin was already consumed by another hook
if [[ -z "$INPUT" ]]; then
  echo "⚠️ Task loop: No stdin received (likely consumed by another active hook)" >&2
  echo "   State file preserved for next session" >&2
  exit 0  # Exit without deleting state - loop continues next time
fi

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Parse YAML frontmatter only (not prompt body)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

# Extract fields from frontmatter
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "")
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "")
FEATURE=$(echo "$FRONTMATTER" | grep '^feature:' | sed 's/feature: *//' || echo "")
TASK_ID=$(echo "$FRONTMATTER" | grep '^task_id:' | sed 's/task_id: *//' || echo "")

# Extract prompt (everything after the closing ---)
PROMPT_TEXT=$(awk '/^---$/{if(i<2){i++; next}} i>=2' "$STATE_FILE")

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Task loop: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "   Run /cancel-task-loop or delete the file manually" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Task loop: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "   Run /cancel-task-loop or delete the file manually" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Validate prompt text exists
if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️ Task loop: State file corrupted or incomplete" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: No prompt text found after frontmatter" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     - State file was manually edited" >&2
  echo "     - File was corrupted during writing" >&2
  echo "" >&2
  echo "   Run /cancel-task-loop or delete the file manually" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Validate transcript exists and has content
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️ Task loop: Transcript not found, allowing exit" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo "⚠️ Task loop: No assistant messages in transcript, allowing exit" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️ Task loop: Failed to extract last assistant message" >&2
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
  echo "⚠️ Task loop: Assistant message contained no text" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for completion markers
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

# Max iterations check (0 means unlimited)
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "⚠️ Task loop: Max iterations ($MAX_ITERATIONS) reached for $TASK_ID" >&2
  echo "   Run /cancel-task-loop to clear state if needed" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Increment iteration
NEXT_ITERATION=$((ITERATION + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build context-aware system message
MAX_DISPLAY="$MAX_ITERATIONS"
if [[ "$MAX_ITERATIONS" == "0" ]]; then
  MAX_DISPLAY="unlimited"
fi

if [[ $NEXT_ITERATION -eq 2 ]]; then
  # First retry - task was just displayed, no verification occurred
  SYSTEM_MSG="🔄 **Task Loop: Attempt $NEXT_ITERATION/$MAX_DISPLAY**

**Task:** $TASK_ID
**Feature:** $FEATURE

Continue implementing the task. When done, run task-verifier to check completion."
else
  # Subsequent retries - verification actually ran and failed
  SYSTEM_MSG="🔄 **Task Loop: Attempt $NEXT_ITERATION/$MAX_DISPLAY**

Previous attempt did not pass all acceptance criteria.

**Task:** $TASK_ID
**Feature:** $FEATURE

Review what failed and continue implementation. When done, run task-verifier to check completion."
fi

# Return block decision - feed original prompt back for another attempt
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
