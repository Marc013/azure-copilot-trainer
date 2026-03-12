# Module 10 — Governance and Cost Management

**Objective IDs:** GOV-01, GOV-02, GOV-03, GOV-04  
**Estimated time:** 5 hours (2 h reading + 3 h lab)  
**Prerequisites:** Module 04  
**Lab:** Apply Azure Policy; set namespace resource quotas; analyse cost  

---

## Learning Objectives

- GOV-01: Apply built-in Azure Policy definitions to enforce the AKS security baseline.
- GOV-02: Implement namespace resource quotas and limit ranges.
- GOV-03: Analyse AKS cost with Azure Cost Management and understand cost drivers.
- GOV-04: Apply AKS cost-optimisation recommendations: spot node pools and right-sizing.

---

## 1. Azure Policy for AKS (GOV-01)

Azure Policy can enforce Kubernetes admission controls via the **Gatekeeper** OPA component, which is automatically installed when the Azure Policy add-on is enabled.

### 1.1 Enable via Bicep

```bicep
addonProfiles: {
  azurepolicy: {
    enabled: true
  }
}
```

### 1.2 Recommended built-in policy assignments

| Policy                                                                         | Effect | Why                             |
| ------------------------------------------------------------------------------ | ------ | ------------------------------- |
| Kubernetes clusters should not allow container privilege escalation            | Deny   | Prevent container escapes       |
| Kubernetes clusters should not grant CAP_SYS_ADMIN capability                  | Deny   | Block privileged operations     |
| Kubernetes cluster containers should run with read-only root filesystem        | Audit  | Immutable containers            |
| Kubernetes clusters should use internal load balancers                         | Audit  | Internal traffic only           |
| Kubernetes cluster containers CPU and memory resource limits should not exceed | Deny   | Prevent resource monopolisation |
| Kubernetes clusters should not allow privileged containers                     | Deny   | Container isolation             |

```powershell
# GOV-01: Assign AKS restricted security baseline initiative
$scope  = '/subscriptions/<SUB_ID>/resourceGroups/rg-aks-spoke-dev'
$policy = az policy set-definition list `
    --query "[?contains(displayName,'Kubernetes cluster pod security')].id" -o tsv | Select-Object -First 1

az policy assignment create `
    --name 'aks-pod-security-baseline' `
    --scope $scope `
    --policy-set-definition $policy `
    --display-name 'AKS Pod Security Baseline'
```

---

## 2. Namespace Resource Quotas (GOV-02)

Resource quotas prevent a single namespace from consuming all cluster capacity.

```yaml
# GOV-02: Namespace ResourceQuota for aks-store-demo
apiVersion: v1
kind: ResourceQuota
metadata:
  name: store-demo-quota
  namespace: aks-store-demo
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    persistentvolumeclaims: "10"
    count/pods: "50"
    count/services: "20"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: store-demo-limits
  namespace: aks-store-demo
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      max:
        cpu: "2"
        memory: "4Gi"
```

---

## 3. Cost Analysis (GOV-03)

### 3.1 AKS cost components

| Component               | Cost driver               |
| ----------------------- | ------------------------- |
| Node VMs                | Size × count × hours      |
| OS disks                | Managed disk size         |
| Load Balancers          | Per-rule + data processed |
| Egress (Azure Firewall) | Per GB processed          |
| Log Analytics           | Per GB ingested           |
| ACR                     | Storage + operations      |

### 3.2 Cost Management PowerShell

```powershell
# GOV-03: Get daily AKS spend for the last 30 days
$subscriptionId = (az account show --query id -o tsv)
$startDate = (Get-Date).AddDays(-30).ToString('yyyy-MM-dd')
$endDate   = (Get-Date).ToString('yyyy-MM-dd')

az costmanagement query `
    --type Usage `
    --scope "subscriptions/$subscriptionId" `
    --dataset-filter '{
        "and": [{
            "dimensions": {
                "name": "ResourceGroupName",
                "operator": "In",
                "values": ["rg-aks-spoke-dev"]
            }
        }]
    }' `
    --timeframe Custom `
    --time-period start=$startDate end=$endDate `
    --dataset-granularity Daily `
    --output table
```

---

## 4. Cost Optimisation (GOV-04)

### 4.1 Spot node pools

Spot VMs offer up to 90% discount but can be evicted. Use for fault-tolerant workloads only.

```bicep
{
  name: 'spotpool'
  scaleSetPriority: 'Spot'
  scaleSetEvictionPolicy: 'Delete'
  spotMaxPrice: -1              // -1 means current spot price cap
  nodeTaints: ['kubernetes.azure.com/scalesetpriority=spot:NoSchedule']
  enableAutoScaling: true
  minCount: 0
  maxCount: 20
  vmSize: 'Standard_D4ds_v5'
  mode: 'User'
}
```

Use a `tolerations` block in pod specs to schedule on spot:

```yaml
tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
```

### 4.2 Right-sizing recommendations

```powershell
# GOV-04: List AKS Advisor cost recommendations
az advisor recommendation list `
    --category Cost `
    --resource-group 'rg-aks-spoke-dev' `
    --query "[?contains(resourceMetadata.resourceId,'managedClusters')]" `
    --output table
```

---

## Checkpoint M10

1. (GOV-01) What admission controller does Azure Policy use inside AKS?
2. (GOV-02) What happens when a pod in a namespace exceeds the `LimitRange` max CPU?
3. (GOV-03) Name three cost drivers for an AKS cluster.
4. (GOV-04) Why should spot node pools not run stateful workloads?

**Pass criterion:** All four correct.

---

## Proof Links

| Claim                      | Source                                                                                                                                                                                     | Confidence |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| Azure Policy for AKS       | [learn.microsoft.com/azure/aks/policy-reference](https://learn.microsoft.com/azure/aks/policy-reference)                                                                                   | High       |
| Kubernetes resource quotas | [learn.microsoft.com/azure/aks/operator-best-practices-scheduler#enforce-resource-quotas](https://learn.microsoft.com/azure/aks/operator-best-practices-scheduler#enforce-resource-quotas) | High       |
| AKS spot node pools        | [learn.microsoft.com/azure/aks/spot-node-pool](https://learn.microsoft.com/azure/aks/spot-node-pool)                                                                                       | High       |
| Azure Cost Management      | [learn.microsoft.com/azure/cost-management-billing/costs/quick-acm-cost-analysis](https://learn.microsoft.com/azure/cost-management-billing/costs/quick-acm-cost-analysis)                 | High       |
