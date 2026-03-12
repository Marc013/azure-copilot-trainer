# Module 02 — Private AKS Cluster and Networking

**Objective IDs:** NET-01, NET-02, NET-03, NET-04, NET-05  
**Estimated time:** 8 hours (3 h reading + 5 h lab)  
**Prerequisites:** Module 01  
**Lab:** Deploy private AKS cluster with hub-spoke networking, AGIC, and Azure Firewall using Bicep  

---

## Learning Objectives

- NET-01: Design hub-spoke virtual network topology for AKS.
- NET-02: Deploy a private AKS cluster with private API server access.
- NET-03: Configure Application Gateway WAF v2 and AGIC add-on.
- NET-04: Implement Azure CNI Overlay with Network Policies.
- NET-05: Restrict egress with Azure Firewall UDR.

---

## 1. Hub-Spoke Network Design

### 1.1 Subnet layout

| VNet                | Subnet                 | CIDR        | Purpose                                            |
| ------------------- | ---------------------- | ----------- | -------------------------------------------------- |
| Hub (10.0.0.0/16)   | AzureFirewallSubnet    | 10.0.1.0/26 | Azure Firewall                                     |
| Hub                 | AzureBastionSubnet     | 10.0.2.0/27 | Azure Bastion                                      |
| Hub                 | GatewaySubnet          | 10.0.3.0/27 | VPN/ExpressRoute                                   |
| Spoke (10.1.0.0/16) | snet-appgw             | 10.1.1.0/24 | Application Gateway WAF v2                         |
| Spoke               | snet-aks-nodes         | 10.1.2.0/22 | AKS node VMs                                       |
| Spoke               | snet-aks-apiserver     | 10.1.6.0/28 | Reserved delegated subnet for API-server scenarios |
| Spoke               | snet-private-endpoints | 10.1.7.0/24 | ACR, Key Vault private endpoints                   |

