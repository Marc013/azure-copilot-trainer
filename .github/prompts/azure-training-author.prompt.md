---
mode: agent
description: Generate or update a full Azure training program and produce publishable artifacts using only learn.microsoft.com references, with confidence labels and quality-gate results.
---

# Azure Training Author Mode

Use the installed skills to build or update a complete Azure training program.

## Inputs

- Audience profile: role, baseline, goals.
- Program constraints: duration, weekly effort, delivery mode.
- Azure focus: services and architecture emphasis.
- Industry context and realism constraints.

## Required execution order

1. Run /azure-training-orchestrator with the provided audience and constraints. Use `microsoft_docs_search` and `mcp_azure_mcp_get_bestpractices` to ground the curriculum skeleton. Confirm the program includes at least one Bicep IaC module and one PowerShell automation module.
2. Run /azure-service-path-apps to generate module details. Use `microsoft_code_sample_search` for official code samples, `mcp_bicep_list_avm_metadata` and `mcp_bicep_get_az_resource_type_schema` for IaC lab content, and the PowerShell MCP server to validate all automation scripts.
3. Run /azure-scenario-engine to generate at least two realistic scenarios by role and industry. Use `mcp_azure_mcp_get_bestpractices` and `mcp_bicep_get_bicep_best_practices` for IaC scenario tasks and the PowerShell MCP server to validate scenario automation runbooks.
4. Run /azure-assessment-engine to create module checks and final assessment. Use `microsoft_docs_search` and `microsoft_docs_fetch` for answer key evidence. Use `mcp_bicep_get_bicep_file_diagnostics` to validate Bicep assessment snippets and the PowerShell MCP server to validate PowerShell task rubrics. Confirm the final assessment includes at least one Bicep task and one PowerShell task.
5. Run /azure-source-grounding. Use `microsoft_docs_search` and `microsoft_docs_fetch` to verify documentation claims. Use `mcp_bicep_get_bicep_file_diagnostics` to validate Bicep code and the PowerShell MCP server to validate PowerShell scripts. Enforce learn.microsoft.com proof links and confidence labels for every key claim.
6. Run /azure-quality-gates. Use `microsoft_docs_search` to verify proof links, `mcp_bicep_get_bicep_file_diagnostics` to validate IaC artifacts, and the PowerShell MCP server to validate automation scripts. Block release on critical failures.

## Output format

1. Program overview and timeline.
2. Module table with prerequisite and objective IDs.
3. Scenario summary with architecture, operations, security, cost, and troubleshooting sections.
4. Assessment blueprint and rubric links.
5. Trust report with proof links to learn.microsoft.com and confidence labels.
6. Quality-gates pass/fail report with remediation tasks.
7. Next actions and release decision.

## Evidence requirements

- Every key claim must include at least one direct link to learn.microsoft.com sourced from `microsoft_docs_search` or `microsoft_docs_fetch` MCP retrieval. Do not fabricate or generate documentation URLs.
- If no learn.microsoft.com proof link is found via MCP retrieval, label claim as Unverified and exclude it from release output.
- Include a `Proof links` subsection in each module and assessment section.

## Non-negotiable rules

- Do not publish if critical quality checks fail.
- Mark unverified claims clearly and provide verification actions.
- Keep outputs aligned to objective IDs for traceability.
- Do not use domains outside learn.microsoft.com as evidence sources.
