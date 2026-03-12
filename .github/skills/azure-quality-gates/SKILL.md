---
name: azure-quality-gates
description: Evaluate Azure training artifacts against objective acceptance criteria including pedagogy completeness, state continuity, learn.microsoft.com-only source-grounding, scenario realism, and assessment quality. Use before publishing or self-paced rollout.
argument-hint: [artifact set path] [strictness]
---

# Azure Quality Gates

## Purpose

Provide deterministic go/no-go quality checks.

## Workflow

1. Load [test cases](./test-cases.md).
2. Validate structural requirements across modules.
3. Validate learner-state and resume compatibility.
4. Validate anti-hallucination controls are present.
5. Validate scenario realism dimensions.
6. Validate assessment objective coverage.
7. Produce pass/fail report with corrective actions.

## Output contract

- Status: Pass or Fail
- Findings grouped by severity: Critical, Major, Minor
- Exact failed condition and remediation action
