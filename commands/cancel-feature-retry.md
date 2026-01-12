---
description: Cancel active feature implementation retry loop
allowed-tools:
  - Bash(test:*)
  - Bash(rm:*)
  - Read
---

# Cancel Feature Retry

Cancel an active feature implementation retry loop.

## Step 1: Check for Active Loop

```bash
test -f .claude/shipspec-feature-retry.local.md && echo "EXISTS" || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No active feature retry loop found."

**Stop here.**

## Step 2: Read Current State

If EXISTS, read the state file:

```
Read .claude/shipspec-feature-retry.local.md
```

Extract from the YAML frontmatter:
- `current_task_id` - the task being implemented
- `feature` - the feature name
- `task_attempt` - current attempt number for the task
- `max_task_attempts` - maximum attempts per task
- `tasks_completed` - number of completed tasks
- `total_tasks` - total number of tasks

## Step 3: Cancel the Loop

Remove the state file:

```bash
rm .claude/shipspec-feature-retry.local.md
```

## Step 4: Report

> "Cancelled feature retry for **[FEATURE]**
>
> - Current task: [CURRENT_TASK_ID] (attempt [TASK_ATTEMPT]/[MAX_TASK_ATTEMPTS])
> - Progress: [TASKS_COMPLETED]/[TOTAL_TASKS] tasks completed
>
> The current task remains in `[~]` (in-progress) status in TASKS.md.
> Run `/implement-feature [feature]` to resume, or `/implement-task [feature]` to continue task-by-task."
