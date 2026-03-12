---
name: azure-assessment-engine
description: Build objective-aligned quizzes, practical checks, recap prompts, and final assessments for Azure training, then generate remediation guidance from learner performance.
argument-hint: [module id or full course] [difficulty] [question count]
---

# Azure Assessment Engine

## Purpose

Create measurable assessment assets aligned to objectives and learner level.

## Workflow

1. Read objective map from orchestrator output.
2. Load [question framework](./question-types.md).
3. Generate per-module:
- Diagnostic pre-check
- Formative check-for-understanding
- Practical task rubric
- Recap prompts
4. Generate final assessment:
- Multi-domain practical scenario
- Scoring rubric and pass criteria
5. Build remediation plan based on weak objective IDs.

## MCP tools

- Call `microsoft_docs_search` to retrieve source evidence for answer keys and technical rationale.
- Call `microsoft_docs_fetch` to retrieve full page content when building detailed answer rationale requiring deep technical accuracy.
- Call `microsoft_code_sample_search` for any assessment item that references code, deployment steps, or implementation tasks.
- Call `mcp_bicep_get_bicep_best_practices` when building assessment items that test IaC or Bicep template knowledge.
- Call `mcp_bicep_get_bicep_file_diagnostics` to validate Bicep snippets used in practical task rubrics before including them in assessments.
- Call `mcp_bicep_get_az_resource_type_schema` to verify resource property correctness in IaC-focused assessment items.
- Use the PowerShell MCP server to validate PowerShell script answers and automation task rubrics before including them in assessments.

## Constraints

- Each item must map to a single objective ID.
- Include answer key and rationale for each objective.
- Include partial-credit policy for practical tasks.
- Include learn.microsoft.com proof links for technical answer keys and rationales. Source all links from MCP retrieval results only.
- Every final assessment must include at least one Bicep deployment validation task and at least one PowerShell automation task.
