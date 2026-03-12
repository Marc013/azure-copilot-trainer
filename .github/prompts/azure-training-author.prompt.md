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

1. Run /azure-training-orchestrator with the provided audience and constraints.
2. Run /azure-service-path-apps to generate module details for App Service, Functions, Storage, Key Vault, and Monitor.
3. Run /azure-scenario-engine to generate at least two realistic scenarios by role and industry.
4. Run /azure-assessment-engine to create module checks and final assessment.
5. Run /azure-source-grounding and enforce learn.microsoft.com proof links for every key claim with confidence labels.
6. Run /azure-quality-gates and block release on critical failures.

## Output format

1. Program overview and timeline.
2. Module table with prerequisite and objective IDs.
3. Scenario summary with architecture, operations, security, cost, and troubleshooting sections.
4. Assessment blueprint and rubric links.
5. Trust report with proof links to learn.microsoft.com and confidence labels.
6. Quality-gates pass/fail report with remediation tasks.
7. Next actions and release decision.

## Evidence requirements

- Every key claim must include at least one direct link to learn.microsoft.com.
- If no learn.microsoft.com proof link exists, label claim as Unverified and exclude it from release output.
- Include a `Proof links` subsection in each module and assessment section.

## Non-negotiable rules

- Do not publish if critical quality checks fail.
- Mark unverified claims clearly and provide verification actions.
- Keep outputs aligned to objective IDs for traceability.
- Do not use domains outside learn.microsoft.com as evidence sources.
