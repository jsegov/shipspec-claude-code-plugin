# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShipSpec is a Claude Code plugin for spec-driven feature development. It replaces vague plans with structured PRDs (Product Requirements Documents), SDDs (Software Design Documents), and ordered tasks with acceptance criteria.

## Plugin Architecture

```
shipspec/
├── commands/           # User-invocable slash commands
│   ├── feature-planning.md    # 7-phase planning workflow
│   ├── implement-task.md      # Single task implementation with verification
│   ├── implement-feature.md   # Full feature implementation loop
│   ├── cancel-task-loop.md    # Cancel active task retry loop
│   └── cancel-feature-retry.md
├── agents/             # Specialized subagents (Task tool invocations)
│   ├── prd-gatherer.md        # Requirements elicitation
│   ├── design-architect.md    # Technical design decisions
│   ├── task-planner.md        # Task decomposition
│   ├── task-manager.md        # Read-only TASKS.md parsing/validation
│   ├── task-verifier.md       # Acceptance criteria verification
│   └── planning-validator.md  # PRD/SDD alignment checking
├── skills/             # Reusable skill templates (invoked via skill loader)
│   ├── prd-template/          # PRD structure and patterns
│   ├── sdd-template/          # Atlassian 8-section SDD format
│   ├── codebase-context/      # Tech stack extraction
│   ├── agent-prompts/         # Task prompt generation
│   ├── research/              # Web/doc research patterns
│   └── task-loop-verify/      # Loop verification skill
├── hooks/              # Stop hooks for Ralph Loop methodology
│   ├── hooks.json             # Hook registration
│   ├── task-loop-hook.sh      # Per-task auto-retry
│   ├── feature-retry-hook.sh  # Feature-wide task retry
│   └── planning-refine-hook.sh # Large task refinement
└── .claude-plugin/     # Plugin metadata
    └── plugin.json
```

## Key Workflows

### Feature Planning (`/feature-planning`)
7-phase workflow: Description → Setup → Requirements Gathering → PRD Generation → Technical Decisions → SDD Generation → Task Generation

Output: `.shipspec/planning/{feature}/PRD.md`, `SDD.md`, `TASKS.md`

### Task Implementation (`/implement-task`, `/implement-feature`)
1. Parse and validate TASKS.md via `task-manager` agent
2. Find next ready task (dependencies satisfied)
3. Mark task `[~]` (in-progress)
4. Create loop state file for auto-retry
5. Implement and verify via `task-verifier` agent
6. Mark `[x]` on success, retry on failure

## Ralph Loop Methodology

Stop hooks intercept Claude's exit and feed prompts back until completion markers are detected:
- `<task-loop-complete>VERIFIED|INCOMPLETE|BLOCKED|MISALIGNED</task-loop-complete>`
- `<feature-task-complete>VERIFIED|BLOCKED</feature-task-complete>`
- `<feature-complete>APPROVED|APPROVED_WITH_WARNINGS</feature-complete>`

State files track loop iterations: `.claude/shipspec-*.local.md`

## Hook Behavior

All hooks share stdin sequentially. Each hook:
1. Checks for its state file first (before reading stdin)
2. If no state file, exits immediately (preserves stdin for other hooks)
3. If state file exists, reads stdin and processes

Empty stdin detection prevents erroneous state file deletion when multiple hooks are active.

## Development Notes

### Testing Hooks
Hooks expect JSON input with `transcript_path` field. Test with:
```bash
echo '{"transcript_path": "/path/to/transcript.jsonl"}' | ./hooks/task-loop-hook.sh
```

### State File Format
```yaml
---
active: true
feature: feature-name
task_id: TASK-001
iteration: 1
max_iterations: 5
---

[Full task prompt content here]
```

### Task Status Markers
- `[ ]` - Not started
- `[~]` - In progress
- `[x]` - Completed

### Requirement Numbering
- REQ-001 to REQ-009: Core Features
- REQ-010 to REQ-019: User Interface
- REQ-020 to REQ-029: Data & Storage
- REQ-030 to REQ-039: Integration
- REQ-040 to REQ-049: Performance
- REQ-050 to REQ-059: Security

### Task Sizing
Fibonacci story points (1, 2, 3, 5, 8). Tasks >5 points trigger auto-refinement.

### Version Bumping
When updating the plugin version, update both files:
- `.claude-plugin/plugin.json` - the actual plugin version
- `.claude-plugin/marketplace.json` - the version advertised in the marketplace

These are not automatically synced.
