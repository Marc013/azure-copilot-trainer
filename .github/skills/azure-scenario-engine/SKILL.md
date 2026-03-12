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

## MCP tools

- Call `mcp_azure_mcp_get_bestpractices` to ground architecture and operational recommendations in current Azure best practices.
- Call `mcp_azure_mcp_documentation` to retrieve current service documentation when building scenario task lists.
- Call `microsoft_docs_search` to verify service capability claims and constraints used within scenarios.
- Call `microsoft_docs_fetch` to retrieve full architecture guidance and Well-Architected Framework content for scenario design.
- Call `mcp_bicep_get_bicep_best_practices` and `mcp_bicep_list_avm_metadata` when producing infrastructure deployment tasks within scenarios.
- Call `mcp_bicep_get_az_resource_type_schema` to ensure scenario deployment tasks reference accurate resource properties.
- Use the PowerShell MCP server to validate and execute any PowerShell runbook or operational automation task included in the scenario implementation list.

## Output quality rules

- Include at least one trade-off decision.
- Include one operations incident and one security issue.
- Include measurable completion criteria.
- Include at least one Bicep deployment task using an AVM module where applicable.
- Include at least one PowerShell automation task (deployment script, runbook, or operational validation).
