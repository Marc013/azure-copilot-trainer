# Module Checkpoint Reference — AKS Training Program

> This file contains the diagnostic questions and expected answers for every per-module checkpoint.
> Use during self-assessment or facilitated review sessions.

---

## Module 00 — Prerequisites (PRE)

### Checkpoint PRE-01: Tool Validation

**Q1.** Run `az aks get-versions --location eastus2 --query "values[?isPreview==false].version" -o tsv`. What determines whether a version appears in this list for your target region?

**Expected A:** AKS manages GA Kubernetes versions per region. A version is available only after Microsoft validates and certifies it for that region. Preview versions require the `--allow-experimental-features` flag and are not suitable for production.

**Q2.** Why must you run `kubelogin convert-kubeconfig -l azurecli` before using `kubectl` against an AKS cluster with `disableLocalAccounts: true`?

**Expected A:** When local accounts are disabled, the kubeconfig credential references Entra ID OAuth tokens, not static bearer tokens. `kubelogin` is a credential plugin that handles the Entra ID OAuth flow. Without it, `kubectl` cannot acquire tokens and all API calls return 401 Unauthorized.
Source: https://learn.microsoft.com/azure/aks/managed-azure-ad

---

## Module 01 — AKS Fundamentals (AKS)

### Checkpoint AKS-01: Control Plane vs Node Pool

**Q1.** Contoso has 3 dev node pools with 2 nodes each and 1 production node pool with 5 nodes. How many control planes are running? Who manages them?

**Expected A:** One control plane per AKS cluster. Microsoft fully manages it (patching, scaling, HA). You are not billed for the control plane in standard tier — only node VMs. If multiple AKS clusters exist, each has its own independent control plane.

**Q2.** A system node pool is tainted with `CriticalAddonsOnly=true:NoSchedule`. The team tries to schedule a user workload without a toleration. What happens?

**Expected A:** The pod is not scheduled to the system node pool — it receives a `PodUnschedulable` status until a user node pool without the taint is available. This ensures system components (CoreDNS, metrics-server) are not evicted by user workloads.

### Checkpoint AKS-02: Networking

**Q3.** Compare Azure CNI and Azure CNI Overlay: which one consumes IP addresses from the VNet subnet for every pod?

**Expected A:** Azure CNI (classic) assigns each pod a VNet IP — this exhausts the IP range quickly in large clusters. Azure CNI Overlay uses a separate pod CIDR (e.g., 192.168.0.0/16) that is only routable within the cluster. The VNet only sees node IPs, greatly reducing VNet IP consumption.
Source: https://learn.microsoft.com/azure/aks/azure-cni-overlay

---

## Module 02 — Private Cluster Networking (NET)

### Checkpoint NET-01: Private Cluster Access

**Q1.** Why can't an Azure DevOps Microsoft-hosted agent run `kubectl apply` against the private AKS cluster deployed in lab-02?

**Expected A:** The private AKS API server has no public IP — it only has a private endpoint reachable within the spoke VNet (or via VNet peering/Private Link). Microsoft-hosted agents run on Microsoft-managed IPs outside the spoke VNet. Self-hosted agents deployed inside the spoke VNet (or connected VNet) can reach the private API server.

### Checkpoint NET-02: AGIC Constraints

**Q2.** You deploy two AKS clusters in the same spoke VNet and both have AGIC enabled as an add-on. Can they share one Application Gateway? Why or why not?

**Expected A:** No. The AGIC add-on claims exclusive ownership of the Application Gateway. Each AGIC instance must manage a dedicated Application Gateway. Sharing one Gateway between two AGIC instances would cause both controllers to overwrite each other's routing rules.
Source: https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview

### Checkpoint NET-03: Network Policy

**Q3.** You apply a `NetworkPolicy` that selects `app: order-service` and sets `podSelector: {}` for ingress. What does an empty `podSelector` mean?

**Expected A:** An empty `podSelector` (`{}`) selects ALL pods in the namespace. Combined with the policy, it means all pods in the namespace are allowed to send ingress traffic to `order-service`. To restrict access, specify `matchLabels` to select only the intended callers.

---

## Module 03 — ACR Integration (ACR)

### Checkpoint ACR-01: SKU Selection

**Q1.** The team wants to use ACR content trust (image signing) and geo-replication. Which ACR SKU is required?

**Expected A:** Premium. Premium is the only SKU that supports private endpoints, geo-replication, content trust (Notary), dedicated data endpoints, and customer-managed keys. Basic and Standard are suitable for development only.
Source: https://learn.microsoft.com/azure/container-registry/container-registry-skus

