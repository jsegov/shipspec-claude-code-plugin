---
name: production-signals
description: This skill should be used when the user asks to "detect tech stack for production", "gather codebase signals", "analyze production infrastructure", "check deployment configuration", "identify project setup", or when preparing for production readiness analysis by understanding the current codebase state.
version: 0.1.0
allowed-tools: Read, Glob, Grep, Bash(find:*), Bash(head:*), Bash(cat:*), Bash(ls:*), Bash(wc:*)
---

# Production Signals Detection

Detect codebase signals relevant to production readiness assessment. This skill provides patterns for identifying the tech stack, infrastructure configuration, and development practices in a project.

## Signal Categories

Gather signals across these categories to inform production readiness analysis.

### 1. Package Manager and Dependencies

Identify the package manager and dependency management approach.

**Node.js ecosystem:**
- `package.json` - npm/yarn/pnpm/bun project
- `package-lock.json` - npm lockfile
- `yarn.lock` - Yarn lockfile
- `pnpm-lock.yaml` - pnpm lockfile
- `bun.lockb` - Bun lockfile

**Python ecosystem:**
- `pyproject.toml` - Modern Python project (Poetry, PDM, Hatch)
- `requirements.txt` - pip dependencies
- `Pipfile` / `Pipfile.lock` - Pipenv
- `poetry.lock` - Poetry lockfile
- `setup.py` / `setup.cfg` - Legacy setuptools

**Other languages:**
- `go.mod` / `go.sum` - Go modules
- `Cargo.toml` / `Cargo.lock` - Rust cargo
- `Gemfile` / `Gemfile.lock` - Ruby bundler
- `pom.xml` - Java Maven
- `build.gradle` - Java Gradle

### 2. CI/CD Configuration

Identify continuous integration and deployment setup.

**GitHub Actions:** `.github/workflows/*.yml`
**GitLab CI:** `.gitlab-ci.yml`
**CircleCI:** `.circleci/config.yml`
**Jenkins:** `Jenkinsfile`
**Azure Pipelines:** `azure-pipelines.yml`
**Bitbucket:** `bitbucket-pipelines.yml`
**Travis CI:** `.travis.yml`

Read CI configuration to understand:
- Build steps and test commands
- Deployment targets
- Environment variables used
- Code quality checks

### 3. Test Configuration

Identify testing frameworks and coverage setup.

**JavaScript/TypeScript:**
- `jest.config.*` - Jest
- `vitest.config.*` - Vitest
- `cypress.config.*` - Cypress E2E
- `playwright.config.*` - Playwright E2E
- `.mocharc.*` - Mocha

**Python:**
- `pytest.ini` or `[tool.pytest]` in `pyproject.toml`
- `conftest.py` - pytest fixtures
- `tox.ini` - tox testing

**Coverage indicators:**
- `.nyc_output/` - Istanbul/nyc coverage
- `coverage/` - Generic coverage directory
- `htmlcov/` - Python coverage reports
- `codecov.yml` - Codecov integration
- `.coveragerc` - Coverage.py config

Count test files to estimate coverage:
- `*.test.ts`, `*.spec.ts` - TypeScript tests
- `test_*.py`, `*_test.py` - Python tests
- `*_test.go` - Go tests

### 4. Container and Orchestration

Identify containerization and orchestration setup.

**Docker:**
- `Dockerfile` - Container build
- `docker-compose.yml` / `docker-compose.yaml` - Multi-container
- `.dockerignore` - Build exclusions

**Kubernetes:**
- `k8s/`, `kubernetes/`, `manifests/` directories
- `*.yaml` files with `kind: Deployment`, `kind: Service`
- `kustomization.yaml` - Kustomize
- `Chart.yaml` - Helm charts

**Other orchestration:**
- `ecs-task-definition.json` - AWS ECS
- `app.yaml` - Google App Engine
- `fly.toml` - Fly.io
- `vercel.json` - Vercel
- `netlify.toml` - Netlify

### 5. Infrastructure as Code

Identify IaC tools and cloud configuration.

**Terraform:** `*.tf` files, `terraform/` directory
**Pulumi:** `Pulumi.yaml`, `Pulumi.*.yaml`
**CloudFormation:** `*.template.json`, `*.template.yaml`
**CDK:** `cdk.json`, `cdk.context.json`
**Serverless:** `serverless.yml`
**SAM:** `template.yaml` with `AWSTemplateFormatVersion`
**Bicep:** `*.bicep` files

