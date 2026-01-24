---
name: frontend
description: Use when designing UI/UX, building components, managing state, implementing accessibility, or optimizing frontend performance
---

# Frontend Engineer

## Overview

Provide frontend expertise for UI/UX, component architecture, and client-side development.

## When to Use

- Designing user interfaces
- Building reusable components
- Managing application state
- Implementing accessibility (a11y)
- Responsive design
- Frontend performance optimization

## Checklist

### Component Design
- [ ] Single responsibility per component
- [ ] Props interface clearly defined
- [ ] Controlled vs uncontrolled decided
- [ ] Composition over prop drilling
- [ ] Reusable and testable

### State Management
- [ ] State location appropriate (local vs global)
- [ ] Minimal state (derive when possible)
- [ ] State updates immutable
- [ ] Loading/error states handled
- [ ] Optimistic updates where appropriate

### Accessibility (a11y)
- [ ] Semantic HTML elements used
- [ ] ARIA labels where needed
- [ ] Keyboard navigation works
- [ ] Focus management correct
- [ ] Color contrast sufficient
- [ ] Screen reader tested

### Responsive Design
- [ ] Mobile-first approach
- [ ] Breakpoints consistent
- [ ] Touch targets appropriately sized
- [ ] Images responsive
- [ ] Layout doesn't break

### Performance
- [ ] Bundle size optimized
- [ ] Code splitting implemented
- [ ] Images lazy loaded
- [ ] Memoization where beneficial
- [ ] Unnecessary re-renders avoided

### Forms
- [ ] Validation (client and server)
- [ ] Error messages clear and helpful
- [ ] Loading states during submission
- [ ] Accessible form labels
- [ ] Proper input types

## Anti-Patterns

- Prop drilling through many layers
- Global state for local concerns
- Inline styles everywhere
- Missing loading/error states
- Inaccessible custom components
- Massive bundle sizes

## Context7 Usage

Use Context7 for frontend framework docs:
- React, Vue, Svelte, Angular
- State: Redux, Zustand, Pinia
- Styling: Tailwind, styled-components
- Testing: Testing Library, Cypress
