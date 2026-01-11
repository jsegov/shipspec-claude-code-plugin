---
description: Review implementation changes against planning artifacts (TASKS.md, SDD.md, PRD.md)
argument-hint: <directory-name>
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(git:*), Bash(npm:*), Bash(npx:*), Bash(ls:*), Bash(cat:*), Bash(find:*), Bash(head:*), Bash(wc:*)
---

# Review Diff: $ARGUMENTS

Validate implementation work against planning artifacts by checking acceptance criteria, design alignment, and requirements coverage. Auto-completes the task if all validations pass.

## Step 0: Validate Argument

**If $ARGUMENTS is empty or missing:**
> "Error: Directory name is required.
>
> **Usage:** `/review-diff <directory-name>`
>
> The directory name should match your planning context used with `/feature-planning` or `/implement-next-task`.
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

**Check for TASKS.md (required for both workflows):**
```bash
ls $WORKFLOW_DIR/TASKS.md 2>/dev/null || echo "TASKS.md NOT FOUND"
```

**If TASKS.md not found:**
> "No TASKS.md found in '$WORKFLOW_DIR/'.
>
> - For feature planning: Run `/feature-planning $ARGUMENTS` to complete the planning workflow.
> - For production readiness: Run `/production-readiness-review $ARGUMENTS` to generate remediation tasks."

**For Feature Planning workflow only**, also verify PRD.md and SDD.md exist:
```bash
echo "=== Checking feature planning artifacts ==="
ls $WORKFLOW_DIR/PRD.md 2>/dev/null || echo "PRD.md NOT FOUND"
ls $WORKFLOW_DIR/SDD.md 2>/dev/null || echo "SDD.md NOT FOUND"
```

**If Feature Planning and any artifact missing:**
> "Missing required planning artifacts for '$ARGUMENTS':
> - [List missing files]
>
> Run `/feature-planning $ARGUMENTS` to generate them."

## Step 2: Find In-Progress Task

Load TASKS.md and find the in-progress task:
@$WORKFLOW_DIR/TASKS.md

Search for a task marked with `[~]` (in progress).

**If no in-progress task found:**
> "No in-progress task found in TASKS.md.
>
> **Expected workflow:**
> 1. Run `/implement-next-task $ARGUMENTS` to start a task
> 2. Implement the task
> 3. Run `/review-diff $ARGUMENTS` to validate your work
>
> There's nothing to review right now. Run `/implement-next-task $ARGUMENTS` first."

**If multiple in-progress tasks found:**
> "Warning: Multiple tasks are marked as in-progress. This shouldn't happen.
>
> In-progress tasks:
> - [List tasks]
>
> Please resolve this by marking all but one as either `[ ]` or `[x]`, then run this command again."

**Once in-progress task is identified, extract:**
- Task ID (TASK-XXX or FINDING-XXX)
- Task title
- Full task content (from header until next task header or end of section)

Display:
> "Found in-progress task: **[TASK-ID]: [Title]**
>
> Analyzing implementation changes..."

## Step 3: Gather Git Diff

Get the list of changed files:
```bash
echo "=== Files changed (uncommitted) ==="
git status --short
echo ""
echo "=== Detailed diff ==="
git diff --stat
```

Store the list of changed files for reference in validation steps.

**If no changes detected:**
> "No uncommitted changes detected.
>
> Before running `/review-diff`, make sure you have:
> 1. Implemented the task
> 2. NOT committed your changes yet
>
> If you've already committed, you can still verify manually or use `/implement-next-task $ARGUMENTS` to check acceptance criteria."

**Stop here** - cannot review without uncommitted changes to analyze.

## Step 4: Load Planning Artifacts (Feature Planning Only)

**For Feature Planning workflow**, load the PRD and SDD for reference:
@$WORKFLOW_DIR/PRD.md
@$WORKFLOW_DIR/SDD.md

**For Production Readiness workflow**, skip this step - proceed directly to Step 5.

## Step 5: Validate Acceptance Criteria

From the in-progress task, locate the `## Acceptance Criteria` section.

**If no Acceptance Criteria section found OR section is empty:**
> "Warning: No acceptance criteria found in task. Cannot validate implementation without criteria.
>
> The task must have an `## Acceptance Criteria` section with at least one verifiable criterion.
> Please add acceptance criteria to the task in TASKS.md and run this command again."

**Mark validation as BLOCKED and stop** - do not proceed to verdict. A task without acceptance criteria cannot be auto-approved.

**If Acceptance Criteria found**, for each criterion listed:

### Criterion Categories and Verification Methods

| Criterion Pattern | Verification Method |
|-------------------|---------------------|
| "File X exists" or "Create file X" | Use `ls -la path/to/file` or Glob |
| "Tests pass" | Run `npm test` or project's test command |
| "No TypeScript errors" | Run `npx tsc --noEmit` |
| "Linting passes" | Run `npm run lint` |
| "Function X implemented" | Grep for function definition, Read the file |
| "API endpoint works" | Check route file exists, handler implemented |
| "Component renders" | Check component file exists with proper exports |
| "Database migration" | Check migration file in migrations folder |
| "Documentation updated" | Check relevant docs for content |

For each criterion:
1. Determine the appropriate verification method
2. Execute the verification
3. Record: PASS, FAIL, or CANNOT_VERIFY

### Output Format for Acceptance Criteria

```markdown
### 1. Acceptance Criteria Validation

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | [criterion text] | PASS/FAIL | [brief evidence] |
| 2 | [criterion text] | PASS/FAIL | [brief evidence] |
...

**Result:** X passed, Y failed, Z could not verify
```

## Step 6: Validate Design Alignment (Feature Planning Only)

