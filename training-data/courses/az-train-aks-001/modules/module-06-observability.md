# Module 06 — Observability: Container Insights, Logs, and Alerts

**Objective IDs:** OBS-01, OBS-02, OBS-03, OBS-04  
**Estimated time:** 6 hours (3 h reading + 3 h lab)  
**Prerequisites:** Module 02  
**Lab:** Enable Container Insights; write KQL queries; configure alerts  

---

## Learning Objectives

- OBS-01: Enable Container Insights and send metrics to Log Analytics workspace.
- OBS-02: Write KQL queries for pod crash loops, OOM kills, and node CPU pressure.
- OBS-03: Configure Azure Monitor alerts and action groups for SLO breach.
- OBS-04: Enable Azure Managed Prometheus and Grafana for metrics visualisation.

---

## 1. Observability Stack

```
Cluster
 ├─ Container Insights (agent)    ──► Log Analytics Workspace
 ├─ Azure Managed Prometheus       ──► Azure Monitor Workspace
 └─ kube-state-metrics / cAdvisor  ──► (scraped by Prometheus)
                                        │
                                   Azure Managed Grafana
```

---

## 2. Container Insights

Container Insights is an AKS add-on that collects logs and metrics from nodes and pods and stores them in a Log Analytics workspace.

### 2.1 Enable via Bicep

```bicep
// OBS-01: Container Insights via omsagent add-on
addonProfiles: {
  omsagent: {
    enabled: true
    config: {
      logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
    }
  }
}
```

### 2.2 Verify data ingestion

```powershell
# Confirm that ContainerLog table is receiving data
$query = "ContainerLog | summarize count() by bin(TimeGenerated, 5m) | take 10"

az monitor log-analytics query `
    --workspace $lawId `
    --analytics-query $query `
    --output table
```

---

## 3. Key KQL Queries (OBS-02)

### 3.1 Pod restart / crash loop detection

```kql
KubePodInventory
| where TimeGenerated > ago(1h)
| where ContainerStatusReason has_any ('OOMKilled', 'CrashLoopBackOff', 'Error')
| summarize Restarts=max(PodRestartCount) by PodName, ContainerName, Namespace, ContainerStatusReason
| where Restarts > 3
| order by Restarts desc
```

### 3.2 OOM killings on nodes

```kql
KubeNodeInventory
| where TimeGenerated > ago(1h)
| join kind=leftouter (
    KubePodInventory
    | where ContainerStatusReason == 'OOMKilled'
) on Computer
| summarize OOMKills=count() by Computer, NodeName=Computer
| order by OOMKills desc
```

### 3.3 Node CPU pressure

```kql
Perf
| where ObjectName == 'K8SNode' and CounterName == 'cpuUsageNanoCores'
| summarize AvgCPU=avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| where AvgCPU > 8e9  // 8 CPU cores in nanocores
| order by TimeGenerated desc
```

### 3.4 Image pull failures

```kql
KubeEvents
| where TimeGenerated > ago(3h)
| where Reason has_any ('Failed', 'BackOff')
| where Message has 'ImagePull'
| project TimeGenerated, Namespace, Name, Reason, Message
```

---

## 4. Azure Monitor Alerts (OBS-03)

### 4.1 Create an action group

```bicep
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-aks-oncall'
  location: 'Global'
  properties: {
    groupShortName: 'AKSOncall'
    enabled: true
    emailReceivers: [
      {
        name: 'PlatformTeam'
        emailAddress: 'platform-team@contoso.com'
        useCommonAlertSchema: true
      }
    ]
  }
}
```

### 4.2 Scheduled query alert for CrashLoopBackOff

```bicep
resource crashLoopAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-aks-crashloop'
  location: location
  properties: {
    displayName: 'AKS Pod CrashLoopBackOff'
    severity: 2
    enabled: true
    scopes: [logAnalyticsWorkspaceId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: '''
            KubePodInventory
            | where ContainerStatusReason == "CrashLoopBackOff"
            | summarize CrashCount=count() by PodName, Namespace
            | where CrashCount >= 3
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [actionGroup.id]
    }
  }
}
```

---

## 5. Azure Managed Prometheus and Grafana (OBS-04)

```bicep
// Enable metrics add-on (sends to Azure Monitor Workspace)
addonProfiles: {
  azureMonitorMetrics: {
    enabled: true
    config: {
      metricLabelsAllowlist: ''
      metricAnnotationsAllowList: ''
    }
  }
}
```

```powershell
# OBS-04: Link Grafana dashboard to Azure Monitor Workspace
$grafana = az grafana show --name 'grafana-aks' --resource-group 'rg-aks-ops-dev' `
    --query id -o tsv

az monitor account show --name 'amw-aks' --resource-group 'rg-aks-ops-dev' --query id -o tsv

# Associate the Azure Monitor workspace as a Prometheus data source in Grafana
az grafana data-source create `
    --name 'grafana-aks' `
    --resource-group 'rg-aks-ops-dev' `
    --definition '{
        "name": "Azure Monitor",
        "type": "prometheus",
    "url": "<PROMETHEUS_WORKSPACE_ENDPOINT>"
    }'
```

---

## Troubleshooting Drills

| Symptom                         | KQL query to run               | Action                                                   |
| ------------------------------- | ------------------------------ | -------------------------------------------------------- |
| High pod restart count          | KubePodInventory \| OOM filter | Check memory requests/limits                             |
| Node NotReady                   | KubeNodeInventory              | Check kubelet logs on node                               |
| Missing Container Insights data | Check omsagent pod status      | `kubectl get pods -n kube-system -l component=oms-agent` |

---

## Checkpoint M06

1. (OBS-01) What Kubernetes namespace does the Container Insights agent run in?
2. (OBS-02) Write a KQL query that shows pods with more than 5 restarts in the last hour.
3. (OBS-03) What alert severity level represents a warning (non-critical)?
4. (OBS-04) What Azure service provides managed Prometheus-compatible metrics storage?

**Pass criterion:** All four correct.

---

## Proof Links

| Claim                       | Source                                                                                                                                                                                       | Confidence |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| Container Insights overview | [learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview)                     | High       |
| Enable Container Insights   | [learn.microsoft.com/azure/azure-monitor/containers/container-insights-enable-new-cluster](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-enable-new-cluster) | High       |
| Azure Managed Prometheus    | [learn.microsoft.com/azure/azure-monitor/essentials/prometheus-metrics-overview](https://learn.microsoft.com/azure/azure-monitor/essentials/prometheus-metrics-overview)                     | High       |
| Scheduled query alert rules | [learn.microsoft.com/azure/azure-monitor/alerts/alerts-create-log-alert-rule](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-create-log-alert-rule)                           | High       |
