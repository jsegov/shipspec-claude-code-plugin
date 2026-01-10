---
description: Generate a Software Design Document from an approved PRD
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Bash(cat:*), Bash(ls:*), Bash(find:*)
---

# Generate SDD: $ARGUMENTS

Generate a comprehensive Software Design Document based on the approved PRD.

## Step 1: Validate Prerequisites

Check that the PRD exists:
```bash
ls -la docs/planning/$ARGUMENTS/PRD.md 2>/dev/null || echo "PRD NOT FOUND"
```

If PRD is missing, tell the user to run `/generate-prd $ARGUMENTS` first.

## Step 2: Load Inputs

PRD Content:
@docs/planning/$ARGUMENTS/PRD.md

Context (if exists):
```bash
cat docs/planning/$ARGUMENTS/context.md 2>/dev/null || echo "No context file"
```

## Step 3: Analyze Codebase

Delegate to the `design-architect` subagent to:
- Deeply explore the existing codebase
- Understand current patterns and conventions
- Identify integration points
- Propose architecture aligned with existing patterns

## Step 4: Generate SDD

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

## Step 5: Save Document

Save the SDD to: `docs/planning/$ARGUMENTS/SDD.md`

## Step 6: Confirm and Next Steps

After generating, tell the user:

> "SDD generated and saved to `docs/planning/$ARGUMENTS/SDD.md`
>
> Please review the technical design. Key decisions:
> - [Decision 1]
> - [Decision 2]
>
> **Next step:** Run `/generate-tasks $ARGUMENTS` to create implementation tasks."
