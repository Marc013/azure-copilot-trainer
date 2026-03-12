---
name: azure-service-path-apps
description: Generate Azure multi-service training modules for application platform scenarios across App Service, Functions, Storage, Key Vault, and Monitor. Use when composing practical implementation modules for real-world cloud application delivery.
argument-hint: [module ids] [skill level] [industry]
---

# Azure Service Path: Applications

## Purpose

Produce practical, composable training modules focused on Azure application platform delivery.

## Service scope

- Azure App Service
- Azure Functions
- Azure Storage
- Azure Key Vault
- Azure Monitor (Application Insights, Log Analytics)

## Workflow

1. Load [module map](./module-map.yaml).
2. For each module request, provide:
- Why this service is used
- Architecture placement
- Hands-on lab steps
- Security controls
- Cost considerations
- Troubleshooting drills
3. Tag each activity with objective IDs and complexity level.
4. Add dependency notes for prerequisite services.
5. Emit module artifacts in orchestrator-compatible format.

## Output rules

- Use progressive complexity from guided to independent tasks.
- Include production constraints (SLO, budget, compliance).
- Keep each lab measurable with pass/fail criteria.
- Add a `Proof links` section for technical claims using learn.microsoft.com URLs only.
