# Final Assessment — AKS Platform Engineer Certification

> **Pass threshold:** 75% (27/36 points)  
> **Duration:** 90 minutes (open-book — documentation allowed, no AI assistance)  
> **Format:** 4 sections — multiple choice, short answer, Bicep task, PowerShell task  
> **Objective coverage:** All domains (PRE, AKS, NET, ACR, IDN, CICD, OBS, SCA, UPG, BDR, GOV)

---

## Assessment Instructions

- Read all questions before starting
- Bicep and PowerShell tasks should be written in the code blocks provided
- For multiple choice, select the single best answer unless "select all that apply" is stated
- Partial credit is awarded on Bicep/PowerShell tasks (see rubric)

---

## Section 1 — Multiple Choice (12 questions × 1 point = 12 points)

**1. (AKS-01)** Which AKS component handles the Kubernetes API server, etcd, and scheduler?

- A. Node pool  
- B. System node pool  
- C. Control plane ✓  
- D. VMSS extension

---

**2. (NET-01)** Your AKS cluster uses `outboundType: userDefinedRouting`. Node pods are failing to pull images from `mcr.microsoft.com`. What is the most likely cause?

- A. ACR private endpoint is missing  
- B. Azure Firewall application rule for `mcr.microsoft.com` is absent ✓  
- C. The node pool subnet has no Network Security Group  
- D. CoreDNS is not resolving external FQDNs

---

**3. (NET-02)** The AGIC add-on requires a dedicated Application Gateway. What is the minimum subnet CIDR size recommended for the Application Gateway subnet when using Azure CNI Overlay?

- A. /28  
- B. /27  
- C. /26  
- D. /24 ✓

---

**4. (ACR-01)** Which ACR SKU supports private endpoints AND geo-replication?

- A. Basic  
- B. Standard  
- C. Premium ✓  
- D. Enterprise

---

**5. (IDN-02)** In the Workload Identity flow, where does the Kubernetes API server publish its OIDC public keys so Azure AD can validate projected service account tokens?

- A. Key Vault  
- B. The pod's `/var/run/secrets` directory  
- C. The OIDC issuer URL (`<issuer>/.well-known/openid-configuration`) ✓  
- D. Azure Managed Identity endpoint

---

**6. (CICD-01)** A private AKS cluster has `disableLocalAccounts: true`. Which Azure DevOps service connection type is compatible with `KubernetesManifest@1`?

- A. Kubernetes service connection (service account)  
- B. Kubernetes service connection (kubeconfig)  
- C. Azure Resource Manager service connection ✓  
- D. GitHub service connection

---

**7. (OBS-01)** Which Log Analytics table stores container STDOUT/STDERR log lines from Container Insights?

- A. `KubePodInventory`  
- B. `ContainerLog` ✓  
- C. `AzureDiagnostics`  
- D. `KubeEvents`

---

**8. (SCA-01)** HPA is configured with `targetCPUUtilizationPercentage: 60`. The pod's resource spec has no `requests.cpu` defined. What will HPA report for current utilization?

- A. 0%  
- B. 100%  
- C. `<unknown>` ✓  
- D. An error is thrown and HPA is disabled

---

**9. (UPG-01)** `autoUpgradeProfile.upgradeChannel: patch` is set on a cluster running Kubernetes 1.29.3. Version 1.30.0 is released. What happens?

- A. The cluster upgrades to 1.30.0 automatically  
- B. The cluster upgrades to the latest patch of 1.29.x only ✓  
- C. No upgrade occurs — patch only affects node images  
- D. An alert fires asking the operator to approve the upgrade

---

**10. (BDR-01)** Azure Backup for AKS is configured with a 7-day operational tier and a 30-day vault tier policy. An admin deletes the Backup Vault. What happens to backups?

- A. Backups are permanently deleted immediately  
- B. Backups are retained in soft-deleted state for the soft-delete retention period ✓  
- C. Backups are migrated to the recovery services vault automatically  
- D. The cluster is also deleted

---

**11. (GOV-01)** Azure Policy with `EnforcementMode: DoNotEnforce` is assigned. A new pod is created that violates the policy. What is the result?

- A. Pod creation is blocked  
- B. Pod creation is allowed but the violation is logged as non-compliant ✓  
- C. Pod creation is allowed and no record is created  
- D. The policy assignment is automatically removed

