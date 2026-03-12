---
mode: agent
description: Run a self-paced weekly progress review for one learner, analyze weak areas and trend data, and produce a targeted remediation plan with next-week goals.
---

# Azure Self-Paced Progress Review Mode

Run a periodic learner review and adapt the training path.

## Inputs

- Learner ID.
- Course ID.
- Review window (for example: last 7 days).
- Optional target completion date.

## Required execution order

1. Run /azure-learner-state with action validate or resume.
2. Extract progress, score trends, and weak areas from learner state and checkpoints.
3. Run /azure-assessment-engine to generate a short diagnostic check for top weak objectives.
4. Map remediation tasks to objective IDs and service modules.
5. Run /azure-source-grounding for any new technical claims in remediation guidance.
6. Run /azure-learner-state with action save to persist updated remediation plan and next checkpoint.

## Output format

1. Weekly progress summary with completion percentage delta.
2. Strongest and weakest objective IDs with evidence.
3. Remediation plan for next week with time budget and measurable goals.
4. Suggested session cadence for self-paced execution.
5. Checkpoint update confirmation and resume token status.

## Decision rules

- If quiz average < 0.75, schedule foundational remediation before advanced labs.
- If practical average < 0.80, assign guided troubleshooting tasks.
- If no weak areas remain high severity, advance to the next module.

## Safety and trust rules

- Do not fabricate trend data if state history is incomplete.
- Mark uncertain recommendations and include verification tasks when needed.
- Support technical recommendations with proof links from learn.microsoft.com only.
