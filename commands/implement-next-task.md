---
description: Start implementing the next available task from TASKS.md
argument-hint: <directory-name>
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(npm:*), Bash(git:*), Bash(head:*), Bash(wc:*)
---

# Implement Next Task: $ARGUMENTS

Find and display the next task ready for implementation, verifying any in-progress work first. Supports both feature-planning (TASK-XXX) and production-readiness-review (FINDING-XXX) workflows.

## Step 0: Validate Argument

**If $ARGUMENTS is empty or missing:**
> "Error: Directory name is required.
>
> **Usage:** `/implement-next-task <directory-name>`
>
> The directory name should match your planning context:
> - For features: the feature name used with `/feature-planning`
> - For production readiness: the context name used with `/production-readiness-review`
>
> **To see available directories:**
> ```bash
> ls .shipspec/planning/           # Feature planning
> ls .shipspec/production-readiness/  # Production readiness
> ```"

**Stop here** - do not proceed without an argument.

## Step 1: Auto-Detect Workflow Directory

Check which directory the argument exists in:

```bash
echo "=== Auto-detecting workflow directory ==="
ls -d .shipspec/planning/$ARGUMENTS 2>/dev/null && echo "FOUND_PLANNING"
ls -d .shipspec/production-readiness/$ARGUMENTS 2>/dev/null && echo "FOUND_PRODUCTION"
```

**Directory resolution:**
- If found in `.shipspec/planning/` only → **Feature Planning** workflow (uses TASK-XXX IDs)
  - Set `WORKFLOW_DIR=.shipspec/planning/$ARGUMENTS`
- If found in `.shipspec/production-readiness/` only → **Production Readiness** workflow (uses FINDING-XXX IDs)
  - Set `WORKFLOW_DIR=.shipspec/production-readiness/$ARGUMENTS`
- If found in BOTH → Error: "Ambiguous: '$ARGUMENTS' exists in both `.shipspec/planning/` and `.shipspec/production-readiness/`. Please use a unique name or specify the full path."
- If found in NEITHER → Error: "No directory found for '$ARGUMENTS'. Please run either:
  - `/feature-planning $ARGUMENTS` - for new feature development
  - `/production-readiness-review $ARGUMENTS` - for production readiness analysis"

**Check for TASKS.md:**
```bash
ls -la $WORKFLOW_DIR/TASKS.md 2>/dev/null || echo "TASKS.md NOT FOUND"
```

**If TASKS.md not found:**
> "No TASKS.md found in '$WORKFLOW_DIR/'.
>
> - For feature planning: Run `/feature-planning $ARGUMENTS` to complete the planning workflow.
> - For production readiness: Run `/production-readiness-review $ARGUMENTS` to generate remediation tasks."

## Step 2: Load and Parse Tasks

Load the tasks document:
@$WORKFLOW_DIR/TASKS.md

Parse the document to extract:
1. **Workflow type** (determined by directory location in Step 1)
2. **Task ID pattern**:
   - Feature Planning: `TASK-XXX`
   - Production Readiness: `FINDING-XXX`
3. **All tasks** with their IDs, titles, and statuses
4. **Status indicators**:
   - `- [ ]` = Not started
   - `- [~]` = In progress
   - `- [x]` = Completed
5. **Dependencies** from each task's `Depends on:` line

Build a task map (example for each workflow type):

**Feature Planning:**
```
TASK-001: status=[ ], depends_on=[], title="..."
TASK-002: status=[ ], depends_on=[TASK-001], title="..."
TASK-003: status=[x], depends_on=[], title="..."
```

**Production Readiness:**
```
FINDING-001: status=[ ], depends_on=[], title="..."
FINDING-002: status=[ ], depends_on=[FINDING-001], title="..."
FINDING-003: status=[x], depends_on=[], title="..."
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
   - For Feature Planning: Find `### - [ ] TASK-XXX:` → Replace with `### - [~] TASK-XXX:`
   - For Production Readiness: Find `### - [ ] FINDING-XXX:` → Replace with `### - [~] FINDING-XXX:`

2. **Extract the full task prompt**: Get all content from the task header until the next task header (or end of phase/document)

3. **Display to user** (workflow-aware):

> "## Starting Task: [TASK-ID or FINDING-ID]
>
> **[Task Title]**
>
> **Workflow:** [Feature Development | Production Remediation]
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

### Missing Argument
If no directory name is provided, show the error from Step 0 and stop.

### Multiple In-Progress Tasks
If more than one task is marked `[~]`:
> "Warning: Multiple tasks are marked as in-progress. This shouldn't happen.
>
> In-progress tasks:
> - [TASK-XXX or FINDING-XXX]: [Title]
> - [TASK-YYY or FINDING-YYY]: [Title]
>
> Please resolve this by marking all but one as either `[ ]` (not started) or `[x]` (completed), then run this command again."

### Circular Dependencies
If dependency resolution detects a cycle:
> "Error: Circular dependency detected in tasks. Please review the dependency chain:
> [ID-001] → [ID-002] → [ID-003] → [ID-001]
>
> Fix the dependencies in TASKS.md and try again."

(Use TASK-XXX for feature planning or FINDING-XXX for production readiness based on detected workflow)

### Empty Dependencies Field
If a task has `Depends on: None` or no dependencies section, treat it as having no dependencies (ready if status is `[ ]`).
