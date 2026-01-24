---
name: security
description: Use when threat modeling, auditing code, reviewing auth/authz, managing secrets, scanning dependencies, or assessing security posture
---

# Security Engineer

## Overview

Provide security expertise for threat modeling, code auditing, and security best practices.

## When to Use

- Threat modeling new features
- Reviewing code for vulnerabilities
- Designing authentication/authorization
- Managing secrets and credentials
- Dependency vulnerability scanning
- Security architecture review

## Checklist

### Threat Modeling
- [ ] Assets identified (what are we protecting?)
- [ ] Trust boundaries mapped
- [ ] Entry points enumerated
- [ ] STRIDE threats considered
- [ ] Mitigations for high-risk threats
- [ ] Residual risk accepted explicitly

### OWASP Top 10
- [ ] Injection (SQL, NoSQL, command, LDAP)
- [ ] Broken authentication
- [ ] Sensitive data exposure
- [ ] XML external entities (XXE)
- [ ] Broken access control
- [ ] Security misconfiguration
- [ ] Cross-site scripting (XSS)
- [ ] Insecure deserialization
- [ ] Using components with known vulnerabilities
- [ ] Insufficient logging and monitoring

### Authentication
- [ ] Passwords hashed with strong algorithm (bcrypt, argon2)
- [ ] Multi-factor authentication available
- [ ] Session management secure
- [ ] Token expiration appropriate
- [ ] Brute force protection

### Authorization
- [ ] Principle of least privilege
- [ ] Role-based access control (RBAC)
- [ ] Resource-level permissions checked
- [ ] Authorization checked server-side
- [ ] Default deny policy

### Secrets Management
- [ ] No secrets in code or env vars
- [ ] Secrets in vault/secrets manager
- [ ] Rotation policy defined
- [ ] Access to secrets audited
- [ ] Different secrets per environment

### Input Validation
- [ ] All input validated server-side
- [ ] Parameterized queries (no string concat)
- [ ] Output encoding for context
- [ ] File upload restrictions
- [ ] Content-Type validation

### Dependency Security
- [ ] Dependencies regularly updated
- [ ] Vulnerability scanning in CI
- [ ] Known vulnerabilities addressed
- [ ] License compliance checked
- [ ] Minimal dependencies

## Anti-Patterns

- Security through obscurity
- Client-side only validation
- Secrets in code/env vars
- Missing rate limiting
- Overly permissive CORS
- Logging sensitive data

## Context7 Usage

Use Context7 for security library docs:
- Auth: Passport, NextAuth, Auth0 SDKs
- Crypto: bcrypt, argon2, jose
- Validation: Zod, Joi, class-validator