---

**12. (GOV-02)** A `ResourceQuota` sets `requests.cpu: 4` for the `aks-store-demo` namespace. All existing pods already consume 3.9 CPU cores. A new pod with `requests.cpu: 200m` is submitted. What happens?

- A. The pod is scheduled and the namespace CPU usage temporarily exceeds the quota  
- B. The pod is rejected by the API server with a quota exceeded error ✓  
- C. The pod is queued until another pod releases CPU  
- D. The Cluster Autoscaler adds a node to accommodate the request

---

## Section 2 — Short Answer (6 questions × 2 points = 12 points)

**13. (NET-03)** Explain the purpose of the UDR (User Defined Route) with `nextHopType: VirtualAppliance` pointing to the Azure Firewall private IP, applied to the AKS node pool subnet. What traffic does it affect and why is it required for a private cluster with `outboundType: userDefinedRouting`?

> **Model answer (2 points):** The UDR overrides the default Azure routing for the node subnet, forcing **all egress traffic** (Internet-bound) from AKS nodes through Azure Firewall. This is required because: (1) `outboundType: userDefinedRouting` tells AKS not to create a load balancer for outbound internet access, so the cluster relies on the UDR/Firewall for egress; (2) egress through Firewall applies network-level and application-level inspection, blocking unauthorized outbound calls (e.g., data exfiltration). Without the UDR, nodes would have no path to internet endpoints (MCR, Ubuntu apt repos) needed for image pulls and node bootstrapping. *(1 point for egress path explanation, 1 point for why this blocks data exfiltration / provides security control)*

---

**14. (IDN-01)** A developer accidentally deletes their Entra ID user account mid-incident response. They can no longer run `kubectl` against the cluster. Describe two different ways the ops team can regain cluster access without re-creating the Entra ID account.

> **Model answer (2 points):**
> 1. **Azure Emergency Access Account:** Add a break-glass Entra ID account (a dedicated emergency UPN) to the AKS admin group before incidents occur. Use that account to run `az aks get-credentials --admin` and then kubelogin. *(1 point)*
> 2. **Azure Role Assignment via Owner/Contributor:** An Azure subscription Owner can assign the `Azure Kubernetes Service RBAC Cluster Admin` built-in role to a different user/service principal on the cluster resource, granting kubectl access without any Kubernetes-side changes. *(1 point)*

---

**15. (CICD-02)** The `azure-pipelines.yml` in lab-05 uses `$(Build.BuildId)` as the Docker image tag. A security team asks whether image tags are immutable references. Answer with an explanation of image tags versus image digests.

> **Model answer (2 points):** Image tags (e.g., `:1042`) are **mutable** — a new image with a different content can be pushed to the same tag. Image **digests** (e.g., `@sha256:abc123...`) are **immutable** — they are the SHA256 hash of the manifest content. For highest integrity, use digest pinning: `KubernetesManifest@1` can be configured to resolve tag to digest at deploy time. For the training assessment environment, `BuildId`-based tags are acceptable because ACR retention policies prevent overwrite of existing tags in production (configurable). *(1 point for tag mutability explanation, 1 point for digest alternative)*

---

**16. (OBS-02)** Write a KQL query that returns the top 5 pods with the highest number of OOMKILL events in the last 24 hours. Which Log Analytics table do you use?

> **Model answer (2 points):**
> ```kql
> KubePodInventory
> | where TimeGenerated > ago(24h)
> | where ContainerStatusReason == "OOMKilled"
> | summarize OOMCount = count() by PodName, Namespace
> | top 5 by OOMCount desc
> | project PodName, Namespace, OOMCount
> ```
> Table: `KubePodInventory`. *(1 point for correct table, 1 point for correct aggregation/filter)*

---

**17. (UPG-02)** The Cluster Autoscaler and AKS node upgrade process can conflict. Describe the potential conflict and how `maxSurge` on a node pool mitigates it.

> **Model answer (2 points):** During a node image upgrade, AKS drains and reimages nodes one at a time (default `maxSurge: 1`). If HPA scales up workloads during the drain (due to increased latency caused by fewer nodes), the Autoscaler tries to add nodes while the upgrade process is also managing node lifecycle. `maxSurge: 1` allows AKS to provision a **new, already-upgraded node** before draining the old one, so capacity is maintained during the upgrade and the Autoscaler does not need to react. Setting `maxSurge` to a higher value (e.g., 33%) speeds upgrades for large clusters at the cost of temporarily higher node spend. *(1 point for conflict description, 1 point for maxSurge explanation)*

