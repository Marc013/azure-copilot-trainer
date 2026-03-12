# Module 09 — Backup, Disaster Recovery, and Business Continuity

**Objective IDs:** BDR-01, BDR-02, BDR-03  
**Estimated time:** 5 hours (2 h reading + 3 h lab)  
**Prerequisites:** Module 04  
**Lab:** Enable Azure Backup for AKS; create a backup policy; restore workload state  

---

## Learning Objectives

- BDR-01: Install and configure Azure Backup for AKS.
- BDR-02: Create backup policies for cluster state and persistent volumes.
- BDR-03: Execute a restore operation and validate workload recovery.

---

## 1. Azure Backup for AKS

Azure Backup for AKS is a native cloud-scale backup solution that protects:
- Kubernetes cluster resources (Deployments, Services, ConfigMaps, etc.)
- Persistent Volume Claims (PVC) backed by Azure Disks

**Proof link:** [learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview) — Confidence: High

### 1.1 Prerequisites

| Requirement          | Notes                                                                              |
| -------------------- | ---------------------------------------------------------------------------------- |
| Backup Vault         | Create a Backup Vault in the same region as the cluster                            |
| Trusted access       | Enable `Microsoft.DataProtection/backupVaults` as a trusted service on the cluster |
| Blob storage account | Used as an intermediate staging location for backup data                           |
| Extension            | Azure Backup extension installed in the AKS cluster (`az k8s-extension`)           |

---

## 2. Bicep: Backup Vault

```bicep
// BDR-01: Backup Vault for AKS
resource backupVault 'Microsoft.DataProtection/backupVaults@2023-12-01' = {
  name: 'bvault-aks-prod'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        type: 'LocallyRedundant'    // Use 'GeoRedundant' for DR requirements
        datastoreType: 'VaultStore'
      }
    ]
  }
}

// Grant Backup Vault contributor access to AKS cluster
resource backupVaultAksContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(backupVault.id, aksCluster.id, 'contributor')
  scope: aksCluster
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    )
    principalId: backupVault.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

---

## 3. Backup Policy (BDR-02)

```bicep
resource backupPolicy 'Microsoft.DataProtection/backupVaults/backupPolicies@2023-12-01' = {
  name: 'policy-aks-daily'
  parent: backupVault
  properties: {
    datasourceTypes: ['Microsoft.ContainerService/managedClusters']
    objectType: 'BackupPolicy'
    policyRules: [
      {
        name: 'BackupHourly'
        objectType: 'AzureRetentionRule'
        isDefault: false
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P7D'  // Retain hourly backups for 7 days
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'OperationalStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
      }
      {
        name: 'Default'
        objectType: 'AzureRetentionRule'
        isDefault: true
        lifecycles: [
          {
            deleteAfter: {
              objectType: 'AbsoluteDeleteOption'
              duration: 'P30D'  // Retain daily backups for 30 days
            }
            targetDataStoreCopySettings: []
            sourceDataStore: {
              dataStoreType: 'VaultStore'
              objectType: 'DataStoreInfoBase'
            }
          }
        ]
      }
    ]
  }
}
```

---

## 4. Trigger and Validate Backup

```powershell
# BDR-02: Trigger an on-demand backup
$backupVaultRg   = 'rg-aks-ops-dev'
$backupVaultName = 'bvault-aks-prod'
$backupInstance  = 'aks-backup-instance'

az dataprotection backup-instance adhoc-backup `
    --resource-group  $backupVaultRg `
    --vault-name      $backupVaultName `
    --name            $backupInstance `
    --rule-name       'BackupHourly'

# Monitor job status
az dataprotection job list `
    --resource-group $backupVaultRg `
    --vault-name     $backupVaultName `
    --query "[?contains(properties.operationCategory,'Backup')]" `
    --output table
```

---

## 5. Restore Operation (BDR-03)

```powershell
# BDR-03: Restore AKS backup to a target cluster (can be same cluster, different namespace)
$recoveryPoint = az dataprotection recovery-point list `
    --resource-group  $backupVaultRg `
    --vault-name      $backupVaultName `
    --backup-instance-name $backupInstance `
    --query '[0].name' -o tsv

az dataprotection backup-instance restore trigger `
    --resource-group  $backupVaultRg `
    --vault-name      $backupVaultName `
    --backup-instance-name $backupInstance `
    --restore-request-object '{
        "objectType": "AzureWorkloadRestoreRequest",
        "recoveryPointId": "'"$recoveryPoint"'",
        "restoreTargetInfo": {
            "objectType": "RestoreTargetInfo",
            "recoveryOption": "FailIfExists",
            "restoreLocation": "eastus2",
            "datasourceInfo": {
                "resourceID": "/subscriptions/.../managedClusters/aks-prod-01",
                "datasourceType": "Microsoft.ContainerService/managedClusters"
            }
        }
    }'

# Validate: check pods are running after restore
kubectl get pods -n aks-store-demo
```

---

## 6. Multi-Region DR Design (Reference)

For RPO < 1 hour and RTO < 4 hours, consider:
- **Secondary AKS cluster** in a paired region (pre-provisioned with same Bicep)
- **Geo-replicated ACR** (`Premium` SKU)
- **Azure Front Door** for global traffic routing with health probes
- **Velero** as an alternative backup tool using Azure Blob as backend

---

## Checkpoint M09

1. (BDR-01) What two Azure roles must the Backup Vault identity have on the AKS cluster?
2. (BDR-02) What is the minimum retention duration recommended for a production backup policy?
3. (BDR-03) Does a restore operation require downtime of the target cluster?

**Pass criterion:** All three correct.

---

## Proof Links

| Claim                         | Source                                                                                                                                                                                                                               | Confidence |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| Azure Backup for AKS overview | [learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview)                                                                       | High       |
| AKS backup tutorial           | [learn.microsoft.com/azure/backup/azure-kubernetes-service-cluster-backup](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-cluster-backup)                                                                         | High       |
| AKS multi-region reference    | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-multi-region/aks-multi-cluster](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks-multi-region/aks-multi-cluster) | High       |
