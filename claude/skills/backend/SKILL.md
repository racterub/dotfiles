---
name: backend
description: Use when designing APIs, implementing services, optimizing performance, or architecting backend systems
---

# Backend Engineer

## Overview

Provide backend expertise for API design, service architecture, and server-side development.

## When to Use

- Designing REST or GraphQL APIs
- Implementing service logic
- Database interaction patterns
- Performance optimization
- Caching strategies
- Message queues and async processing

## Checklist

### API Design
- [ ] RESTful conventions followed (or GraphQL schema well-designed)
- [ ] Versioning strategy defined
- [ ] Request/response schemas documented
- [ ] Error responses consistent and informative
- [ ] Pagination for list endpoints
- [ ] Rate limiting considered

### Service Architecture
- [ ] Clear separation of concerns
- [ ] Dependency injection for testability
- [ ] Business logic isolated from framework
- [ ] Transactions scoped appropriately
- [ ] Idempotency for critical operations

### Database Interaction
- [ ] Connection pooling configured
- [ ] Queries optimized (no N+1)
- [ ] Transactions used correctly
- [ ] Migrations versioned
- [ ] Read replicas for read-heavy loads

### Performance
- [ ] Response times measured
- [ ] Bottlenecks identified
- [ ] Caching applied appropriately
- [ ] Async processing for slow operations
- [ ] Database queries optimized

### Caching
- [ ] Cache invalidation strategy clear
- [ ] TTLs appropriate for data freshness
- [ ] Cache stampede prevention
- [ ] Cache warming if needed
- [ ] Monitoring cache hit rates

### Error Handling
- [ ] Errors logged with context
- [ ] User-facing errors sanitized
- [ ] Retry logic for transient failures
- [ ] Circuit breakers for dependencies
- [ ] Graceful degradation

## Anti-Patterns

- N+1 query problems
- Unbounded queries without pagination
- Synchronous calls for slow operations
- Missing input validation
- Leaking internal errors to clients
- Tight coupling to frameworks

## Context7 Usage

Use Context7 for framework and library docs:
- Express, FastAPI, Spring Boot, etc.
- ORMs: Prisma, SQLAlchemy, TypeORM
- Message queues: Redis, RabbitMQ, Kafka
