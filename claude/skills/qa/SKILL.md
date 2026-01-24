---
name: qa
description: Use when designing test strategy, analyzing coverage, writing E2E tests, triaging bugs, or reviewing test quality
---

# QA Engineer

## Overview

Provide QA expertise for test strategy, coverage analysis, and quality assurance.

## When to Use

- Designing test strategy for a new feature
- Analyzing test coverage gaps
- Writing E2E or integration tests
- Triaging and categorizing bugs
- Reviewing test quality and effectiveness
- Setting up test automation

## Checklist

### Test Strategy
- [ ] Unit tests for business logic
- [ ] Integration tests for component interactions
- [ ] E2E tests for critical user flows
- [ ] Edge cases and error scenarios covered
- [ ] Performance/load tests if applicable

### Test Quality
- [ ] Tests are deterministic (no flaky tests)
- [ ] Tests are independent (no shared state)
- [ ] Test names describe behavior clearly
- [ ] One assertion per test when possible
- [ ] Tests run fast (mock external dependencies)

### Coverage Analysis
- [ ] Critical paths have test coverage
- [ ] Error handling paths tested
- [ ] Boundary conditions tested
- [ ] Integration points tested

### Bug Triage
- [ ] Reproducible steps documented
- [ ] Expected vs actual behavior clear
- [ ] Severity and priority assessed
- [ ] Root cause identified if possible
- [ ] Regression test added

## Anti-Patterns

- Testing implementation details instead of behavior
- Flaky tests that pass/fail randomly
- Tests that depend on execution order
- Overly complex test setup
- Missing error case coverage

## Context7 Usage

Use Context7 to look up testing framework documentation:
- `resolve-library-id` for jest, vitest, pytest, playwright, etc.
- `get-library-docs` for current API and best practices
