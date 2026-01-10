---
name: prd-template
description: This skill should be used when the user asks to "create a PRD", "write requirements", "document a feature", "generate product spec", "define requirements", "write feature specifications", or when creating PRD documents from gathered requirements.
version: 0.1.0
---

# PRD Template Knowledge

Create well-structured Product Requirements Documents following industry best practices.

## Document Structure

A comprehensive PRD includes these sections:

### 1. Overview (Required)

```markdown
## 1. Overview

### 1.1 Problem Statement
[2-3 sentences describing the problem users face]

### 1.2 Proposed Solution
[High-level description of what we're building]

### 1.3 Target Users
[Who will use this feature and their characteristics]

### 1.4 Success Metrics
- [Measurable metric 1]
- [Measurable metric 2]
```

### 2. Requirements (Required)

Organize requirements with consistent IDs and categories:

```markdown
## 2. Requirements

### 2.1 Core Features

**REQ-001: [Requirement Title]**
- Description: The system shall [specific, testable behavior]
- Priority: High
- Rationale: [Why this matters]

**REQ-002: [Requirement Title]**
- Description: The system shall [specific, testable behavior]
- Priority: High
- Rationale: [Why this matters]

### 2.2 User Interface

**REQ-010: [UI Requirement]**
- Description: [Specific UI behavior]
- Priority: Medium

### 2.3 Data & Storage

**REQ-020: [Data Requirement]**
- Description: [Data handling behavior]
- Priority: High
```

**Requirement Categories:**
- Core Features (REQ-001 to REQ-009)
- User Interface (REQ-010 to REQ-019)
- Data & Storage (REQ-020 to REQ-029)
- Integration (REQ-030 to REQ-039)
- Performance (REQ-040 to REQ-049)
- Security (REQ-050 to REQ-059)

### 3. User Stories (Required)

```markdown
## 3. User Stories

### 3.1 Primary Flow
As a [user type], I want to [goal] so that [benefit].

**Acceptance Criteria:**
- Given [context], when [action], then [result]
- Given [context], when [action], then [result]

### 3.2 [Secondary Flow]
As a [user type], I want to [goal] so that [benefit].
```

### 4. Technical Considerations (Optional but Recommended)

```markdown
## 4. Technical Considerations

### 4.1 Constraints
- [Technical constraint 1]
- [Technical constraint 2]

### 4.2 Dependencies
- [Dependency on system X]
- [Dependency on team Y]

### 4.3 Known Technical Debt
- [Relevant existing debt that affects this feature]
```

### 5. Out of Scope (Required)

```markdown
## 5. Out of Scope

The following are explicitly NOT included in this version:
- [Feature X] - Deferred to v2
- [Feature Y] - Requires separate initiative
- [Feature Z] - Out of product scope
```

### 6. Open Questions (If Any)

```markdown
## 6. Open Questions

1. [Question requiring stakeholder input]
   - Options: A, B, C
   - Recommendation: [if any]

2. [Technical question]
   - Blocked by: [dependency]
```

## Quality Checklist

Before finalizing a PRD, verify:

- [ ] Every requirement uses "shall" language and is testable
- [ ] No ambiguous terms ("fast", "easy", "intuitive", "user-friendly")
- [ ] All requirements have unique IDs (REQ-XXX)
- [ ] Priorities are assigned (High/Medium/Low)
- [ ] Success metrics are measurable
- [ ] Out of scope section exists and is specific
- [ ] User stories have acceptance criteria
- [ ] Dependencies are identified

## Anti-Patterns to Avoid

**Vague requirements:**
- "The system should be fast"
- "Users can easily manage their data"

**Specific requirements:**
- "API responses shall complete within 200ms at p95"
- "Users shall be able to export data as CSV with a single click"

**Solution-focused:**
- "Use Redis for caching"

**Problem-focused:**
- "Frequently accessed data shall be cached to reduce database load"

## Examples

For a complete PRD example, see `examples/sample-prd.md`.
