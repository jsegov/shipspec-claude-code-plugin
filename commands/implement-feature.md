---
description: Implement all tasks for a feature end-to-end automatically
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(npm:*), Bash(git:*), Bash(head:*), Bash(wc:*), Bash(npx:*), Task, AskUserQuestion
---

# Implement Feature: $ARGUMENTS

Automatically implement ALL tasks in a feature's TASKS.md file end-to-end. For each task: implement the code, verify completion, and continue to the next task.

## Step 0: Validate Argument

**If $ARGUMENTS is empty or missing:**
> "Error: Feature name is required.
>
> **Usage:** `/implement-feature <feature-name>`
>
> The feature name should match the name used with `/feature-planning`.
>
> **To see available features:**
> ```bash
> ls .shipspec/planning/
> ```"

**Stop here** - do not proceed without an argument.

## Step 1: Locate Feature Directory

Check that the feature directory exists:

```bash
ls -d .shipspec/planning/$ARGUMENTS 2>/dev/null || echo "NOT_FOUND"
```

**If NOT_FOUND:**
> "No directory found for '$ARGUMENTS' at `.shipspec/planning/$ARGUMENTS`.
>
> Please run `/feature-planning $ARGUMENTS` first to create the planning artifacts."

**Check for TASKS.md:**
```bash
ls -la .shipspec/planning/$ARGUMENTS/TASKS.md 2>/dev/null || echo "TASKS.md NOT FOUND"
```

**If TASKS.md not found:**
> "No TASKS.md found in `.shipspec/planning/$ARGUMENTS/`.
>
> Run `/feature-planning $ARGUMENTS` to complete the planning workflow and generate tasks."

## Step 2: Load and Parse Tasks

Load the tasks document:
@.shipspec/planning/$ARGUMENTS/TASKS.md

Parse the document to extract:
1. **All tasks** with their IDs (TASK-XXX or T01, T02, etc.), titles, and statuses
2. **Status indicators**:
   - `- [ ]` = Not started
   - `- [~]` = In progress
   - `- [x]` = Completed
3. **Dependencies** from each task's `Depends on:` or `Dependencies:` line
4. **Total task count** for progress tracking

Build a task map:
```
TASK-001: status=[ ], depends_on=[], title="..."
TASK-002: status=[ ], depends_on=[TASK-001], title="..."
TASK-003: status=[x], depends_on=[], title="..."
```

Calculate:
- Total tasks
- Completed tasks (status `[x]`)
- Remaining tasks (status `[ ]` or `[~]`)

Tell the user:
> "## Feature: $ARGUMENTS
>
> Found **X tasks** total. **Y completed**, **Z remaining**.
>
> Starting automatic implementation..."

## Step 3: Check for In-Progress Task

Before starting the loop, check if there's already a task marked `[~]`:

**If an in-progress task is found:**
1. Tell user: "Found in-progress task: **[TASK-ID]: [Title]**. Verifying completion..."
2. Delegate to `task-verifier` subagent with the full task prompt
3. Handle verification result (see Step 6 below)
4. If VERIFIED, mark as `[x]` and continue to the main loop
5. If INCOMPLETE, attempt to fix (retry once) before asking user

## Step 4: Main Implementation Loop

**LOOP** until all tasks are complete or user aborts:

### 4.1: Find Next Ready Task

Find the first task that meets ALL criteria:
1. Status is `[ ]` (not started)
2. All dependencies are `[x]` (completed)

**Dependency resolution:**
- Parse the `Depends on:` line from each task
- A task is "ready" if it has no dependencies OR all listed dependencies are marked `[x]`
- Skip tasks whose dependencies aren't satisfied

### 4.2: Check Completion Status

**If no task is ready AND tasks remain:**

Check what's blocking:
> "**Implementation Paused**
>
> No tasks are currently ready. Blocked tasks:
>
> | Task | Blocked By |
> |------|------------|
> | TASK-003 | TASK-001, TASK-002 |
>
> This may indicate a circular dependency or missing task. Please review TASKS.md."

**Stop the loop** - ask user how to proceed.

**If all tasks are complete:**

> "## All Tasks Complete!
>
> **Feature:** $ARGUMENTS
> **Tasks Completed:** X/X
>
> All tasks have been implemented and verified. Run `/review-diff $ARGUMENTS` to review the changes against the design documents."

**End the loop successfully.**

### 4.3: Start Task Implementation

Once a ready task is found:

1. **Update TASKS.md**: Change status from `[ ]` to `[~]`
   - Find `### - [ ] TASK-XXX:` -> Replace with `### - [~] TASK-XXX:`

2. **Display task header**:
> "---
>
> ## [X/TOTAL] Implementing: [TASK-ID] - [Title]
>
> *Dependencies satisfied. Starting implementation...*
>
> ---"

