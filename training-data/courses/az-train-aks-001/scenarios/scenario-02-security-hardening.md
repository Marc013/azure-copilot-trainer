# Scenario 2: Security Hardening Audit — Contoso AKS Platform

> **Skill level:** Intermediate–Advanced  
> **Time box:** 60–90 minutes  
> **Objective IDs:** IDN-01, IDN-02, IDN-03, IDN-04, GOV-01, GOV-02, NET-03  
> **Tools required:** kubectl, Azure CLI, Bicep, PowerShell (Az module)

---

## Scenario Brief

**Role:** Cloud Security Engineer at Contoso  
**Trigger:** Quarterly security audit — external pen-tester findings delivered

The pen-tester has identified the following **findings** in the production AKS environment. Your task is to reproduce each finding, understand its risk, and remediate it using the appropriate Bicep, kubectl, or PowerShell command.

---

## Finding Summary

| #    | Finding                                                                                                                 | Severity | Control |
| ---- | ----------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| F-01 | Local accounts not disabled — `kubectl get cm -n kube-system cluster-admin-kubeconfig` returns static username/password | Critical | IDN-01  |
| F-02 | Containers running as root (`runAsNonRoot` not enforced)                                                                | High     | GOV-02  |
| F-03 | No `LimitRange` in aks-store-demo namespace — pod can consume unbounded CPU/memory                                      | High     | GOV-02  |
| F-04 | Workload pods have `automountServiceAccountToken: true` (default) even when no API access needed                        | Medium   | IDN-03  |
| F-05 | Key Vault `enablePurgeProtection: false` on staging Key Vault                                                           | Medium   | IDN-04  |
| F-06 | Azure Policy not assigned: `Kubernetes cluster containers should not share host process ID or host IPC namespace`       | Medium   | GOV-01  |

---

## Remediation Tasks

### F-01 — Disable local accounts (IDN-01)

Local admin kubeconfig grants cluster-admin without Entra ID. Disable it.

**Diagnose:**
```bash
az aks show \
  --resource-group rg-aks-spoke-prod \
  --name aks-prod-contoso \
  --query "disableLocalAccounts" -o tsv
# Expected: false (the problem)
```

**Remediate via Bicep** (add to spoke.bicep `properties` block):
```bicep
disableLocalAccounts: true
aadProfile: {
  managed: true
  enableAzureRBAC: true
  tenantID: subscription().tenantId
}
```

Then redeploy lab-02:
```powershell
az deployment sub create `
    --location eastus2 `
  --template-file 'C:\Git\Private\azure-copilot-trainer\training-data\courses\az-train-aks-001\labs\lab-02-private-cluster\main.bicep' `
  --parameters 'C:\Git\Private\azure-copilot-trainer\training-data\courses\az-train-aks-001\labs\lab-02-private-cluster\main.bicepparam'
```

**Validate:**
```bash
az aks show --resource-group rg-aks-spoke-prod --name aks-prod-contoso \
  --query "disableLocalAccounts" -o tsv
# Expected: true
```

---

### F-02 — Enforce non-root containers with Azure Policy (GOV-01, GOV-02)

Azure Policy with the OPA/Gatekeeper add-on enforces cluster-wide admission rules.

**Diagnose — check whether the restrict-non-root-containers policy is assigned:**
```powershell
$assignments = Get-AzPolicyAssignment -Scope (Get-AzResourceGroup -Name rg-aks-spoke-prod).ResourceId
$assignments | Where-Object { $_.Properties.DisplayName -like "*non-root*" }
# Expected: nothing returned (the problem)
```

**Remediate — assign the built-in policy:**
```powershell
$scope = (Get-AzResourceGroup -Name rg-aks-spoke-prod).ResourceId

New-AzPolicyAssignment `
    -Name "aks-no-root-containers" `
    -Scope $scope `
    -PolicyDefinition (Get-AzPolicyDefinition | Where-Object {
        $_.Properties.DisplayName -eq "Kubernetes cluster containers should not run as root"
    }) `
    -EnforcementMode Default
```

**Or via Azure CLI:**
```bash
POLICY_ID=$(az policy definition list \
  --query "[?displayName=='Kubernetes cluster containers should not run as root'].id" \
  -o tsv)

az policy assignment create \
  --name "aks-no-root-containers" \
  --scope $(az group show -n rg-aks-spoke-prod --query id -o tsv) \
  --policy $POLICY_ID \
  --enforcement-mode Default
```

**Validate (wait up to 15 min for policy evaluation):**
```bash
az policy state list \
  --resource-group rg-aks-spoke-prod \
  --query "[?policyDefinitionName=='aks-no-root-containers']" \
  -o table
```

---

### F-03 — Add LimitRange to aks-store-demo namespace (GOV-02)

Without a LimitRange, a pod can request 0 CPU but consume an entire node.

**Diagnose:**
```bash
kubectl get limitrange -n aks-store-demo
# Expected: No resources found (the problem)
```

**Remediate — apply LimitRange:**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: aks-store-default-limits
  namespace: aks-store-demo
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "256Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      max:
        cpu: "4"
        memory: "2Gi"
      min:
        cpu: "50m"
        memory: "64Mi"
EOF
```

**Validate:**
```bash
kubectl describe limitrange aks-store-default-limits -n aks-store-demo
```

---

### F-04 — Disable automountServiceAccountToken for stateless pods (IDN-03)

```bash
# Diagnose: check current value
kubectl get deployment store-front -n aks-store-demo \
  -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'
# Expected: null (default = true — the problem)
```

