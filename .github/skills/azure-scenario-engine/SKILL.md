---
name: azure-scenario-engine
description: Generate realistic Azure implementation scenarios by role, industry, skill level, and operational constraints, including architecture, security, cost, operations, and troubleshooting tasks.
argument-hint: [role] [industry] [level] [constraints]
---

# Azure Scenario Engine

## Purpose

Create high-fidelity practice scenarios that mirror production environments.

## Inputs

- Role
- Industry
- Skill level
- Constraints (budget, compliance, SLO, region, staffing)

## Workflow

1. Load [scenario catalog](./scenario-catalog.yaml).
2. Select baseline scenario archetype.
3. Inject constraints and failure events.
4. Produce artifacts:
- Architecture narrative
- Implementation task list
- Security controls checklist
- Cost optimization challenge
- Troubleshooting incident timeline
- Grading rubric mapping
5. Add extension tasks for advanced learners.

## Output quality rules

- Include at least one trade-off decision.
- Include one operations incident and one security issue.
- Include measurable completion criteria.
