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
- Infrastructure as Code (Bicep) — mandatory for all deployment labs
- PowerShell automation — mandatory for all operational and deployment tasks

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

## MCP tools

- Call `microsoft_docs_search` to retrieve current service documentation for grounding service descriptions and feature explanations.
- Call `microsoft_code_sample_search` to obtain official code samples for lab exercises. Base hands-on steps on returned official samples.
- Call `microsoft_docs_fetch` to retrieve full quickstart and architecture content for each service in scope.
- Call `mcp_azure_mcp_get_bestpractices` to incorporate current Azure service best practices into module guidance.
- Call `mcp_bicep_get_bicep_best_practices` before authoring any IaC lab step or deployment template exercise.
- Call `mcp_bicep_get_az_resource_type_schema` to retrieve accurate resource property schemas when building Bicep lab exercises.
- Call `mcp_bicep_list_avm_metadata` to identify Azure Verified Modules relevant to the services in scope and include them as preferred deployment patterns.
- Call `mcp_bicep_get_bicep_file_diagnostics` to validate any Bicep snippets generated for lab exercises before including them in module content.
- Use the PowerShell MCP server to execute and validate all PowerShell automation scripts included in lab steps before publishing them to learners.

## Output rules

- Use progressive complexity from guided to independent tasks.
- Include production constraints (SLO, budget, compliance).
- Keep each lab measurable with pass/fail criteria.
- Every module must include at least one Bicep deployment exercise using AVM where available.
- Every module must include at least one PowerShell automation task covering deployment, configuration, or operational validation.
- Add a `Proof links` section for technical claims using learn.microsoft.com URLs sourced from MCP retrieval only.
