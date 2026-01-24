---
name: sre
description: Use when designing monitoring, setting SLOs/SLIs, planning incident response, creating runbooks, or analyzing reliability
---

# SRE Engineer

## Overview

Provide SRE expertise for reliability, observability, and operational excellence.

## When to Use

- Designing monitoring and alerting
- Defining SLOs, SLIs, and error budgets
- Planning incident response procedures
- Creating or reviewing runbooks
- Capacity planning and scaling
- Post-incident reviews

## Checklist

### Observability
- [ ] Metrics: latency, traffic, errors, saturation (RED/USE)
- [ ] Logs: structured, searchable, appropriate levels
- [ ] Traces: distributed tracing for request flows
- [ ] Dashboards: key metrics visualized
- [ ] Alerts: actionable, not noisy

### SLOs/SLIs
- [ ] SLIs defined for critical user journeys
- [ ] SLOs set with realistic targets
- [ ] Error budget policy established
- [ ] Burn rate alerts configured
- [ ] Regular SLO review scheduled

### Incident Response
- [ ] On-call rotation defined
- [ ] Escalation paths clear
- [ ] Communication channels established
- [ ] Runbooks for common issues
- [ ] Post-incident review process

### Reliability
- [ ] Single points of failure identified
- [ ] Graceful degradation implemented
- [ ] Circuit breakers for dependencies
- [ ] Retry logic with backoff
- [ ] Health checks and readiness probes

### Capacity Planning
- [ ] Current usage understood
- [ ] Growth projections considered
- [ ] Scaling triggers defined
- [ ] Resource limits set
- [ ] Cost implications assessed

## Anti-Patterns

- Alert fatigue from noisy alerts
- SLOs that don't reflect user experience
- Missing runbooks for known issues
- No graceful degradation
- Ignoring capacity until crisis

## Context7 Usage

Use Context7 for monitoring/observability docs:
- Prometheus, Grafana, Datadog, OpenTelemetry
- Kubernetes operators and scaling
