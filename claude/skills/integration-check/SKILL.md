---
name: integration-check
description: Use after implementing components to verify they are properly wired up, data flows correctly, and no pieces are disconnected
---

# Integration Check

## Overview

Verify that implemented components are properly connected and working together.

## When to Use

- After implementing multiple components from a plan
- Before claiming implementation is complete
- When suspecting components aren't properly wired
- During code review to verify integration
- Before creating a PR

## The Problem

LLMs often implement individual components correctly but fail to wire them together:
- Functions defined but never called
- Exports created but never imported
- Config added but never read
- Event handlers defined but never attached
- Routes created but never registered

## Verification Process

### 1. Trace Entry Points

Start from where users/systems interact:
- [ ] HTTP routes registered with server
- [ ] CLI commands wired to handlers
- [ ] Event listeners attached to emitters
- [ ] Cron jobs scheduled
- [ ] Message queue consumers subscribed

### 2. Follow Data Flow

Trace the path data takes:
- [ ] Input -> Validation -> Processing -> Output
- [ ] Each step calls the next
- [ ] No dead ends or orphaned code
- [ ] Error paths also complete

### 3. Verify Imports/Exports

Check module connections:
- [ ] Every export has at least one import
- [ ] No missing imports that would crash at runtime
- [ ] Circular dependencies resolved
- [ ] Re-exports properly forwarded

### 4. Check Configuration

Verify config is consumed:
- [ ] Environment variables read where used
- [ ] Config files loaded at startup
- [ ] Feature flags checked in code paths
- [ ] Default values sensible

### 5. Test the Actual Path

Don't just unit test - run the flow:
- [ ] Call the API endpoint end-to-end
- [ ] Trigger the event and verify handler runs
- [ ] Run the CLI command with real args
- [ ] Verify database actually updates

## Checklist Per Component

For each component implemented:
- [ ] Is it imported somewhere?
- [ ] Is it called/instantiated?
- [ ] Are its dependencies injected?
- [ ] Is it registered (routes, handlers, etc.)?
- [ ] Does an E2E test exercise it?

## Red Flags

These indicate incomplete integration:
- "I've implemented the function" but no call site shown
- Tests only mock the component, never run it
- Component works in isolation but untested in context
- Export statement added but no import statement

## Verification Command

After implementation, run:
```bash
# Find unused exports (example for TypeScript)
npx ts-prune

# Find unused code
npx knip

# Or simply: try to use the feature end-to-end
```

## The Rule

**Never claim "done" until you've traced the complete path from entry point to exit.**

If you can't demonstrate the data flow working end-to-end, the integration is incomplete.
