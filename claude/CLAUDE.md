# Development Guidelines

## STOP - Before Code Changes

Before using **Edit**, **Write**, or **NotebookEdit**:

1. Has the user approved a plan for this change? → If NO, propose the plan first
2. For trivial fixes (typos, obvious bugs): ask "Should I fix this?" before editing

**Does NOT require approval:** Reading/searching code, exploring codebase, running read-only commands, answering questions
**Requires approval:** Any file modification, any new file creation

## Core Principles

- **Clear intent over clever code** - Be boring and obvious
- **Incremental progress over big bangs** - Small changes that compile and pass tests
- **Learning from existing code** - Study and plan before implementing
- **Pragmatic over dogmatic** - Adapt to project reality
- If you need to explain it, it's too complex
- Avoid premature abstractions

## Tidy First

Separate all changes into two distinct types:
1. **STRUCTURAL CHANGES**: Rearranging code without changing behavior
2. **BEHAVIORAL CHANGES**: Adding or modifying actual functionality

- Never mix structural and behavioral changes in the same commit
- Always make structural changes first when both are needed
- Every commit must clearly state whether it contains structural or behavioral changes

## Before Committing

- Run formatters/linters
- Self-review changes
- Ensure commit message explains "why"

## Architecture Principles

- **Composition over inheritance** - Use dependency injection
- **Interfaces over singletons** - Enable testing and flexibility
- **Explicit over implicit** - Clear data flow and dependencies

## Decision Framework

When multiple valid approaches exist, choose based on:
1. **Testability** - Can I easily test this?
2. **Readability** - Will someone understand this in 6 months?
3. **Consistency** - Does this match project patterns?
4. **Simplicity** - Is this the simplest solution that works?
5. **Reversibility** - How hard to change later?

## Hard Rules

- NEVER use `--no-verify` to bypass commit hooks
- ALWAYS learn from existing implementations before writing new code
