---
description: Cancel active task implementation loop
allowed-tools:
  - Bash(test:*)
  - Bash(rm:*)
  - Read
---

# Cancel Task Loop

Cancel an active task implementation loop.

## Step 1: Check for Active Loop

```bash
test -f .claude/shipspec-task-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No active task loop found."

**Stop here.**

## Step 2: Read Current State

If EXISTS, read the state file:

```
Read .claude/shipspec-task-loop.local.md
```

Extract from the YAML frontmatter:
- `task_id` - the task being implemented
- `feature` - the feature name
- `iteration` - current attempt number
- `max_iterations` - maximum attempts configured

## Step 3: Cancel the Loop

Remove the state file:

```bash
rm .claude/shipspec-task-loop.local.md
```

## Step 4: Report

> "Cancelled task loop for **[TASK_ID]** in feature **[FEATURE]**
>
> - Was at iteration: [ITERATION]/[MAX_ITERATIONS]
>
> The task remains in `[~]` (in-progress) status in TASKS.md.
> Run `/implement-task [feature]` to resume, or manually update the task status."
