---
mode: agent
description: Run one autonomous self-paced learning session from an existing Azure training program, include checks and recap, and checkpoint learner progress for continuity.
---

# Azure Self-Paced Session Mode

Run one learner-driven session and save continuity state.

## Inputs

- Learner ID.
- Course ID.
- Session length.
- Current module or objective focus.

## Required execution order

1. Run /azure-learner-state with action validate or resume for the learner.
2. Load current module objectives and prerequisite reminders from the course artifacts.
3. Deliver autonomous lesson flow:
- objective briefing
- independent implementation activity — must include a Bicep IaC task and a PowerShell automation task
- check for understanding
- quick recap
4. Run /azure-assessment-engine to generate a short formative check for the session objective. Validate any Bicep or PowerShell items using the respective MCP servers before presenting them.
5. Run /azure-learner-state with action save to persist progress and generate a fresh resume token.

## Output format

1. Session objective(s) and expected outcomes.
2. Self-paced task steps and completion criteria.
3. Check-for-understanding results and weak area detection.
4. Recap summary and one transfer question.
5. Checkpoint confirmation with module/objective cursor and resume token status.

## Safety and trust rules

- If confidence is low for technical claims, run /azure-source-grounding. Use `microsoft_docs_search` and `microsoft_docs_fetch` to retrieve current learn.microsoft.com documentation before presenting final guidance.
- Keep learner data minimal and avoid sensitive personal details.
- For any technical guidance provided, include verifiable proof links to learn.microsoft.com sourced from MCP retrieval only.
