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

## Step 2: Load, Parse, and Validate Tasks

Delegate to the `task-manager` agent with:
- Feature name: $ARGUMENTS
- Operation: `parse`

**If error (TASKS.md not found or empty):**
Show the error message from task-manager and stop.

**If successful:**
Use the task map and statistics from the response.

Next, validate the task structure by delegating to `task-manager` with:
- Feature name: $ARGUMENTS
- Operation: `validate`

**If INVALID:**
Show all issues from the validation result (circular dependencies, multiple in-progress, invalid references) and stop.

**If VALID:**
Tell the user:
> "## Feature: $ARGUMENTS
>
> Found **X tasks** total. **Y completed**, **Z remaining**.
>
> Starting automatic implementation..."

## Step 3: Check for In-Progress Task

Delegate to the `task-manager` agent with:
- Feature name: $ARGUMENTS
- Operation: `find_in_progress`

**If MULTIPLE:**
The validation in Step 2 should have caught this, but if it occurs:
Show the warning message from task-manager and **stop** - wait for user to resolve.

**If SINGLE:**
1. Tell user: "Found in-progress task: **[TASK-ID]: [Title]**. Verifying if already complete..."

2. **Get full task prompt** by delegating to `task-manager` with:
   - Feature name: $ARGUMENTS
   - Operation: `get_task`
   - Task ID: [the in-progress task ID]

3. **Delegate to task-verifier agent** with:
   - The full task prompt including acceptance criteria
   - The feature name ($ARGUMENTS)
   - The task ID

4. **Based on verification result:**

   **Log verification** to `.claude/shipspec-debug.log`:
   ```
   $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task-id] | VERIFY | [result] | [details]
   ```

   **If VERIFIED:**
   - Update task status from `[~]` to `[x]` in TASKS.md
   - **Log task completion** to `.claude/shipspec-debug.log`:
     ```
     $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task-id] | COMPLETE | Status updated to [x]
     ```
   - **Clean up any existing feature retry state:**
     ```bash
     rm -f .claude/shipspec-feature-retry.local.md
     ```
   - **Output completion marker:**
     `<feature-task-complete>VERIFIED</feature-task-complete>`
   - Tell user: "Task [TASK-ID] verified complete! Marking as done and continuing..."
   - Continue to Step 4 (main loop)

   **If INCOMPLETE:**
   - Tell user: "Task [TASK-ID] not yet complete. Continuing implementation..."
   - **Create feature retry state file** for auto-retry:
     ```bash
     mkdir -p .claude
     cat > .claude/shipspec-feature-retry.local.md << 'EOF'
     ---
     active: true
     feature: $ARGUMENTS
     current_task_id: [task-id]
     task_attempt: 1
     max_task_attempts: 5
     total_tasks: [total count]
     tasks_completed: [completed count]
     started_at: "[ISO timestamp]"
     ---

     [Full task prompt from task-manager]
     EOF
     ```
   - **IMPLEMENT THE TASK**:
     - Read the task prompt carefully
     - Identify files to create or modify
     - Write the actual code following the implementation notes
     - Run any specified build/test commands as you implement
     - Follow the acceptance criteria to guide what needs to be done
   - After implementation, delegate to `task-verifier` to verify the task
   - **If VERIFIED after implementation:**
     - Mark as `[x]` in TASKS.md
     - Log task completion
     - Clean up state file: `rm -f .claude/shipspec-feature-retry.local.md`
     - Output: `<feature-task-complete>VERIFIED</feature-task-complete>`
     - Continue to Step 4 (main loop)
   - **If still INCOMPLETE:**
     - DO NOT output completion marker (stop hook will trigger retry)
     - Show what failed to user

   **If BLOCKED:**
   - **Clean up any existing feature retry state:**
     ```bash
     rm -f .claude/shipspec-feature-retry.local.md
     ```
   - **Output blocked marker:**
     `<feature-task-complete>BLOCKED</feature-task-complete>`
   - Tell user: "Task [TASK-ID] is blocked: [reason]. Manual intervention required."
   - Ask user how to proceed (skip task, abort feature, or manual fix)

**If NONE:**
Continue to Step 4 (main loop).

## Step 4: Main Implementation Loop

**LOOP** until all tasks are complete or user aborts:

### 4.1: Find Next Ready Task

