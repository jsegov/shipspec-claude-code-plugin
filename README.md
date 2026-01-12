# ShipSpec Claude Code Plugin

**Spec-driven development for Claude Code.** Plan features systematically before writing code—transform ideas into well-structured PRDs, technical designs, and implementation tasks.

Spec-driven development ensures you think through requirements and architecture before implementation, resulting in better code, fewer rewrites, and clearer communication.

## Features

- **Conversational PRD Gathering**: Structured interview process to extract clear requirements
- **Codebase-Aware Design**: Technical designs grounded in your existing architecture
- **Agent-Ready Tasks**: Implementation tasks with detailed prompts for coding agents
- **Progressive Workflow**: Each phase builds on the previous

## Installation

### From Local Directory

```bash
/plugin marketplace add shipspec/planning-plugin
/plugin install shipspec@shipspec
```

## Usage

### Quick Start

```bash
# Start planning a new feature with a description (or run interactively)
/feature-planning "Add user authentication with OAuth2 and session management"
/feature-planning                  # prompts for description interactively

# Implement tasks one by one (or specify a task ID)
/implement-task user-auth-oauth2
/implement-task user-auth-oauth2 3  # implement specific task
```

### Full Feature Planning Workflow

Run `/feature-planning` with a description to go through the complete planning workflow:

```
/feature-planning "Add user authentication with OAuth2 and session management"
```

The command auto-generates a directory name (e.g., `user-auth-oauth2`) and guides you through 7 phases:

1. **Feature Description** - Gather or confirm the feature description, auto-generate directory name

2. **Setup** - Creates `.shipspec/planning/<generated-name>/` and extracts codebase context

3. **Requirements Gathering** - Interactive Q&A with the PRD Gatherer agent about:
   - The problem you're solving
   - Target users
   - Must-have vs nice-to-have features
   - Technical constraints

4. **PRD Generation** - Creates structured PRD with numbered requirements
   - *Pauses for your review and approval*

5. **Technical Decisions** - Interactive Q&A about:
   - Infrastructure preferences (databases, caching, queues)
   - Framework and library choices
   - Deployment and scaling considerations

6. **SDD Generation** - Creates technical design document with:
   - Architecture decisions
   - API specifications
   - Data models
   - Component designs
   - *Pauses for your review and approval*

7. **Task Generation** - Automatically creates implementation tasks with:
   - Story point estimates
   - Dependencies
   - Detailed agent prompts
   - Acceptance criteria

## Output Structure

After completing the feature planning workflow:

```
.shipspec/planning/your-feature/
├── PRD.md       # Product Requirements Document
├── SDD.md       # Software Design Document
└── TASKS.md     # Implementation tasks with agent prompts
```

Note: A temporary `context.md` file is created during planning but automatically cleaned up after task generation.

## Commands

| Command | Description |
|---------|-------------|
| `/feature-planning [description]` | Run complete planning workflow - provide description inline or interactively |
| `/implement-task <feature-dir> [task-id]` | Implement a specific task or the next available task from TASKS.md |
| `/implement-feature <feature-dir>` | Automatically implement all tasks end-to-end with final review |

## Agents

| Agent | Purpose | Auto-Invoked When |
|-------|---------|-------------------|
| `prd-gatherer` | Requirements elicitation | Planning features, writing specs |
| `design-architect` | Technical design | Architecture decisions, API design |
| `task-planner` | Task decomposition | Breaking down features |
| `task-verifier` | Verify task completion | Running /implement-task or /implement-feature |

## Skills

| Skill | Purpose |
|-------|---------|
| `codebase-context` | Extract tech stack and patterns |
| `prd-template` | PRD structure and best practices |
| `sdd-template` | Atlassian 8-section design template |
| `agent-prompts` | Task prompt generation patterns |

## Requirement Numbering

Requirements follow a consistent numbering scheme:

| Range | Category |
|-------|----------|
| REQ-001 to REQ-009 | Core Features |
| REQ-010 to REQ-019 | User Interface |
| REQ-020 to REQ-029 | Data & Storage |
| REQ-030 to REQ-039 | Integration |
| REQ-040 to REQ-049 | Performance |
| REQ-050 to REQ-059 | Security |

## Task Sizing

Tasks use Fibonacci story points:

| Points | Description | Duration |
|--------|-------------|----------|
| 1 | Trivial | < 2 hours |
| 2 | Small | 2-4 hours |
| 3 | Medium | 4-8 hours |
| 5 | Large | 1-2 days |
| 8 | Complex | 2-3 days |

Tasks larger than 8 points are automatically broken down.

## Implementation Workflow

After planning is complete, use this workflow to implement tasks:

### Manual Task-by-Task
```
/implement-task my-feature         # Start next available task (marks it [~])
        ↓
   Implement the task              # Write the code
        ↓
/implement-task my-feature         # Verify and move to next task
        ↓
   ┌────┴────┐
   │ Passed? │
   └────┬────┘
   Yes: Task marked [x], shows next task
   No:  Shows issues to fix, re-run after fixing
```

### Automatic Full Feature
```
/implement-feature my-feature      # Implement ALL tasks automatically
```

The `/implement-feature` command implements all tasks and runs a comprehensive final review that validates:
1. **Acceptance Criteria** - All criteria from every task are met
2. **Design Alignment** - Implementation follows SDD sections
3. **Requirements Coverage** - All PRD requirements are satisfied

## Tips

- **Use `/feature-planning` for full workflow**: Single command runs requirements → PRD → SDD → tasks
- **Review at each gate**: The workflow pauses after PRD and SDD for your review
- **Use `/implement-task` to work through tasks manually**: Tracks progress and verifies completion
- **Use `/implement-feature` for automation**: Implements all tasks and runs comprehensive final review

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
