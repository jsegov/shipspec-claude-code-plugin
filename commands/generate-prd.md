---
description: Generate a PRD document from gathered requirements
argument-hint: <feature-name>
allowed-tools: Read, Glob, Grep, Write, Bash(cat:*), Bash(ls:*)
---

# Generate PRD: $ARGUMENTS

Generate a comprehensive Product Requirements Document based on the planning conversation.

## Step 1: Load Context

Read the codebase context if it exists:
```bash
cat docs/planning/$ARGUMENTS/context.md 2>/dev/null || echo "No context file found"
```

## Step 2: Review Conversation

Look at the recent conversation for requirements that were gathered. The user should have just finished a requirements gathering session with the prd-gatherer agent.

If no requirements are apparent in the conversation, ask the user to run `/feature $ARGUMENTS` first.

## Step 3: Generate PRD

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

## Step 4: Save Document

Save the PRD to: `docs/planning/$ARGUMENTS/PRD.md`

## Step 5: Confirm and Next Steps

After generating, tell the user:

> "PRD generated and saved to `docs/planning/$ARGUMENTS/PRD.md`
>
> Please review the document and let me know if any changes are needed.
>
> **Next step:** Run `/generate-sdd $ARGUMENTS` to create the technical design document."
