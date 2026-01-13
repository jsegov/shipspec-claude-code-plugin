# ShipSpec Claude Code Plugin

**Spec-driven development for big features.**

Claude Code's native plan mode works great—for small features. But when a feature gets big, the plan gets vague. There's just too much to capture, so you end up with high-level bullet points instead of real structure. And vague plans lead to hallucinations during implementation.

Claude loses sight of *why* it's building what it's building. It makes architecture decisions that contradict what you discussed. It "finishes" tasks that don't actually meet the requirements. The plan is there, but it's too shallow to keep a complex implementation on track.

**The problem isn't Claude—it's that big features need more than a plan. They need a spec.**

ShipSpec replaces vague plans with structured PRDs, technical designs, and ordered tasks that keep Claude grounded throughout implementation.

## Why ShipSpec?

| Problem | Solution |
|---------|----------|
| Big features make plans too vague | Structured PRD with numbered requirements |
| Claude drifts from original intent | Requirements stay visible, linked to every task |
| Architecture decisions get contradicted | SDD documents design choices before implementation |
| Implementation feels chaotic | Ordered tasks with acceptance criteria and verification |

**The result**: Claude always knows *why* it's building something (requirements) and *how* to build it (design), working through manageable chunks that build on each other.

## Features

- **Conversational PRD Gathering**: Structured interview to extract clear requirements
- **Codebase-Aware Design**: Technical designs grounded in your existing architecture
- **Agent-Ready Tasks**: Implementation tasks with detailed prompts for coding agents
- **Built-in Verification**: Each task is verified against acceptance criteria before moving on

## Installation

```bash
/plugin marketplace add jsegov/shipspec-claude-code-plugin
/plugin install shipspec@shipspec-marketplace
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

## Ralph Loop Methodology

This plugin uses the [Ralph Loop](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-loop) methodology for iterative, self-correcting implementation.

### What is Ralph Loop?

Ralph Loop is a development methodology based on continuous AI agent loops. The core concept: use a **Stop hook** to intercept Claude's exit attempts and feed the same prompt back until the task is complete. This creates a self-referential feedback loop where Claude iteratively improves its work.

### How ShipSpec Uses It

ShipSpec adapts Ralph Loop for structured feature development:

| Feature | Ralph Loop Technique |
|---------|---------------------|
| `/implement-task` auto-retry | Stop hook blocks exit on failed verification, retries until VERIFIED or max attempts |
| `/implement-feature` per-task retry | Same mechanism, applied to each task during full-feature implementation |
| `/feature-planning` task refinement | Stop hook triggers re-analysis of large tasks (>5 story points) |

### Key Components

1. **Stop Hooks** - Intercept session exit and trigger retry loops
2. **State Files** - Track iteration count and current task:
   - Pointer: `.shipspec/active-loop.local.md`
   - State: `.shipspec/planning/<feature>/<loop-type>.local.md`
3. **Completion Markers** - Signal successful completion (`<task-loop-complete>VERIFIED</task-loop-complete>`)
4. **Max Iterations** - Safety limit to prevent infinite loops (default: 5 attempts per task)

### Philosophy

From Ralph Loop:
- **Iteration > Perfection** - Don't aim for perfect on first try; let the loop refine the work
- **Failures Are Data** - Failed verification tells Claude exactly what to fix
- **Persistence Wins** - Keep trying until success; the loop handles retry logic automatically

### Learn More

- [Ralph Loop Plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-loop)
- [Original Ralph Technique](https://ghuntley.com/ralph/)

## Issues & Feedback

Found a bug or have a suggestion? [Submit an issue](https://github.com/jsegov/shipspec-claude-code-plugin/issues)

## License

MIT
