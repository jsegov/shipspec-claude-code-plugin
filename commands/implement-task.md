---
description: Implement a specific task or the next available task from TASKS.md
argument-hint: <feature-dir> [task-id]
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(git:*), Bash(head:*), Bash(wc:*), Bash(npm:*), Bash(npx:*), Bash(yarn:*), Bash(pnpm:*), Bash(bun:*), Bash(cargo:*), Bash(make:*), Bash(pytest:*), Bash(go:*), Bash(mypy:*), Bash(ruff:*), Bash(flake8:*), Bash(golangci-lint:*), Task
---

# Implement Task: $ARGUMENTS

Implement a specific task by ID, or find and implement the next available task.

## Step 0: Parse and Validate Arguments

Parse `$ARGUMENTS` to extract:
1. **feature-dir** (required): The first word/argument
2. **task-id** (optional): The second word/argument, if provided

**Normalize task-id format:**
- If task-id is just a number (e.g., `3`), convert to `TASK-003` format (zero-padded to 3 digits)
- If task-id is already in `TASK-XXX` format, use as-is
- Store the normalized task-id for later use

**If feature-dir is empty or missing:**
> "Error: Feature directory is required.
>
> **Usage:** `/implement-task <feature-dir> [task-id]`
>
> **Examples:**
> - `/implement-task my-feature` - implement next available task
> - `/implement-task my-feature 3` - implement TASK-003 specifically
> - `/implement-task my-feature TASK-003` - same as above
>
> **To see available features:**
> ```bash
> ls .shipspec/planning/
> ```"

**Stop here** - do not proceed without a feature directory.

## Step 1: Locate Feature Directory

Check that the feature directory exists:

```bash
ls -d .shipspec/planning/[feature-dir] 2>/dev/null || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No directory found for '[feature-dir]' at `.shipspec/planning/[feature-dir]`.
>
> Please run `/feature-planning` first to create the planning artifacts."

**Check for TASKS.md:**
```bash
ls -la .shipspec/planning/[feature-dir]/TASKS.md 2>/dev/null || echo "TASKS.md NOT FOUND"
```

**If TASKS.md not found:**
> "No TASKS.md found in `.shipspec/planning/[feature-dir]/`.
>
> Run `/feature-planning` to complete the planning workflow and generate tasks."

## Step 2: Load, Parse, and Validate Tasks

Delegate to the `task-manager` agent with:
- Feature name: [feature-dir]
- Operation: `parse`

**If error (TASKS.md not found or empty):**
Show the error message from task-manager and stop.

**If successful:**
Use the task map and statistics from the response.

Next, validate the task structure by delegating to `task-manager` with:
- Feature name: [feature-dir]
- Operation: `validate`

**If INVALID:**
Show all issues from the validation result (circular dependencies, multiple in-progress, invalid references) and stop.

**If VALID:**
Continue to Step 3.

## Step 3: Determine Target Task

**If task-id was provided in arguments:**

Delegate to the `task-manager` agent with:
- Feature name: [feature-dir]
- Operation: `get_task`
- Task ID: [task-id]

**Based on the result:**

- **NOT_FOUND**: Show error with available task IDs and stop.
- **ALREADY_COMPLETED**: "Task [task-id] is already completed. Choose a different task or omit the task-id to get the next available."
- **DEPENDENCIES_NOT_MET**: Show blocking dependencies and stop.
- **FOUND** with status `in_progress`: Proceed to Step 4 (verify completion)
- **FOUND** with status `not_started`: The task is ready - skip to Step 6

**If no task-id was provided:**
Continue to Step 4 to check for in-progress tasks, then Step 5 to find the next available.

## Step 4: Check for In-Progress Task

Delegate to the `task-manager` agent with:
- Feature name: [feature-dir]
- Operation: `find_in_progress`

**If MULTIPLE:**
The validation in Step 2 should have caught this, but if it occurs:
Show the warning message from task-manager and **stop** - wait for user to resolve.

**If SINGLE:**

If task-id was specified and it's different from the in-progress task:
> "Warning: Task [in-progress-id] is currently in progress.
>
> You requested [task-id], but [in-progress-id] is marked as in-progress.
>
> Options:
> 1. Complete or abandon [in-progress-id] first
> 2. Run `/implement-task [feature-dir]` without a task-id to continue [in-progress-id]"
>
> **Stop here.**

If task-id matches the in-progress task OR no task-id was specified:

Tell the user:
> "Found in-progress task: **[TASK-ID]: [Title]**
>
> Let me verify if this task has been completed..."

**Get full task prompt** by delegating to `task-manager` with:
- Feature name: [feature-dir]
- Operation: `get_task`
- Task ID: [the in-progress task ID]

Delegate to the `task-verifier` subagent with:
- The full task prompt for the in-progress task
- The feature directory name

**Based on verification result:**

- **VERIFIED**:
  - Continue to Step 4.5 to validate planning alignment (if task has references)

- **INCOMPLETE**:
  - Keep the task as `[~]`
  - Show the user what's missing
  - Tell user: "Task [TASK-ID] is not complete. Please address the issues above, then run this command again."
  - **Stop here** - don't proceed to next task

- **BLOCKED**:
  - Keep the task as `[~]`
  - Show the blocking reason
  - Ask user how they want to proceed

**If NONE:**
Continue to Step 5.

## Step 4.5: Validate Planning Alignment (if references exist)

**This step runs after task-verifier returns VERIFIED.**

Check if the task has a `## References` section containing SDD or PRD references.

