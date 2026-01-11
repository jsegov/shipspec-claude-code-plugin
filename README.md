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
# Start planning a new feature (runs full workflow)
/feature-planning my-feature

# Implement tasks one by one
/implement-next-task my-feature

# Review implementation against planning artifacts
/review-diff my-feature
```

### Full Feature Planning Workflow

Run `/feature-planning <name>` to go through the complete planning workflow:

```
/feature-planning user-authentication
```

The command guides you through 6 phases:

1. **Setup** - Creates `.shipspec/planning/user-authentication/` and extracts codebase context

2. **Requirements Gathering** - Interactive Q&A with the PRD Gatherer agent about:
   - The problem you're solving
   - Target users
   - Must-have vs nice-to-have features
   - Technical constraints

3. **PRD Generation** - Creates structured PRD with numbered requirements
   - *Pauses for your review and approval*

4. **Technical Decisions** - Interactive Q&A about:
   - Infrastructure preferences (databases, caching, queues)
   - Framework and library choices
   - Deployment and scaling considerations

5. **SDD Generation** - Creates technical design document with:
   - Architecture decisions
   - API specifications
   - Data models
   - Component designs
   - *Pauses for your review and approval*

6. **Task Generation** - Automatically creates implementation tasks with:
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
| `/feature-planning <name>` | Run complete planning workflow (requirements → PRD → SDD → tasks) |
| `/implement-next-task <name>` | Start/continue implementing tasks from TASKS.md |
| `/review-diff <name>` | Review implementation against planning artifacts (TASKS.md, SDD.md, PRD.md) |

## Agents

| Agent | Purpose | Auto-Invoked When |
|-------|---------|-------------------|
| `prd-gatherer` | Requirements elicitation | Planning features, writing specs |
| `design-architect` | Technical design | Architecture decisions, API design |
| `task-planner` | Task decomposition | Breaking down features |
| `task-verifier` | Verify task completion | Running /implement-next-task |

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

```
/implement-next-task my-feature    # Start a task (marks it [~])
        ↓
   Implement the task              # Write the code
        ↓
/review-diff my-feature            # Validate against PRD, SDD, acceptance criteria
        ↓
   ┌────┴────┐
   │ Passed? │
   └────┬────┘
   Yes: Task marked [x], suggests next task
   No:  Shows issues to fix, re-run /review-diff after fixing
```

The `/review-diff` command validates three things:
1. **Acceptance Criteria** - All criteria from the task in TASKS.md are met
2. **Design Alignment** - Implementation follows the referenced SDD section
3. **Requirements Coverage** - Referenced PRD requirements are satisfied

## Tips

- **Use `/feature-planning` for full workflow**: Single command runs requirements → PRD → SDD → tasks
- **Review at each gate**: The workflow pauses after PRD and SDD for your review
- **Use `/implement-next-task` to work through tasks**: Tracks progress and verifies completion
- **Use `/review-diff` after implementing**: Validates work against planning artifacts before marking complete

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
