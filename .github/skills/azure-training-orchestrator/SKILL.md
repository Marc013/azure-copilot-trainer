---
name: azure-training-orchestrator
description: Build and adapt complete Azure training programs with prerequisites, learning objectives, module flow, checks, recap, and final assessment. Use when designing end-to-end training paths, sequencing modules, or remediating learning gaps.
argument-hint: [audience] [duration] [target services] [constraints]
---

# Azure Training Orchestrator

## Purpose

Create a complete training plan that is pedagogically structured and operationally feasible.

## Use when

- A new Azure training program is needed.
- Existing training needs objective mapping and sequencing.
- A learner needs adaptive remediation in self-paced flow.

## Inputs required

1. Audience profile: role, baseline skill, goals.
2. Program constraints: duration, delivery mode, time per week.
3. Azure scope: services and architecture focus.
4. Success criteria: measurable outcomes and pass thresholds.

## Workflow

1. Load [course template](./course-template.yaml).
2. Define prerequisite matrix and objective map.
3. Generate module sequence with dependency graph.
4. For each module, produce:
- Prerequisites
- Learning objectives
- Content blocks
- Check-for-understanding
- Recap
- Assessment mapping
5. Insert adaptation rules based on quiz/practical performance.
6. Send content to source-grounding and quality-gates skills.
7. Return publication-ready program output.

## Output contract

- Program overview with timeline.
- Module list with objective IDs.
- Assessment blueprint and thresholds.
- Adaptation rules and remediation paths.
- Handoff list for scenario and assessment skills.
- Proof links section for every module and assessment claim using learn.microsoft.com URLs only.

## Composition rules

- Delegate service-specific module content to `/azure-service-path-apps`.
- Delegate realism to `/azure-scenario-engine`.
- Delegate trust checks to `/azure-source-grounding`.
- Delegate scoring assets to `/azure-assessment-engine`.
- Delegate acceptance checks to `/azure-quality-gates`.
- Do not include claims without learn.microsoft.com proof links.
