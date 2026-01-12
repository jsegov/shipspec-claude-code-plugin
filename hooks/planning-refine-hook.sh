#!/bin/bash
# hooks/planning-refine-hook.sh
# Stop hook for task refinement during planning

STATE_FILE=".claude/shipspec-planning-refine.local.md"

# Exit early if no refinement active - BEFORE consuming stdin
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

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]] || [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
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

  if echo "$LAST_OUTPUT" | grep -q '<planning-refine-complete>'; then
    rm -f "$STATE_FILE"
    exit 0
  fi
fi

# Max iterations check
if [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "⚠️ Max refinement iterations ($MAX_ITERATIONS) reached" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Increment iteration
NEXT_ITER=$((ITERATION + 1))
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITER/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
SYSTEM_MSG="🔄 **Task Refinement: Iteration $NEXT_ITER/$MAX_ITERATIONS**

**Feature:** $FEATURE

Continue refining large tasks. Check TASKS.md for any tasks still > 5 story points."

# Return block decision
jq -n \
  --arg prompt "Continue refining large tasks for $FEATURE. Check for tasks > 5 story points and break them down." \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
