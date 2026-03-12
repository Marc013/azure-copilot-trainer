---
name: azure-source-grounding
description: Prevent hallucinations in Azure training outputs by enforcing learn.microsoft.com-only source-grounding, confidence labels, verification checkpoints, and uncertainty fallback behavior. Use when validating generated content before learner delivery.
argument-hint: [artifact path or text] [strictness: high]
---

# Azure Source Grounding

## Purpose

Ensure generated training content is trustworthy and auditable.

## MCP tools

- Call `microsoft_docs_search` with the claim text to find relevant learn.microsoft.com pages.
- Call `microsoft_docs_fetch` on the top-ranked URL to retrieve full page content and confirm the claim is supported.
- Call `microsoft_code_sample_search` when validating code-level claims or implementation steps.
- Call `mcp_bicep_get_bicep_file_diagnostics` to validate any Bicep code included in training content. Reject Bicep snippets with diagnostic errors.
- Call `mcp_bicep_get_bicep_best_practices` to verify that Bicep authoring guidance aligns with current practices.
- Use the PowerShell MCP server to validate any PowerShell script included in training content. Reject scripts with syntax errors or unsafe constructs.
- Use only URLs returned by MCP retrieval as proof links. Never fabricate or generate documentation URLs.

## Required behavior

1. Extract key claims from content.
2. For each key claim, call `microsoft_docs_search` to find supporting learn.microsoft.com pages.
3. For top-ranked results, call `microsoft_docs_fetch` to retrieve full content and confirm the claim is accurately represented.
4. For code-level or implementation claims, call `microsoft_code_sample_search` to find official samples.
5. Attach at least one proof link sourced from MCP retrieval results. Do not fabricate or generate URLs.
6. Label confidence as High, Medium, or Low with rationale.
7. Run checklist in [verification-checklist.md](./verification-checklist.md).
8. If unverifiable via MCP retrieval, produce safe fallback response with explicit uncertainty.

## Source policy

- Allowed domain only: learn.microsoft.com.
- Reject claims with missing links or links outside learn.microsoft.com.
- Reject unsupported claims.

## Output contract

- Claim evidence table: claim, learn.microsoft.com link, confidence, status.
- Validation summary: pass/fail with reasons.
- Remediation actions for failed claims.
