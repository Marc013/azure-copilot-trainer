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

## Constraints

- Each item must map to a single objective ID.
- Include answer key and rationale for each objective.
- Include partial-credit policy for practical tasks.
- Include learn.microsoft.com proof links for technical answer keys and rationales.
