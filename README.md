# Azure Training Agent Skills Starter Package

<!-- ![azure-copilot-trainer][1] -->
<center><img src="./docs/media/azure_copilot_trainer.png" alt="azure-copilot-trainer" width="75%"/></center>

This package provides a production-ready blueprint and starter implementation for GitHub Copilot Agent Skills in VS Code focused on Azure training delivery.

## What you get

- Composable skills for course orchestration, service-specific instruction, learner state, anti-hallucination checks, scenario generation, assessment, and quality gates.
- Persistent learner progress model for pause/resume continuity.
- Guardrails for source-grounded answers and uncertainty handling.
- Scenario framework for role/industry/constraint-based implementation labs.
- Validation checklist and test cases for acceptance.

## Prerequisites

- VS Code with GitHub Copilot and Agent mode enabled.
- Agent Skills enabled: setting `chat.useAgentSkills` = true.
- Skills stored in `.github/skills` (project-level, versioned with repo).

## Skill map

1. `azure-training-orchestrator`: Creates and adapts the full training path.
2. `azure-service-path-apps`: Generates service modules for Azure App Service, Functions, Storage, Key Vault, Monitor.
3. `azure-learner-state`: Saves/restores learner state and resume token.
4. `azure-source-grounding`: Applies anti-hallucination checks and citation policy.
5. `azure-scenario-engine`: Generates realistic architecture and operations scenarios.
6. `azure-assessment-engine`: Builds formative/summative checks with remediation.
7. `azure-quality-gates`: Enforces objective acceptance checks and fail conditions.

## Suggested invocation order

1. `/azure-training-orchestrator Create a 6-week Azure app platform track for platform engineers`
2. `/azure-service-path-apps build modules for the generated track`
3. `/azure-scenario-engine generate scenarios for healthcare and fintech`
4. `/azure-assessment-engine create module quizzes and capstone rubric`
5. `/azure-quality-gates validate track artifacts against acceptance criteria`
6. `/azure-learner-state checkpoint learner Marc profile`

## Prompt pack workflows

- `/.github/prompts/azure-training-author.prompt.md`: complete authoring and quality gate workflow.
- `/.github/prompts/azure-self-paced-session.prompt.md`: autonomous learner session and checkpoint workflow.
- `/.github/prompts/azure-learner-resume.prompt.md`: deterministic resume and recovery workflow.
- `/.github/prompts/azure-self-paced-review.prompt.md`: periodic progress review and remediation planning workflow.

Use from chat by typing `/` and selecting:

1. `/azure-training-author`
2. `/azure-self-paced-session`
3. `/azure-learner-resume`
4. `/azure-self-paced-review`

## Data location for learner state

- `training-data/learners/<learner-id>.json`
- `training-data/checkpoints/<learner-id>-<timestamp>.json`

## Security defaults

- Minimize PII. Store learner ID and optional display alias only.
- Keep confidence labels and evidence links for generated content.
- Set retention and purge policy before production use.

## Source policy (mandatory)

- Use only learn.microsoft.com as evidence source when building training content.
- Every key training claim must include a verifiable proof link to learn.microsoft.com.
- Claims without learn.microsoft.com proof links must be treated as unverified and excluded from release output.

For a full operational guide, see [docs/how-to-use.md](docs/how-to-use.md).

[1]: /docs/media/azure_copilot_trainer.png
