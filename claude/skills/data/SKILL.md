---
name: data
description: Use when designing ETL pipelines, data modeling, building warehouses, implementing streaming, or ensuring data quality
---

# Data Engineer

## Overview

Provide data engineering expertise for pipelines, data modeling, and data infrastructure.

## When to Use

- Designing ETL/ELT pipelines
- Data modeling for analytics
- Building data warehouses
- Batch vs stream processing decisions
- Data quality and validation
- Data catalog and lineage

## Checklist

### Pipeline Design
- [ ] Idempotent operations (rerunnable safely)
- [ ] Error handling and dead letter queues
- [ ] Backfill capability
- [ ] Incremental processing where possible
- [ ] Monitoring and alerting
- [ ] Data validation at each stage

### Data Modeling
- [ ] Star or snowflake schema for analytics
- [ ] Fact and dimension tables clear
- [ ] Slowly changing dimensions handled
- [ ] Grain of fact tables defined
- [ ] Naming conventions consistent

### Data Quality
- [ ] Schema validation
- [ ] Null/missing value handling
- [ ] Duplicate detection
- [ ] Range and format checks
- [ ] Referential integrity
- [ ] Data freshness monitoring

### Batch Processing
- [ ] Partition strategy defined
- [ ] Appropriate file formats (Parquet, etc.)
- [ ] Compression enabled
- [ ] Job scheduling and dependencies
- [ ] Resource allocation optimized

### Stream Processing
- [ ] Exactly-once vs at-least-once decided
- [ ] Windowing strategy appropriate
- [ ] Late data handling
- [ ] Checkpointing configured
- [ ] Backpressure handling

### Data Governance
- [ ] Data catalog maintained
- [ ] Lineage tracked
- [ ] PII identified and protected
- [ ] Access controls defined
- [ ] Retention policies clear

## Anti-Patterns

- Non-idempotent pipelines
- Missing data validation
- No monitoring on pipelines
- Hardcoded credentials
- Missing lineage tracking
- Over-engineering for scale not needed

## Context7 Usage

Use Context7 for data tooling docs:
- Apache Spark, Flink, Beam
- dbt, Airflow, Dagster
- Kafka, Kinesis, Pub/Sub
- Snowflake, BigQuery, Redshift
