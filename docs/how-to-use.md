# How To Use The Azure Training Agent Skills Package

## Purpose

This guide explains how to operate the skill package in Visual Studio Code from first-time setup to day-to-day use in authoring, self-paced delivery, learner resume, and quality control.

## What this package contains

### Skills

1. .github/skills/azure-training-orchestrator
2. .github/skills/azure-service-path-apps
3. .github/skills/azure-scenario-engine
4. .github/skills/azure-assessment-engine
5. .github/skills/azure-source-grounding
6. .github/skills/azure-learner-state
7. .github/skills/azure-quality-gates

### Prompts

1. .github/prompts/azure-training-author.prompt.md
2. .github/prompts/azure-self-paced-session.prompt.md
3. .github/prompts/azure-learner-resume.prompt.md
4. .github/prompts/azure-self-paced-review.prompt.md

### Runtime data

1. training-data/learners
2. training-data/checkpoints

## Prerequisites

1. Visual Studio Code with GitHub Copilot access.
2. Agent mode enabled in chat.
3. Agent Skills enabled in settings.
4. Open this folder as the active workspace root.

## Step 1: Verify skills and prompts are in the expected locations

Confirm these folders exist:

1. .github/skills
2. .github/prompts
3. training-data/learners
4. training-data/checkpoints

If these are present, VS Code can discover the skills and prompts.

## Step 2: Enable Agent Skills in VS Code

Open Settings and enable chat.useAgentSkills.

Recommended additional setting:

1. Keep custom instructions concise and project-specific.
2. Use skills for workflows, not for broad coding style rules.

## Step 3: Confirm discovery in chat

1. Open Copilot Chat.
2. Type slash.
3. Verify these entries appear:
- azure-training-author
- azure-self-paced-session
- azure-learner-resume
- azure-self-paced-review

If they do not appear:

1. Re-open the workspace folder.
2. Confirm SKILL names match their directory names exactly.
3. Confirm prompt files end with .prompt.md.
4. Reload window.

## Operating modes

### Mode A: Author a full training program

Use prompt: /azure-training-author

Provide input like:

1. Audience role and level.
2. Duration and weekly time.
3. Industry context.
4. Azure service focus.
5. Constraints: budget, compliance, SLO, region.

What happens behind the scenes:

1. Orchestrator builds curriculum skeleton and objective map.
2. Service-path skill builds Azure module content and labs.
3. Scenario engine adds realistic implementation scenarios.
4. Assessment engine builds checks and final assessment.
5. Source-grounding validates claims with learn.microsoft.com proof links and confidence labels.
6. Quality-gates evaluates release readiness.

Expected output:

1. Program timeline and modules.
2. Objective-linked assessments.
3. Scenario artifacts.
4. Trust report with learn.microsoft.com proof links and confidence labels.
5. Pass or fail quality decision with remediation steps.

### Mode B: Run a self-paced learning session

Use prompt: /azure-self-paced-session

Provide input like:

1. Learner ID.
2. Course ID.
3. Session duration.
4. Target module or objective.

What happens:

1. Learner state is validated or resumed.
2. Session objective is delivered with independent activity.
3. Formative check runs and weak areas are detected.
4. Recap is generated.
5. State is saved with a new checkpoint and token.

Expected output:

1. Session objective summary.
2. Self-paced task list and completion criteria.
3. Check results and weak area notes.
4. New checkpoint confirmation.

### Mode C: Resume interrupted learning

Use prompt: /azure-learner-resume

Provide input like:

1. Learner ID.
2. Optional resume token.
3. Session window if needed.

What happens:

1. State and token are validated.
2. Learner cursor is restored exactly.
3. If token mismatch occurs, recovery checkpoint is used.
4. Brief reactivation recap is delivered.
5. Session continues and a new checkpoint is saved.

Expected output:

1. Resume validation status.
2. Restored module, lesson, objective, activity index.
3. Recovery details if applicable.
4. Next action estimate.

### Mode D: Run a weekly self-paced progress review

Use prompt: /azure-self-paced-review

Provide input like:

1. Learner ID.
2. Course ID.
3. Review window such as last 7 days.
4. Optional target completion date.

What happens:

1. Learner state and checkpoints are analyzed.
2. Weak areas and trend patterns are identified.
3. A targeted remediation plan is generated.
4. Updated next-week goals are persisted to learner state.

Expected output:

