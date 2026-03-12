# Module 07 — Scaling

**Objective IDs:** SCA-01, SCA-02, SCA-03  
**Estimated time:** 5 hours (2 h reading + 3 h lab)  
**Prerequisites:** Module 01, Module 06  
**Lab:** Configure HPA, Cluster Autoscaler, and KEDA  

---

## Learning Objectives

- SCA-01: Configure Horizontal Pod Autoscaler (HPA) based on CPU and custom metrics.
- SCA-02: Enable and tune Cluster Autoscaler on a user node pool.
- SCA-03: Deploy KEDA with Azure Service Bus scaler for event-driven scaling.

---

## 1. Horizontal Pod Autoscaler (SCA-01)

HPA automatically scales the number of pod replicas based on observed metrics.

### 1.1 CPU-based HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: store-front-hpa
  namespace: aks-store-demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: store-front
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70  # Scale when CPU > 70%
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

**Prerequisite:** Every pod must have CPU and memory `requests` set in the pod spec:

```yaml
resources:
  requests:
    cpu: "250m"
    memory: "256Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

### 1.2 Custom metrics HPA (Azure Monitor)

```yaml
# Requires the azure-adapter for external metrics
- type: External
  external:
    metric:
      name: azure_servicebus_active_messages
      selector:
        matchLabels:
          queue: orders
    target:
      type: AverageValue
      averageValue: 50   # Scale when avg active messages > 50
```

---

## 2. Cluster Autoscaler (SCA-02)

The Cluster Autoscaler adds or removes nodes from a node pool based on pending pod scheduling pressure.

### 2.1 Enable on a node pool via Bicep

```bicep
{
  name: 'userpool'
  enableAutoScaling: true
  minCount: 2
  maxCount: 10
  count: 2  // Initial node count
  vmSize: 'Standard_D4ds_v5'
  mode: 'User'
}
```

### 2.2 Cluster Autoscaler profile

```bicep
autoScalerProfile: {
  'scale-down-delay-after-add': '10m'
  'scale-down-unneeded-time': '10m'
  'scale-down-utilization-threshold': '0.5'
  'max-graceful-termination-sec': '600'
  'balance-similar-node-groups': 'true'
  'expander': 'random'
}
```

### 2.3 Validate scale-out

```powershell
# SCA-02: Trigger a scale-out by deploying an overloaded deployment
kubectl apply -f ./labs/lab-07-scaling/load-test-deploy.yaml

# Watch node count
Watch-AksNodeCount -ResourceGroup 'rg-aks-spoke-dev' -ClusterName 'aks-prod-01' -NodePool 'userpool'

function Watch-AksNodeCount {
    param(
        [string]$ResourceGroup,
        [string]$ClusterName,
        [string]$NodePool
    )

    for ($i = 0; $i -lt 30; $i++) {
        $count = az aks nodepool show `
            --resource-group $ResourceGroup `
            --cluster-name $ClusterName `
            --name $NodePool `
            --query count -o tsv

        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Node count: $count"
        Start-Sleep -Seconds 30
    }
}
```

---

## 3. KEDA — Event-Driven Autoscaling (SCA-03)

KEDA (Kubernetes Event-Driven Autoscaler) extends HPA with 50+ external event sources including Azure Service Bus, Event Hubs, and Storage Queue.

### 3.1 Install KEDA add-on

```bicep
addonProfiles: {
  keda: {
    enabled: true
  }
}
```

### 3.2 ScaledObject for Azure Service Bus

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-service-scaler
  namespace: aks-store-demo
spec:
  scaleTargetRef:
    name: order-service
  minReplicaCount: 1
  maxReplicaCount: 30
  cooldownPeriod: 300
  triggers:
    - type: azure-servicebus
      metadata:
        queueName: orders
        namespace: sb-aks-store-demo
        messageCount: "10"       # Scale when queue depth > 10 per replica
      authenticationRef:
        name: keda-servicebus-auth
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: keda-servicebus-auth
  namespace: aks-store-demo
spec:
  podIdentity:
    provider: azure-workload  # Use Workload Identity (no secrets)
```

---

## Checkpoint M07

1. (SCA-01) What is required in a pod spec before HPA can scale on CPU?
2. (SCA-02) What happens to running pods when the cluster autoscaler removes a node?
3. (SCA-03) What authentication method should KEDA use for Azure Service Bus in production?

**Pass criterion:** All three correct.

---

## Proof Links

| Claim                     | Source                                                                                                                                                   | Confidence |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| HPA in AKS                | [learn.microsoft.com/azure/aks/concepts-scale#horizontal-pod-autoscaler](https://learn.microsoft.com/azure/aks/concepts-scale#horizontal-pod-autoscaler) | High       |
| Cluster Autoscaler in AKS | [learn.microsoft.com/azure/aks/cluster-autoscaler](https://learn.microsoft.com/azure/aks/cluster-autoscaler)                                             | High       |
| KEDA add-on for AKS       | [learn.microsoft.com/azure/aks/keda-about](https://learn.microsoft.com/azure/aks/keda-about)                                                             | High       |
