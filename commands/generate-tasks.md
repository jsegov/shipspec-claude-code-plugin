---
description: Generate implementation tasks with agent prompts from PRD and SDD
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Bash(cat:*), Bash(ls:*), Bash(find:*), Bash(wc:*)
---

# Generate Tasks: $ARGUMENTS

Generate a complete set of implementation tasks with agent-ready prompts.

## Step 1: Validate Prerequisites

Check that both PRD and SDD exist:
```bash
echo "=== Checking PRD ==="
ls -la docs/planning/$ARGUMENTS/PRD.md 2>/dev/null || echo "PRD NOT FOUND"
echo "=== Checking SDD ==="
ls -la docs/planning/$ARGUMENTS/SDD.md 2>/dev/null || echo "SDD NOT FOUND"
```

If either is missing, tell the user which command to run first.

## Step 2: Load Planning Documents

PRD:
@docs/planning/$ARGUMENTS/PRD.md

SDD:
@docs/planning/$ARGUMENTS/SDD.md

Context (if exists):
```bash
cat docs/planning/$ARGUMENTS/context.md 2>/dev/null || echo "No context file"
```

## Step 3: Delegate to Task Planner

Use the `task-planner` subagent to:
- Review all requirements and design components
- Break down into well-sized tasks (1-8 points each)
- Identify dependencies and critical path
- Create detailed agent prompts for each task
- Group into execution phases

## Step 4: Generate Task Document

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

## Step 5: Save Document

Save the tasks to: `docs/planning/$ARGUMENTS/TASKS.md`

## Step 6: Summary and Next Steps

After generating, provide:

> "Implementation tasks generated and saved to `docs/planning/$ARGUMENTS/TASKS.md`
>
> **Summary:**
> - Total Tasks: [X]
> - Total Story Points: [Y]
> - Estimated Duration: [Z] sessions
> - Critical Path: [list]
>
> **Planning Complete!** You now have:
> - `docs/planning/$ARGUMENTS/context.md` - Codebase context
> - `docs/planning/$ARGUMENTS/PRD.md` - Product requirements
> - `docs/planning/$ARGUMENTS/SDD.md` - Technical design
> - `docs/planning/$ARGUMENTS/TASKS.md` - Implementation tasks
>
> To start implementation, work through tasks in order, beginning with Phase 1.
> Each task includes a detailed prompt you can give directly to Claude Code."
