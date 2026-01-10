# SDD Section Deep Dive

## Writing Effective System Overview

The System Overview should answer:
1. What does this system do?
2. Who uses it?
3. What systems does it interact with?

**Good Example:**
> The Authentication Service handles user identity verification and session management. It integrates with the User Service for profile data and the Notification Service for security alerts. Client applications (web, mobile, API) interact with it via REST endpoints.

**Bad Example:**
> This system does authentication.

## Data Model Best Practices

Always include:
- Field types with constraints
- Nullability
- Indexes
- Foreign key relationships
- Default values

```typescript
// Good
interface User {
  id: string;              // UUID, PK, indexed
  email: string;           // VARCHAR(255), unique, not null
  passwordHash: string;    // VARCHAR(255), not null
  role: 'user' | 'admin';  // ENUM, default 'user'
  createdAt: Date;         // TIMESTAMP, default now(), indexed
  deletedAt: Date | null;  // TIMESTAMP, nullable (soft delete)
}
```

## API Design Guidelines

1. Use RESTful conventions
2. Version your APIs (`/api/v1/`)
3. Document all error responses
4. Include request/response examples

```typescript
// Document both success and error cases
/**
 * POST /api/v1/users
 *
 * Success (201):
 * { id: "uuid", email: "user@example.com", createdAt: "2025-01-10T00:00:00Z" }
 *
 * Error (400):
 * { error: "VALIDATION_ERROR", message: "Email is required", field: "email" }
 *
 * Error (409):
 * { error: "CONFLICT", message: "Email already exists" }
 */
```

## Sequence Diagram Notation (ASCII)

For complex flows, use ASCII sequence diagrams:

```
Client          API Gateway       Auth Service      Database
  |                 |                  |               |
  |-- Login Req -->|                  |               |
  |                 |-- Validate -->  |               |
  |                 |                  |-- Query -->  |
  |                 |                  |<-- User --   |
  |                 |<-- Token ----   |               |
  |<-- Response ---|                  |               |
```

## Component Diagram Patterns

### Layered Architecture
```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (React Components, API Handlers)   │
├─────────────────────────────────────┤
│            Business Layer           │
│    (Services, Domain Logic)         │
├─────────────────────────────────────┤
│             Data Layer              │
│   (Repositories, ORM, Database)     │
└─────────────────────────────────────┘
```

### Microservices Pattern
```
┌──────────┐    ┌──────────┐    ┌──────────┐
│   Auth   │    │   User   │    │  Orders  │
│ Service  │    │ Service  │    │ Service  │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────────────┼───────────────┘
                     │
              ┌──────┴──────┐
              │ API Gateway │
              └─────────────┘
```

## Error Handling Patterns

### Error Response Format
```typescript
interface ErrorResponse {
  error: string;          // Machine-readable error code
  message: string;        // Human-readable message
  details?: Record<string, string>;  // Field-specific errors
  requestId?: string;     // For debugging
}
```

### Error Categories
| HTTP Status | Use Case |
|-------------|----------|
| 400 | Validation errors, malformed request |
| 401 | Missing or invalid authentication |
| 403 | Valid auth but insufficient permissions |
| 404 | Resource not found |
| 409 | Conflict (duplicate, version mismatch) |
| 422 | Semantically invalid (business rule) |
| 500 | Unexpected server error |

## Security Considerations

### Authentication Strategies
- **JWT**: Stateless, good for APIs, include expiration
- **Sessions**: Server-side state, easier revocation
- **OAuth**: Third-party auth, delegate to providers

### Authorization Patterns
- **RBAC**: Role-based access control
- **ABAC**: Attribute-based access control
- **Resource-based**: Per-resource permissions

### Data Protection
- Encrypt sensitive data at rest (AES-256)
- TLS 1.3 for data in transit
- Hash passwords with bcrypt (cost factor 12+)
- Sanitize inputs to prevent injection

## Performance Strategies

### Caching Layers
1. **Browser cache**: Static assets (CSS, JS, images)
2. **CDN**: Geographically distributed content
3. **Application cache**: Redis/Memcached for hot data
4. **Database cache**: Query result caching

### Database Optimization
- Index frequently queried fields
- Use connection pooling
- Implement pagination for large datasets
- Consider read replicas for heavy read workloads

## Detailed Design Template

```markdown
### 7.X [Component Name] Design

#### Responsibilities
- [What this component is responsible for]
- [Single responsibility principle]

#### Interface
\`\`\`typescript
interface ComponentInterface {
  method1(input: Input): Promise<Output>;
  method2(id: string): Promise<void>;
}
\`\`\`

#### Dependencies
- [Service A] - for [purpose]
- [Library B] - for [purpose]

#### State Management
- [What state is maintained]
- [How state changes]

#### Error Handling
- [How errors are handled]
- [What errors are propagated]

#### Implementation Notes
- [Specific algorithms or patterns]
- [Edge cases to handle]
- [Performance considerations]
```

## Traceability Matrix Example

| Requirement | Design Component | Verification |
|-------------|-----------------|--------------|
| REQ-001 | User table, /api/users endpoint | Integration test |
| REQ-002 | OAuth service, login flow | E2E test |
| REQ-050 | Password validation middleware | Unit test |
