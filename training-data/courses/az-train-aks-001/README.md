# AKS Production Training Program

**Role:** Azure Engineer (limited AKS experience)  
**Audience:** Cloud engineers moving from IaaS/PaaS to container-based workloads on AKS  
**Duration:** 12 weeks · ~8 hours/week  
**Delivery:** Self-paced with hands-on labs, checkpoints, and a final scenario assessment  
**Date authored:** March 12, 2026  

---

## Program Goals

| #   | Goal                                                                       |
| --- | -------------------------------------------------------------------------- |
| 1   | Cover AKS fundamentals through enterprise-grade operations                 |
| 2   | Deploy Azure-Samples/aks-store-demo to AKS using ACR as the image registry |
| 3   | Use Azure DevOps Pipeline for CI/CD to AKS                                 |
| 4   | Implement Application Gateway Ingress Controller (AGIC) for ingress        |
| 5   | Operate a private AKS cluster with private networking                      |

---

## Directory Layout

```
AKS-training/
├── README.md                     ← This file (program overview)
├── program-overview.md           ← Full timeline, module table, objective map
├── modules/
│   ├── module-00-prerequisites.md
│   ├── module-01-aks-fundamentals.md
│   ├── module-02-private-cluster-networking.md
│   ├── module-03-acr-integration.md
│   ├── module-04-identity-security.md
│   ├── module-05-cicd-azure-devops.md
│   ├── module-06-observability.md
│   ├── module-07-scaling.md
│   ├── module-08-upgrades-maintenance.md
│   ├── module-09-backup-dr.md
│   └── module-10-governance-cost.md
├── labs/
│   ├── lab-02-private-cluster/   ← Bicep IaC for private AKS + AGIC
│   ├── lab-03-acr/               ← Bicep IaC for ACR + AKS attachment
│   ├── lab-04-identity/          ← Bicep IaC for workload identity
│   ├── lab-05-cicd/              ← Azure DevOps pipeline YAML
│   ├── lab-06-observability/     ← Bicep for Log Analytics + alerts
│   ├── lab-07-scaling/           ← HPA and KEDA manifests
│   ├── lab-08-upgrades/          ← PowerShell upgrade runbook
│   └── lab-11-aks-store-demo/    ← End-to-end scenario manifests
├── scenarios/
│   ├── scenario-01-production-incident.md
│   └── scenario-02-security-hardening.md
├── assessment/
│   ├── module-checks.md
│   └── final-assessment.md
├── trust-report.md               ← Source grounding + proof links
└── quality-gates.md              ← Pass/fail quality gate report
```

---

## Quick Start

1. Review this README and `program-overview.md` for the full module sequence.
2. Complete prerequisites in `modules/module-00-prerequisites.md`.
3. Work through modules 01–10 in order; each module contains a lab and a checkpoint.
4. Complete both scenarios in `scenarios/`.
5. Attempt the final assessment in `assessment/final-assessment.md`.

---

## Confidence and Source Policy

> Every key technical claim in this program has a **learn.microsoft.com** proof link
> sourced via MCP retrieval. Claims without a verifiable link are labelled **Unverified**.
> See `trust-report.md` for the full evidence table.