Delegate to the `task-manager` agent with:
- Feature name: $ARGUMENTS
- Operation: `find_next`

### 4.2: Check Result and Completion Status

**If BLOCKED:**
Show the blocked tasks table from task-manager:
> "**Implementation Paused**
>
> No tasks are currently ready. [Show blocked tasks from task-manager response]
>
> This may indicate a circular dependency or missing task. Please review TASKS.md."

**Stop the loop** - ask user how to proceed.

**If ALL_COMPLETE:**
Continue to Step 5 (Final Feature Review).

**If FOUND:**
Continue to Step 4.3 with the returned task.

### 4.3: Start Task Implementation

Once a ready task is found:

1. **Update TASKS.md**: Change status from `[ ]` to `[~]`
   - Find `### - [ ] TASK-XXX:` -> Replace with `### - [~] TASK-XXX:`

2. **Log task start** to `.claude/shipspec-debug.log`:
   ```
   $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task-id] | START | [X/TOTAL] [title]
   ```

3. **Display task header**:
> "---
>
> ## [X/TOTAL] Implementing: [TASK-ID] - [Title]
>
> *Dependencies satisfied. Starting implementation...*
>
> ---"

4. **Get full task prompt** by delegating to `task-manager` with:
   - Feature name: $ARGUMENTS
   - Operation: `get_task`
   - Task ID: [the ready task ID from step 4.1]

5. **Create feature retry state file** for auto-retry on failure:
   ```bash
   mkdir -p .claude
   cat > .claude/shipspec-feature-retry.local.md << 'EOF'
   ---
   active: true
   feature: $ARGUMENTS
   current_task_id: [task-id]
   task_attempt: 1
   max_task_attempts: 5
   total_tasks: [total count]
   tasks_completed: [completed count]
   started_at: "[ISO timestamp]"
   ---

   [Full task prompt from task-manager]
   EOF
   ```

6. **IMPLEMENT THE TASK**:
   - Read the task prompt carefully
   - Identify files to create or modify
   - Write the actual code following the implementation notes
   - Run any specified build/test commands as you implement
   - Follow the acceptance criteria to guide what needs to be done

### 4.4: Verify and Handle Result

After implementation, verify the task:

1. **Delegate to task-verifier** agent with:
   - The full task prompt including acceptance criteria
   - The feature name ($ARGUMENTS)
   - The task ID

2. **Log verification** to `.claude/shipspec-debug.log`:
   ```
   $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task-id] | VERIFY | [result] | [details]
   ```

3. **Handle verification result:**

**If VERIFIED:**
- Update TASKS.md from `[~]` to `[x]`
- **Log task completion** to `.claude/shipspec-debug.log`:
  ```
  $(date -u +%Y-%m-%dT%H:%M:%SZ) | [task-id] | COMPLETE | Status updated to [x]
  ```
- **Clean up state file:**
  ```bash
  rm -f .claude/shipspec-feature-retry.local.md
  ```
- **Output completion marker:**
  `<feature-task-complete>VERIFIED</feature-task-complete>`
- **Show progress**:
> "**Progress: [X/TOTAL]**
>
> | Status | Count |
> |--------|-------|
> | Completed | X |
> | Remaining | Y |
>
> *Task verified! Continuing to next task...*"
- Return to Step 4.1 to find the next task.

**If INCOMPLETE:**
- DO NOT output completion marker (stop hook will trigger retry)
- Keep task as `[~]` in TASKS.md
- Show what failed to user:
> "**Verification Failed**
>
> The following criteria are not met:
> - [List failed criteria]
>
> The loop will retry automatically."

**If BLOCKED:**
- **Clean up state file:**
  ```bash
  rm -f .claude/shipspec-feature-retry.local.md
  ```
- **Output blocked marker:**
  `<feature-task-complete>BLOCKED</feature-task-complete>`
- Tell user: "Task [TASK-ID] is blocked: [reason]. Manual intervention required."
- Ask user how to proceed (skip task, abort feature, or manual fix)

---

## Step 5: Final Feature Review

After all tasks are marked complete, perform a comprehensive review of the entire feature implementation.

**Clean up any remaining state file:**
```bash
rm -f .claude/shipspec-feature-retry.local.md
```

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

### 5.3: Validate Planning Alignment (Design & Requirements)

