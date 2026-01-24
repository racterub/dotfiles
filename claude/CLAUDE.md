# Development Guidelines

## Mandatory Workflow

Every task follows this flow. No exceptions.

```
1. Brainstorm  →  Clarify requirements (use superpowers:brainstorming)
2. Plan        →  Create implementation plan (use superpowers:writing-plans)
3. Approve     →  User approves before any implementation
4. Implement   →  TDD cycle (use superpowers:test-driven-development)
5. Verify      →  Run tests + integration check (use integration-check skill)
```

Do NOT skip steps. Do NOT jump to implementation without approval.

## Guardrails

### Anti-Hallucination

**When uncertain, say "I don't know."**

- Never fabricate APIs, library methods, or configuration options
- Never guess at syntax or behavior - look it up first
- Use Context7 MCP to fetch current documentation for libraries/frameworks
- Cite sources when referencing external docs
- If documentation is unavailable, explicitly state uncertainty

**Red flags that require verification:**
- "I believe this API..."
- "This should work..."
- "Typically this is done by..."

Replace with actual lookup or explicit "I don't know."

### Core Principles

- **Clear intent over clever code** - Be boring and obvious
- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Pragmatic over dogmatic** - Adapt to project reality
- If you need to explain it, it's too complex
- Avoid premature abstractions

## Role Skills

Invoke domain expertise when needed. Each skill provides checklists and best practices.

| Skill | Invoke for |
|-------|------------|
| `qa` | Test strategy, coverage analysis, E2E testing, bug triage |
| `sre` | Reliability, monitoring, SLOs, incident response, capacity |
| `infra` | IaC, cloud architecture, CI/CD, containers, networking |
| `backend` | API design, services, performance, caching |
| `frontend` | UI/UX, components, state management, accessibility |
| `dba` | Schema design, query optimization, migrations, indexing |
| `data` | ETL pipelines, data modeling, warehousing, data quality |
| `security` | Threat modeling, OWASP, auth, secrets, dependency scanning |
| `integration-check` | Verify components are wired up correctly |

## Implementation Flow

1. **Understand** - Study existing patterns in codebase
2. **Test** - Write test first (red)
3. **Implement** - Minimal code to pass (green)
4. **Refactor** - Clean up with tests passing
5. **Commit** - With clear message linking to plan

## TDD Methodology

- Always follow the TDD cycle: Red -> Green -> Refactor
- Write the simplest failing test first
- Implement the minimum code needed to make tests pass
- Refactor only after tests are passing
- Follow Beck's "Tidy First" approach: separate structural changes from behavioral changes

### Tidy First Approach

Separate all changes into two distinct types:
1. **STRUCTURAL CHANGES**: Rearranging code without changing behavior (renaming, extracting methods, moving code)
2. **BEHAVIORAL CHANGES**: Adding or modifying actual functionality

- Never mix structural and behavioral changes in the same commit
- Always make structural changes first when both are needed
- Validate structural changes do not alter behavior by running tests before and after

## When Stuck (After 3 Attempts)

**CRITICAL**: Maximum 3 attempts per issue, then STOP.

1. **Document what failed**:
   - What you tried
   - Specific error messages
   - Why you think it failed

2. **Research alternatives**:
   - Find 2-3 similar implementations
   - Note different approaches used

3. **Question fundamentals**:
   - Is this the right abstraction level?
   - Can this be split into smaller problems?
   - Is there a simpler approach entirely?

4. **Try different angle**:
   - Different library/framework feature?
   - Different architectural pattern?
   - Remove abstraction instead of adding?

## Quality Gates

### Definition of Done

- [ ] Tests written and passing
- [ ] Code follows project conventions
- [ ] No linter/formatter warnings
- [ ] Commit messages are clear
- [ ] Implementation matches plan
- [ ] Integration verified (components wired up)
- [ ] No TODOs without issue numbers

### Every Commit Must

- Compile successfully
- Pass all existing tests
- Include tests for new functionality
- Follow project formatting/linting
- Clearly state whether it contains structural or behavioral changes

### Before Committing

- Run formatters/linters
- Self-review changes
- Ensure commit message explains "why"

## Architecture Principles

- **Composition over inheritance** - Use dependency injection
- **Interfaces over singletons** - Enable testing and flexibility
- **Explicit over implicit** - Clear data flow and dependencies
- **Test-driven when possible** - Never disable tests, fix them

## Decision Framework

When multiple valid approaches exist, choose based on:

1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Important Reminders

**NEVER**:
- Use `--no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code
- Fabricate information - say "I don't know" instead

**ALWAYS**:
- Commit working code incrementally
- Update plan documentation as you go
- Learn from existing implementations
- Stop after 3 failed attempts and reassess
- Use Context7 to verify library/framework behavior