> **Design rule:** Application Gateway subnet must be a **/24 or smaller** before upgrading CNI to CNI Overlay.  
> **Proof link:** [learn.microsoft.com/azure/application-gateway/ingress-controller-overview#container-networking-and-agic](https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview#container-networking-and-agic) — Confidence: High

### 1.2 IP planning checklist

- [ ] VNet address space large enough for upgrades (AKS creates a surge node per upgrade)
- [ ] Pod overlay CIDR does not overlap with any VNet or peered network
- [ ] Application Gateway subnet is /24 or smaller

---

## 2. Private AKS Cluster

A private cluster ensures all API server traffic stays within the private network.

> "We recommend that you deploy your AKS cluster as a private cluster. All control plane and node pool traffic remain on your private network."  
> — [AKS Baseline Architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#secure-the-network-flow) — Confidence: High

Key configuration flags:
- `enablePrivateCluster: true` — makes API server accessible only via private endpoint
- `enablePrivateClusterPublicFQDN: false` — prevents public DNS disclosure

Access patterns for operators:
1. **Azure Bastion tunnel** — tunnel directly to the private API server (recommended for most teams)
2. **Jump-box VM** — for teams needing advanced diagnostic tooling or stable long-running sessions

---

## 3. Application Gateway Ingress Controller (AGIC)

AGIC runs as a pod in AKS and translates Kubernetes `Ingress` resources into Application Gateway rules.

### 3.1 Deployment method

Use the **AKS add-on** (not Helm) for production — it is fully managed, auto-updated, and better integrated.

```
AGIC add-on limitations:
- One AGIC add-on per AKS cluster
- Each AGIC targets one Application Gateway
- usePrivateIp defaults to false (cannot be changed via add-on)
- shared mode not supported
```

**Proof link:** [learn.microsoft.com/azure/application-gateway/ingress-controller-overview#difference-between-helm-deployment-and-aks-add-on](https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview#difference-between-helm-deployment-and-aks-add-on) — Confidence: High

### 3.2 AGIC identity requirements

The AGIC managed identity (`ingressapplicationgateway-<AKSNAME>`) needs:
- **Contributor** on the Application Gateway resource
- **Reader** on the Application Gateway resource group
- **Network Contributor** on the spoke VNet

---

## 4. Lab 02 — Deploy Private AKS + AGIC with Bicep

See [labs/lab-02-private-cluster/](../labs/lab-02-private-cluster/) for the complete Bicep files.

### Steps

```powershell
# NET-02 Lab: Deploy private cluster
$hubRg   = 'rg-aks-hub-dev'
$spokeRg = 'rg-aks-spoke-dev'
$location = 'eastus2'

# Create resource groups
az group create --name $hubRg   --location $location
az group create --name $spokeRg --location $location

# Preview deployment
az deployment sub what-if `
    --location $location `
    --template-file .\labs\lab-02-private-cluster\main.bicep `
    --parameters .\labs\lab-02-private-cluster\main.bicepparam

# Deploy
az deployment sub create `
    --location $location `
    --template-file .\labs\lab-02-private-cluster\main.bicep `
    --parameters .\labs\lab-02-private-cluster\main.bicepparam
```

### Validation

```powershell
# Confirm cluster is private
$cluster = az aks show `
    --name 'aks-prod-01' `
    --resource-group $spokeRg `
    --query 'apiServerAccessProfile.enablePrivateCluster' -o tsv

if ($cluster -eq 'true') {
    Write-Host "✓ Private cluster confirmed" -ForegroundColor Green
} else {
    Write-Warning "Cluster is NOT private — check deployment"
}

# Get credentials via Azure Bastion tunnel (from jump-box or Bastion session)
az aks get-credentials `
    --name 'aks-prod-01' `
    --resource-group $spokeRg `
    --overwrite-existing

kubectl get nodes
```

---

## 5. Network Policy Validation

```powershell
# NET-04: Deploy a test deny-all NetworkPolicy and confirm pod isolation
$denyAll = @"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: aks-store-demo
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
"@

$denyAll | kubectl apply -f -

# Test connectivity (should fail)
kubectl run -it --rm testpod --image=busybox --restart=Never -n aks-store-demo `
    -- wget -qO- http://store-front:80 --timeout=5
```

---

## Troubleshooting Drills

| Symptom                                            | Likely cause                                                | Investigation step                                                      |
| -------------------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| `kubectl` times out after `az aks get-credentials` | No network path to private API server                       | Verify you're on Bastion tunnel or jump-box                             |
| Pods cannot pull images from ACR                   | AcrPull role missing                                        | `az role assignment list --assignee <kubelet-identity-object-id>`       |
| AGIC pod in `CrashLoopBackOff`                     | AG subnet too large or identity missing Network Contributor | Check AGIC pod logs: `kubectl logs -n kube-system -l app=ingress-appgw` |
| NodePort 80 accessible from internet               | NSG missing DENY inbound rule                               | Review NSG on node subnet                                               |

---

## Checkpoint M02

1. (NET-01) Draw (or describe) the hub-spoke topology with subnet names and CIDRs.
2. (NET-02) What flag prevents a public FQDN from being exposed for the private API server?
3. (NET-03) What Application Gateway SKUs does AGIC require?
4. (NET-04) What happens if you don't enable network policy at cluster creation time?
5. (NET-05) What Azure service should be used to control outbound internet traffic from AKS?

**Pass criterion:** All five correct before progressing.

---

## Proof Links

| Claim                           | Source                                                                                                                                                                                                                                                             | Confidence |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| AKS baseline network topology   | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#network-topology](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#network-topology)                                 | High       |
| Private AKS cluster             | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#secure-the-network-flow](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#secure-the-network-flow)                   | High       |
| AGIC overview                   | [learn.microsoft.com/azure/application-gateway/ingress-controller-overview](https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview)                                                                                                     | High       |
| AGIC add-on vs Helm differences | [learn.microsoft.com/azure/application-gateway/ingress-controller-overview#difference-between-helm-deployment-and-aks-add-on](https://learn.microsoft.com/azure/application-gateway/ingress-controller-overview#difference-between-helm-deployment-and-aks-add-on) | High       |
| Network policies on AKS         | [learn.microsoft.com/azure/aks/use-network-policies](https://learn.microsoft.com/azure/aks/use-network-policies)                                                                                                                                                   | High       |
| Azure CNI Overlay               | [learn.microsoft.com/azure/aks/azure-cni-overlay](https://learn.microsoft.com/azure/aks/azure-cni-overlay)                                                                                                                                                         | High       |
| AGIC multitenant architecture   | [learn.microsoft.com/azure/architecture/example-scenario/aks-agic/aks-agic](https://learn.microsoft.com/azure/architecture/example-scenario/aks-agic/aks-agic)                                                                                                     | High       |
