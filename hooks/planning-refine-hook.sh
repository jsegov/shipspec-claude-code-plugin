#!/bin/bash
# hooks/planning-refine-hook.sh
# Stop hook for task refinement during planning

set -euo pipefail

STATE_FILE=".claude/shipspec-planning-refine.local.md"

# Exit early if no refinement active - BEFORE consuming stdin
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
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "")
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "")
FEATURE=$(echo "$FRONTMATTER" | grep '^feature:' | sed 's/feature: *//' || echo "")

# Extract prompt (everything after the closing ---)
PROMPT_TEXT=$(awk '/^---$/{if(i<2){i++; next}} i>=2' "$STATE_FILE")

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Planning refine: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "   Delete the file manually to cancel: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Planning refine: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "   Delete the file manually to cancel: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Validate prompt text exists
if [[ -z "$PROMPT_TEXT" ]]; then
  echo "⚠️ Planning refine: State file corrupted or incomplete" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: No prompt text found after frontmatter" >&2
  echo "" >&2
  echo "   This usually means:" >&2
  echo "     - State file was manually edited" >&2
  echo "     - File was corrupted during writing" >&2
  echo "" >&2
  echo "   Delete the file manually to cancel: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Validate transcript exists and has content
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️ Planning refine: Transcript not found, allowing exit" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo "⚠️ Planning refine: No assistant messages in transcript, allowing exit" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️ Planning refine: Failed to extract last assistant message" >&2
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
  echo "⚠️ Planning refine: Assistant message contained no text" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Check for completion marker
if echo "$LAST_OUTPUT" | grep -q '<planning-refine-complete>'; then
  rm -f "$STATE_FILE"
  exit 0
fi

# Max iterations check (0 means unlimited)
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "⚠️ Planning refine: Max iterations ($MAX_ITERATIONS) reached" >&2
  echo "   Delete the file manually if needed: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Increment iteration
NEXT_ITER=$((ITERATION + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITER/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
MAX_DISPLAY="$MAX_ITERATIONS"
if [[ "$MAX_ITERATIONS" == "0" ]]; then
  MAX_DISPLAY="unlimited"
fi

SYSTEM_MSG="🔄 **Task Refinement: Iteration $NEXT_ITER/$MAX_DISPLAY**

**Feature:** $FEATURE

Continue refining large tasks. Check TASKS.md for any tasks still > 5 story points."

# Return block decision - feed original prompt back for another attempt
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
