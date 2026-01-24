# Claude Code Development Team Setup

## Overview

Configure Claude Code to act as a full development team with role-specific skills, enforced workflow, and anti-hallucination guardrails.

## Directory Structure

```
/home/racterub/github/dotfiles/
├── claude/
│   ├── CLAUDE.md                    # Global workflow + guardrails
│   ├── settings.json                # MCP config (Context7)
│   └── skills/
│       ├── qa/SKILL.md
│       ├── sre/SKILL.md
│       ├── infra/SKILL.md
│       ├── backend/SKILL.md
│       ├── frontend/SKILL.md
│       ├── dba/SKILL.md
│       ├── data/SKILL.md
│       ├── security/SKILL.md
│       └── integration-check/SKILL.md
└── install.sh                       # Symlinks to ~/.claude/
```

## CLAUDE.md Content

### Workflow (Mandatory)
1. Brainstorm → clarify requirements (superpowers:brainstorming)
2. Plan → create implementation plan (superpowers:writing-plans)
3. Approve → user approves before implementation
4. Implement → TDD cycle (superpowers:test-driven-development)
5. Verify → run tests + integration check

### Guardrails

**Anti-Hallucination:**
- If uncertain, say "I don't know" - never fabricate
- Cite sources when referencing docs/APIs
- Use Context7 MCP to fetch current documentation
- When unsure about library behavior, look it up first

**Core Principles:**
- Clear intent over clever code
- Incremental progress over big bangs
- Learning from existing code first
- Pragmatic over dogmatic

### Preserved from existing CLAUDE.md
- TDD methodology (Red → Green → Refactor)
- Tidy First approach (structural vs behavioral changes)
- Quality gates and Definition of Done
- 3-attempt rule when stuck

## Role Skills

| Skill | Focus Areas |
|-------|-------------|
| qa | Test strategy, test case design, coverage analysis, E2E testing, regression testing, bug triage |
| sre | Reliability, monitoring, alerting, SLOs/SLIs, incident response, runbooks, capacity planning |
| infra | IaC (Terraform/Pulumi), cloud architecture, networking, CI/CD pipelines, containerization |
| backend | API design, database interactions, service architecture, performance, caching strategies |
| frontend | UI/UX patterns, component design, state management, accessibility, responsive design |
| dba | Schema design, query optimization, migrations, indexing, backup/recovery, data modeling |
| data | ETL pipelines, data modeling, warehousing, batch/stream processing, data quality |
| security | Threat modeling, code audit, OWASP top 10, auth/authz, secrets management, dependency scanning |
| integration-check | Verify components are wired up: trace data flow, check imports/exports, run actual code paths |

Each skill:
- YAML frontmatter with name and description starting with "Use when..."
- Checklist of things to verify
- Reference to Context7 for documentation lookup

## Context7 MCP Setup

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

## Install Script

1. Backup existing ~/.claude/CLAUDE.md and ~/.claude/settings.json
2. Symlink claude/CLAUDE.md → ~/.claude/CLAUDE.md
3. Symlink claude/skills/ → ~/.claude/skills/
4. Merge MCP config into existing ~/.claude/settings.json (preserve plugins)
