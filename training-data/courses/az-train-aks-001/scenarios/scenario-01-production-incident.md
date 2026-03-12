# Scenario 1: Production Incident — CrashLoopBackOff in aks-store-demo

> **Skill level:** Intermediate  
> **Time box:** 45–60 minutes  
> **Objective IDs:** OBS-01, OBS-02, OBS-03, ACR-02, NET-05  
> **Tools required:** kubectl, kubelogin, Azure CLI, Log Analytics / Azure Monitor

---

## Scenario Brief

**Role:** On-call SRE for Contoso Retail  
**Time:** 02:15 AM — your PagerDuty alert fires

You receive the following alert from Azure Monitor:

```
ALERT: CrashLoopBackOff detected
Affected resource: aks-store-demo/order-service (3 of 3 pods crashing)
Cluster: aks-prod-contoso
Severity: P1
```

Customer orders are failing. The store-front UI returns HTTP 503. Management wants a root-cause analysis and remediation within 30 minutes.

---

## Environment State

- AKS private cluster deployed per lab-02 (hub-spoke, AGIC)
- aks-store-demo deployed per lab-11 (all 4 services running at start)
- A recent pipeline run pushed image tag `build-1042` to ACR
- Azure Service Bus queue `orders` has **3,847 unprocessed messages** (visible in Azure Portal)

---

## Investigation Tasks

### Task 1 — Establish cluster access via Bastion tunnel  
*(Prerequisite — private cluster, no public kubectl access)*

```powershell
# Connect to the private cluster over Azure Bastion tunnel
az aks get-credentials `
    --resource-group rg-aks-spoke-prod `
    --name aks-prod-contoso `
    --overwrite-existing

kubelogin convert-kubeconfig -l azurecli
```

**Checkpoint:** `kubectl get nodes` returns Ready nodes.

---

### Task 2 — Triage the crash (OBS-01)

```bash
# Step 1: Identify affected pods
kubectl get pods -n aks-store-demo -o wide

# Step 2: Check events for the crashing pod
kubectl describe pod -l app=order-service -n aks-store-demo

# Step 3: Read the last log lines before the crash
# Replace <POD_NAME> with a crashing pod
kubectl logs <POD_NAME> -n aks-store-demo --previous --tail=100
```

**What to look for:**
- Exit code in `describe pod` (exit 1 = app error, exit 137 = OOMKill, exit 143 = SIGTERM)
- Error messages in `--previous` logs (image pull failure, connection refused, env var missing)
- Events showing `Back-off restarting failed container`

---

### Task 3 — Verify with Log Analytics KQL (OBS-02)

Run the following KQL in Log Analytics workspace linked to the cluster:

```kql
ContainerLog
| where TimeGenerated > ago(30m)
| where ContainerName == "order-service"
| where LogEntry has_any ("error", "fatal", "ECONNREFUSED", "ETIMEDOUT")
| order by TimeGenerated desc
| take 50
```

Also check node resource pressure:

```kql
KubeNodeInventory
| where TimeGenerated > ago(10m)
| summarize arg_max(TimeGenerated, *) by Computer
| project Computer, Labels, Status = case(
    tostring(parse_json(Labels)["kubernetes.io/role"]) == "agent", "Node",
    "Other"
  )
```

---

### Task 4 — Investigate the root cause (guided discovery)

The scenario has **three possible root causes** — work through each:

#### Hypothesis A: Image pull failure (ACR-02)

```bash
# Check if the pod can pull the image
kubectl describe pod -l app=order-service -n aks-store-demo | grep -A5 Events

# Verify ACR private endpoint DNS is resolving correctly from inside the cluster
# Deploy a debug pod into the spoke VNet first:
kubectl run dnstest --image=mcr.microsoft.com/dotnet/runtime-deps:8.0-alpine \
  --restart=Never -n aks-store-demo -- sleep 300
kubectl exec -it dnstest -n aks-store-demo -- nslookup <ACR_NAME>.azurecr.io
```

**Expected:** Private IP in range 10.1.7.x (private-endpoints subnet)  
**Failure sign:** Public IP or NXDOMAIN → private DNS zone missing or unlinked

#### Hypothesis B: Environment variable/secret missing (IDN-04)

```bash
# Inspect the deployment environment variables
kubectl get deployment order-service -n aks-store-demo -o yaml | grep -A 20 env:

# Check if the SecretProviderClass secret mounted correctly
kubectl get secretproviderclass -n aks-store-demo
kubectl describe secretproviderclass kv-store-secrets -n aks-store-demo
```

**Failure sign:** `SecretProviderClass` shows `Synced: false` → Key Vault private endpoint unreachable or RBAC missing

#### Hypothesis C: OOMKill — container memory limit too low (SCA-01)

```bash
# Check if exit code 137 appears in describe (OOMKill)
kubectl describe pod -l app=order-service -n aks-store-demo | grep "OOMKilled\|137"

# Check current resource usage vs limits
kubectl top pod -n aks-store-demo
```

**Remediation if OOMKill:** Patch the deployment to increase memory limit:

```bash
kubectl patch deployment order-service -n aks-store-demo \
  --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"512Mi"}]'
```

---

### Task 5 — Drain the Service Bus backlog (OBS-03)

Once the order-service is healthy, the backlog of 3,847 messages must process:

```bash
# Scale out to 5 replicas temporarily to drain the queue faster
kubectl scale deployment order-service -n aks-store-demo --replicas=5

# Monitor queue depth in Azure CLI
az servicebus queue show \
  --resource-group rg-aks-ops-prod \
  --namespace-name <SB_NAMESPACE> \
  --name orders \
  --query messageCount -o tsv
```

**Checkpoint:** `messageCount` drops to 0 within the SLA window.

---

### Task 6 — Confirm resolution and write post-incident notes

```bash
# Confirm all 5 (scaled) pods are Running
kubectl get pods -n aks-store-demo -l app=order-service

# Check AGIC Ingress for 200 OK on store-front
curl -I http://<STORE_FRONT_HOSTNAME>/

# Verify no new crashes in the last 10 minutes
kubectl get events -n aks-store-demo --sort-by=.metadata.creationTimestamp | tail -20
```

---

## Scenario Debrief Questions

Answer these before moving to the next scenario:

1. What was the **exit code** of the crashing container and what does it indicate?
2. Which Hypothesis (A, B, or C) caused the crash in your environment?
3. What monitoring alert **rule** (KQL + Action Group) would have detected this 10 minutes earlier? Write the KQL threshold condition.
4. Why must you use `kubelogin convert-kubeconfig -l azurecli` before running kubectl against this cluster? What would happen without it?
5. The Service Bus queue had 3,800+ messages. What AKS scaling mechanism would **automatically** handle this queue depth without manual `kubectl scale`?

> **Answer guidance:** See `assessment/module-checks.md` for expected answers and objective-to-skill cross-reference.

---

## Remediation Checklist

- [ ] Pod exit code identified and root cause confirmed
- [ ] Crashing container logs captured and analyzed
- [ ] KQL query run in Log Analytics
- [ ] Root cause resolved (image pull / secret mount / memory limit)
- [ ] Service Bus queue draining confirmed
- [ ] Replicas scaled back to 2 after queue cleared
- [ ] Alert rule created (or validated existing) in Azure Monitor

---

## Source References

| Claim                                                                          | Source                                                                                                                                                      | Confidence |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| CrashLoopBackOff is diagnosed via `kubectl describe` and `--previous` logs     | [Diagnose and solve problems with Azure Kubernetes Service](https://learn.microsoft.com/azure/aks/aks-diagnostics)                                          | High       |
| Container Insights stores pod logs in `ContainerLog` table, queryable via KQL  | [Container insights overview](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview)                                       | High       |
| Exit code 137 indicates OOMKill                                                | [Troubleshoot common Azure Kubernetes Service problems](https://learn.microsoft.com/azure/aks/aks-diagnostics)                                              | High       |
| Private DNS zone required for ACR private endpoint resolution from within VNet | [Connect privately to an Azure container registry using Private Link](https://learn.microsoft.com/azure/container-registry/container-registry-private-link) | High       |