### 6. Configuration and Secrets

Identify environment and secret management.

**Environment files:**
- `.env` - Local environment (should be gitignored)
- `.env.example` / `.env.sample` - Example configuration
- `.env.development`, `.env.staging`, `.env.production` - Environment-specific

**Secret management indicators:**
- HashiCorp Vault references
- AWS Secrets Manager / Parameter Store
- `sops` encrypted files
- `sealed-secrets` for Kubernetes
- `doppler.yaml` - Doppler

**Configuration patterns:**
- `config/` directory
- `settings.py`, `config.ts`
- Environment variable usage patterns

### 7. Monitoring and Observability

Identify logging, monitoring, and APM setup.

**Logging libraries:**
- `winston`, `pino`, `bunyan` (Node.js)
- `loguru`, `structlog` (Python)
- `zap`, `logrus` (Go)
- `log4j`, `slf4j` (Java)

**APM and monitoring:**
- Datadog (`dd-trace`, `datadog.yaml`)
- New Relic (`newrelic.js`, `newrelic.yml`)
- Sentry (`sentry.*.ts`, `@sentry/*`)
- Prometheus (`prometheus.yml`, `/metrics` endpoint)
- OpenTelemetry (`@opentelemetry/*`)

**Health checks:**
- `/health`, `/ready`, `/live` endpoints
- Health check middleware

### 8. Security Configuration

Identify security-related setup.

**Authentication libraries:**
- `passport` (Node.js)
- `next-auth` / `@auth/*` (Next.js)
- `clerk`, `auth0`, `firebase-admin`
- `python-jose`, `PyJWT` (Python)

**Security middleware:**
- `helmet` (Node.js security headers)
- CORS configuration
- CSRF protection
- Rate limiting (`express-rate-limit`, etc.)

**Security files:**
- `SECURITY.md` - Security policy
- `.snyk` - Snyk configuration
- `security.txt` - Well-known security contact

## Output Format

Structure detected signals as:

```markdown
## Production Signals: [Project Name]

**Detected:** [Date]

### Tech Stack
- **Primary Language:** [TypeScript/Python/Go/etc.]
- **Runtime:** [Node.js 20/Python 3.12/etc.]
- **Framework:** [Next.js/FastAPI/Gin/etc.]
- **Package Manager:** [npm/pnpm/pip/etc.]
- **Lock File Present:** [Yes/No]

### Build and Deploy
- **CI/CD Platform:** [GitHub Actions/GitLab CI/etc.]
- **Container:** [Docker/None]
- **Orchestration:** [Kubernetes/ECS/Vercel/None]
- **IaC Tool:** [Terraform/Pulumi/None]

### Quality Signals
- **Test Framework:** [Jest/Vitest/Pytest/etc.]
- **Test Files Found:** [count]
- **Source-to-Test Ratio:** [X:Y]
- **Linting:** [ESLint/Prettier/Ruff/etc.]
- **Type Checking:** [TypeScript strict/mypy/etc.]

### Security Signals
- **Auth Library:** [NextAuth/Passport/etc.]
- **Secret Management:** [Vault/AWS Secrets/env files]
- **Security Headers:** [Helmet/custom/none]
- **SECURITY.md Present:** [Yes/No]

### Observability
- **Logging Library:** [Winston/Pino/etc.]
- **APM/Monitoring:** [Datadog/Sentry/etc.]
- **Health Endpoints:** [Found/Not found]

### Configuration
- **Environment Files:** [.env.example found/missing]
- **Environment Separation:** [Yes/No]
- **Config Pattern:** [Environment vars/Config files]

### Risk Indicators
- [ ] Lock file missing
- [ ] No CI/CD detected
- [ ] No tests found
- [ ] No .env.example
- [ ] No SECURITY.md
```

## Usage in Production Analysis

After gathering signals, use them to:

1. **Focus analysis** - Prioritize categories based on stack
2. **Identify gaps** - Missing signals indicate potential issues
3. **Inform interview** - Ask targeted questions based on detected setup
4. **Set context** - Ground compliance requirements in actual infrastructure

## Quality Checklist

Before completing signal detection:

- [ ] Package manager and lock file status identified
- [ ] CI/CD configuration checked
- [ ] Test setup documented
- [ ] Container/orchestration detected
- [ ] IaC presence noted
- [ ] Security configuration identified
- [ ] Observability tools noted
- [ ] Risk indicators flagged
