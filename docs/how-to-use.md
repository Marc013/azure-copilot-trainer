---
layout: default
title: How To Use
nav_order: 2
description: Step-by-step setup and usage instructions for the Azure Training Agent Skills package.
---

# How To Use The Azure Training Agent Skills Package

## Before you start

Install and configure the following before using this package.

### 1. Install Visual Studio Code

Download and install VS Code from code.visualstudio.com if you have not already done so.

### 2. Install Node.js 18 or later

The MCP servers configured in `.vscode/mcp.json` are started via `npx`. Node.js 18 or later is required.

1. Download Node.js from nodejs.org and run the installer.
2. Open a terminal and run the following to confirm the version:

   ```bash
   node --version
   ```

   The output must show `v18` or higher.

### 3. Install the Azure CLI and sign in

The Azure MCP server uses your active Azure CLI session.

1. Install the Azure CLI from [learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli).
2. Open a terminal and run:

   ```bash
   az login
   ```

3. Complete the browser sign-in. Confirm you are signed in to the correct tenant and subscription:

   ```bash
   az account show
   ```

### 4. Install GitHub Copilot in VS Code

1. Open VS Code.
2. Open the Extensions panel (`Ctrl+Shift+X`).
3. Search for **GitHub Copilot Chat** and install it.
4. Sign in with your GitHub account when prompted.

### 5. Install the recommended VS Code extensions

This workspace includes an `extensions.json` with all required extension recommendations.

1. Open VS Code.
2. Open the Extensions panel (`Ctrl+Shift+X`).
3. Click the filter icon in the search bar and select **Recommended**.
4. Install all of the following if they are not already installed:

   | Extension            | Publisher   | Purpose                                  |
   | -------------------- | ----------- | ---------------------------------------- |
   | GitHub Copilot Chat  | GitHub      | Agent mode and skills                    |
   | Azure GitHub Copilot | Microsoft   | Azure-aware Copilot guidance             |
   | Azure MCP Server     | Microsoft   | Azure MCP tools                          |
   | Bicep                | Microsoft   | Bicep MCP tools for IaC labs             |
   | PowerShell           | Microsoft   | PowerShell MCP tools for automation labs |
   | Markdown All in One  | Yu Zhang    | Markdown editing                         |
   | markdownlint         | David Anson | Markdown linting                         |

---

## Set up the workspace

### 1. Open the repo folder in VS Code

1. In VS Code, go to **File › Open Folder**.
2. Select the root of this repository (`azure-copilot-trainer`).
3. VS Code must have this exact folder as the workspace root for skills and prompts to be discovered correctly.

### 2. Accept the extension recommendations

If VS Code shows a notification asking you to install recommended extensions, click **Install All**.

---

## Start the MCP servers

This package uses four MCP servers. Two are started automatically from `.vscode/mcp.json`. Two are provided by installed extensions and require no manual action.

### Azure MCP server and Microsoft Learn MCP server

When you open the workspace, VS Code detects `.vscode/mcp.json` and offers to start the servers automatically.

1. Look for a notification in the bottom-right corner asking to start MCP servers.
2. Click **Start** or **Allow**.

If you do not see a notification, start them manually:

1. Open the Command Palette (`Ctrl+Shift+P`).
2. Type **MCP: Start Server** and press Enter.
3. Select `azure-mcp` and confirm.
4. Repeat and select `microsoft-learn-mcp`.

To verify both servers are running:

1. Open the **Output** panel (`Ctrl+Shift+U`).
2. In the dropdown, select **MCP: azure-mcp** and confirm no errors are shown.
3. In the dropdown, select **MCP: microsoft-learn-mcp** and confirm no errors are shown.

If the Azure MCP server fails to start, run `az login` in a terminal and try again.

If the Microsoft Learn MCP server fails to start, run `node --version` and confirm it shows v18 or higher.

### Bicep MCP server

