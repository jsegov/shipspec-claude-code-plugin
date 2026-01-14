#!/bin/bash
# hooks/planning-refine-hook.sh
# Stop hook for task refinement during planning

set -euo pipefail

POINTER_FILE=".shipspec/active-loop.local.json"
EXPECTED_LOOP_TYPE="planning-refine"

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
  echo "⚠️ Planning refine: Pointer references non-existent state file" >&2
  rm -f "$POINTER_FILE"  # Clean up stale pointer
  exit 0
fi

# Only read stdin if this hook is active
INPUT=$(cat)

# Check if stdin was already consumed by another hook
if [[ -z "$INPUT" ]]; then
  echo "⚠️ Planning refine: No stdin received (likely consumed by another active hook)" >&2
  echo "   State file preserved for next session" >&2
  exit 0  # Exit without deleting state - loop continues next time
fi

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# Parse state file (JSON)
ITERATION=$(jq -r '.iteration // 0' "$STATE_FILE" 2>/dev/null || echo "0")
MAX_ITERATIONS=$(jq -r '.max_iterations // 3' "$STATE_FILE" 2>/dev/null || echo "3")

# Build refinement prompt from state - for planning-refine, we use a static prompt
# since the refinement instructions are in the state file
PROMPT_TEXT="Continue refining large tasks in \`.shipspec/planning/$FEATURE/TASKS.json\`.

### Instructions:
1. Read TASKS.json and identify tasks with story points > 5
2. For each large task, break it into 2-3 smaller subtasks (each ≤3 story points)
3. Update TASKS.json with the new subtasks
4. Update TASKS.md to reflect the changes
5. Preserve acceptance criteria across subtasks
6. Update dependencies pointing to the original task

### Completion:
When all tasks are ≤5 story points, output:
\`<planning-refine-complete>\`"

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Planning refine: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'iteration' field is not a valid number (got: '$ITERATION')" >&2
  echo "   Delete the file manually to cancel: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "⚠️ Planning refine: State file corrupted" >&2
  echo "   File: $STATE_FILE" >&2
  echo "   Problem: 'max_iterations' field is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "   Delete the file manually to cancel: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Validate transcript exists and has content
if [[ -z "$TRANSCRIPT_PATH" ]] || [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️ Planning refine: Transcript not found, allowing exit" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Check for assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null; then
  echo "⚠️ Planning refine: No assistant messages in transcript, allowing exit" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
if [[ -z "$LAST_LINE" ]]; then
  echo "⚠️ Planning refine: Failed to extract last assistant message" >&2
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
  echo "⚠️ Planning refine: Assistant message contained no text" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Check for completion marker
if echo "$LAST_OUTPUT" | grep -q '<planning-refine-complete>'; then
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Max iterations check (0 means unlimited)
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "⚠️ Planning refine: Max iterations ($MAX_ITERATIONS) reached" >&2
  echo "   Delete the file manually if needed: rm $STATE_FILE" >&2
  rm -f "$STATE_FILE" "$POINTER_FILE"
  exit 0
fi

# Increment iteration in state file (JSON)
NEXT_ITER=$((ITERATION + 1))
jq --argjson iter "$NEXT_ITER" '.iteration = $iter' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

# Build system message
MAX_DISPLAY="$MAX_ITERATIONS"
if [[ "$MAX_ITERATIONS" == "0" ]]; then
  MAX_DISPLAY="unlimited"
fi

SYSTEM_MSG="🔄 **Task Refinement: Iteration $NEXT_ITER/$MAX_DISPLAY**

**Feature:** $FEATURE

Continue refining large tasks. Check TASKS.json for any tasks still > 5 story points."

# Return block decision - feed refinement prompt back for another attempt
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
