---
layout: default
title: Home
nav_order: 1
---

# Azure Copilot Trainer

<center>
  <img src="{{ '/media/azure_copilot_trainer.png' | relative_url }}" alt="Azure Copilot Trainer" width="60%" style="max-width: 400px; margin: 2rem 0;">
</center>

A production-ready blueprint and starter implementation for GitHub Copilot Agent Skills in VS Code focused on Azure training delivery.

## What You Get

- **Composable skills** for course orchestration, service-specific instruction, learner state, anti-hallucination checks, scenario generation, assessment, and quality gates.
- **Persistent learner progress** model for pause/resume continuity.
- **Guardrails** for source-grounded answers and uncertainty handling.
- **Scenario framework** for role/industry/constraint-based implementation labs.
- **Validation checklist** and test cases for acceptance.

## Key Features

- 🎯 Course orchestration with flexible learning paths
- 📊 Real-time learner state tracking and progress persistence
- 🛡️ Anti-hallucination checks with source grounding
- 🏗️ Scenario-based learning for real-world implementations
- ✅ Comprehensive assessment framework with remediation
- 🔐 Quality gates and acceptance criteria validation

## Get Started

To set up and use this package, see the [How To Use](./how-to-use.html) guide for step-by-step instructions.

## Prerequisites

- VS Code with GitHub Copilot and Agent mode enabled
- Agent Skills enabled: setting `chat.useAgentSkills` = true
- Node.js 18 or later
- Azure CLI (for Azure operations)
- Recommended VS Code extensions (detailed in setup guide)

## MCP Servers

This solution uses four powerful MCP servers:

| Server                  | Purpose                                | Provided By                                       |
| ----------------------- | -------------------------------------- | ------------------------------------------------- |
| **Azure MCP**           | Azure best practices, resource schemas | `ms-azuretools.vscode-azure-mcp-server` extension |
| **Microsoft Learn MCP** | Documentation search and code samples  | `.vscode/mcp.json` (npm)                          |
| **Bicep MCP**           | Infrastructure-as-code tooling         | `ms-azuretools.vscode-bicep` extension            |
| **PowerShell MCP**      | Automation and scripting               | `ms-vscode.powershell` extension                  |

---

**Ready to begin?** → [View Setup Instructions](./how-to-use.html)
