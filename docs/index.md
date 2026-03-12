---
title: Home
nav_order: 1
description: A production-ready blueprint for GitHub Copilot Agent Skills in VS Code, focused on Azure training delivery.
permalink: /
---

<section class="hero">
  <div>
    <div class="hero-kicker">Azure Training • MCP Powered • Agent Driven</div>
    <h1>Build Azure training that feels like a live platform, not static documentation.</h1>
    <p>
      This site packages GitHub Copilot Agent Skills, Azure MCP tools, Bicep validation,
      PowerShell automation, and Microsoft Learn grounding into one repeatable training workflow.
    </p>
    <div class="hero-actions">
      <a class="btn btn-primary" href="{{ '/how-to-use/' | relative_url }}">Start With The Setup Guide</a>
      <a class="btn btn-secondary" href="{{ '/how-to-use/#using-the-prompts' | relative_url }}">Jump To Prompt Workflows</a>
    </div>
  </div>
  <aside class="hero-panel">
    <h3>Delivery Stack</h3>
    <div class="hero-stats">
      <div class="hero-stat">
        <strong>4</strong>
        Prompts that run end-to-end delivery workflows.
      </div>
      <div class="hero-stat">
        <strong>4</strong>
        MCP servers grounding Azure docs, IaC, and automation.
      </div>
      <div class="hero-stat">
        <strong>7</strong>
        Skills composing orchestration, assessment, quality, and learner state.
      </div>
      <div class="hero-stat">
        <strong>Learn</strong>
        Every key claim is grounded in learn.microsoft.com evidence.
      </div>
    </div>
  </aside>
</section>

<div class="azure-callout">
  <strong>What this is for:</strong> teams building guided Azure learning paths with hands-on Bicep deployment labs,
  PowerShell automation, learner checkpointing, remediation, and release-quality trust controls.
</div>

## What You Get

<section class="azure-grid">
  <article class="azure-card">
    <div class="azure-chip">Orchestration</div>
    <h3>Composable agent skills</h3>
    <p>Create full training programs with dedicated skills for service modules, scenarios, assessments, learner state, source-grounding, and quality gates.</p>
  </article>
  <article class="azure-card">
    <div class="azure-chip">Hands-On</div>
    <h3>Infrastructure and automation built in</h3>
    <p>Every training path includes Bicep IaC tasks and PowerShell automation work so learners practice real deployment and operations flows.</p>
  </article>
  <article class="azure-card">
    <div class="azure-chip">Trust</div>
    <h3>Grounded outputs only</h3>
    <p>Technical claims are validated against Microsoft Learn, with confidence labels and evidence links before content is considered releasable.</p>
  </article>
  <article class="azure-card">
    <div class="azure-chip">Continuity</div>
    <h3>Learner progress survives interruptions</h3>
    <p>Checkpoint snapshots and resume tokens let learners pause and continue without losing their exact objective and activity position.</p>
  </article>
</section>

## Prompt Workflows

<section class="azure-grid">
  <article class="azure-card">
    <div class="azure-chip">Author</div>
    <h3><code>/azure-training-author</code></h3>
    <p>Generates a complete Azure training program with modules, labs, scenarios, assessments, a trust report, and a quality-gate decision.</p>
  </article>
  <article class="azure-card">
    <div class="azure-chip">Session</div>
    <h3><code>/azure-self-paced-session</code></h3>
    <p>Runs one timed self-paced session for a learner, including a Bicep lab, a PowerShell task, a recap, and a saved checkpoint.</p>
  </article>
  <article class="azure-card">
    <div class="azure-chip">Resume</div>
    <h3><code>/azure-learner-resume</code></h3>
    <p>Restores the learner to the last validated checkpoint and continues the session, with automatic checkpoint recovery when needed.</p>
  </article>
  <article class="azure-card">
    <div class="azure-chip">Review</div>
    <h3><code>/azure-self-paced-review</code></h3>
    <p>Analyzes learner progress, detects weak areas, and builds a remediation plan with next-step Bicep and PowerShell exercises.</p>
  </article>
</section>

## MCP Server Integration

<div class="azure-table">

| Server              | Purpose                                                                | Why It Matters                                                                          |
| ------------------- | ---------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Azure MCP           | Azure best practices, resource schemas, and service documentation      | Keeps architecture and service guidance aligned with current Azure recommendations.     |
| Microsoft Learn MCP | Documentation search, full-page retrieval, official code samples       | Prevents unsupported claims and provides traceable evidence.                            |
| Bicep MCP           | Bicep best practices, file diagnostics, resource schemas, AVM metadata | Makes infrastructure labs accurate, validated, and aligned with current Bicep patterns. |
| PowerShell MCP      | Script execution, syntax validation, automation task tooling           | Ensures automation exercises are executable instead of theoretical.                     |

</div>

## How The Experience Fits Together

<section class="azure-grid">
  <article class="azure-card">
    <h3><span class="azure-chip">1</span> Set up VS Code, extensions, and MCP servers</h3>
    <p>Install the required tooling and confirm Agent mode plus MCP services are active.</p>
  </article>
  <article class="azure-card">
    <h3><span class="azure-chip">2</span> Generate a training track</h3>
    <p>Use the authoring prompt to create a role-based Azure program with scenarios, labs, and assessments.</p>
  </article>
  <article class="azure-card">
    <h3><span class="azure-chip">3</span> Deliver sessions and checkpoint learners</h3>
    <p>Run self-paced sessions, persist learner state, and recover seamlessly after interruptions.</p>
  </article>
  <article class="azure-card">
    <h3><span class="azure-chip">4</span> Review progress and tighten weak areas</h3>
    <p>Use the weekly review prompt to adapt the path based on objective-level performance trends.</p>
  </article>
</section>

## Get Started

See [How To Use]({{ '/how-to-use/' | relative_url }}) for the full step-by-step setup and operating guide.

## Source Policy

All training content generated by this package is grounded in [learn.microsoft.com](https://learn.microsoft.com) exclusively. Every key claim includes a verifiable proof link. Claims without a proof link are marked Unverified and excluded from release output.
