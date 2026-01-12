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

## Step 2: Load and Parse Tasks

Load the tasks document:
@.shipspec/planning/[feature-dir]/TASKS.md

Parse the document to extract:
1. **All tasks** with their IDs (TASK-XXX), titles, and statuses
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

## Step 3: Determine Target Task

**If task-id was provided in arguments:**

1. Validate the task exists in TASKS.md
   - If not found: "Error: Task '[task-id]' not found in TASKS.md. Available tasks: [list task IDs]"

2. Check task status:
   - If `[x]` (completed): "Task [task-id] is already completed. Choose a different task or omit the task-id to get the next available."
   - If `[~]` (in-progress): Proceed to Step 4 (verify completion)
   - If `[ ]` (not started): Check dependencies are satisfied

3. Validate dependencies (for not-started tasks):
   - If any dependency is not `[x]`:
     > "Cannot start [task-id] - dependencies not satisfied:
     > - [DEP-ID]: [status]
     >
     > Complete the dependencies first, or choose a different task."

**If no task-id was provided:**
Continue to Step 4 to check for in-progress tasks, then Step 5 to find the next available.

## Step 4: Check for In-Progress Task

Search for any task marked with `[~]` (in progress).

**If an in-progress task is found:**

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

**If no in-progress task found:**
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
Use that task as the target.

**Otherwise, find the next available task:**
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
All [x]? → "Congratulations! All tasks for '[feature-dir]' are complete!"
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

## Step 6: Start Task

Once a target task is identified:

1. **Update TASKS.md**: Change the task's status from `[ ]` to `[~]`
   - Find `### - [ ] TASK-XXX:` -> Replace with `### - [~] TASK-XXX:`

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

### Missing Feature Directory
If no feature directory is provided, show the error from Step 0 and stop.

### Invalid Task ID Format
If task-id doesn't match expected formats:
> "Invalid task ID format: '[input]'
>
> Expected formats:
> - Numeric: `3` (will be converted to TASK-003)
> - Full ID: `TASK-003`"

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
> TASK-001 -> TASK-002 -> TASK-003 -> TASK-001
>
> Fix the dependencies in TASKS.md and try again."

### Empty Dependencies Field
If a task has `Depends on: None` or no dependencies section, treat it as having no dependencies (ready if status is `[ ]`).
