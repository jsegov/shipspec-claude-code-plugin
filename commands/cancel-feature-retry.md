---
description: Cancel active feature implementation retry loop
allowed-tools:
  - Bash(test:*)
  - Bash(rm:*)
  - Bash(grep:*)
  - Bash(sed:*)
  - Read
---

# Cancel Feature Retry

Cancel an active feature implementation retry loop.

## Step 1: Check for Active Loop

Check for the pointer file:
```bash
test -f .shipspec/active-loop.local.md && echo "POINTER_EXISTS" || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No active feature retry loop found."

**Stop here.**

**If POINTER_EXISTS:**
Read the pointer file and verify it's a feature-retry:
```bash
grep "^loop_type:" .shipspec/active-loop.local.md
```

**If loop_type is NOT "feature-retry":**
> "No active feature retry loop found. (A different loop type is active)"

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
- `current_task_id` - the task being implemented
- `feature` - the feature name
- `task_attempt` - current attempt number for the task
- `max_task_attempts` - maximum attempts per task
- `tasks_completed` - number of completed tasks
- `total_tasks` - total number of tasks

## Step 3: Cancel the Loop

Remove both the state file and pointer:

```bash
rm -f [state_path] .shipspec/active-loop.local.md
```

## Step 4: Report

> "Cancelled feature retry for **[FEATURE]**
>
> - Current task: [CURRENT_TASK_ID] (attempt [TASK_ATTEMPT]/[MAX_TASK_ATTEMPTS])
> - Progress: [TASKS_COMPLETED]/[TOTAL_TASKS] tasks completed
>
> The current task remains in `[~]` (in-progress) status in TASKS.md.
> Run `/implement-feature [feature]` to resume, or `/implement-task [feature]` to continue task-by-task."
