---
name: azure-learner-state
description: Persist, restore, and validate learner progress for Azure training with checkpoints and resume tokens. Use when pausing sessions, resuming after interruption, or analyzing weak areas and progress trends.
argument-hint: [learner-id] [save|resume|validate] [course-id]
---

# Azure Learner State Manager

## Purpose

Maintain deterministic learner continuity across sessions.

## Storage contract

- Primary state file: `training-data/learners/<learner-id>.json`
- Checkpoint snapshot: `training-data/checkpoints/<learner-id>-<timestamp>.json`
- Schema: [state schema](./state.schema.json)

## Save workflow

1. Load existing learner state or create new from schema.
2. Update current module, objective pointer, scores, weak areas, and checkpoint log.
3. Generate resume token using [resume-token.ps1](./resume-token.ps1).
4. Write primary state file and immutable checkpoint snapshot.
5. Return confirmation payload with token and next recommended step.

## Resume workflow

1. Read learner state file.
2. Validate schema version and required fields.
3. Recompute token checksum and compare with stored token.
4. If valid, restore module/objective cursor and pending tasks.
5. If invalid, recover using latest checkpoint and mark `recoveryMode=true`.

## Safety rules

- Never delete checkpoints automatically.
- Never overwrite state without appending checkpoint.
- Avoid PII beyond learner ID and optional alias.