For each task in TASKS.md that is marked `[x]` (completed) AND has a `## References` section:

1. Delegate to the `planning-validator` agent with:
   - The task ID
   - The feature name ($ARGUMENTS)
   - The task's References section (containing SDD sections and PRD requirements)

2. Record the validation result:
   - **ALIGNED**: Implementation matches design and requirements
   - **MISALIGNED**: Implementation doesn't match (collect specific issues)
   - **UNVERIFIED**: References not found (track in `missing_references` list)

3. Aggregate results from all tasks

**Output Format:**

```markdown
### 2. Design Alignment

| Task | SDD Section | Status | Notes |
|------|-------------|--------|-------|
| TASK-001 | 5.3 | PASS/FAIL/UNVERIFIED | [notes from planning-validator] |
| TASK-002 | 7.1 | PASS/FAIL/UNVERIFIED | [notes from planning-validator] |
...

**Result:** X/Y design aspects verified
```

```markdown
### 3. Requirements Coverage

| Requirement | Implementing Tasks | Status | Evidence |
|-------------|-------------------|--------|----------|
| REQ-001 | TASK-001, TASK-003 | PASS/FAIL/UNVERIFIED | [evidence from planning-validator] |
| REQ-005 | TASK-002 | PASS/FAIL/UNVERIFIED | [evidence from planning-validator] |
...

**Result:** X/Y requirements satisfied
```

**Note:** Tasks without a References section are skipped for planning validation (they still go through acceptance criteria validation in 5.2).

### 5.4: Generate Final Verdict

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

**APPROVED** (all validations pass, no warnings):
- All acceptance criteria PASSED (CANNOT_VERIFY is acceptable)
- Design alignment verified for all tasks (no UNVERIFIED)
- All requirements satisfied (no UNVERIFIED)

**APPROVED WITH WARNINGS** (passes but has unverified references):
- All acceptance criteria PASSED (CANNOT_VERIFY is acceptable)
- Some design alignment or requirements are UNVERIFIED due to missing references
- No explicit FAILs

**NEEDS WORK** (any validation fails):
- One or more acceptance criteria FAILED
- OR design alignment FAILED (implementation doesn't match design)
- OR requirements FAILED (implementation doesn't satisfy requirements)

**BLOCKED** (cannot verify):
- One or more tasks returned BLOCKED from task-verifier
- AND no explicit FAILED criteria exist (otherwise it's NEEDS WORK)
- Examples: missing test infrastructure, cannot run type checker, missing acceptance criteria

**Log final review result** to `.claude/shipspec-debug.log`:
```
$(date -u +%Y-%m-%dT%H:%M:%SZ) | FEATURE | REVIEW | [verdict] | [summary e.g., "5/5 tasks verified" or "2 criteria failed"]
```

### 5.5: Take Action Based on Verdict

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

**Output feature complete marker:**
`<feature-complete>APPROVED</feature-complete>`

**If APPROVED WITH WARNINGS:**

> "## APPROVED WITH WARNINGS
>
> Feature **$ARGUMENTS** has been implemented and core validations passed, but some references could not be verified.
>
> **Summary:**
> - Tasks Completed: X/X
> - Acceptance Criteria: X passed
> - Design Alignment: X verified, Y unverified
> - Requirements: X/X satisfied, Y unverified
>
> **Unverified References:**
>
> | Source | Reference | Task | Issue |
> |--------|-----------|------|-------|
> | SDD | Section X.Y | TASK-XXX | Section not found in SDD.md |
> | PRD | REQ-XXX | TASK-YYY | Requirement not found in PRD.md |
>
> **Action Required:**
> Please manually verify these references are either:
> 1. No longer relevant (safe to ignore)
> 2. Need to be updated in TASKS.md, PRD.md, or SDD.md
>
> **Next Steps:**
> - Review the unverified references above
> - If satisfied, proceed with: `git add . && git commit -m "Implement $ARGUMENTS feature"`
> - If references need fixing, update the planning artifacts and re-run `/implement-feature $ARGUMENTS`"

**Output feature complete marker:**
`<feature-complete>APPROVED_WITH_WARNINGS</feature-complete>`

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

**Note:** Structural validation issues (multiple in-progress tasks, circular dependencies, invalid references) are handled by `task-manager validate` in Step 2 before implementation begins.

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
