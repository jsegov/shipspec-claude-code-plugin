---
description: Implement all tasks for a feature end-to-end automatically
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(git:*), Bash(head:*), Bash(wc:*), Bash(npm:*), Bash(npx:*), Bash(yarn:*), Bash(pnpm:*), Bash(bun:*), Bash(cargo:*), Bash(make:*), Bash(pytest:*), Bash(go:*), Bash(mypy:*), Bash(ruff:*), Bash(flake8:*), Bash(golangci-lint:*), Task, AskUserQuestion
---

# Implement Feature: $ARGUMENTS

Automatically implement ALL tasks in a feature's TASKS.md file end-to-end. After all tasks are complete, run a comprehensive review against PRD, SDD, and all acceptance criteria.

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

**Check for required planning artifacts:**
```bash
echo "=== Checking planning artifacts ==="
ls .shipspec/planning/$ARGUMENTS/TASKS.md 2>/dev/null || echo "TASKS.md NOT FOUND"
ls .shipspec/planning/$ARGUMENTS/PRD.md 2>/dev/null || echo "PRD.md NOT FOUND"
ls .shipspec/planning/$ARGUMENTS/SDD.md 2>/dev/null || echo "SDD.md NOT FOUND"
```

**If any artifact missing:**
> "Missing required planning artifacts for '$ARGUMENTS':
> - [List missing files]
>
> Run `/feature-planning $ARGUMENTS` to generate them."

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
1. Tell user: "Found in-progress task: **[TASK-ID]: [Title]**. Resuming implementation..."

2. **Extract the full task prompt**: Get all content from the task header until the next task header

3. **IMPLEMENT THE TASK**:
   - Read the task prompt carefully
   - Identify files to create or modify
   - Write the actual code following the implementation notes
   - Run any specified build/test commands as you implement
   - Follow the acceptance criteria to guide what needs to be done

4. Mark as `[x]` when implementation is complete

5. Continue to the main loop

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
Continue to Step 5 (Final Feature Review).

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

5. **Mark task complete**: After implementation, update TASKS.md from `[~]` to `[x]`

6. **Show progress**:
> "**Progress: [X/TOTAL]**
>
> | Status | Count |
> |--------|-------|
> | Completed | X |
> | Remaining | Y |
>
> *Continuing to next task...*"

7. Return to Step 4.1 to find the next task.

---

## Step 5: Final Feature Review

After all tasks are marked complete, perform a comprehensive review of the entire feature implementation.

> "## All Tasks Implemented!
>
> Running comprehensive feature review against PRD, SDD, and all acceptance criteria..."

### 5.1: Load Planning Artifacts

Load the PRD and SDD for reference:
@.shipspec/planning/$ARGUMENTS/PRD.md
@.shipspec/planning/$ARGUMENTS/SDD.md

### 5.2: Validate All Acceptance Criteria

For each task in TASKS.md that is marked `[x]` (completed):

1. Extract the full task prompt (from task header to next task header)
2. Delegate to the `task-verifier` agent with:
   - The full task prompt including acceptance criteria
   - The feature name ($ARGUMENTS)
   - The task ID
3. Record the verification result (VERIFIED, INCOMPLETE, or BLOCKED)

**Aggregate results into a summary:**

```markdown
### 1. Acceptance Criteria Validation

| Task | Status | Details |
|------|--------|---------|
| TASK-001 | VERIFIED | All criteria passed |
| TASK-002 | INCOMPLETE | 2 criteria failed: [brief list] |
| TASK-003 | VERIFIED | All criteria passed |

**Result:** X verified, Y incomplete, Z blocked
```

If any task is INCOMPLETE, collect all failed criteria for the final report in Step 5.5.

### 5.3: Validate Design Alignment

For each task with a Design Doc reference in its `## References` section:

1. Extract the section reference (e.g., "Section 5.3" or "Section 7.1")
2. Locate that section in SDD.md
3. Verify the implementation aligns with the design

**Design Alignment Checks:**
- **API Contracts**: Do endpoints/methods match the design?
- **Data Models**: Do types/interfaces match the design?
- **Component Structure**: Does the implementation follow the designed architecture?
- **Error Handling**: Is error handling implemented as designed?
- **Security**: Are security measures from the design implemented?

**Output Format:**

```markdown
### 2. Design Alignment

| Task | SDD Section | Aspect | Status | Notes |
|------|-------------|--------|--------|-------|
| TASK-001 | 5.3 | API Contracts | PASS/FAIL | [notes] |
| TASK-002 | 7.1 | Data Models | PASS/FAIL | [notes] |
...

**Result:** X/Y design aspects verified
```

### 5.4: Validate Requirements Coverage

For each task with PRD references (e.g., `PRD: REQ-001, REQ-005`):

