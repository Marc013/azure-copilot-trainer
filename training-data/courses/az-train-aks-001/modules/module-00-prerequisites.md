# Module 00 — Prerequisites

**Objective IDs:** PRE-01, PRE-02, PRE-03  
**Estimated time:** 2 hours  
**Lab:** Environment validation script  

---

## Learning Objectives

After completing this module you will be able to:
- PRE-01: Configure the Azure subscription, resource groups, and initial RBAC to support all labs.
- PRE-02: Install and verify all required CLI tools and PowerShell modules.
- PRE-03: Access the Azure DevOps organisation and confirm pipeline permissions.

---

## 1. Azure Subscription Setup

### 1.1 Resource group naming convention

All labs use the following resource groups:

| Resource Group       | Purpose                                  |
| -------------------- | ---------------------------------------- |
| `rg-aks-hub-<env>`   | Hub VNet, Azure Firewall, Bastion        |
| `rg-aks-spoke-<env>` | AKS cluster, ACR, Key Vault, App Gateway |
| `rg-aks-ops-<env>`   | Log Analytics workspace, backup vault    |

Replace `<env>` with `dev`, `staging`, or `prod`.

### 1.2 Required RBAC assignments

| Principal                      | Role                                    | Scope                                      |
| ------------------------------ | --------------------------------------- | ------------------------------------------ |
| Your user account              | Owner                                   | Subscription (for RBAC delegation in labs) |
| Azure DevOps service principal | Contributor + User Access Administrator | `rg-aks-spoke-<env>`                       |

---

## 2. Tooling Installation

### 2.1 Required tools

| Tool                 | Minimum version                       | Install command                        |
| -------------------- | ------------------------------------- | -------------------------------------- |
| Azure CLI            | 2.56.0                                | `winget install Microsoft.AzureCLI`    |
| kubectl              | 1.29.x                                | `az aks install-cli`                   |
| Bicep CLI            | Latest (bundled with Azure CLI 2.48+) | `az bicep upgrade`                     |
| kubelogin            | Latest                                | `az aks install-cli` (included)        |
| PowerShell Az module | 11.0+                                 | `Install-Module Az -Scope CurrentUser` |
| Helm                 | 3.14+                                 | `winget install Helm.Helm`             |

### 2.2 PowerShell environment validation

```powershell
# PRE-02: Validate tooling
$tools = @{
    'az'         = 'az --version'
    'kubectl'    = 'kubectl version --client'
    'bicep'      = 'az bicep version'
    'kubelogin'  = 'kubelogin --version'
    'helm'       = 'helm version'
}

foreach ($tool in $tools.GetEnumerator()) {
    try {
        $output = Invoke-Expression $tool.Value 2>&1
        Write-Host "✓ $($tool.Key) available" -ForegroundColor Green
    } catch {
        Write-Warning "✗ $($tool.Key) not found — please install before proceeding"
    }
}

# Verify Az PowerShell module
if (Get-Module -ListAvailable Az.Aks) {
    Write-Host "✓ Az.Aks PowerShell module available" -ForegroundColor Green
} else {
    Write-Warning "Install-Module Az -Scope CurrentUser -Force"
}
```

---

## 3. Azure DevOps Prerequisites

1. Create (or confirm access to) an Azure DevOps organization and project named **AKSTraining**.
2. Create a service connection of type **Azure Resource Manager** using a service principal with **Contributor** on the spoke resource group. Name it `sc-aks-spoke`.
3. Create a variable group named `aks-training-vars` with:
   - `ACR_NAME` — your ACR registry name (set after Module 03)
   - `AKS_CLUSTER_NAME` — your cluster name (set after Module 02)
   - `RESOURCE_GROUP` — `rg-aks-spoke-dev`

---

## Checkpoint PRE

Answer the following before moving to Module 01:

1. What resource groups have you created?
2. Run the validation script above. All tools show ✓?
3. Can you run `az account show` and see your subscription?
4. Is the Azure DevOps service connection **Verified**?

**Pass criterion:** All four answers are Yes.

---

## Proof Links

| Claim                                    | Source                                                                                                                                             | Confidence |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| Install kubectl via `az aks install-cli` | [learn.microsoft.com/azure/aks/install-kubectl](https://learn.microsoft.com/azure/aks/install-kubectl)                                             | High       |
| Azure DevOps ARM service connection      | [learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure](https://learn.microsoft.com/azure/devops/pipelines/library/connect-to-azure) | High       |