### Checkpoint ACR-02: Image Pull Authentication

**Q2.** What is the correct RBAC role assignment to allow AKS nodes to pull images from ACR without storing credentials?

**Expected A:** Assign the built-in `AcrPull` role (ID: `7f951dda-4ed3-4680-a7ca-43fe172d538d`) on the ACR resource to the **kubelet managed identity** object ID. The kubelet identity is the one attached to node pool VMs — not the control plane identity. This eliminates the need for `imagePullSecrets` in pod specs.
Source: https://learn.microsoft.com/azure/aks/cluster-container-registry-integration

---

## Module 04 — Identity and Security (IDN)

### Checkpoint IDN-01: Managed Entra ID

**Q1.** When `enableAzureRBAC: true` is set on the AKS `aadProfile`, which Kubernetes RBAC objects (ClusterRole, RoleBinding) are still valid?

**Expected A:** When Azure RBAC is enabled, Azure built-in roles (e.g., `Azure Kubernetes Service RBAC Cluster Admin`) are evaluated in addition to — but with higher precedence than — native Kubernetes RBAC. Native ClusterRoles and RoleBindings still function for service accounts and pod identities. Human Entra ID users/groups should use Azure role assignments, not native Kubernetes ClusterRoleBindings.

### Checkpoint IDN-02: Workload Identity Flow

**Q2.** Draw the token exchange sequence for an `order-service` pod using Workload Identity to authenticate to Azure Service Bus. What happens at each step?

**Expected A (5 steps):**
1. Kubernetes projects a **signed service account token** (signed by the cluster OIDC issuer) into the pod at `/var/run/secrets/azure/tokens/azure-identity-token`.
2. The Azure SDK in `order-service` reads the projected token file.
3. The SDK calls the **Azure AD token endpoint** (`login.microsoftonline.com`), presenting the SA token + client ID of the managed identity.
4. Azure AD validates the token signature using the cluster's OIDC **public keys** (published at `<oidcIssuerUrl>/.well-known/openid-configuration`).
5. Azure AD returns a **short-lived Azure access token**. The SDK uses this to authenticate to Service Bus.
Source: https://learn.microsoft.com/azure/aks/workload-identity-overview

### Checkpoint IDN-03: Kubernetes RBAC

**Q3.** A developer asks to give the `order-service` service account read-only access to Kubernetes `Secret` resources in the `aks-store-demo` namespace. What is the minimum RBAC manifest?

**Expected A:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: aks-store-demo
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: order-service-secret-reader
  namespace: aks-store-demo
subjects:
  - kind: ServiceAccount
    name: workload-identity-sa
    namespace: aks-store-demo
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## Module 05 — CI/CD Azure DevOps (CICD)

### Checkpoint CICD-01: Service Connection Type

**Q1.** The team asks whether to use a **Kubernetes service connection** or an **Azure Resource Manager service connection** for the `KubernetesManifest@1` task. Which should they choose for the private cluster, and why?

**Expected A:** Azure Resource Manager (ARM) service connection. The Kubernetes service connection type uses a static service account token stored in Azure DevOps — this token is long-lived and must be rotated manually. The ARM connection uses short-lived Azure credentials at runtime (`az aks get-credentials`) and respects the cluster's Entra ID RBAC. For a private cluster with `disableLocalAccounts: true`, the ARM connection is the only supported option.
Source: https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/kubernetes-manifest-v1?view=azure-pipelines

### Checkpoint CICD-02: Image Tag Strategy

**Q2.** The pipeline uses `$(Build.BuildId)` as the image tag. What is the risk of using `latest` instead, and how does the `KubernetesManifest@1` `containers` parameter mitigate it?

**Expected A:** Using `latest` means every deployment pulls the most recent image — there is no immutable reference to a specific build. If a bad image is tagged `latest` and rolled out, rolling back with `kubectl rollout undo` restores the previous deployment spec, but the **image** pulled may still be `latest` (already overwritten). The `containers` parameter in `KubernetesManifest@1` performs token substitution — it replaces image references in manifests with `<repo>:<BuildId>`, ensuring each deployment is pinned to a specific, immutable image digest.

---

## Module 06 — Observability (OBS)

### Checkpoint OBS-01: Container Insights Tables

**Q1.** Which Log Analytics table would you query to find all pod restarts in the last hour across the cluster?

**Expected A:** `KubePodInventory` — it tracks pod state, restart count, container status, and namespace. Example query:
```kql
KubePodInventory
| where TimeGenerated > ago(1h)
| where ContainerRestartCount > 0
| project TimeGenerated, PodName, Namespace, ContainerRestartCount
| order by ContainerRestartCount desc
```