1. Extract all REQ-XXX references
2. Locate each requirement in PRD.md
3. Verify the implementation satisfies the requirement's "shall" statement

**Output Format:**

```markdown
### 3. Requirements Coverage

| Requirement | Description | Implementing Tasks | Status | Evidence |
|-------------|-------------|-------------------|--------|----------|
| REQ-001 | [brief description] | TASK-001, TASK-003 | PASS/FAIL | [evidence] |
| REQ-005 | [brief description] | TASK-002 | PASS/FAIL | [evidence] |
...

**Result:** X/Y requirements satisfied
```

### 5.5: Generate Final Verdict

Compile results from all three validation categories:

```markdown
## Feature Review Summary: $ARGUMENTS

### Implementation Results
- Total Tasks: X
- Tasks Completed: X

### Validation Results

| Category | Result | Details |
|----------|--------|---------|
| Acceptance Criteria | X/Y passed | [brief summary] |
| Design Alignment | X/Y verified | [brief summary] |
| Requirements Coverage | X/Y satisfied | [brief summary] |

### Overall Verdict
```

**Determine overall verdict:**

**APPROVED** (all validations pass):
- All acceptance criteria PASSED (CANNOT_VERIFY is acceptable)
- Design alignment verified or N/A for all tasks
- All requirements satisfied or N/A

**NEEDS WORK** (any validation fails):
- One or more acceptance criteria FAILED
- OR design alignment FAILED (implementation doesn't match design)
- OR requirements FAILED (implementation doesn't satisfy requirements)

**BLOCKED** (cannot verify):
- One or more tasks returned BLOCKED from task-verifier
- AND no explicit FAILED criteria exist (otherwise it's NEEDS WORK)
- Examples: missing test infrastructure, cannot run type checker, missing acceptance criteria

### 5.6: Take Action Based on Verdict

**If APPROVED:**

> "## APPROVED
>
> All validations passed! Feature **$ARGUMENTS** has been fully implemented and verified.
>
> **Summary:**
> - Tasks Completed: X/X
> - Acceptance Criteria: X passed
> - Design Alignment: Verified
> - Requirements: X/X satisfied
>
> **Next Steps:**
> - Review the changes: `git diff`
> - Commit your changes: `git add . && git commit -m "Implement $ARGUMENTS feature"`
> - Create a pull request if needed"

**If NEEDS WORK:**

> "## NEEDS WORK
>
> Feature implementation is complete, but some validations failed.
>
> ### Issues to Fix
>
> **Acceptance Criteria:**
> - [List failed criteria with specific fixes needed]
>
> **Design Alignment:**
> - [List misalignments with references to SDD sections]
>
> **Requirements:**
> - [List unsatisfied requirements with what's missing]
>
> ---
>
> After fixing these issues, run `/implement-feature $ARGUMENTS` again to re-validate."

**If BLOCKED:**

> "## BLOCKED
>
> Cannot complete feature review due to missing infrastructure or requirements.
>
> **Blocked Tasks:**
>
> | Task | Issue | Resolution |
> |------|-------|------------|
> | [TASK-ID] | [What's blocking] | [How to fix] |
>
> **Common Resolutions:**
> - **Missing test infrastructure**: Set up testing framework (e.g., `npm init jest`, `pytest`)
> - **Missing acceptance criteria**: Add acceptance criteria to tasks in TASKS.md
> - **Missing type checker**: Install and configure type checking (e.g., TypeScript, mypy)
>
> After resolving the blocking issues, run `/implement-feature $ARGUMENTS` again."

---

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

**Stop the loop** - wait for user to resolve.

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
If running build or tests fails during implementation:
> "Build/test failed while implementing [TASK-ID]:
> [error output]
>
> Attempting to fix..."

Try to fix the issue. If unable to fix after reasonable attempts, ask user how to proceed.

### Tests Not Configured
If the project's test command fails because tests aren't set up:
- Note as CANNOT_VERIFY for test-related criteria
- Add suggestion: "Test infrastructure not found. Consider setting up tests."
- Do not fail the entire review for this

### Type Checker / Linter Not Available
If the project doesn't have a type checker or linter configured:
- Note as CANNOT_VERIFY for type/lint criteria
- Continue with other validations

---

## Important Notes

1. **Save progress frequently**: Update TASKS.md after each task completion so progress survives interruptions
2. **Be thorough**: Implement each task fully before marking complete
3. **Read context**: Use PRD.md and SDD.md in the feature directory for additional context
4. **Follow patterns**: Look at existing code in the codebase for consistent patterns
5. **Run tests**: If the project has tests, run them as part of implementation
6. **Final review matters**: The comprehensive review at the end validates the entire feature against the spec