**If the task has SDD or PRD references:**

1. Tell user: "Acceptance criteria verified. Checking planning alignment..."

2. Delegate to the `planning-validator` agent with:
   - The task ID
   - The feature directory name
   - The task's References section

3. **Based on validation result:**

   **If ALIGNED:**
   - Tell user: "Planning alignment verified."
   - Update task status from `[~]` to `[x]` in TASKS.md
   - Tell user: "Task [TASK-ID] complete! Moving to next task..."
   - If task-id was specified and matches: **Stop here** - the requested task is complete
   - Otherwise: Continue to Step 5

   **If MISALIGNED:**
   - Show specific misalignment issues
   - Tell user: "Implementation doesn't match design/requirements. Please fix the issues above."
   - Keep task as `[~]`, **stop here**

   **If UNVERIFIED:**
   - Show missing references
   - Tell user: "Warning: Some planning references could not be verified. Consider updating references in TASKS.md or planning documents."
   - Update task status from `[~]` to `[x]` in TASKS.md (warning only, not blocking)
   - Tell user: "Task [TASK-ID] complete with warnings. Moving to next task..."
   - If task-id was specified and matches: **Stop here**
   - Otherwise: Continue to Step 5

**If the task has NO References section:**
- Update task status from `[~]` to `[x]` in TASKS.md
- Tell user: "Task [TASK-ID] verified complete! Moving to next task..."
- If task-id was specified and matches: **Stop here**
- Otherwise: Continue to Step 5

## Step 5: Find Target Task

**If task-id was provided and validated in Step 3:**
Use that task as the target (already validated as ready). Skip to Step 6.

**Otherwise, find the next available task:**

Delegate to the `task-manager` agent with:
- Feature name: [feature-dir]
- Operation: `find_next`

**Based on the result:**

- **ALL_COMPLETE**: "Congratulations! All tasks for '[feature-dir]' are complete!"
- **BLOCKED**: Show the blocked tasks table from task-manager and stop.
- **FOUND**: Continue to Step 6 with the returned task.

## Step 6: Start Task

Once a target task is identified:

1. **Update TASKS.md**: Change the task's status from `[ ]` to `[~]`
   - Find `### - [ ] TASK-XXX:` -> Replace with `### - [~] TASK-XXX:`

2. **Get full task prompt** by delegating to `task-manager` with:
   - Feature name: [feature-dir]
   - Operation: `get_task`
   - Task ID: [the target task ID]

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
> /implement-task [feature-dir]
> ```
> This will verify your work and move to the next task."

## Step 7: Summary

After displaying the task, show progress:

> "**Progress for [feature-dir]:**
> - Completed: X tasks
> - In Progress: 1 task (current)
> - Remaining: Y tasks
> - Blocked: Z tasks"

## Edge Cases

**Note:** Structural validation issues (multiple in-progress tasks, circular dependencies, invalid references) are handled by `task-manager validate` in Step 2 before task operations begin.

### Missing Feature Directory
If no feature directory is provided, show the error from Step 0 and stop.

### Invalid Task ID Format
If task-id doesn't match expected formats:
> "Invalid task ID format: '[input]'
>
> Expected formats:
> - Numeric: `3` (will be converted to TASK-003)
> - Full ID: `TASK-003`"

### Empty Dependencies Field
If a task has `Depends on: None` or no dependencies section, treat it as having no dependencies (ready if status is `[ ]`).