No manual action required. The Bicep extension (`ms-azuretools.vscode-bicep`) automatically registers its MCP server when it is installed and active.

### PowerShell MCP server

No manual action required. The PowerShell extension (`ms-vscode.powershell`) automatically registers its MCP server when it is installed and active.

---

## Enable Agent Skills

1. Open VS Code Settings (`Ctrl+,`).
2. In the search box, type `chat.useAgentSkills`.
3. Check the box to set it to `true`.

---

## Switch Copilot Chat to Agent mode

1. Open Copilot Chat (`Ctrl+Alt+I`).
2. Click the mode selector in the chat input bar (it shows **Ask** or **Edit** by default).
3. Select **Agent**.

---

## Verify the setup

1. Open Copilot Chat in Agent mode.
2. Click inside the chat input bar.
3. Type `/` — a dropdown list of available prompts and skills should appear.
4. Confirm you see all four prompts:
   - `/azure-training-author`
   - `/azure-self-paced-session`
   - `/azure-learner-resume`
   - `/azure-self-paced-review`

If the prompts do not appear:

1. Confirm the workspace root is the `azure-copilot-trainer` folder (not a subfolder of it).
2. Confirm the four `.prompt.md` files exist in `.github/prompts/`.
3. Confirm `chat.useAgentSkills` is set to `true`.
4. Close and reopen VS Code, then check again.

---

## Using the prompts

Each prompt runs a full automated workflow using the installed skills and MCP servers. You do not need to call individual skills manually — the prompts orchestrate everything for you.

---

### `/azure-training-author` — Build a training program

Use this to generate a complete Azure training program from scratch.

**Steps:**

1. Open Copilot Chat in Agent mode.
2. Type `/` and select `/azure-training-author` from the list, or type it in full and press Enter.
3. In your message, describe the training program you want. Be specific about the audience, duration, services, and any constraints. Example:

   ```text
   Create a 4-week Azure training program for an intermediate platform engineer.
   Focus on Azure App Service, Azure Functions, Azure Storage, and Azure Key Vault.
   Use 4 hours per week. Include hands-on Bicep deployment labs, PowerShell automation
   tasks, checks for understanding, and a final assessment.
   Industry context: financial services with strict compliance requirements.
   ```

4. Wait for the agent to complete. It invokes multiple skills automatically and may take several minutes.

**What you will receive:**

- A full program timeline with module names and objective IDs.
- Hands-on lab steps including Bicep IaC exercises and PowerShell automation tasks.
- At least two realistic implementation scenarios by role and industry.
- Module quizzes and a final assessment with answer keys.
- A trust report listing learn.microsoft.com proof links for every key claim with confidence labels.
- A quality-gate result: **Pass** means the program is ready to use. **Fail** means corrective actions are listed that you must address before using.

**Example for an advanced AKS end-to-end request:**

```text
As an Azure engineer with limited knowledge of AKS, create a step-by-step training program
to implement, operate, and maintain AKS in production.

Goals:
- Cover AKS fundamentals through enterprise operations.
- Deploy the Azure-Samples/aks-store-demo app to AKS using ACR as the image registry.
- Use Azure DevOps pipeline for CI/CD to AKS.
- Use Application Gateway Ingress Controller (AGIC) for ingress.
- Implement a private AKS cluster with private networking.

Requirements:
- Progressive hands-on labs covering architecture, networking, security, identity, scaling,
  upgrades, observability, backup/DR, governance, and cost management.
- Bicep IaC labs for all infrastructure provisioning.
- PowerShell automation tasks for operational workflows.
- Checkpoints, practical validations, troubleshooting tasks, and final assessment.
- learn.microsoft.com proof links and confidence labels for all key claims.
```

---

### `/azure-self-paced-session` — Run a learning session

Use this to run one timed learning session for a specific learner on a specific objective.

**Steps:**

