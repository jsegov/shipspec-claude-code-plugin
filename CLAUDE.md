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
│   ├── task-manager.md        # TASKS.json parsing/validation/status updates
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

Output:
- `.shipspec/planning/{feature}/PRD.md` - Product requirements
- `.shipspec/planning/{feature}/SDD.md` - Technical design
- `.shipspec/planning/{feature}/TASKS.json` - Machine-parseable task metadata
- `.shipspec/planning/{feature}/TASKS.md` - Human-readable task prompts

### Task Implementation (`/implement-task`, `/implement-feature`)
1. Parse and validate TASKS.json via `task-manager` agent
2. Find next ready task (dependencies satisfied, status = `not_started`)
3. Update status to `in_progress` via task-manager `update_status` operation
4. Create loop state file (JSON) for auto-retry
5. Implement and verify via `task-verifier` agent
6. Update status to `completed` on success, retry on failure

## Task File Structure

### TASKS.json (Machine-Parseable)
```json
{
  "version": "1.0",
  "feature": "feature-name",
  "summary": {
    "total_tasks": 5,
    "total_points": 18,
    "critical_path": ["TASK-001", "TASK-003", "TASK-005"]
  },
  "phases": [
    { "id": 1, "name": "Foundation" }
  ],
  "tasks": {
    "TASK-001": {
      "title": "Setup Database Schema",
      "status": "not_started",
      "phase": 1,
      "points": 3,
      "depends_on": [],
      "blocks": ["TASK-002"],
      "prd_refs": ["REQ-001"],
      "sdd_refs": ["Section 5.1"],
      "acceptance_criteria": ["Schema file exists", "Migration runs"],
      "testing": ["npm run db:migrate"],
      "prompt": "## Context\n..."
    }
  }
}
```

### TASKS.md (Human-Readable)
Contains context, requirements prose, technical approach, files to create/modify, key interfaces, and constraints. No status markers or dependencies (those live in JSON).

### Task Status Values
- `"not_started"` - Task not yet begun
- `"in_progress"` - Currently being implemented
- `"completed"` - All acceptance criteria verified

## Ralph Loop Methodology

Stop hooks intercept Claude's exit and feed prompts back until completion markers are detected:
- `<task-loop-complete>VERIFIED|INCOMPLETE|BLOCKED|MISALIGNED</task-loop-complete>`
- `<feature-task-complete>VERIFIED|BLOCKED</feature-task-complete>`
- `<feature-complete>APPROVED|APPROVED_WITH_WARNINGS</feature-complete>`

State files are stored alongside planning artifacts in `.shipspec/planning/<feature>/`.

## Hook Behavior

All hooks share stdin sequentially. Each hook:
1. Checks for pointer file (`.shipspec/active-loop.local.json`) first
2. Parses pointer JSON to check if this hook's loop type is active
3. If not this hook's loop type, exits immediately (preserves stdin for other hooks)
4. If active, reads the state file from `.shipspec/planning/<feature>/<loop-type>.local.json`
5. Reads task prompt from TASKS.json: `jq -r '.tasks[TASK_ID].prompt' TASKS.json`

Empty stdin detection prevents erroneous state file deletion when multiple hooks are active.

## Development Notes

### Testing Hooks
Hooks expect JSON input with `transcript_path` field. Test with:
```bash
echo '{"transcript_path": "/path/to/transcript.jsonl"}' | ./hooks/task-loop-hook.sh
```

### Pointer File Format (`.shipspec/active-loop.local.json`)
```json
{
  "feature": "feature-name",
  "loop_type": "task-loop",
  "state_path": ".shipspec/planning/feature-name/task-loop.local.json",
  "created_at": "2024-01-15T10:30:00Z"
}
```

Supported loop types: `task-loop`, `feature-retry`, `planning-refine`

### State File Format (`.shipspec/planning/<feature>/<loop-type>.local.json`)

**task-loop.local.json:**
```json
{
  "active": true,
  "feature": "feature-name",
  "task_id": "TASK-001",
  "iteration": 1,
  "max_iterations": 5,
  "started_at": "2024-01-15T10:30:00Z"
}
```

**feature-retry.local.json:**
```json
{
  "active": true,
  "feature": "feature-name",
  "current_task_id": "TASK-001",
  "task_attempt": 1,
  "max_task_attempts": 5,
  "tasks_completed": 0,
  "total_tasks": 5,
  "started_at": "2024-01-15T10:30:00Z"
}
```

**planning-refine.local.json:**
```json
{
  "active": true,
  "feature": "feature-name",
  "iteration": 1,
  "max_iterations": 3,
  "large_tasks": ["TASK-003", "TASK-007"],
  "tasks_refined": 0,
  "started_at": "2024-01-15T10:30:00Z"
}
```

Note: Task prompts are read from TASKS.json, not stored in state files.

### Requirement Numbering
- REQ-001 to REQ-009: Core Features
- REQ-010 to REQ-019: User Interface
- REQ-020 to REQ-029: Data & Storage
- REQ-030 to REQ-039: Integration
- REQ-040 to REQ-049: Performance
- REQ-050 to REQ-059: Security

### Task Sizing
Fibonacci story points (1, 2, 3, 5, 8). Tasks >5 points trigger auto-refinement.

### JSON Operations (jq)
All hooks and commands use `jq` for JSON parsing:
```bash
# Read task status
jq -r '.tasks["TASK-001"].status' TASKS.json

# Update task status
jq '.tasks["TASK-001"].status = "in_progress"' TASKS.json > tmp && mv tmp TASKS.json

# Read prompt
jq -r '.tasks["TASK-001"].prompt' TASKS.json

# Increment iteration
jq '.iteration += 1' state.json > tmp && mv tmp state.json
```

### Version Bumping
When updating the plugin version, update both files:
- `.claude-plugin/plugin.json` - the actual plugin version
- `.claude-plugin/marketplace.json` - the version advertised in the marketplace

These are not automatically synced.
