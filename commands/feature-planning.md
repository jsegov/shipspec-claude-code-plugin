---
description: Start planning a new feature with AI-assisted PRD generation
argument-hint: [feature-description]
allowed-tools: Read, Glob, Grep, Write, Bash(git status), Bash(git log:*), Bash(find:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(mkdir:*), Bash(rm:*), Bash(jq:*), Task, AskUserQuestion
---

# Feature Planning

Guide the user through the complete feature planning workflow from requirements gathering to implementation tasks.

## Workflow Overview

This command runs through 7 phases:
1. **Feature Description** - Gather or confirm the feature description
2. **Setup** - Create planning directory and extract codebase context
3. **Requirements Gathering** - Interactive Q&A with prd-gatherer agent
4. **PRD Generation** - Generate PRD and pause for user review
5. **Technical Decisions** - Interactive Q&A with design-architect agent
6. **SDD Generation** - Generate SDD and pause for user review
7. **Task Generation** - Automatically generate implementation tasks (TASKS.json + TASKS.md)

---

## Phase 1/7: Feature Description

**Goal:** Gather a detailed description of the feature to guide all downstream work.

### If description provided as argument ($ARGUMENTS is not empty):

Use the provided argument as the feature description:
> "Got it! Planning feature: **$ARGUMENTS**"

Store this description for use in later phases.

### If no argument provided ($ARGUMENTS is empty):

Prompt the user for a detailed feature description using AskUserQuestion:

> "Let's start planning a new feature! Please describe what you want to build."

- **Header**: "Feature Description"
- **Question**: "Describe the feature you want to build. Include what problem it solves, key functionality, and any important constraints. The more detail you provide, the better the planning will be."
- **Options**:
  - **Quick example**: "A user authentication system with OAuth2 support"
  - **Detailed example**: "An e-commerce checkout flow with payment processing, cart management, shipping options, and order confirmation emails"

The user can also type their own description in the free text field.

**Store the description** for use throughout all phases.

---

## Phase 2/7: Setup

### Generate Directory Name

From the feature description, extract key concepts and generate a directory name:

1. Identify 2-4 key words/concepts from the description
2. Convert to kebab-case
3. Keep it concise (max 30 characters)

**Examples:**
- "Add user authentication with OAuth2 and session management" → `user-auth-oauth2`
- "Build a notification system for email and push alerts" → `notification-system`
- "Create API endpoints for product inventory management" → `product-inventory-api`

### Confirm Directory Name

Use AskUserQuestion to confirm or override the generated name:

> "I'll create the planning directory for this feature."

- **Header**: "Directory Name"
- **Question**: "I've generated the directory name `[generated-name]` based on your description. Would you like to use this name or provide a different one?"
- **Options**:
  - **Use generated name**: "Use `[generated-name]`"
  - **Enter custom name**: "I'll type a different name"

If user selects custom name, use the value they type in the free text field.

Store the final directory name as `FEATURE_DIR`.

### Create Planning Directory

```bash
mkdir -p .shipspec/planning/[FEATURE_DIR]
```

### Save Feature Description

Save the feature description to the planning directory for reference:

```bash
# Write description to a file for context
echo "[FEATURE_DESCRIPTION]" > .shipspec/planning/[FEATURE_DIR]/description.txt
```

### Extract Codebase Context

Analyze the current codebase to understand:

1. **Tech Stack** - What technologies are used?
2. **Project Structure** - How is the code organized?
3. **Patterns** - What conventions are followed?
4. **Documentation** - What guidance exists?

**Focus the codebase analysis based on the feature description:**
- If description mentions "API", focus on API-related files and patterns
- If description mentions "UI" or "component", focus on frontend patterns
- If description mentions "database", focus on data models and migrations

Use the codebase-context skill for this analysis. Save findings to:
`.shipspec/planning/[FEATURE_DIR]/context.md`

---

## Phase 3/7: Requirements Gathering

Delegate to the `prd-gatherer` subagent to have a focused conversation about requirements.

**Pass the feature description to the agent as initial context:**

Begin with:
> "**Phase 3/7: Requirements Gathering**
>
> **Feature:** [FEATURE_DESCRIPTION]
>
> I'll now gather detailed requirements for this feature. Let me ask you some questions to understand what we're building."

The subagent will:
- Use the feature description to focus its questions
- Ask clarifying questions about the problem
- Explore the codebase for context
- Help define clear, testable requirements
- Identify what's out of scope

When the user indicates requirements are complete, proceed to Phase 4.

---

## Phase 4/7: Generate PRD

Load the context file:
```bash
cat .shipspec/planning/[FEATURE_DIR]/context.md 2>/dev/null || echo "No context file found"
```

Load the feature description:
```bash
cat .shipspec/planning/[FEATURE_DIR]/description.txt 2>/dev/null || echo "No description file"
```

Using the prd-template skill, create a comprehensive PRD with:

1. **Overview**
   - Problem statement (derived from feature description)
   - Proposed solution
   - Target users
   - Success metrics

2. **Requirements** (numbered REQ-001, REQ-002, etc.)
   - Core Features (REQ-001 to REQ-009)
   - User Interface (REQ-010 to REQ-019)
   - Data & Storage (REQ-020 to REQ-029)
   - Integration Points (REQ-030 to REQ-039)
   - Performance (REQ-040 to REQ-049)
   - Security (REQ-050 to REQ-059)

3. **User Stories** with acceptance criteria

4. **Technical Considerations**
   - Constraints
   - Dependencies

5. **Out of Scope**

6. **Open Questions**

Save the PRD to: `.shipspec/planning/[FEATURE_DIR]/PRD.md`

### Review Gate

After generating, use the AskUserQuestion tool to get approval:

- **Header**: "PRD Review"
- **Question**: "PRD generated and saved to `.shipspec/planning/[FEATURE_DIR]/PRD.md`. Please review the document. Would you like to approve it or request changes?"
- **Options**:
  - **Approve**: "Continue to technical design phase"
  - **Request changes**: "I'll describe changes needed"

**WAIT for user response before proceeding.**

- If **"Approve"** selected: Continue to Phase 5.
- If **"Request changes"** selected: Ask user to describe the changes, update the PRD, then ask for review again.

---

## Phase 5/7: Technical Decisions Gathering

Once the PRD is approved, begin gathering technical decisions.

Delegate to the `design-architect` subagent to:
- Deeply explore the existing codebase
- Understand current patterns and conventions
- Identify integration points
- Ask about infrastructure preferences (databases, caching, queues)
- Ask about framework and library choices
- Ask about deployment and scaling considerations
- Propose architecture aligned with existing patterns

**Pass the feature description as context:**

Begin with:
> "**Phase 5/7: Technical Decisions**
>
> **Feature:** [FEATURE_DESCRIPTION]
>
> Now I need to understand the technical approach. Let me ask about infrastructure, frameworks, and architectural decisions."

When the user indicates technical decisions are complete, proceed to Phase 6.

---

## Phase 6/7: Generate SDD

Load the PRD:
@.shipspec/planning/[FEATURE_DIR]/PRD.md

Load context:
```bash
cat .shipspec/planning/[FEATURE_DIR]/context.md 2>/dev/null || echo "No context file"
```

Using the sdd-template skill, create a comprehensive design document with all 8 sections:

1. **Introduction** - Purpose, scope, definitions
2. **System Overview** - High-level architecture
3. **Design Considerations** - Assumptions, constraints, risks
4. **Architectural Strategies** - Key decisions and alternatives
5. **System Architecture** - Components, data flow, APIs, data models
6. **Policies and Tactics** - Security, error handling, logging
7. **Detailed Design** - Component-level specifications
8. **Appendix** - Diagrams, glossary

Ensure every requirement from the PRD is addressed with traceability.

Save the SDD to: `.shipspec/planning/[FEATURE_DIR]/SDD.md`

### Review Gate

After generating, summarize the key design decisions and use the AskUserQuestion tool to get approval:

> **Key design decisions:**
> - [Decision 1]
> - [Decision 2]
> - [Decision 3]

- **Header**: "SDD Review"
- **Question**: "SDD generated and saved to `.shipspec/planning/[FEATURE_DIR]/SDD.md`. Please review the technical design. Would you like to approve it or request changes?"
- **Options**:
  - **Approve**: "Continue to generate implementation tasks"
  - **Request changes**: "I'll describe changes needed"

**WAIT for user response before proceeding.**

- If **"Approve"** selected: Continue to Phase 7.
- If **"Request changes"** selected: Ask user to describe the changes, update the SDD, then ask for review again.

---

## Phase 7/7: Generate Tasks

Once the SDD is approved, automatically generate implementation tasks.

Load the planning documents:
@.shipspec/planning/[FEATURE_DIR]/PRD.md
@.shipspec/planning/[FEATURE_DIR]/SDD.md

Load context:
```bash
cat .shipspec/planning/[FEATURE_DIR]/context.md 2>/dev/null || echo "No context file"
```

Delegate to the `task-planner` subagent to:
- Review all requirements and design components
- Break down into well-sized tasks (1-8 points each)
- Identify dependencies and critical path
- Create detailed agent prompts for each task
- Group into execution phases

Using the agent-prompts skill, create comprehensive task files:

1. **TASKS.json** - Machine-parseable metadata
   - Version and feature name
   - Summary (total tasks, points, critical path)
   - Phases array
   - Tasks object with all metadata:
     - title, status, phase, points
     - depends_on, blocks arrays
     - prd_refs, sdd_refs arrays
     - acceptance_criteria, testing arrays
     - prompt field (full implementation prompt)

2. **TASKS.md** - Human-readable task prompts
   - Summary section
   - Requirement coverage matrix
   - Phase groupings
   - Individual tasks with:
     - Context
     - Requirements (prose)
     - Technical Approach
     - Files to Create/Modify
     - Key Interfaces
     - Constraints

Save to:
- `.shipspec/planning/[FEATURE_DIR]/TASKS.json`
- `.shipspec/planning/[FEATURE_DIR]/TASKS.md`

### Cleanup Temporary Files

After tasks are generated successfully, clean up the temporary files:

```bash
rm -f .shipspec/planning/[FEATURE_DIR]/context.md
rm -f .shipspec/planning/[FEATURE_DIR]/description.txt
```

The context and description are now incorporated into the PRD, SDD, and task files.

---

## Phase 8: Task Refinement (Optional)

After generating TASKS.json, analyze task complexity to identify tasks that may be too large.

### 8.1: Identify Large Tasks

Parse TASKS.json and find tasks with estimated effort > 5 story points:

```bash
jq -r '.tasks | to_entries[] | select(.value.points > 5) | "\(.key): \(.value.title) (\(.value.points) points)"' .shipspec/planning/[FEATURE_DIR]/TASKS.json
```

**If no large tasks found:**
> "All tasks are appropriately sized (≤5 story points). Skipping refinement."

Skip to Completion Summary.

**If large tasks found:**

Show user:
> "## Task Size Analysis
>
> Found **X tasks** with estimated effort > 5 story points:
>
> | Task | Title | Story Points |
> |------|-------|--------------|
> | TASK-003 | [Title] | 8 |
> | TASK-007 | [Title] | 13 |
>
> Large tasks are harder to implement and verify. Would you like to auto-refine them into smaller subtasks?"

Use AskUserQuestion with options:
- "Yes, auto-refine large tasks"
- "No, keep current breakdown"

**If user chooses No:** Skip to Completion Summary.

### 8.2: Initialize Refinement Loop

Create state files (JSON format):
```bash
# Create pointer file
cat > .shipspec/active-loop.local.json << 'EOF'
{
  "feature": "[FEATURE_DIR]",
  "loop_type": "planning-refine",
  "state_path": ".shipspec/planning/[FEATURE_DIR]/planning-refine.local.json",
  "created_at": "[ISO timestamp]"
}
EOF

# Create state file in feature directory
cat > .shipspec/planning/[FEATURE_DIR]/planning-refine.local.json << 'EOF'
{
  "active": true,
  "feature": "[FEATURE_DIR]",
  "iteration": 1,
  "max_iterations": 3,
  "large_tasks": ["TASK-003", "TASK-007"],
  "tasks_refined": 0,
  "started_at": "[ISO timestamp]"
}
EOF
```

### 8.3: Refine Each Large Task

For each task in large_tasks:

1. Get full task details from TASKS.json:
   ```bash
   jq -r '.tasks["TASK-XXX"]' .shipspec/planning/[FEATURE_DIR]/TASKS.json
   ```

2. Delegate to `task-planner` agent:
   > "Break down TASK-XXX into 2-3 subtasks.
   >
   > Original task:
   > [task prompt]
   >
   > Requirements:
   > - Each subtask should be < 3 story points
   > - Preserve the original acceptance criteria distributed across subtasks
   > - Maintain dependency relationships
   > - Use format TASK-XXX-A, TASK-XXX-B, etc. for subtask IDs"

3. Replace original task with generated subtasks in TASKS.json and TASKS.md
4. Update dependencies pointing to original task
5. Run task-manager validate to check no circular deps

**If validation fails:**
- Rollback changes
- Mark task as "cannot refine"
- Continue to next large task

### 8.4: Check Completion

After processing all large tasks:

1. Re-analyze TASKS.json for tasks > 5 points:
   ```bash
   jq '[.tasks | to_entries[] | select(.value.points > 5)] | length' .shipspec/planning/[FEATURE_DIR]/TASKS.json
   ```
2. If still have large tasks AND iteration < max_iterations:
   - Increment iteration in state file:
     ```bash
     jq '.iteration += 1' .shipspec/planning/[FEATURE_DIR]/planning-refine.local.json > tmp && mv tmp .shipspec/planning/[FEATURE_DIR]/planning-refine.local.json
     ```
   - Add new large tasks to list
   - Return to 8.3
3. If no more large tasks OR max iterations:
   - Clean up state file
   - Show summary

### 8.5: Summary

> "## Task Refinement Complete
>
> **Results:**
> - Original large tasks: X
> - Successfully refined: Y
> - Could not refine: Z
>
> **New task count:** N (was M)"

**Output completion marker:**
`<planning-refine-complete>`

Clean up:
```bash
rm -f .shipspec/planning/[FEATURE_DIR]/planning-refine.local.json .shipspec/active-loop.local.json
```

---

## Completion Summary

After all phases complete, provide:

> "**Planning Complete for [FEATURE_DIR]!**
>
> **Feature:** [FEATURE_DESCRIPTION]
>
> **Summary:**
> - Total Tasks: [X]
> - Total Story Points: [Y]
> - Estimated Duration: [Z] sessions
> - Critical Path: [list]
>
> **Generated Documents:**
> - `.shipspec/planning/[FEATURE_DIR]/PRD.md` - Product requirements
> - `.shipspec/planning/[FEATURE_DIR]/SDD.md` - Technical design
> - `.shipspec/planning/[FEATURE_DIR]/TASKS.json` - Task metadata (machine-parseable)
> - `.shipspec/planning/[FEATURE_DIR]/TASKS.md` - Task prompts (human-readable)
>
> **Next Steps:**
> Run `/implement-task [FEATURE_DIR]` to start implementing the first task.
> Run `/implement-feature [FEATURE_DIR]` to implement all tasks automatically.
> Each task includes a detailed prompt you can give directly to Claude Code."

---

## Pre-loaded Context

Current git status:
!`git status --short 2>/dev/null | head -10 || echo "Not a git repository"`

Recent activity:
!`git log --oneline -5 2>/dev/null || echo "No git history"`

Project root files:
!`ls -la *.md *.json 2>/dev/null | head -10 || echo "No root files found"`
