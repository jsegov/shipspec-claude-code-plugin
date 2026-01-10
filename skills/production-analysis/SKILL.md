---
name: production-analysis
description: This skill should be used when performing deep code analysis for production readiness, identifying security vulnerabilities, compliance gaps, code quality issues, and configuration problems. Use when asked to "analyze code for security", "check SOC 2 compliance", "find vulnerabilities", "identify production blockers", or "audit code quality".
version: 0.1.0
allowed-tools: Read, Glob, Grep, Bash(find:*), Bash(head:*), Bash(cat:*), Bash(wc:*)
---

# Production Analysis Patterns

Code analysis patterns for identifying production readiness issues without external SAST scanners. Use these patterns with Grep and Read tools to perform comprehensive code analysis.

## Severity Definitions

Apply these severity levels consistently across all findings.

| Severity | Definition | Timeline | Examples |
|----------|------------|----------|----------|
| **Critical** | Immediate security risk, data exposure likely, or complete compliance blocker | Block deployment | Hardcoded prod credentials, SQL injection, exposed API keys |
| **High** | Significant risk that should block production | Fix before production | Missing authentication, no input validation, insecure direct object refs |
| **Medium** | Best practice violation or moderate risk | Fix within sprint | Missing rate limiting, insufficient logging, outdated deps with CVEs |
| **Low** | Code smell or minor improvement | Fix when convenient | Type safety issues, missing docs, verbose logging |
| **Info** | Observation or recommendation | Document only | Architecture notes, optimization suggestions |

## Analysis Categories

### Category 1: Security

#### 1.1 Hardcoded Credentials (Critical)

Search for secrets in source code:

```
# Password assignments
password\s*[=:]\s*['"][^'"]+['"]

# API keys
api[_-]?key\s*[=:]\s*['"][^'"]+['"]

# Secret values
secret\s*[=:]\s*['"][^'"]+['"]

# Long tokens (likely credentials)
token\s*[=:]\s*['"][A-Za-z0-9_-]{20,}['"]

# AWS credentials
AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY

# Database connection strings with credentials
(postgres|mysql|mongodb)://[^:]+:[^@]+@
```

**Compliance:** OWASP A07:2021 (Identification and Authentication Failures), SOC 2 CC6.1

#### 1.2 SQL Injection (Critical)

Search for unsafe query construction:

```
# JavaScript/TypeScript string interpolation in queries
query.*\`.*\${
execute.*\${
\.raw\s*\(

# Python f-strings in queries
execute.*f".*{
execute.*%.*%

# Go unsafe formatting
fmt.Sprintf.*SELECT|INSERT|UPDATE|DELETE
```

**Compliance:** OWASP A03:2021 (Injection)

#### 1.3 XSS Vulnerabilities (High)

Search for unsafe HTML rendering:

```
# React dangerous HTML
dangerouslySetInnerHTML

# Direct innerHTML assignment
innerHTML\s*=

# Vue v-html directive
v-html=

# Angular bypass trust
bypassSecurityTrust
```

**Compliance:** OWASP A03:2021 (Injection)

#### 1.4 Authentication Issues (High)

Search for auth bypasses or weak auth:

```
# TODO comments about auth
// TODO.*auth|# TODO.*auth

# Skip validation patterns
skip.*valid|bypass.*auth

# Disabled verification
verify\s*=\s*False|verify:\s*false

# JWT algorithm none
algorithm.*none|alg.*none
```

**Compliance:** OWASP A01:2021 (Broken Access Control), A07:2021

#### 1.5 CORS Misconfiguration (Medium)

Search for overly permissive CORS:

```
# Allow all origins
cors.*origin.*\*|Access-Control-Allow-Origin.*\*

# Credentials with wildcard (very dangerous)
credentials.*true.*origin.*\*
```

**Compliance:** OWASP A05:2021 (Security Misconfiguration)

### Category 2: SOC 2 Compliance

#### 2.1 Logging and Audit (CC7.2)

Check for logging presence:

```
# Files without logging
# Use Grep with -L flag to find files missing logging

# Logging configuration
log.*level|LOG_LEVEL

# Audit trail patterns
audit|action.*log
```

Search for audit trail implementation:
- User action logging
- Authentication event logging
- Data access logging
- Administrative action logging

#### 2.2 Access Control (CC6.1)

Search for authorization patterns:

```
# Role-based access
role|permission|authorize|isAdmin|canAccess

# RBAC/ACL files
*auth*|*rbac*|*acl*|*permission*
```

Verify:
- Role definitions exist
- Permission checks on endpoints
- Admin functions are protected

#### 2.3 Encryption (CC6.7)

Search for encryption usage:

```
# Encryption libraries
encrypt|decrypt|bcrypt|argon2|scrypt

# Secure protocols
https://|TLS|SSL

# Crypto operations
crypto\.|hashlib\.|SHA256|AES
```

