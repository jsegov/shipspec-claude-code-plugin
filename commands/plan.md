---
description: Start planning a new feature with AI-assisted PRD generation
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Bash(git status), Bash(git log:*), Bash(find:*), Bash(ls:*), Bash(cat:*), Bash(head:*), Bash(mkdir:*)
---

# Feature Planning: $ARGUMENTS

Start the planning workflow for a new feature.

## Step 1: Setup Planning Directory

Create the planning directory structure:

```bash
mkdir -p docs/planning/$ARGUMENTS
```

## Step 2: Extract Codebase Context

Analyze the current codebase to understand:

1. **Tech Stack** - What technologies are used?
2. **Project Structure** - How is the code organized?
3. **Patterns** - What conventions are followed?
4. **Documentation** - What guidance exists?

Use the codebase-context skill for this analysis. Save findings to:
`docs/planning/$ARGUMENTS/context.md`

## Step 3: Gather Requirements

Delegate to the `prd-gatherer` subagent to have a focused conversation about requirements.

Begin with:
> "I'll now start gathering requirements for the $ARGUMENTS feature. Let me ask you some questions to understand what we're building."

The subagent will:
- Ask clarifying questions about the problem
- Explore the codebase for context
- Help define clear, testable requirements
- Identify what's out of scope

## Step 4: Next Steps

After requirements gathering, inform the user:

> "Requirements gathering complete! Here's what we discussed:
> [Summary]
>
> **Next steps:**
> 1. Run `/generate-prd $ARGUMENTS` to create the PRD document
> 2. Review and refine the PRD
> 3. Run `/generate-sdd $ARGUMENTS` to create the technical design
> 4. Run `/generate-tasks $ARGUMENTS` to create implementation tasks"

## Pre-loaded Context

Current git status:
!`git status --short 2>/dev/null | head -10 || echo "Not a git repository"`

Recent activity:
!`git log --oneline -5 2>/dev/null || echo "No git history"`

Project root files:
!`ls -la *.md *.json 2>/dev/null | head -10 || echo "No root files found"`