### Checkpoint OBS-02: Alert Threshold

**Q2.** You want an alert that fires when any container restart count exceeds 5 in a 10-minute window. Write the KQL condition.

**Expected A:**
```kql
KubePodInventory
| where TimeGenerated > ago(10m)
| summarize MaxRestarts = max(ContainerRestartCount) by PodName, Namespace
| where MaxRestarts > 5
```
Threshold: `ResultCount > 0` (alert fires if any row matches the `where MaxRestarts > 5` condition).

---

## Module 07 — Scaling (SCA)

### Checkpoint SCA-01: HPA Prerequisites

**Q1.** HPA scales based on CPU utilization percentage. What is the **prerequisite** in the pod spec for HPA to function?

**Expected A:** Resource `requests` must be defined for the containers being scaled. HPA calculates utilization as `current CPU usage / requested CPU`. If `requests` are not set, utilization is undefined and HPA cannot calculate a target value — the HPA object will show `<unknown>/50%` and no scaling will occur.

### Checkpoint SCA-02: Cluster Autoscaler Interaction

**Q2.** HPA has scaled `order-service` to 10 replicas but nodes are at 90% CPU. No new nodes are joining. What is the most likely cause?

**Expected A:** The node pool `maxCount` in the Cluster Autoscaler configuration is set too low (e.g., 3 nodes). The Autoscaler respects the max boundary and will not provision nodes beyond it. Check `az aks nodepool show --query "maxCount"`. Increase `maxCount` to allow further scaling.

---

## Module 08 — Upgrades and Maintenance (UPG)

### Checkpoint UPG-01: Upgrade Channels

**Q1.** What is the difference between `upgradeChannel: patch` and `upgradeChannel: stable`?

**Expected A:** 
- `patch`: Auto-upgrades to the latest **patch version** of the currently running minor version (e.g., 1.29.3 → 1.29.5). Does not perform minor version upgrades.
- `stable`: Auto-upgrades to the latest **patch of the N-1 latest minor version** (one minor version behind latest GA). Provides stability while staying current.
Source: https://learn.microsoft.com/azure/aks/auto-upgrade-cluster

### Checkpoint UPG-02: Disruption Budgets

**Q2.** During a node image upgrade, AKS cordons and drains nodes one at a time by default. What Kubernetes object tells AKS the minimum number of replicas that must remain available during the drain?

**Expected A:** `PodDisruptionBudget` (PDB). Example that requires at least 1 `order-service` replica to remain available:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service-pdb
  namespace: aks-store-demo
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: order-service
```

---

## Module 09 — Backup and DR (BDR)

### Checkpoint BDR-01: Backup Scope

**Q1.** Azure Backup for AKS backs up Kubernetes resources (Deployments, Services, ConfigMaps, etc.) and persistent volume snapshots. What does it **not** back up, and what must be backed up separately?

**Expected A:** AKS Backup does not back up the cluster configuration (node pools, VMSS settings, add-on configs described in Bicep). The cluster infrastructure must be backed up through Bicep/IaC in source control. The cluster configuration (Kubernetes object manifests) and PV snapshots are what AKS Backup covers.
Source: https://learn.microsoft.com/azure/backup/azure-kubernetes-service-backup-overview

---

## Module 10 — Governance and Cost (GOV)

### Checkpoint GOV-01: Policy Enforcement

**Q1.** A pod is deployed with `hostNetwork: true`. Azure Policy is assigned with `EnforcementMode: Default` for the no-host-network policy. What happens to the pod?

**Expected A:** The API server rejects the pod creation request with a `403 Forbidden` response. The OPA/Gatekeeper admission controller intercepts the CREATE request before the pod is written to etcd. In `Default` enforcement mode, non-compliant resources are blocked at admission time, not just flagged.

### Checkpoint GOV-02: Cost Optimization

**Q2.** The team wants to run batch processing jobs on cheaper hardware without impacting production workloads. What AKS feature enables this, and what Kubernetes construct must batch jobs include?

**Expected A:** Spot node pools (`scaleSetPriority: Spot`). Spot VMs are up to 90% cheaper but can be evicted with 30 seconds notice when Azure reclaims capacity. Batch jobs must include the spot toleration:
```yaml
tolerations:
  - key: kubernetes.azure.com/scalesetpriority
    operator: Equal
    value: spot
    effect: NoSchedule
```
Jobs must also be designed for interruption — using Kubernetes `Job` resources with `restartPolicy: OnFailure` so incomplete work is retried on another spot node.
Source: https://learn.microsoft.com/azure/aks/spot-node-pool
