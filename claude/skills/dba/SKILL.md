---
name: dba
description: Use when designing schemas, optimizing queries, planning migrations, configuring indexes, or managing database operations
---

# Database Administrator

## Overview

Provide DBA expertise for schema design, query optimization, and database operations.

## When to Use

- Designing database schemas
- Optimizing slow queries
- Planning and executing migrations
- Index strategy and tuning
- Backup and recovery planning
- Database scaling decisions

## Checklist

### Schema Design
- [ ] Normalization appropriate (3NF usually)
- [ ] Primary keys defined
- [ ] Foreign keys with proper constraints
- [ ] Data types appropriate and efficient
- [ ] Nullability intentional
- [ ] Naming conventions consistent

### Query Optimization
- [ ] EXPLAIN/ANALYZE run on slow queries
- [ ] Indexes support query patterns
- [ ] N+1 queries eliminated
- [ ] Appropriate use of JOINs
- [ ] Pagination for large result sets
- [ ] Query timeouts configured

### Indexing
- [ ] Indexes on foreign keys
- [ ] Composite indexes for multi-column queries
- [ ] Index order matches query patterns
- [ ] Covering indexes where beneficial
- [ ] Unused indexes identified and removed
- [ ] Index bloat monitored

### Migrations
- [ ] Migrations are reversible
- [ ] Backwards compatible (zero-downtime)
- [ ] Large table changes planned carefully
- [ ] Data migrations tested
- [ ] Migration order dependencies clear

### Backup & Recovery
- [ ] Backup schedule defined
- [ ] Point-in-time recovery possible
- [ ] Backups tested regularly
- [ ] Recovery time objective (RTO) met
- [ ] Recovery point objective (RPO) met

### Performance
- [ ] Connection pooling configured
- [ ] Query plan cache effective
- [ ] Memory allocation appropriate
- [ ] Disk I/O monitored
- [ ] Slow query logging enabled

## Anti-Patterns

- Missing indexes on foreign keys
- Over-indexing (too many indexes)
- SELECT * in production queries
- No query timeouts
- Migrations that lock tables for long periods
- Missing foreign key constraints

## Context7 Usage

Use Context7 for database docs:
- PostgreSQL, MySQL, MongoDB
- ORMs: Prisma, SQLAlchemy, TypeORM
- Migration tools: Flyway, Alembic
