---
description: Cancel active task implementation loop
allowed-tools:
  - Bash(test:*)
  - Bash(rm:*)
  - Bash(grep:*)
  - Bash(sed:*)
  - Read
---

# Cancel Task Loop

Cancel an active task implementation loop.

## Step 1: Check for Active Loop

Check for the pointer file:
```bash
test -f .shipspec/active-loop.local.md && echo "POINTER_EXISTS" || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No active task loop found."

**Stop here.**

**If POINTER_EXISTS:**
Read the pointer file and verify it's a task-loop:
```bash
grep "^loop_type:" .shipspec/active-loop.local.md
```

**If loop_type is NOT "task-loop":**
> "No active task loop found. (A different loop type is active)"

**Stop here.**

## Step 2: Read Current State

Extract the state path from the pointer:
```bash
grep "^state_path:" .shipspec/active-loop.local.md | sed 's/state_path: *//'
```

Read the state file using the extracted path:
```
Read [state_path]
```

Extract from the YAML frontmatter:
- `task_id` - the task being implemented
- `feature` - the feature name
- `iteration` - current attempt number
- `max_iterations` - maximum attempts configured

## Step 3: Cancel the Loop

Remove both the state file and pointer:

```bash
rm -f [state_path] .shipspec/active-loop.local.md
```

## Step 4: Report

> "Cancelled task loop for **[TASK_ID]** in feature **[FEATURE]**
>
> - Was at iteration: [ITERATION]/[MAX_ITERATIONS]
>
> The task remains in `[~]` (in-progress) status in TASKS.md.
> Run `/implement-task [feature]` to resume, or manually update the task status."
