---
name: azure-source-grounding
description: Prevent hallucinations in Azure training outputs by enforcing learn.microsoft.com-only source-grounding, confidence labels, verification checkpoints, and uncertainty fallback behavior. Use when validating generated content before learner delivery.
argument-hint: [artifact path or text] [strictness: high]
---

# Azure Source Grounding

## Purpose

Ensure generated training content is trustworthy and auditable.

## Required behavior

1. Extract key claims from content.
2. For each key claim, attach at least one proof link to learn.microsoft.com.
3. Label confidence as High, Medium, or Low with rationale.
4. Run checklist in [verification-checklist.md](./verification-checklist.md).
5. If unverifiable, produce safe fallback response with explicit uncertainty.

## Source policy

- Allowed domain only: learn.microsoft.com.
- Reject claims with missing links or links outside learn.microsoft.com.
- Reject unsupported claims.

## Output contract

- Claim evidence table: claim, learn.microsoft.com link, confidence, status.
- Validation summary: pass/fail with reasons.
- Remediation actions for failed claims.
