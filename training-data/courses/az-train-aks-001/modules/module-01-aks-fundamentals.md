# Module 01 — AKS Fundamentals and Architecture

**Objective IDs:** AKS-01, AKS-02, AKS-03, AKS-04  
**Estimated time:** 5 hours (3 h reading + 2 h lab)  
**Prerequisites:** Module 00  
**Lab:** Review AKS baseline architecture; create a minimal dev cluster with Bicep  

---

## Learning Objectives

- AKS-01: Explain the AKS control-plane vs. node-pool architecture.
- AKS-02: Compare networking options: Kubenet, Azure CNI, and Azure CNI Overlay.
- AKS-03: Describe node pool types, VM SKUs, and OS disk options.
- AKS-04: Explain the AKS baseline architecture with hub-spoke networking.

---

## 1. AKS Architecture Overview

### 1.1 Control plane vs. node pools

AKS is a **managed Kubernetes service**. Microsoft manages the control plane (API server, scheduler, controller manager, etcd). You manage the **node pools** — groups of Azure VMs that run your workload pods.

```
┌─────────────────────────────────────┐
│         Azure-managed               │
│  ┌─────────────────────────────┐    │
│  │  Kubernetes control plane   │    │
│  │  API Server · Etcd          │    │
│  │  Scheduler · Controller Mgr │    │
│  └──────────────┬──────────────┘    │
│                 │ kubelet            │
└─────────────────┼───────────────────┘
                  │
       ┌──────────┴──────────┐
       │   Node Pools         │
  ┌────┴────┐           ┌────┴────┐
  │ System  │           │  User   │
  │ pool    │           │  pool   │
  └─────────┘           └─────────┘
```

> **Key point:** AKS charges only for node VMs and associated resources. The control plane is free.

### 1.2 Node pool types

| Type   | Purpose                                           | Can be deleted?   |
| ------ | ------------------------------------------------- | ----------------- |
| System | Runs `kube-system` pods (CoreDNS, metrics-server) | No (one required) |
| User   | Runs workload pods                                | Yes               |

**Best practice:** Always have at least one dedicated system node pool. Taint user node pools with `CriticalAddonsOnly=true:NoSchedule` to prevent workload pods on system nodes.

### 1.3 VM SKU guidance

| Workload          | Recommended SKU family               |
| ----------------- | ------------------------------------ |
| General workloads | D-series v5 (e.g., Standard_D4ds_v5) |
| Memory-intensive  | E-series v5                          |
| GPU inference     | NC-series                            |
| Spot/batch        | any with spot priority               |

---

## 2. Networking Options

### 2.1 Comparison

| Option            | Pod IPs                    | Subnet consumption | Best for                       |
| ----------------- | -------------------------- | ------------------ | ------------------------------ |
| Kubenet           | From internal CIDR, NAT'd  | Low                | Dev/test only                  |
| Azure CNI         | From VNet subnet           | High               | Production (direct pod access) |
| Azure CNI Overlay | From separate overlay CIDR | Low                | Production (large clusters)    |

> **Production recommendation:** Use **Azure CNI Overlay** for new production clusters. Pod IPs come from a separate overlay CIDR that does not consume VNet address space, enabling large-scale deployments.

**Proof link:** [learn.microsoft.com/azure/aks/azure-cni-overlay](https://learn.microsoft.com/azure/aks/azure-cni-overlay) — Confidence: High

### 2.2 Network policy engines

| Engine    | Notes                                          |
| --------- | ---------------------------------------------- |
| Azure NPM | Microsoft-supported; integrates with Azure CNI |
| Calico    | Open-source; more features; community support  |
| Cilium    | eBPF-based; high performance; Azure-supported  |

---

## 3. AKS Baseline Architecture

The [AKS baseline architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks) defines the minimum recommended configuration for production:

- **Hub-spoke virtual network topology** (hub hosts firewall, bastion; spoke hosts AKS)
- **Private cluster** with API server VNet integration
- **Application Gateway WAF v2** in the spoke for ingress (AGIC)
- **System + user node pool** separation
- **Microsoft Entra ID** integration with Azure RBAC for Kubernetes
- **Container Insights** and **Log Analytics**
- **ACR with private endpoint**
- **Key Vault** for secrets

---

## 4. Lab 01 — Explore Dev Cluster Bicep

This lab deploys a minimal non-private AKS cluster for experimentation only. Production deployment is in Module 02.

### main.bicep (dev exploration only)

```bicep
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('AKS cluster name')
param clusterName string = 'aks-dev-lab01'

@description('Log Analytics workspace resource ID for Container Insights')
param logAnalyticsWorkspaceId string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.29'
    dnsPrefix: '${clusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 2
        vmSize: 'Standard_D4ds_v5'
        osType: 'Linux'
        osDiskSizeGB: 128
        osDiskType: 'Ephemeral'
        mode: 'System'
        nodeTaints: ['CriticalAddonsOnly=true:NoSchedule']
      }
      {
        name: 'userpool'
        count: 2
        vmSize: 'Standard_D4ds_v5'
        osType: 'Linux'
        osDiskSizeGB: 128
        osDiskType: 'Ephemeral'
        mode: 'User'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'azure'
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
    }
    enableRBAC: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
  }
}

output clusterName string = aksCluster.name
output kubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
```

### Deploy command

```powershell
# AKS-04 Lab: Deploy dev cluster
$rg = 'rg-aks-spoke-dev'
$law = (az monitor log-analytics workspace show `
    --resource-group $rg `
    --workspace-name 'law-aks-dev' `
    --query id -o tsv)

az deployment group what-if `
    --resource-group $rg `
    --template-file .\main.bicep `
    --parameters logAnalyticsWorkspaceId=$law

az deployment group create `
    --resource-group $rg `
    --template-file .\main.bicep `
    --parameters logAnalyticsWorkspaceId=$law
```

---

## Checkpoint M01

1. (AKS-01) What components are managed by Microsoft in AKS?
2. (AKS-02) Why is Azure CNI Overlay preferred over Kubenet for production?
3. (AKS-03) Why should system and user node pools be separated?
4. (AKS-04) List three components from the AKS baseline architecture.

**Pass criterion:** Answer all four correctly before progressing to Module 02.

---

## Recap

- AKS control plane is managed by Microsoft; you manage node pools.
- Use Azure CNI Overlay for production to avoid VNet IP exhaustion.
- Separate system and user node pools for stability.
- The AKS baseline is your architecture starting point for production.

---

## Proof Links

| Claim                      | Source                                                                                                                                                                                           | Confidence |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| AKS baseline architecture  | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks) | High       |
| Azure CNI Overlay          | [learn.microsoft.com/azure/aks/azure-cni-overlay](https://learn.microsoft.com/azure/aks/azure-cni-overlay)                                                                                       | High       |
| System vs. user node pools | [learn.microsoft.com/azure/aks/use-system-pools](https://learn.microsoft.com/azure/aks/use-system-pools)                                                                                         | High       |
| Ephemeral OS disk for AKS  | [learn.microsoft.com/azure/aks/cluster-configuration#ephemeral-os](https://learn.microsoft.com/azure/aks/cluster-configuration#ephemeral-os)                                                     | High       |
