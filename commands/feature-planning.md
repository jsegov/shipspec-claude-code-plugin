---
description: Start planning a new feature with AI-assisted PRD generation
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Bash(git status), Bash(git log:*), Bash(find:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(mkdir:*), Bash(rm:*), Task, AskUserQuestion
---

# Feature Planning: $ARGUMENTS

Guide the user through the complete feature planning workflow from requirements gathering to implementation tasks.

## Workflow Overview

This command runs through 6 phases:
1. **Setup** - Create planning directory and extract codebase context
2. **Requirements Gathering** - Interactive Q&A with prd-gatherer agent
3. **PRD Generation** - Generate PRD and pause for user review
4. **Technical Decisions** - Interactive Q&A with design-architect agent
5. **SDD Generation** - Generate SDD and pause for user review
6. **Task Generation** - Automatically generate implementation tasks

---

## Phase 1/6: Setup

Create the planning directory structure:

```bash
mkdir -p .shipspec/planning/$ARGUMENTS
```

### Extract Codebase Context

Analyze the current codebase to understand:

1. **Tech Stack** - What technologies are used?
2. **Project Structure** - How is the code organized?
3. **Patterns** - What conventions are followed?
4. **Documentation** - What guidance exists?

Use the codebase-context skill for this analysis. Save findings to:
`.shipspec/planning/$ARGUMENTS/context.md`

---

## Phase 2/6: Requirements Gathering

Delegate to the `prd-gatherer` subagent to have a focused conversation about requirements.

Begin with:
> "**Phase 2/6: Requirements Gathering**
>
> I'll now gather requirements for the $ARGUMENTS feature. Let me ask you some questions to understand what we're building."

The subagent will:
- Ask clarifying questions about the problem
- Explore the codebase for context
- Help define clear, testable requirements
- Identify what's out of scope

When the user indicates requirements are complete, proceed to Phase 3.

---

## Phase 3/6: Generate PRD

Load the context file:
```bash
cat .shipspec/planning/$ARGUMENTS/context.md 2>/dev/null || echo "No context file found"
```

Using the prd-template skill, create a comprehensive PRD with:

1. **Overview**
   - Problem statement
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

Save the PRD to: `.shipspec/planning/$ARGUMENTS/PRD.md`

### Review Gate

After generating, use the AskUserQuestion tool to get approval:

- **Header**: "PRD Review"
- **Question**: "PRD generated and saved to `.shipspec/planning/$ARGUMENTS/PRD.md`. Please review the document. Would you like to approve it or request changes?"
- **Options**:
  - **Approve**: "Continue to technical design phase"
  - **Request changes**: "I'll describe changes needed"

**WAIT for user response before proceeding.**

- If **"Approve"** selected: Continue to Phase 4.
- If **"Request changes"** selected: Ask user to describe the changes, update the PRD, then ask for review again.

---

## Phase 4/6: Technical Decisions Gathering

Once the PRD is approved, begin gathering technical decisions.

Delegate to the `design-architect` subagent to:
- Deeply explore the existing codebase
- Understand current patterns and conventions
- Identify integration points
- Ask about infrastructure preferences (databases, caching, queues)
- Ask about framework and library choices
- Ask about deployment and scaling considerations
- Propose architecture aligned with existing patterns

Begin with:
> "**Phase 4/6: Technical Decisions**
>
> Now I need to understand the technical approach for $ARGUMENTS. Let me ask about infrastructure, frameworks, and architectural decisions."

When the user indicates technical decisions are complete, proceed to Phase 5.

---

## Phase 5/6: Generate SDD

Load the PRD:
@.shipspec/planning/$ARGUMENTS/PRD.md

Load context:
```bash
cat .shipspec/planning/$ARGUMENTS/context.md 2>/dev/null || echo "No context file"
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

Save the SDD to: `.shipspec/planning/$ARGUMENTS/SDD.md`

### Review Gate

After generating, summarize the key design decisions and use the AskUserQuestion tool to get approval:

> **Key design decisions:**
> - [Decision 1]
> - [Decision 2]
> - [Decision 3]

- **Header**: "SDD Review"
- **Question**: "SDD generated and saved to `.shipspec/planning/$ARGUMENTS/SDD.md`. Please review the technical design. Would you like to approve it or request changes?"
- **Options**:
  - **Approve**: "Continue to generate implementation tasks"
  - **Request changes**: "I'll describe changes needed"

**WAIT for user response before proceeding.**

- If **"Approve"** selected: Continue to Phase 6.
- If **"Request changes"** selected: Ask user to describe the changes, update the SDD, then ask for review again.

---

## Phase 6/6: Generate Tasks

Once the SDD is approved, automatically generate implementation tasks.

Load the planning documents:
@.shipspec/planning/$ARGUMENTS/PRD.md
@.shipspec/planning/$ARGUMENTS/SDD.md

Load context:
```bash
cat .shipspec/planning/$ARGUMENTS/context.md 2>/dev/null || echo "No context file"
```

Delegate to the `task-planner` subagent to:
- Review all requirements and design components
- Break down into well-sized tasks (1-8 points each)
- Identify dependencies and critical path
- Create detailed agent prompts for each task
- Group into execution phases

Using the agent-prompts skill, create a comprehensive task list with:

1. **Summary**
   - Total tasks and story points
   - Estimated duration
   - Critical path
   - Requirement coverage matrix

2. **Execution Phases**
   - Phase 1: Foundation (schema, types)
   - Phase 2: Core Implementation (APIs, services)
   - Phase 3: UI Layer (components, pages)
   - Phase 4: Polish (tests, docs)

3. **Individual Tasks**
   - Each with full agent prompt
   - Dependencies clearly marked
   - Acceptance criteria

Save the tasks to: `.shipspec/planning/$ARGUMENTS/TASKS.md`

### Cleanup Temporary Files

After tasks are generated successfully, clean up the temporary context file:

```bash
rm -f .shipspec/planning/$ARGUMENTS/context.md
```

The context information is now incorporated into the PRD, SDD, and TASKS.md files.

---

## Completion Summary

After all phases complete, provide:

> "**Planning Complete for $ARGUMENTS!**
>
> **Summary:**
> - Total Tasks: [X]
> - Total Story Points: [Y]
> - Estimated Duration: [Z] sessions
> - Critical Path: [list]
>
> **Generated Documents:**
> - `.shipspec/planning/$ARGUMENTS/PRD.md` - Product requirements
> - `.shipspec/planning/$ARGUMENTS/SDD.md` - Technical design
> - `.shipspec/planning/$ARGUMENTS/TASKS.md` - Implementation tasks
>
> **Next Steps:**
> Run `/implement-next-task` to start implementing the first task.
> Each task includes a detailed prompt you can give directly to Claude Code."

---

## Pre-loaded Context

Current git status:
!`git status --short 2>/dev/null | head -10 || echo "Not a git repository"`

Recent activity:
!`git log --oneline -5 2>/dev/null || echo "No git history"`

Project root files:
!`ls -la *.md *.json 2>/dev/null | head -10 || echo "No root files found"`