---

**18. (GOV-02)** The cost analysis PowerShell showed `order-service` pods are consuming 400m CPU on average but their `requests.cpu` is `100m`. What operational risk does this create, and how do you resolve it?

> **Model answer (2 points):** The under-requested pods appear "cheap" to the Kubernetes scheduler, which packs more of them onto nodes than the actual CPU budget allows. This causes **CPU throttling** (the cgroups limit caps them at `limits.cpu`) and potential **node-level CPU pressure** that degrades all co-located workloads. Resolution: update `requests.cpu` to match observed average consumption (e.g., `400m`) and set `limits.cpu` to the burst ceiling (e.g., `1`). Use the Kubernetes Vertical Pod Autoscaler (VPA) in `Recommend` mode to calculate the right values based on historical usage before applying them. *(1 point for scheduler/throttling risk, 1 point for corrective action)*

---

## Section 3 — Bicep Task (1 task × 8 points)

**19. Bicep Deploy Task (IDN-02, NET-02, AKS-01)**

You are given the outputs from lab-02 (spoke.bicep):
- `oidcIssuerUrl` = `<OIDC_ISSUER_URL>`
- `privateEndpointSubnetId` = `/subscriptions/.../resourceGroups/rg-aks-spoke-dev/providers/Microsoft.Network/virtualNetworks/vnet-spoke-dev/subnets/snet-private-endpoints`
- `spokeVnetId` = `/subscriptions/.../resourceGroups/rg-aks-spoke-dev/providers/Microsoft.Network/virtualNetworks/vnet-spoke-dev`

**Task:** Write a Bicep parameters file (`main.bicepparam`) for `labs/lab-04-identity/main.bicep` that:  
1. Sets `location` to `eastus2`  
2. Sets `environment` to `dev`  
3. Provides the OIDC issuer URL, private endpoint subnet ID, and spoke VNet ID from the outputs above  
4. Sets `k8sNamespace` to `aks-store-demo` and `k8sServiceAccountName` to `workload-identity-sa`

**Write your answer below:**

```bicep
// Expected answer:
using './main.bicep'

param location                 = 'eastus2'
param environment              = 'dev'
param oidcIssuerUrl            = '<OIDC_ISSUER_URL>'
param k8sNamespace             = 'aks-store-demo'
param k8sServiceAccountName    = 'workload-identity-sa'
param privateEndpointSubnetId  = '/subscriptions/.../resourceGroups/rg-aks-spoke-dev/providers/Microsoft.Network/virtualNetworks/vnet-spoke-dev/subnets/snet-private-endpoints'
param spokeVnetId              = '/subscriptions/.../resourceGroups/rg-aks-spoke-dev/providers/Microsoft.Network/virtualNetworks/vnet-spoke-dev'
```

**Rubric (8 points):**
| Criterion                                                                                                                          | Points |
| ---------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `using` directive references correct relative path                                                                                 | 1      |
| `oidcIssuerUrl` correctly populated with the issuer URL                                                                            | 1      |
| `k8sNamespace` and `k8sServiceAccountName` both set                                                                                | 1      |
| `privateEndpointSubnetId` and `spokeVnetId` correctly set                                                                          | 2      |
| File uses `.bicepparam` format (not ARM JSON parameters)                                                                           | 1      |
| No hardcoded secrets; placeholders are used for environment-specific values                                                        | 1      |
| The federated credential `subject` would resolve to `system:serviceaccount:aks-store-demo:workload-identity-sa` given these inputs | 1      |

---

## Section 4 — PowerShell Task (1 task × 4 points)

**20. PowerShell Automation Task (UPG-02, OBS-03)**

Write a PowerShell function `Invoke-AksNodePoolUpgrade` that:  
1. Accepts parameters: `ResourceGroup`, `ClusterName`, `NodePoolName`  
2. Checks the current node image version using `az aks nodepool show`  
3. Starts a node pool upgrade to the latest node image (`az aks nodepool upgrade --node-image-only`)  
4. Polls every 60 seconds until the provisioning state is `Succeeded` or `Failed`  
5. Outputs a summary line including the time taken

