---
name: infra
description: Use when designing cloud architecture, writing IaC, setting up CI/CD, configuring containers, or planning networking
---

# Infrastructure Engineer

## Overview

Provide infrastructure expertise for cloud architecture, IaC, CI/CD, and platform engineering.

## When to Use

- Designing cloud architecture
- Writing Terraform, Pulumi, or CloudFormation
- Setting up CI/CD pipelines
- Configuring Docker, Kubernetes
- Planning networking and security groups
- Managing secrets and configuration

## Checklist

### Infrastructure as Code
- [ ] All infrastructure defined in code
- [ ] State managed properly (remote backend)
- [ ] Modules/components reusable
- [ ] Variables for environment differences
- [ ] Drift detection in place

### CI/CD Pipeline
- [ ] Build, test, deploy stages defined
- [ ] Fast feedback (parallel where possible)
- [ ] Artifacts versioned and stored
- [ ] Rollback mechanism exists
- [ ] Environment promotion path clear

### Containerization
- [ ] Images minimal (multi-stage builds)
- [ ] Non-root user in containers
- [ ] Health checks defined
- [ ] Resource limits set
- [ ] Secrets not baked into images

### Kubernetes (if applicable)
- [ ] Deployments with rolling updates
- [ ] Resource requests/limits set
- [ ] Liveness/readiness probes
- [ ] ConfigMaps/Secrets for config
- [ ] Network policies defined

### Networking
- [ ] VPC/network segmentation
- [ ] Security groups least-privilege
- [ ] Load balancing configured
- [ ] DNS and service discovery
- [ ] TLS everywhere

### Security
- [ ] Secrets in vault/secrets manager
- [ ] IAM roles least-privilege
- [ ] Network segmentation
- [ ] Encryption at rest and in transit
- [ ] Audit logging enabled

## Anti-Patterns

- ClickOps (manual console changes)
- Secrets in code or environment variables
- Overly permissive security groups
- Missing resource limits
- No rollback strategy

## Context7 Usage

Use Context7 for IaC and cloud docs:
- Terraform providers, Pulumi packages
- AWS, GCP, Azure SDKs
- Kubernetes API resources
