---
description: Analyze codebase for production readiness and generate remediation tasks
argument-hint: <context-name>
allowed-tools: Read, Glob, Grep, Write, Bash(git status), Bash(ls:*), Bash(mkdir:*), Bash(find:*), Bash(head:*), Bash(cat:*), Bash(wc:*), WebSearch, WebFetch
---

# Production Readiness Review: $ARGUMENTS

Analyze the codebase for production readiness, identifying security vulnerabilities, compliance gaps, and code quality issues. Generate structured remediation tasks that can be implemented using `/implement-next-task`.

## Step 1: Setup Output Directory

Create the output directory for analysis results:

```bash
mkdir -p .shipspec/planning/$ARGUMENTS
```

## Step 2: Gather Codebase Signals

Use the production-signals skill to detect:
- Tech stack and runtime
- Package manager and lock files
- CI/CD configuration
- Test framework and coverage
- Container and orchestration setup
- Infrastructure as Code
- Security configuration
- Monitoring and observability

Save signals to: `.shipspec/planning/$ARGUMENTS/production-signals.md`

## Step 3: Gather Production Context

Delegate to the `production-interviewer` subagent to understand:
- Primary concerns (security, performance, compliance, reliability)
- Deployment target (AWS, GCP, Azure, Vercel, on-prem)
- Compliance requirements (SOC 2, HIPAA, PCI-DSS, GDPR)
- Timeline and constraints

Begin with:
> "I'll help you assess production readiness. Let me ask a few questions to understand your specific concerns and requirements."

The interviewer will:
- Ask focused questions about concerns and constraints
- Research relevant compliance standards
- Produce a structured context summary

## Step 4: Deep Code Analysis

Delegate to the `production-analyzer` subagent to perform analysis across six categories:

1. **Security** - Hardcoded secrets, injection vulnerabilities, auth issues
2. **SOC 2 Compliance** - Logging, access control, encryption, change management
3. **Code Quality** - Error handling, technical debt, type safety
4. **Dependencies** - Lock files, risky patterns, version management
5. **Testing** - Coverage, test types, CI integration
6. **Configuration** - Secret management, environment separation

The analyzer will:
- Search for critical patterns using Grep
- Read files for context and verification
- Filter false positives
- Document findings with evidence and severity

## Step 5: Generate Reports and Tasks

Delegate to the `production-reporter` subagent to generate:

1. **production-report.md** - Executive summary, findings by category, compliance matrix, remediation roadmap
2. **TASKS.md** - Structured remediation tasks (same format as feature-planning tasks)

Save to: `.shipspec/planning/$ARGUMENTS/`

## Step 6: Present Results

After report generation, present a summary:

> **Production Readiness Review Complete**
>
> **Output files:**
> - `.shipspec/planning/$ARGUMENTS/production-signals.md` - Detected tech stack and infrastructure
> - `.shipspec/planning/$ARGUMENTS/production-report.md` - Full analysis report
> - `.shipspec/planning/$ARGUMENTS/TASKS.md` - Structured remediation tasks
>
> **Summary:**
> - Overall Status: [Ready/Ready with Reservations/Not Ready]
> - Critical Issues: [count]
> - High Priority: [count]
> - Total Findings: [count]
> - Estimated Fix Effort: [story points]
>
> **Recommended Next Steps:**
> 1. Review production-report.md with stakeholders
> 2. Run `/implement-next-task $ARGUMENTS` to start fixing issues
> 3. Re-run `/production-readiness-review $ARGUMENTS` after fixes to verify

## Pre-loaded Context

Current git status:
!`git status --short 2>/dev/null | head -10 || echo "Not a git repository"`

Project structure:
!`ls -la 2>/dev/null | head -15 || echo "Cannot list directory"`

Package files present:
!`ls package.json pyproject.toml go.mod Cargo.toml 2>/dev/null || echo "No package files found"`