**Write your answer below:**

```powershell
# Expected answer (representative — partial credit for core logic):
function Invoke-AksNodePoolUpgrade {
    param(
        [Parameter(Mandatory)] [string] $ResourceGroup,
        [Parameter(Mandatory)] [string] $ClusterName,
        [Parameter(Mandatory)] [string] $NodePoolName
    )

    $before = az aks nodepool show `
        -g $ResourceGroup -n $NodePoolName --cluster-name $ClusterName `
        --query nodeImageVersion -o tsv

    Write-Host "Current node image: $before"
    Write-Host "Starting node image upgrade for pool '$NodePoolName'..."

    az aks nodepool upgrade `
        --resource-group $ResourceGroup `
        --cluster-name $ClusterName `
        --name $NodePoolName `
        --node-image-only `
        --no-wait

    $start = Get-Date
    do {
        Start-Sleep -Seconds 60
        $state = az aks nodepool show `
            -g $ResourceGroup -n $NodePoolName --cluster-name $ClusterName `
            --query provisioningState -o tsv
        $elapsed = [int](New-TimeSpan -Start $start).TotalMinutes
        Write-Host "[$elapsed min] Provisioning state: $state"
    } while ($state -notin @('Succeeded', 'Failed', 'Canceled'))

    $after = az aks nodepool show `
        -g $ResourceGroup -n $NodePoolName --cluster-name $ClusterName `
        --query nodeImageVersion -o tsv

    $totalMin = [int](New-TimeSpan -Start $start).TotalMinutes
    if ($state -eq 'Succeeded') {
        Write-Host "Upgrade SUCCEEDED in $totalMin minutes. New image: $after" -ForegroundColor Green
    } else {
        Write-Error "Upgrade $state after $totalMin minutes. Check AKS diagnostics."
    }
}
```

**Rubric (4 points):**
| Criterion                                                             | Points |
| --------------------------------------------------------------------- | ------ |
| `--node-image-only` flag used (not a full Kubernetes version upgrade) | 1      |
| Polling loop waits and re-checks `provisioningState`                  | 1      |
| Loop exits on both `Succeeded` AND `Failed`/`Canceled` states         | 1      |
| Before/after image versions are captured and reported                 | 1      |

---

## Scoring Summary

| Section         | Questions | Max Points | Points Earned |
| --------------- | --------- | ---------- | ------------- |
| Multiple Choice | 1–12      | 12         |               |
| Short Answer    | 13–18     | 12         |               |
| Bicep Task      | 19        | 8          |               |
| PowerShell Task | 20        | 4          |               |
| **Total**       |           | **36**     |               |

**Pass threshold: 27/36 (75%)**

---

## Domain Coverage Map

| Domain                | Questions      | Objectives Assessed            |
| --------------------- | -------------- | ------------------------------ |
| AKS Fundamentals      | 1, 13(partial) | AKS-01, AKS-02                 |
| Networking            | 2, 3, 13       | NET-01, NET-02, NET-03         |
| ACR Integration       | 4              | ACR-01, ACR-02                 |
| Identity and Security | 5, 6, 14, 19   | IDN-01, IDN-02, IDN-03, IDN-04 |
| CI/CD                 | 6, 15          | CICD-01, CICD-02               |
| Observability         | 7, 16          | OBS-01, OBS-02, OBS-03         |
| Scaling               | 8, 18(partial) | SCA-01, SCA-02                 |
| Upgrades              | 9, 17, 20      | UPG-01, UPG-02                 |
| Backup & DR           | 10             | BDR-01                         |
| Governance            | 11, 12, 18     | GOV-01, GOV-02                 |

---

## Remediation Guidance

| Score Range     | Recommendation                                                                               |
| --------------- | -------------------------------------------------------------------------------------------- |
| 32–36 (89–100%) | Excellent — consider Azure Kubernetes Service specialty certification                        |
| 27–31 (75–88%)  | Pass — review any missed module checkpoints for weak domains                                 |
| 22–26 (61–74%)  | Near pass — revisit modules for domains with ≥2 wrong answers; re-sit in 1 week              |
| < 22 (< 61%)    | Significant gaps — repeat scenario labs 1 and 2; re-read module 02, 04, and 05 before re-sit |
