---
description: Start implementing the next available task from TASKS.md
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(npm:*), Bash(git:*), Bash(head:*), Bash(wc:*)
---

# Implement Next Task: $ARGUMENTS

Find and display the next task ready for implementation, verifying any in-progress work first.

## Step 1: Validate Prerequisites

Check that TASKS.md exists:
```bash
echo "=== Checking TASKS.md ==="
ls -la .shipspec/planning/$ARGUMENTS/TASKS.md 2>/dev/null || echo "TASKS.md NOT FOUND"
```

If TASKS.md is not found, tell the user:
> "No TASKS.md found for '$ARGUMENTS'. Please run `/feature-planning $ARGUMENTS` first to complete the planning workflow and generate tasks."

## Step 2: Load and Parse Tasks

Load the tasks document:
@.shipspec/planning/$ARGUMENTS/TASKS.md

Parse the document to extract:
1. **All tasks** with their IDs, titles, and statuses
2. **Status indicators**:
   - `- [ ]` = Not started
   - `- [~]` = In progress
   - `- [x]` = Completed
3. **Dependencies** from each task's `Depends on:` line

Build a task map:
```
TASK-001: status=[ ], depends_on=[], title="..."
TASK-002: status=[ ], depends_on=[TASK-001], title="..."
TASK-003: status=[x], depends_on=[], title="..."
```

## Step 3: Check for In-Progress Task

Search for any task marked with `[~]` (in progress).

**If an in-progress task is found:**

Tell the user:
> "Found in-progress task: **[TASK-ID]: [Title]**
>
> Let me verify if this task has been completed..."

Delegate to the `task-verifier` subagent with:
- The full task prompt for the in-progress task
- The feature name: `$ARGUMENTS`

**Based on verification result:**

- **VERIFIED**:
  - Update the task status from `[~]` to `[x]` in TASKS.md
  - Tell user: "Task [TASK-ID] verified complete! Moving to next task..."
  - Continue to Step 4

- **INCOMPLETE**:
  - Keep the task as `[~]`
  - Show the user what's missing
  - Tell user: "Task [TASK-ID] is not complete. Please address the issues above, then run this command again."
  - **Stop here** - don't proceed to next task

- **BLOCKED**:
  - Keep the task as `[~]`
  - Show the blocking reason
  - Ask user how they want to proceed

**If no in-progress task found:**
Continue to Step 4.

## Step 4: Find Next Available Task

Find the first task that meets ALL criteria:
1. Status is `[ ]` (not started)
2. All dependencies are `[x]` (completed)

**Dependency resolution logic:**
- Parse the `Depends on:` line from each task
- A task is "ready" if it has no dependencies OR all listed dependencies are marked `[x]`
- Skip tasks whose dependencies aren't satisfied

**If no task is ready:**

Check if all tasks are done:
```
All [x]? → "Congratulations! All tasks for '$ARGUMENTS' are complete!"
```

Otherwise, show the blocking situation:
> "No tasks are currently ready. The following tasks are blocked:
>
> | Task | Blocked By |
> |------|------------|
> | TASK-003 | TASK-001, TASK-002 |
> | TASK-004 | TASK-002 |
>
> Complete the blocking tasks first, then run this command again."

## Step 5: Start Next Task

Once a ready task is found:

1. **Update TASKS.md**: Change the task's status from `[ ]` to `[~]`
   - Find the line with `### - [ ] TASK-XXX:`
   - Replace with `### - [~] TASK-XXX:`

2. **Extract the full task prompt**: Get all content from the task header until the next task header (or end of phase/document)

3. **Display to user**:

> "## Starting Task: [TASK-ID]
>
> **[Task Title]**
>
> Status updated to: In Progress
>
> ---
>
> [Full task prompt content here]
>
> ---
>
> **Instructions:**
> Implement this task following the prompt above. When you're done, run:
> ```
> /implement-next-task $ARGUMENTS
> ```
> This will verify your work and move to the next task."

## Step 6: Summary

After displaying the task, show progress:

> "**Progress for $ARGUMENTS:**
> - Completed: X tasks
> - In Progress: 1 task (current)
> - Remaining: Y tasks
> - Blocked: Z tasks"

## Edge Cases

### Multiple In-Progress Tasks
If more than one task is marked `[~]`:
> "Warning: Multiple tasks are marked as in-progress. This shouldn't happen.
>
> In-progress tasks:
> - [TASK-XXX]: [Title]
> - [TASK-YYY]: [Title]
>
> Please resolve this by marking all but one as either `[ ]` (not started) or `[x]` (completed), then run this command again."

### Circular Dependencies
If dependency resolution detects a cycle:
> "Error: Circular dependency detected in tasks. Please review the dependency chain:
> TASK-001 → TASK-002 → TASK-003 → TASK-001
>
> Fix the dependencies in TASKS.md and try again."

### Empty Dependencies Field
If a task has `Depends on: None` or no dependencies section, treat it as having no dependencies (ready if status is `[ ]`).