**Remediate — patch the deployments that do not call the Kubernetes API:**
```bash
for deploy in store-front store-admin product-service; do
  kubectl patch deployment ${deploy} -n aks-store-demo \
    --type=json \
    -p='[{"op":"add","path":"/spec/template/spec/automountServiceAccountToken","value":false}]'
done
```

> **Note:** `order-service` uses Workload Identity to call Azure Service Bus, so it **must** keep `automountServiceAccountToken: true` (the token is projected by the OIDC mechanism). Only disable it on pods that have no Azure SDK calls.

**Validate:**
```bash
kubectl get deployment store-front -n aks-store-demo \
  -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'
# Expected: false
```

---

### F-05 — Enable purge protection on Key Vault (IDN-04)

> **Warning:** Once purge protection is enabled, it cannot be disabled. This is intentional — it prevents accidental or malicious secret deletion.

**Diagnose:**
```bash
az keyvault show \
  --resource-group rg-aks-spoke-staging \
  --name <KV_NAME> \
  --query "properties.enablePurgeProtection" -o tsv
# Expected: false or null (the problem)
```

**Remediate via Bicep** (update lab-04-identity/main.bicep, re-deploy):
```bicep
// In the keyVault resource properties block — already set to true in lab-04
enableSoftDelete: true
softDeleteRetentionInDays: 7
enablePurgeProtection: true   // <-- this was missing on the staging vault
```

**Remediate via CLI (if Bicep re-deploy is blocked):**
```bash
az keyvault update \
  --resource-group rg-aks-spoke-staging \
  --name <KV_NAME> \
  --enable-purge-protection true
```

---

### F-06 — Assign host IPC/PID policy (GOV-01)

Containers sharing the host PID or IPC namespace can escape the container boundary.

**Remediate:**
```powershell
$scope = (Get-AzResourceGroup -Name rg-aks-spoke-prod).ResourceId

$policyDef = Get-AzPolicyDefinition | Where-Object {
    $_.Properties.DisplayName -eq "Kubernetes cluster pods should not share host process ID or host IPC namespace"
}

New-AzPolicyAssignment `
    -Name "aks-no-host-pid-ipc" `
    -Scope $scope `
    -PolicyDefinition $policyDef `
    -EnforcementMode Default
```

---

## Post-Remediation Validation Script

Run this PowerShell function after completing all remediations to produce a pass/fail report:

```powershell
function Test-AksSecurityBaseline {
    param(
        [string] $ResourceGroup = 'rg-aks-spoke-prod',
        [string] $ClusterName  = 'aks-prod-contoso'
    )

    $results = @()

    # F-01: disableLocalAccounts
    $localAccounts = az aks show -g $ResourceGroup -n $ClusterName `
        --query disableLocalAccounts -o tsv
    $results += [PSCustomObject]@{
        Finding = 'F-01'
        Check = 'disableLocalAccounts'
        Status = if ($localAccounts -eq 'true') { 'PASS' } else { 'FAIL' }
    }

    # F-03: LimitRange exists
    $lr = kubectl get limitrange -n aks-store-demo --no-headers 2>&1
    $results += [PSCustomObject]@{
        Finding = 'F-03'
        Check = 'LimitRange exists in aks-store-demo'
        Status = if ($lr -notmatch 'No resources') { 'PASS' } else { 'FAIL' }
    }

    # F-04: automountServiceAccountToken disabled on store-front
    $amt = kubectl get deployment store-front -n aks-store-demo `
        -o jsonpath='{.spec.template.spec.automountServiceAccountToken}' 2>&1
    $results += [PSCustomObject]@{
        Finding = 'F-04'
        Check = 'automountServiceAccountToken=false on store-front'
        Status = if ($amt -eq 'false') { 'PASS' } else { 'FAIL' }
    }

    $results | Format-Table -AutoSize

    $failures = $results | Where-Object Status -eq 'FAIL'
    if ($failures) {
        Write-Warning "$($failures.Count) finding(s) still unresolved."
    } else {
        Write-Host "All security checks PASSED." -ForegroundColor Green
    }
}

Test-AksSecurityBaseline
```

---

## Debrief Questions

1. Why does disabling local accounts require `aadProfile.managed: true` and `enableAzureRBAC: true` to be set **simultaneously**?
2. Azure Policy with `EnforcementMode: Default` will **block** new non-compliant pods. What mode would you use to only **audit** existing deployments without blocking?
3. `order-service` kept `automountServiceAccountToken: true` — explain why. What replaces the bearer token mechanism for its Azure SDK calls?
4. What is the risk of using `softDeleteRetentionInDays: 7` (minimum) vs 90 days for a Key Vault in production?
5. A Kubernetes `LimitRange` sets per-**container** defaults. How would you limit the total resource consumption of the **namespace** (all pods combined)?

> **Answer guidance:** See `assessment/module-checks.md`.

---

## Source References

| Claim                                                                               | Source                                                                                                                                | Confidence |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `disableLocalAccounts` requires managed Entra ID to be enabled                      | [Disable local accounts in Azure Kubernetes Service](https://learn.microsoft.com/azure/aks/manage-local-accounts-managed-azure-ad)    | High       |
| `automountServiceAccountToken: false` is best practice for pods not calling K8s API | [Kubernetes security best practices](https://learn.microsoft.com/azure/aks/developer-best-practices-pod-security)                     | High       |
| Azure Policy add-on uses OPA/Gatekeeper for admission control                       | [Understand Azure Policy for Kubernetes clusters](https://learn.microsoft.com/azure/governance/policy/concepts/policy-for-kubernetes) | High       |
| Purge protection prevents soft-deleted vault recovery bypass                        | [Azure Key Vault soft-delete overview](https://learn.microsoft.com/azure/key-vault/general/soft-delete-overview)                      | High       |