**For Production Readiness workflow**, skip this step entirely - mark as N/A and proceed to Step 7.

**For Feature Planning workflow**, from the in-progress task, locate the `## References` section and find the `Design Doc: Section X.Y` reference.

**If no design reference found:**
> "Note: No Design Doc reference found in task. Skipping design alignment check."
> Mark design validation as N/A.

**If design reference found:**

1. Extract the section reference (e.g., "Section 5.3" or "Section 7.1")
2. Locate that section in SDD.md
3. Verify the implementation aligns with the design:

**Design Alignment Checks:**
- **API Contracts**: Do endpoints/methods match the design?
- **Data Models**: Do types/interfaces match the design?
- **Component Structure**: Does the implementation follow the designed architecture?
- **Error Handling**: Is error handling implemented as designed?
- **Security**: Are security measures from the design implemented?

For each relevant aspect, compare the git diff changes against the SDD section.

### Output Format for Design Alignment

```markdown
### 2. Design Alignment (SDD Section X.Y)

| Aspect | Status | Notes |
|--------|--------|-------|
| API Contracts | PASS/FAIL/N/A | [specific notes] |
| Data Models | PASS/FAIL/N/A | [specific notes] |
| Component Structure | PASS/FAIL/N/A | [specific notes] |
| Error Handling | PASS/FAIL/N/A | [specific notes] |

**Result:** X/Y aspects verified
```

## Step 7: Validate Requirements Coverage (Feature Planning Only)

**For Production Readiness workflow**, skip this step entirely - mark as N/A and proceed to Step 8.

**For Feature Planning workflow**, from the in-progress task, locate the `## References` section and find PRD references (e.g., `PRD: REQ-001, REQ-005`).

**If no PRD references found:**
> "Note: No PRD requirement references found in task. Skipping requirements coverage check."
> Mark requirements validation as N/A.

**If PRD references found:**

1. Extract all REQ-XXX references from the task
2. For each requirement, locate it in PRD.md
3. Verify the implementation satisfies the requirement's "shall" statement:
   - Check if the functionality described is implemented
   - Look for evidence in the changed files
   - Verify testable aspects are covered

### Output Format for Requirements Coverage

```markdown
### 3. Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| REQ-001 | [brief description] | PASS/FAIL | [evidence in code] |
| REQ-005 | [brief description] | PASS/FAIL | [evidence in code] |

**Result:** X/Y requirements satisfied
```

## Step 8: Generate Summary and Verdict

Compile results from all three validation categories:

```markdown
## Review Summary for [TASK-ID]: [Title]

### Changes Detected
- Files modified: X
- Files created: Y
- [Brief list of key changed files]

### Validation Results

| Category | Result | Details |
|----------|--------|---------|
| Acceptance Criteria | X/Y passed | [brief summary] |
| Design Alignment | X/Y verified | [brief summary or N/A] |
| Requirements Coverage | X/Y satisfied | [brief summary or N/A] |

### Overall Verdict
```

**Determine overall verdict:**

**APPROVED** (all validations pass):
- No acceptance criteria FAILED (CANNOT_VERIFY is acceptable)
- At least one criterion exists
- Design alignment verified (or N/A if no reference or Production Readiness workflow)
- All requirements satisfied (or N/A if no reference or Production Readiness workflow)

**NEEDS WORK** (any validation fails):
- One or more acceptance criteria FAILED
- OR design misalignment detected
- OR requirements not satisfied

**BLOCKED** (cannot determine verdict):
- No acceptance criteria found in task
- OR critical infrastructure missing (e.g., cannot run any verifications)

## Step 9: Take Action Based on Verdict

### If APPROVED:

1. Update TASKS.md to mark the task as complete:
   - For Feature Planning: Change `### - [~] TASK-XXX:` to `### - [x] TASK-XXX:`
   - For Production Readiness: Change `### - [~] FINDING-XXX:` to `### - [x] FINDING-XXX:`

2. Display success message:
> "## APPROVED
>
> All validations passed! Task **[TASK-ID]: [Title]** has been marked as complete.
>
> **Summary:**
> - Acceptance Criteria: X passed [Y could not verify - review manually]
> - Design Alignment: [Verified | N/A for Production Readiness]
> - Requirements: [X/X satisfied | N/A for Production Readiness]
>
> **Next Steps:**
> - Commit your changes: `git add . && git commit -m "Complete [TASK-ID]: [Title]"`
> - Continue to next task: `/implement-next-task $ARGUMENTS`"

### If NEEDS WORK:

1. Keep the task as `[~]` (do not update TASKS.md)

2. Display detailed failure information:
> "## NEEDS WORK
>
> Some validations failed. Please address the issues below before re-running.
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
> After fixing these issues, run `/review-diff $ARGUMENTS` again to validate."

### If BLOCKED:

1. Keep the task as `[~]` (do not update TASKS.md)

2. Display blocking information:
> "## BLOCKED
>
> Cannot complete review due to missing requirements.
>
> **Issue:** [Describe what's missing - e.g., no acceptance criteria]
>
> **Resolution:** [How to fix - e.g., add acceptance criteria to task in TASKS.md]
>
> After resolving the issue, run `/review-diff $ARGUMENTS` again."

## Edge Cases

### Tests Not Configured
If `npm test` fails because tests aren't set up:
- Note as CANNOT_VERIFY for test-related criteria
- Add suggestion: "Test infrastructure not found. Consider setting up tests."
- Do not fail the entire review for this

### TypeScript Not Available
If `npx tsc` fails:
- Note as CANNOT_VERIFY for TypeScript criteria
- Continue with other validations

### Partial PRD/SDD References
If task has incomplete references (e.g., "Design Doc: TBD"):
- Skip that validation category
- Note it as N/A in the summary