3. **Extract the full task prompt**: Get all content from the task header until the next task header

4. **IMPLEMENT THE TASK**:
   - Read the task prompt carefully
   - Identify files to create or modify
   - Write the actual code following the implementation notes
   - Run any specified build/test commands as you implement
   - Follow the acceptance criteria to guide what needs to be done

## Step 5: Verify Task Completion

After implementing, delegate to the `task-verifier` subagent:
- Pass the full task prompt with acceptance criteria
- Pass the feature name: `$ARGUMENTS`
- Pass the task ID being verified

## Step 6: Handle Verification Result

**IF VERIFIED:**
1. Update TASKS.md: Change status from `[~]` to `[x]`
2. Tell user:
> "**[TASK-ID]: VERIFIED**
>
> Task complete. Moving to next task..."
3. **Continue to next iteration of the loop**

**IF INCOMPLETE (First attempt):**
1. Review what's missing from the verification report
2. Attempt to fix the issues
3. Re-run verification (delegate to task-verifier again)
4. If now VERIFIED -> proceed as above
5. If still INCOMPLETE -> proceed to "Second attempt" below

**IF INCOMPLETE (Second attempt / retry failed):**
1. Keep task as `[~]`
2. Show the user what failed:
> "**[TASK-ID]: Verification Failed**
>
> After retry, the following issues remain:
> - [Issue 1]
> - [Issue 2]
>
> **Options:**
> 1. I can try a different approach to fix these issues
> 2. You can fix manually, then run `/implement-feature $ARGUMENTS` to continue
> 3. Skip this task and continue with others
> 4. Abort the implementation loop"

**Wait for user response**, then:
- Option 1: Attempt another fix approach
- Option 2: Stop the loop (user will fix and re-run)
- Option 3: Mark task with a note and continue to next ready task
- Option 4: Stop the loop entirely

**IF BLOCKED:**
1. Show the blocking reason
2. Ask user how to proceed:
> "**[TASK-ID]: Blocked**
>
> Cannot verify due to: [blocking reason]
>
> **Options:**
> 1. Skip this task and continue
> 2. Abort the implementation loop
> 3. I'll try to resolve the blocking issue first"

## Step 7: Progress Summary (After Each Task)

After successfully completing each task, show cumulative progress:

> "**Progress: [X/TOTAL]**
>
> | Status | Count |
> |--------|-------|
> | Completed | X |
> | In Progress | 0-1 |
> | Remaining | Y |
>
> *Continuing to next task...*"

Then return to Step 4.1 to find the next task.

## Step 8: Final Summary

When the loop ends (either all complete or aborted):

> "## Implementation Summary: $ARGUMENTS
>
> | Status | Tasks |
> |--------|-------|
> | Completed | X tasks |
> | Skipped | Y tasks |
> | Failed | Z tasks |
> | Remaining | W tasks |
>
> **Completed Tasks:**
> - [x] TASK-001: [Title]
> - [x] TASK-002: [Title]
>
> **Next Steps:**
> - Run `/review-diff $ARGUMENTS` to review changes against design
> - Commit your changes when ready"

## Edge Cases

### Multiple In-Progress Tasks
If more than one task is marked `[~]`:
> "Warning: Multiple tasks are marked as in-progress. Resolving...
>
> Verifying each in-progress task before continuing."

Verify each one with task-verifier. Mark verified ones as `[x]`, keep first incomplete one as `[~]`.

### Circular Dependencies
If dependency resolution detects a cycle:
> "Error: Circular dependency detected:
> TASK-001 -> TASK-002 -> TASK-003 -> TASK-001
>
> Fix the dependencies in TASKS.md before continuing."

**Stop the loop.**

### Task Without Clear Implementation
If a task prompt is too vague to implement:
> "Task [TASK-ID] lacks clear implementation guidance. The prompt says:
> [quoted prompt]
>
> **Options:**
> 1. I'll make reasonable assumptions and implement
> 2. Skip this task
> 3. Stop so you can clarify the task in TASKS.md"

### Build/Test Failures During Implementation
If running build or tests fails during implementation (not verification):
> "Build/test failed while implementing [TASK-ID]:
> [error output]
>
> Attempting to fix..."

Try to fix the issue. If unable to fix after reasonable attempts, proceed to verification (which will likely fail and trigger the retry logic).

## Important Notes

1. **Save progress frequently**: Update TASKS.md after each task completion so progress survives interruptions
2. **Be thorough**: Implement each task fully before moving to verification
3. **Read context**: Use PRD.md and SDD.md in the feature directory for additional context
4. **Follow patterns**: Look at existing code in the codebase for consistent patterns
5. **Run tests**: If the project has tests, run them as part of implementation
