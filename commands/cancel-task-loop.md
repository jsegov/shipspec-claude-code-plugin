---
description: Cancel active task implementation loop
allowed-tools:
  - Bash(test:*)
  - Bash(rm:*)
  - Bash(jq:*)
  - Read
---

# Cancel Task Loop

Cancel an active task implementation loop.

## Step 1: Check for Active Loop

Check for the pointer file:
```bash
test -f .shipspec/active-loop.local.json && echo "POINTER_EXISTS" || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No active task loop found."

**Stop here.**

**If POINTER_EXISTS:**
Read the pointer file and verify it's a task-loop:
```bash
jq -r '.loop_type // empty' .shipspec/active-loop.local.json
```

**If loop_type is NOT "task-loop":**
> "No active task loop found. (A different loop type is active)"

**Stop here.**

## Step 2: Read Current State

Extract the state path from the pointer:
```bash
jq -r '.state_path // empty' .shipspec/active-loop.local.json
```

Parse the state file (JSON) to extract:
```bash
jq -r '.task_id // empty' [state_path]
jq -r '.feature // empty' [state_path]
jq -r '.iteration // 0' [state_path]
jq -r '.max_iterations // 5' [state_path]
```

- `task_id` - the task being implemented
- `feature` - the feature name
- `iteration` - current attempt number
- `max_iterations` - maximum attempts configured

## Step 3: Cancel the Loop

Remove both the state file and pointer:

```bash
rm -f [state_path] .shipspec/active-loop.local.json
```

## Step 4: Report

> "Cancelled task loop for **[TASK_ID]** in feature **[FEATURE]**
>
> - Was at iteration: [ITERATION]/[MAX_ITERATIONS]
>
> The task remains in `in_progress` status in TASKS.json.
> Run `/implement-task [feature]` to resume, or use task-manager to update the task status."
