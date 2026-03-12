# Module 05 — CI/CD with Azure DevOps Pipelines

**Objective IDs:** CICD-01, CICD-02, CICD-03, CICD-04  
**Estimated time:** 6 hours (2 h reading + 4 h lab)  
**Prerequisites:** Module 03 (ACR), Module 04 (Identity)  
**Lab:** Build Azure DevOps pipeline that builds aks-store-demo images, pushes to ACR, and deploys to AKS  

---

## Learning Objectives

- CICD-01: Create Azure DevOps pipeline with Docker build stage pushing to ACR.
- CICD-02: Add KubernetesManifest deploy stage using ARM service connection to private AKS.
- CICD-03: Implement environment gates and approval policies.
- CICD-04: Configure image tag strategy and rollback trigger.

---

## 1. Pipeline Architecture

```
┌──────────────────────────────────────────────────────┐
│  Azure DevOps Pipeline                               │
│                                                      │
│  Stage 1: Build                                      │
│  ┌─────────────────────────────────────────────┐     │
│  │ Docker build → ACR push (tag: $(Build.BuildId))│  │
│  └─────────────────────────────────────────────┘     │
│                    │                                 │
│  Stage 2: Deploy-Dev (auto-trigger)                  │
│  ┌─────────────────────────────────────────────┐     │
│  │ KubernetesManifest deploy → dev namespace   │     │
│  └─────────────────────────────────────────────┘     │
│                    │                                 │
│  Stage 3: Deploy-Prod (manual approval gate)         │
│  ┌─────────────────────────────────────────────┐     │
│  │ KubernetesManifest deploy → prod namespace  │     │
│  └─────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────┘
```

---

## 2. Important: ARM Service Connection for Private AKS

For a **private AKS cluster with local accounts disabled**, use the **Azure Resource Manager** service connection type (not a Kubernetes service connection). The ARM connection defers cluster access to pipeline runtime, using a short-lived token — the [Kubernetes recommended approach](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1#remarks).

> "For AKS customers, the Azure Resource Manager service connection type provides the best method to connect to a private cluster, or a cluster that has local accounts disabled."  
> — [learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1#remarks](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1#remarks) — Confidence: High

**Requirements:**
- The pipeline agent must have network line-of-sight to the private API server.
- Use a **self-hosted agent** deployed into the spoke VNet (or a scale-set agent pool in the VNet).

---

## 3. Pipeline YAML

See the full pipeline at [labs/lab-05-cicd/azure-pipelines.yml](../labs/lab-05-cicd/azure-pipelines.yml).

### Key stages summary

**Stage 1 — Build & Push**

```yaml
- task: Docker@2
  displayName: 'Build and push store-front'
  inputs:
    containerRegistry: 'sc-acr'           # ACR service connection
    repository: 'aks-store-demo/store-front'
    command: buildAndPush
    Dockerfile: 'src/store-front/Dockerfile'
    tags: |
      $(Build.BuildId)
      latest
```

**Stage 2/3 — Deploy to AKS (ARM connection)**

```yaml
- task: KubernetesManifest@1
  displayName: 'Deploy store-front to AKS'
  inputs:
    action: deploy
    connectionType: azureResourceManager
    azureSubscriptionConnection: 'sc-aks-spoke'    # ARM service connection
    azureResourceGroup: 'rg-aks-spoke-dev'
    kubernetesCluster: 'aks-prod-01'
    namespace: 'aks-store-demo'
    manifests: |
      labs/lab-11-aks-store-demo/manifests.yaml
    containers: |
      $(ACR_NAME).azurecr.io/aks-store-demo/store-front:$(Build.BuildId)
```

---

## 4. Image Tag Strategy

| Tag                                          | When used                       | Immutable?                             |
| -------------------------------------------- | ------------------------------- | -------------------------------------- |
| `$(Build.BuildId)`                           | Every build — unique, traceable | Yes                                    |
| `latest`                                     | Convenience alias               | No — do not use for production deploys |
| `v1.2.3`                                     | Semantic version from git tag   | Yes                                    |
| `$(Build.SourceBranchName)-$(Build.BuildId)` | Feature branch tracking         | Yes                                    |

**Production rule:** Always deploy with a specific, immutable tag (BuildId or semver). Never deploy using `latest` in production pipelines.

---

## 5. Environment Gates

```yaml
# CICD-03: Approval gate on prod environment
environments:
  - name: production
    approvals:
      - type: manualApproval
        requiresApprovers: true
        approvers:
          - group: 'Platform-Engineers'
        minimumApprovers: 1
        timeout: 1440  # 24 hours in minutes
```

---

## 6. Rollback Trigger

```powershell
# CICD-04: PowerShell rollback on deployment failure
# Run as a post-deployment script or on pipeline failure

param(
    [string]$Namespace     = 'aks-store-demo',
    [string]$Deployment    = 'store-front',
    [string]$ResourceGroup = 'rg-aks-spoke-dev',
    [string]$ClusterName   = 'aks-prod-01'
)

# Authenticate to private cluster via ARM
az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --overwrite-existing

# Check rollout status
$status = kubectl rollout status deployment/$Deployment -n $Namespace --timeout=5m 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Deployment $Deployment failed — initiating rollback"
    kubectl rollout undo deployment/$Deployment -n $Namespace

    # Verify rollback
    kubectl rollout status deployment/$Deployment -n $Namespace --timeout=5m
    Write-Host "Rollback complete. Current revision:" -ForegroundColor Yellow
    kubectl rollout history deployment/$Deployment -n $Namespace
} else {
    Write-Host "✓ Deployment $Deployment is healthy" -ForegroundColor Green
}
```

---

## 7. Self-Hosted Agent Setup

```powershell
# Deploy a Linux self-hosted agent in the spoke VNet
# This allows the agent to reach the private AKS API server

# Create a VMSS-based agent pool (recommended over single VMs)
az vmss create `
    --resource-group 'rg-aks-spoke-dev' `
    --name 'vmss-ado-agents' `
    --image 'Ubuntu2204' `
    --instance-count 2 `
    --vnet-name 'vnet-spoke' `
    --subnet 'snet-aks-nodes' `
    --public-ip-address ""   # No public IP — use NAT gateway or Azure Firewall for outbound
```

---

## Checkpoint M05

1. (CICD-01) What two artifacts does the Docker@2 task produce?
2. (CICD-02) Why must the pipeline agent be within the spoke VNet for a private AKS cluster?
3. (CICD-03) What happens if no approver acts within the approval timeout?
4. (CICD-04) What `kubectl` command rolls back a failed deployment?

**Pass criterion:** All four correct.

---

## Proof Links

| Claim                                  | Source                                                                                                                                                                                         | Confidence |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| Azure DevOps CI/CD to AKS              | [learn.microsoft.com/azure/aks/devops-pipeline](https://learn.microsoft.com/azure/aks/devops-pipeline)                                                                                         | High       |
| ARM service connection for private AKS | [learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1#remarks](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1#remarks) | High       |
| Build CI/CD pipeline for AKS apps      | [learn.microsoft.com/azure/architecture/guide/aks/aks-cicd-azure-pipelines](https://learn.microsoft.com/azure/architecture/guide/aks/aks-cicd-azure-pipelines)                                 | High       |
| KubernetesManifest task                | [learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1)                 | High       |
| AKS automated deployments              | [learn.microsoft.com/azure/aks/automated-deployments](https://learn.microsoft.com/azure/aks/automated-deployments)                                                                             | High       |
