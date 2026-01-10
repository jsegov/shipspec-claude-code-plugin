# ShipSpec Planning Plugin

AI-assisted feature planning and production readiness for Claude Code. Transform ideas into well-structured PRDs, technical designs, and implementation tasks. Analyze codebases for security vulnerabilities, compliance gaps, and production blockers.

## Features

- **Conversational PRD Gathering**: Structured interview process to extract clear requirements
- **Codebase-Aware Design**: Technical designs grounded in your existing architecture
- **Agent-Ready Tasks**: Implementation tasks with detailed prompts for coding agents
- **Progressive Workflow**: Each phase builds on the previous
- **Production Readiness Analysis**: Comprehensive code analysis for security, SOC 2, and deployment
- **Fix Prompts Generation**: Agent-ready prompts to remediate identified issues

## Installation

### From Local Directory

```bash
# Add as a local marketplace
/plugin marketplace add /path/to/shipspec

# Install the plugin
/plugin install shipspec@local
```

### From GitHub (when published)

```bash
/plugin marketplace add shipspec/planning-plugin
/plugin install shipspec@shipspec
```

## Usage

### Quick Start

```bash
# Start planning a new feature
/plan my-feature

# Generate PRD after requirements gathering
/generate-prd my-feature

# Generate technical design
/generate-sdd my-feature

# Generate implementation tasks
/generate-tasks my-feature

# Analyze codebase for production readiness
/productionalize my-analysis
```

### Full Workflow

1. **Start Planning**
   ```
   /plan user-authentication
   ```
   This will:
   - Create `docs/planning/user-authentication/` directory
   - Extract codebase context
   - Start a guided requirements conversation

2. **Gather Requirements**
   The PRD Gatherer agent will ask questions about:
   - The problem you're solving
   - Target users
   - Must-have vs nice-to-have features
   - Technical constraints

3. **Generate PRD**
   ```
   /generate-prd user-authentication
   ```
   Creates a structured PRD with numbered requirements.

4. **Generate Design**
   ```
   /generate-sdd user-authentication
   ```
   Creates a technical design document with:
   - Architecture decisions
   - API specifications
   - Data models
   - Component designs

5. **Generate Tasks**
   ```
   /generate-tasks user-authentication
   ```
   Creates implementation tasks with:
   - Story point estimates
   - Dependencies
   - Detailed agent prompts
   - Acceptance criteria

### Production Readiness Workflow

1. **Start Analysis**
   ```
   /productionalize pre-launch
   ```
   This will:
   - Create `docs/planning/pre-launch/` directory
   - Detect tech stack and infrastructure
   - Start a guided interview about concerns

2. **Gather Context**
   The Production Interviewer agent will ask about:
   - Primary concerns (security, performance, compliance)
   - Deployment target (AWS, GCP, Azure, etc.)
   - Compliance requirements (SOC 2, HIPAA, PCI-DSS, GDPR)
   - Timeline and constraints

3. **Deep Analysis**
   The Production Analyzer examines six categories:
   - **Security**: Hardcoded secrets, injection vulnerabilities, auth issues
   - **SOC 2**: Logging, access control, encryption, change management
   - **Code Quality**: Error handling, technical debt, type safety
   - **Dependencies**: Lock files, risky patterns
   - **Testing**: Coverage, test types, CI integration
   - **Configuration**: Secret management, environment separation

4. **Review Reports**
   ```
   docs/planning/pre-launch/
   ├── production-signals.md   # Detected tech stack
   ├── production-report.md    # Full analysis report
   └── fix-prompts.md          # Agent-ready fix prompts
   ```

5. **Fix Issues**
   Copy prompts from `fix-prompts.md` and paste into Claude Code to remediate findings.

6. **Re-verify**
   ```
   /productionalize pre-launch-v2
   ```
   Run again after fixes to verify remediation.

## Output Structure

After completing the workflow:

```
docs/planning/your-feature/
├── context.md   # Codebase context and patterns
├── PRD.md       # Product Requirements Document
├── SDD.md       # Software Design Document
└── TASKS.md     # Implementation tasks with agent prompts
```

## Commands

| Command | Description |
|---------|-------------|
| `/plan <name>` | Start planning workflow |
| `/generate-prd <name>` | Generate PRD from conversation |
| `/generate-sdd <name>` | Generate design from PRD |
| `/generate-tasks <name>` | Generate tasks from PRD + SDD |
| `/productionalize <name>` | Analyze codebase for production readiness |

## Agents

| Agent | Purpose | Auto-Invoked When |
|-------|---------|-------------------|
| `prd-gatherer` | Requirements elicitation | Planning features, writing specs |
| `design-architect` | Technical design | Architecture decisions, API design |
| `task-planner` | Task decomposition | Breaking down features |
| `production-interviewer` | Production context gathering | Checking production readiness |
| `production-analyzer` | Deep code analysis | Security/compliance analysis |
| `production-reporter` | Report generation | Creating production reports |

## Skills

| Skill | Purpose |
|-------|---------|
| `codebase-context` | Extract tech stack and patterns |
| `prd-template` | PRD structure and best practices |
| `sdd-template` | Atlassian 8-section design template |
| `agent-prompts` | Task prompt generation patterns |
| `production-signals` | Detect tech stack and infrastructure for production |
| `production-analysis` | Code analysis patterns for security and compliance |

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

## Production Analysis Severity

Findings from production analysis use these severity levels:

| Severity | Definition | Action |
|----------|------------|--------|
| Critical | Immediate security risk, data exposure likely | Block deployment |
| High | Significant risk, should block production | Fix before production |
| Medium | Best practice violation, moderate risk | Fix within sprint |
| Low | Code smell, minor improvement | Fix when convenient |
| Info | Observation or recommendation | Document only |

## Analysis Categories

Production analysis covers six categories:

| Category | What It Checks | Compliance References |
|----------|----------------|----------------------|
| Security | Secrets, injection, XSS, auth | OWASP Top 10 |
| SOC 2 | Logging, access control, encryption | CC6.1, CC6.7, CC7.2, CC8.1 |
| Code Quality | Error handling, debt, type safety | Best practices |
| Dependencies | Lock files, risky patterns | Supply chain security |
| Testing | Coverage, test types, CI | Quality assurance |
| Configuration | Secrets, env separation | Secure configuration |

## Tips

- **Start with `/plan`**: Don't skip requirements gathering
- **Review each document**: Make adjustments before moving to the next phase
- **Use the context**: The codebase analysis helps generate better designs
- **Follow the phases**: Tasks are ordered by dependency
- **Run `/productionalize` before launch**: Catch security issues early
- **Use fix prompts**: Copy prompts from fix-prompts.md to remediate issues quickly

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT
