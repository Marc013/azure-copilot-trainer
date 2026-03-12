# Validation Checklist and Test Plan

## Critical checks

1. Every module includes prerequisites, objectives, checks, recap, and assessment mapping.
2. Learner state validates against schema and resume token verification works.
3. Every key claim has at least one verifiable proof link on learn.microsoft.com and a confidence label.
4. Every scenario includes architecture, operations, security, cost, troubleshooting.
5. Every assessment item maps to objective ID.
6. No training evidence links point to domains outside learn.microsoft.com.

## Major checks

1. Adaptation rules are defined for weak areas.
2. Final rubric includes explicit pass thresholds.
3. Checkpoint snapshots are immutable and appended.

## Minor checks

1. Skill descriptions include clear trigger phrases.
2. Assets are referenced by relative path.
3. Schema version is present and documented.

## Failure conditions

- Critical failure blocks release.
- Two or more major failures block release.
- Any unknown schema version blocks resume operations.

## Test scenarios

1. Happy path: build course, run assessments, save checkpoint, resume after restart.
2. Token mismatch: detect mismatch, recover from latest checkpoint, confirm with learner.
3. Missing citation: fail source-grounding gate with remediation task.
4. Objective drift: detect unmapped assessment item and fail quality gate.
5. Scenario incompleteness: detect missing cost or troubleshooting dimension.
6. Non-Learn link detected: fail release and require link replacement.
