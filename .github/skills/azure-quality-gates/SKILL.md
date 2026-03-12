---
name: azure-quality-gates
description: Evaluate Azure training artifacts against objective acceptance criteria including pedagogy completeness, state continuity, learn.microsoft.com-only source-grounding, scenario realism, and assessment quality. Use before publishing or self-paced rollout.
argument-hint: [artifact set path] [strictness]
---

# Azure Quality Gates

## Purpose

Provide deterministic go/no-go quality checks.

## MCP tools

- Call `microsoft_docs_search` to actively verify that claimed learn.microsoft.com proof links correspond to real, accessible content.
- Call `microsoft_docs_fetch` on any proof link under deep review to confirm the page content actually supports the associated claim.
- Call `mcp_bicep_get_bicep_file_diagnostics` on every Bicep file or snippet in the artifact set. Any snippet with errors is a Critical finding.
- Call `mcp_bicep_get_bicep_best_practices` to check that IaC content adheres to current Bicep standards.
- Use the PowerShell MCP server to validate all PowerShell automation scripts in the artifact set. Any script with syntax errors or unsafe patterns is a Critical finding.

## Workflow

1. Load [test cases](./test-cases.md).
2. Validate structural requirements across modules.
3. Validate learner-state and resume compatibility.
4. Validate anti-hallucination controls are present.
5. For each proof link in the artifact set, call `microsoft_docs_search` to verify the claim has matching learn.microsoft.com evidence.
6. Call `mcp_bicep_get_bicep_file_diagnostics` on all Bicep snippets. Fail on any diagnostic error.
7. Use the PowerShell MCP server to validate all PowerShell scripts in the artifact set. Fail on any syntax or security issue.
8. Validate scenario realism dimensions.
9. Confirm every module contains at least one Bicep IaC task and one PowerShell automation task.
10. Validate assessment objective coverage.
11. Produce pass/fail report with corrective actions.

## Output contract

- Status: Pass or Fail
- Findings grouped by severity: Critical, Major, Minor
- Exact failed condition and remediation action