Verify:
- Passwords are hashed (not encrypted)
- Data at rest encryption
- TLS for data in transit

#### 2.4 Change Management (CC8.1)

Check for change control:

```
# CI/CD presence
.github/workflows|.gitlab-ci|Jenkinsfile

# Code review requirements
review|approve|CODEOWNERS

# Changelog maintenance
CHANGELOG|changelog
```

### Category 3: Code Quality

#### 3.1 Empty Error Handling (Medium)

Search for swallowed errors:

```
# JavaScript/TypeScript empty catch
catch\s*\(\s*\w*\s*\)\s*\{\s*\}

# Python bare except
except:\s*$|except Exception:\s*$

# Go ignored errors
if err != nil \{\s*$
```

#### 3.2 Technical Debt Indicators (Low)

Search for debt markers:

```
# TODO/FIXME comments
TODO|FIXME|HACK|XXX|TEMP

# Linting disables
@ts-ignore|@ts-nocheck|eslint-disable|noqa

# Type safety escapes
: any|as any
```

#### 3.3 Dead Code Indicators (Low)

Search for commented-out code:

```
# Commented console/print statements
^\s*//.*console|^\s*#.*print

# Backup files
*.bak|*.old|*_backup*
```

### Category 4: Dependencies

#### 4.1 Lock File Status (High)

Verify lock files exist and are current:
- `package-lock.json` for npm
- `yarn.lock` for Yarn
- `pnpm-lock.yaml` for pnpm
- `poetry.lock` for Poetry
- `Pipfile.lock` for Pipenv

Missing lock files = non-deterministic builds.

#### 4.2 Risky Patterns (Medium)

Search for dangerous code patterns:

```
# Dynamic code execution
eval\(|Function\(|exec\(

# Unsafe deserialization
pickle\.load|yaml\.load\(.*Loader
```

### Category 5: Testing

#### 5.1 Test Coverage (Medium)

Calculate test-to-source ratio:

```bash
# Count source files
find . -name "*.ts" -path "*/src/*" | wc -l

# Count test files
find . -name "*.test.ts" -o -name "*.spec.ts" | wc -l

# Ratio < 0.5 suggests low coverage
```

Check for test types:
- Unit tests (`*.test.ts`, `test_*.py`)
- Integration tests (`*integration*`, `*e2e*`)
- End-to-end tests (`cypress/`, `playwright/`)

#### 5.2 Test Configuration (Low)

Verify testing is configured:

```
# Coverage configuration
coverage|collectCoverage

# CI test integration
test|coverage in CI config
```

### Category 6: Configuration

#### 6.1 Secret Exposure Risk (Critical)

Check for secrets in tracked files:

```
# .env files should be gitignored
.gitignore should contain: .env

# Secrets in config files
password|secret|key|token in *.json, *.yaml
```

#### 6.2 Environment Separation (Medium)

Verify environment-specific configs:

```
# Environment files
.env.development|.env.staging|.env.production

# Environment variable usage
NODE_ENV|ENVIRONMENT|APP_ENV
```

## Finding Template

Document each finding using this structure:

```markdown
### FINDING-XXX: [Clear Title]

**Severity:** Critical | High | Medium | Low | Info
**Category:** Security | SOC2 | Code-Quality | Dependencies | Testing | Configuration

**Description:**
[What the issue is and why it matters for production. Include business impact.]

**Evidence:**
```
[Code snippet or search result showing the issue]
```
- File: `path/to/file.ts:line`
- Pattern: `[grep pattern used]`

**Compliance Reference:**
- [OWASP A01:2021 - Broken Access Control]
- [SOC 2 CC6.1 - Logical and Physical Access]

**Risk:**
[What could happen if this is not addressed before production]

**Recommendation:**
[Specific steps to remediate this issue]

**Effort:** [1-8 story points]
```

## Analysis Workflow

Execute analysis in this order for efficiency:

1. **Critical patterns first** - Security and secret exposure
2. **High severity next** - Auth, injection, compliance blockers
3. **Medium severity** - Code quality, testing gaps
4. **Low/Info last** - Style issues, documentation

## Deduplication

When multiple files have the same issue:
- Group into a single finding
- List all affected files in evidence
- Adjust severity based on scope (more files = higher impact)

## False Positive Filtering

Before reporting, verify:
- Is this in test/mock/example code? (may be acceptable)
- Is there mitigation elsewhere in the codebase?
- Is the pattern actually used at runtime?
- Is the severity appropriate for this project type?

## Quality Checklist

Before completing analysis:

- [ ] All six categories analyzed
- [ ] Each finding has evidence with file:line
- [ ] Severity levels are consistent
- [ ] Compliance references are accurate
- [ ] Recommendations are actionable
- [ ] No obvious false positives included
- [ ] Findings are deduplicated