1. Weekly progress delta.
2. Ranked weak objectives with evidence.
3. Remediation plan with time budget and goals.
4. Checkpoint update confirmation.

## Learner state operations

### Where state lives

1. Primary learner file: training-data/learners/<learner-id>.json
2. Checkpoint snapshots: training-data/checkpoints/<learner-id>-<timestamp>.json

### State schema

Use schema at:

1. .github/skills/azure-learner-state/state.schema.json

Core tracked fields:

1. current pointer for exact resume location
2. progress percentages by module
3. quiz and practical score history
4. weak areas with evidence
5. checkpoint timeline
6. resume token metadata
7. privacy retention values

### Resume token generation

Token helper script:

1. .github/skills/azure-learner-state/resume-token.ps1

Use case:

1. Validate token integrity from stable learning coordinates.
2. Detect tampered or stale resume state.

## Source-grounding and trust checks

Mandatory policy:

1. Use only learn.microsoft.com links as sources for training claims.
2. Every key claim must include a verifiable proof link to learn.microsoft.com.
3. Any claim without a learn.microsoft.com proof link is unverified and must not be released.

### When to run

1. Before publishing any module set.
2. Before final assessments.
3. When confidence is low or claims are uncertain.

### How to run

1. Invoke source-grounding skill from prompt workflow.
2. Ensure each key claim has a learn.microsoft.com proof link and confidence label.
3. Reject outputs with unsupported claims.
4. Reject outputs with source links outside learn.microsoft.com.

Checklist reference:

1. .github/skills/azure-source-grounding/verification-checklist.md

## Quality-gate enforcement

### What is checked

1. Pedagogy completeness across all modules.
2. Learner continuity and resume integrity.
3. Proof-link and confidence coverage for key claims.
4. learn.microsoft.com-only evidence compliance.
5. Scenario realism dimensions.
6. Assessment-to-objective mapping.

Test plan reference:

1. .github/skills/azure-quality-gates/test-cases.md

Release decision policy:

1. Any critical failure blocks release.
2. Major failures require remediation before release.

## Scenario generation best practice

Use scenario engine to create practice labs with all required dimensions:

1. architecture
2. operations
3. security
4. cost
5. troubleshooting

Catalog reference:

1. .github/skills/azure-scenario-engine/scenario-catalog.yaml

Recommended prompt additions:

1. Add industry and role explicitly.
2. Add realistic constraints and SLA/SLO values.
3. Ask for one failure injection and one trade-off analysis.

## Typical end-to-end runbook

1. Start with /azure-training-author and produce draft program.
2. Review quality report and remediate failures.
3. Publish module set for delivery.
4. Run /azure-self-paced-session for each learner session.
5. Save checkpoint every session.
6. Run /azure-learner-resume when learner returns.
7. Run /azure-self-paced-review weekly to adapt remediation paths.
8. Use assessment outputs to advance or reinforce objectives.

## Troubleshooting

### Prompt not visible

1. Confirm file extension is .prompt.md.
2. Confirm workspace root is this project.
3. Reload VS Code window.

### Skill not triggering automatically

1. Improve trigger wording in skill description.
2. Invoke skill explicitly via slash command.
3. Keep prompt request specific to skill purpose.

### Resume fails

1. Validate learner JSON against schema.
2. Check token hash generation inputs.
3. Recover from latest checkpoint.

### Hallucination risk increases

1. Force source-grounding before output.
2. Mark uncertain claims.
3. Ask for verification tasks instead of speculative answers.

### Quality gate fails for evidence links

1. Replace non-Learn links with learn.microsoft.com links.
2. Add missing proof links for each key claim.
3. Re-run source-grounding and then quality-gates.

## Security and privacy defaults

1. Store only learner ID and minimal metadata.
2. Avoid personal sensitive data in learner files.
3. Keep retentionDays and purgeAfterUtc populated.
4. Do not store secrets in skill or prompt files.

## Team workflow recommendation

1. Keep skills and prompts in source control.
2. Require quality-gate pass before training release.
3. Version schema changes and maintain migration notes.
4. Review source-grounding reports in pull requests.

## Suggested first run

1. Run /azure-training-author with your real audience and constraints.
2. Review artifacts and verify learn.microsoft.com proof links for all key claims.
3. Run /azure-self-paced-session using learner sample-001.
4. Interrupt and test /azure-learner-resume.

## References in this repository

1. README.md
2. .github/prompts/README.md
