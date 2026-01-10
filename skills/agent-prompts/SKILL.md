---
name: agent-prompts
description: This skill should be used when the user asks to "generate tasks", "create implementation plan", "break down feature", "write agent prompts", "decompose into tasks", "create work items", or when creating agent-ready task descriptions from PRD and SDD documents.
version: 0.1.0
---

# Agent Prompt Generation

Create structured task prompts that coding agents can execute effectively.

## Task Prompt Template

Each task should include this structure:

```markdown
# Task: [TASK-XXX] [Clear, Action-Oriented Title]

## Context
[2-3 sentences explaining where this task fits in the larger system and why it matters]

## Requirements
- [ ] [Specific, verifiable requirement 1]
- [ ] [Specific, verifiable requirement 2]
- [ ] [Specific, verifiable requirement 3]

## Technical Approach

### Suggested Implementation
[Step-by-step guidance based on codebase patterns]

### Files to Create/Modify
- `path/to/new-file.ts` - [Purpose]
- `path/to/existing-file.ts` - [What changes]

### Key Interfaces
```typescript
// Define expected interfaces
interface ExpectedInput {
  field: string;
}

interface ExpectedOutput {
  result: boolean;
}
```

## Constraints
- Follow existing patterns in `[reference file]`
- Use `[specific library]` for `[purpose]`
- Do not modify `[protected area]`
- Maintain backward compatibility with `[existing API]`

## Testing Requirements
- Unit test: [What to test, expected coverage]
- Integration test: [End-to-end scenario to verify]
- Edge cases: [Specific edge cases to handle]

## Acceptance Criteria
- [ ] [Criterion 1 - must be verifiable]
- [ ] [Criterion 2 - must be verifiable]
- [ ] All tests pass
- [ ] No TypeScript errors
- [ ] Linting passes

## Dependencies
- Depends on: [TASK-XXX] (must complete first)
- Blocks: [TASK-YYY] (cannot start until this completes)

## References
- Design Doc: Section X.Y
- PRD: REQ-XXX, REQ-YYY
- Similar implementation: `path/to/similar/code.ts`

## Estimated Effort
- Story Points: [1/2/3/5/8]
```

## Task Sizing Guidelines

| Points | Description | Duration | Example |
|--------|-------------|----------|---------|
| 1 | Trivial change | < 2 hours | Config update, copy change |
| 2 | Small task | 2-4 hours | Single function, simple component |
| 3 | Medium task | 4-8 hours | Multiple functions, moderate complexity |
| 5 | Large task | 1-2 days | Significant feature piece |
| 8 | Complex task | 2-3 days | Cross-cutting, multiple systems |

**Rule:** If a task would be larger than 8 points, break it down.

## Task Categories

Assign each task to exactly one category:

| Category | Description | Examples |
|----------|-------------|----------|
| `feature` | New user-facing functionality | New UI component, API endpoint |
| `infrastructure` | Backend systems, tooling | Database migration, CI setup |
| `testing` | Test coverage | Unit tests, E2E tests |
| `documentation` | Docs and comments | API docs, README updates |
| `security` | Auth, permissions | Input validation, auth flow |
| `performance` | Optimization | Caching, query optimization |

## Dependency Mapping

When generating tasks, identify:

1. **Hard Dependencies (Blocks)**
   - Task X must complete before Task Y can start
   - Usually: schema → API → UI

2. **Parallel Tasks**
   - Can be worked on simultaneously
   - Usually: independent components, tests

3. **Critical Path**
   - The longest chain of dependent tasks
   - Determines minimum project duration

## Execution Phases

Group tasks into logical phases:

```markdown
### Phase 1: Foundation
- TASK-001: Database schema
- TASK-002: Base types and interfaces
[These must complete first]

### Phase 2: Core Implementation
- TASK-003: API endpoints (depends on 001, 002)
- TASK-004: Service layer (depends on 001, 002)
[Can be parallelized]

### Phase 3: UI Layer
- TASK-005: Components (depends on 003)
- TASK-006: Pages (depends on 005)

### Phase 4: Polish
- TASK-007: Tests (depends on 003, 004, 005)
- TASK-008: Documentation (depends on all)
```

## Output Format for Task List

When generating a complete task list:

```markdown
# Implementation Tasks: [Feature Name]

## Summary
- Total Tasks: X
- Total Story Points: Y
- Estimated Duration: Z sessions
- Critical Path: TASK-001 → TASK-003 → TASK-005

## Requirement Coverage
| Requirement | Task(s) |
|-------------|---------|
| REQ-001 | TASK-001, TASK-003 |
| REQ-002 | TASK-002, TASK-004 |

## Phase 1: [Phase Name]
[Task details...]

## Phase 2: [Phase Name]
[Task details...]
```

## Quality Checklist

Before finalizing tasks:

- [ ] Every task has clear acceptance criteria
- [ ] Dependencies form a valid DAG (no cycles)
- [ ] No task exceeds 8 story points
- [ ] Every requirement (REQ-XXX) maps to at least one task
- [ ] Tests are included as explicit tasks
- [ ] File paths reference actual codebase structure

## Typical Decomposition Pattern

```
Feature X
├── TASK-001: Database schema/migrations (infrastructure)
├── TASK-002: Type definitions and interfaces (infrastructure)
├── TASK-003: API endpoint - create (feature)
├── TASK-004: API endpoint - read (feature)
├── TASK-005: API endpoint - update (feature)
├── TASK-006: API endpoint - delete (feature)
├── TASK-007: UI component - form (feature)
├── TASK-008: UI component - list (feature)
├── TASK-009: Unit tests (testing)
├── TASK-010: Integration tests (testing)
└── TASK-011: Documentation (documentation)
```
