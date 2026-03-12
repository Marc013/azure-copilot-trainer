# Module 08 — Upgrades and Maintenance

**Objective IDs:** UPG-01, UPG-02, UPG-03  
**Estimated time:** 4 hours (2 h reading + 2 h lab)  
**Prerequisites:** Module 02, Module 04  
**Lab:** Set auto-upgrade channel; perform manual node-pool upgrade with PowerShell  

---

## Learning Objectives

- UPG-01: Set cluster auto-upgrade channel and node OS auto-upgrade channel.
- UPG-02: Perform manual control-plane and node-pool upgrade with zero downtime.
- UPG-03: Configure planned maintenance windows for upgrade operations.

---

## 1. Auto-Upgrade Channels

AKS supports automatic upgrades for both the Kubernetes version and node OS images.

### 1.1 Kubernetes version upgrade channels

| Channel    | Behaviour                            | Recommended for                      |
| ---------- | ------------------------------------ | ------------------------------------ |
| none       | No automatic upgrades                | Manual control only                  |
| patch      | Upgrade to latest patch within minor | Production (conservative)            |
| stable     | Upgrade to latest minor – 1          | Staging                              |
| rapid      | Upgrade to latest minor              | Dev/test                             |
| node-image | Only upgrade node OS image           | Combined with `patch` for production |

**Recommended production combination:** `patch` + `NodeImage` OS upgrade.

```bicep
// UPG-01: Auto-upgrade configuration
autoUpgradeProfile: {
  upgradeChannel: 'patch'
  nodeOSUpgradeChannel: 'NodeImage'
}
```

**Proof link:** [learn.microsoft.com/azure/aks/auto-upgrade-cluster](https://learn.microsoft.com/azure/aks/auto-upgrade-cluster) — Confidence: High

---

## 2. Maintenance Windows (UPG-03)

Maintenance windows allow you to schedule upgrades to avoid business-critical hours.

```bicep
// UPG-03: Maintenance window — Sundays 02:00–06:00 UTC
maintenanceConfiguration: {
  name: 'aksManagedAutoUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Sunday'
        }
      }
      durationHours: 4
      startTime: '02:00'
      utcOffset: '+00:00'
    }
    notAllowedTime: [
      {
        start: '2026-12-24T00:00:00Z'
        end: '2026-12-26T00:00:00Z'
      }
    ]
  }
}
```

---

## 3. Manual Upgrade Procedure (UPG-02)

### 3.1 Pre-upgrade checklist

- [ ] Check available upgrade versions: `az aks get-upgrades`
- [ ] Verify node pool has enough surge capacity (PodDisruptionBudgets respected)
- [ ] Confirm maintenance window allows the operation
- [ ] Notify stakeholders
- [ ] Back up critical data (see Module 09)

### 3.2 PowerShell upgrade runbook

```powershell
<#
.SYNOPSIS
    AKS cluster upgrade runbook — performs control plane then node pool upgrade.
.PARAMETER ResourceGroup
    Resource group containing the AKS cluster.
.PARAMETER ClusterName
    Name of the AKS cluster to upgrade.
.PARAMETER TargetVersion
    Target Kubernetes version, e.g., '1.30.2'.
#>
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroup,

    [Parameter(Mandatory)]
    [string]$ClusterName,

    [Parameter(Mandatory)]
    [string]$TargetVersion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Step 1: Confirm available upgrades
Write-Host "=== Available upgrade versions ===" -ForegroundColor Cyan
az aks get-upgrades `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --output table

# Step 2: Upgrade control plane
Write-Host "=== Upgrading control plane to $TargetVersion ===" -ForegroundColor Cyan
az aks upgrade `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --kubernetes-version $TargetVersion `
    --control-plane-only `
    --yes

# Step 3: Upgrade each node pool (one at a time for zero downtime)
$nodePools = az aks nodepool list `
    --resource-group $ResourceGroup `
    --cluster-name $ClusterName `
    --query '[].name' -o tsv

foreach ($pool in $nodePools) {
    Write-Host "=== Upgrading node pool: $pool ===" -ForegroundColor Cyan

    az aks nodepool upgrade `
        --resource-group $ResourceGroup `
        --cluster-name $ClusterName `
        --name $pool `
        --kubernetes-version $TargetVersion `
        --no-wait

    # Poll until upgrade is complete
    do {
        Start-Sleep -Seconds 60
        $provState = az aks nodepool show `
            --resource-group $ResourceGroup `
            --cluster-name $ClusterName `
            --name $pool `
            --query 'provisioningState' -o tsv

        Write-Host "  Node pool $pool provisioning state: $provState"
    } while ($provState -eq 'Upgrading')

    if ($provState -ne 'Succeeded') {
        throw "Node pool $pool upgrade failed. State: $provState"
    }

    Write-Host "  ✓ Node pool $pool upgraded" -ForegroundColor Green
}

# Step 4: Validate
Write-Host "=== Cluster upgrade complete ===" -ForegroundColor Green
az aks show `
    --resource-group $ResourceGroup `
    --name $ClusterName `
    --query '{ version: kubernetesVersion, state: provisioningState }' `
    --output table
```

---

## Troubleshooting Drills

| Symptom                                          | Cause                                | Resolution                                                          |
| ------------------------------------------------ | ------------------------------------ | ------------------------------------------------------------------- |
| Node pool upgrade stuck in `Upgrading` for > 2 h | PDB blocking eviction                | Check `kubectl get pdb -A`; adjust `maxUnavailable`                 |
| Pods not rescheduled after node drain            | Insufficient capacity in other nodes | Add a temporary surge nodepool before upgrade                       |
| Cluster version not in available list            | Skipping minor version               | Must upgrade minor versions sequentially (e.g., 1.28 → 1.29 → 1.30) |

---

## Checkpoint M08

1. (UPG-01) What is the recommended production auto-upgrade channel combination?
2. (UPG-02) Why should control plane be upgraded before node pools?
3. (UPG-03) What field in the maintenance window configuration prevents upgrades on specific dates?

**Pass criterion:** All three correct.

---

## Proof Links

| Claim                       | Source                                                                                                                 | Confidence |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ---------- |
| AKS auto-upgrade channels   | [learn.microsoft.com/azure/aks/auto-upgrade-cluster](https://learn.microsoft.com/azure/aks/auto-upgrade-cluster)       | High       |
| Node OS auto-upgrade        | [learn.microsoft.com/azure/aks/auto-upgrade-node-image](https://learn.microsoft.com/azure/aks/auto-upgrade-node-image) | High       |
| Planned maintenance windows | [learn.microsoft.com/azure/aks/planned-maintenance](https://learn.microsoft.com/azure/aks/planned-maintenance)         | High       |
| Manual cluster upgrade      | [learn.microsoft.com/azure/aks/upgrade-aks-cluster](https://learn.microsoft.com/azure/aks/upgrade-aks-cluster)         | High       |