1. Open Copilot Chat in Agent mode.
2. Type `/` and select `/azure-self-paced-session`, or type it in full and press Enter.
3. Provide the following details in your message:

   ```text
   Learner ID: sample-001
   Course ID: az-train-apps-001
   Session length: 60 minutes
   Objective: M2.2
   ```

   A ready-to-use learner state file for `sample-001` already exists at `training-data/learners/sample-learner.json`. Use this learner ID for your first test run.

**What you will receive:**

- A session objective briefing with expected outcomes.
- A self-paced implementation task. It will always include a Bicep lab and a PowerShell automation task.
- A formative check for understanding with results and any detected weak areas.
- A recap summary and a transfer question.
- A checkpoint confirmation. The learner state file at `training-data/learners/sample-001.json` is saved automatically with an updated module/objective cursor and a new resume token.

---

### `/azure-learner-resume` — Resume an interrupted session

Use this when a learner needs to continue exactly where they left off.

**Steps:**

1. Open Copilot Chat in Agent mode.
2. Type `/` and select `/azure-learner-resume`, or type it in full and press Enter.
3. Provide the learner ID in your message:

   ```text
   Learner ID: sample-001
   ```

   You can also include the resume token if you have it from the last checkpoint output. It is optional.

**What you will receive:**

- A resume validation result:
  - **Valid** — the state file and token are intact, session continues from the saved position.
  - **Recovered** — the primary state was invalid and the latest checkpoint was used to restore position. The agent will tell you which checkpoint was used.
- The restored position: module, lesson, objective, and activity index.
- A brief reactivation recap of what was covered last.
- If high-severity weak areas are present from the previous session, a targeted remediation check runs automatically.
- The session then continues from the restored position and a new checkpoint is saved.

**If the resume fails entirely:**

The agent will describe the reason (missing state file, schema version mismatch, or token checksum failure) and tell you what minimum information is needed to create a recovery plan. Do not fabricate or manually edit state files.

---

### `/azure-self-paced-review` — Weekly progress review

Use this at the end of each week to review progress, find weak areas, and plan the next week.

**Steps:**

1. Open Copilot Chat in Agent mode.
2. Type `/` and select `/azure-self-paced-review`, or type it in full and press Enter.
3. Provide the following details in your message:

   ```text
   Learner ID: sample-001
   Course ID: az-train-apps-001
   Review window: last 7 days
   Target completion date: 2026-06-01
   ```

**What you will receive:**

- A weekly progress summary showing the completion percentage change over the review window.
- The strongest and weakest objective IDs with score evidence from quizzes and practicals.
- A remediation plan for the next week, including:
  - Time budget and measurable goals per objective.
  - Bicep lab exercises assigned to any IaC weak areas.
  - PowerShell tasks assigned to any automation weak areas.
- A suggested session cadence for the coming week.
- A checkpoint update confirmation with a new resume token.

**Remediation thresholds applied automatically:**

- Quiz average below 0.75: foundational remediation is scheduled before advanced labs.
- Practical average below 0.80: guided troubleshooting tasks are assigned.
- No high-severity weak areas remaining: the next module is unlocked automatically.

---

## Learner data files

Learner state is managed automatically by the prompts. You do not need to edit these files manually.

| Location                                                  | Purpose                                                                        |
| --------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `training-data/learners/<learner-id>.json`                | Primary learner state: current position, scores, weak areas, resume token      |
| `training-data/checkpoints/<learner-id>-<timestamp>.json` | Immutable checkpoint snapshots taken after each session                        |
| `training-data/learners/sample-learner.json`              | Pre-built sample state for learner `sample-001` — use this for your first test |

To add a new learner, simply provide a new learner ID in any prompt. The agent creates the state file on the first save.

Do not delete files in `training-data/checkpoints/`. They are the recovery source if the primary state file becomes corrupt or invalid.

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
3. Run /azure-self-paced-session using learner ID sample-001 from training-data/learners/sample-learner.json.
4. Interrupt and test /azure-learner-resume.

## References in this repository

1. README.md
2. .github/prompts/README.md
