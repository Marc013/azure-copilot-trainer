# Module 03 — ACR Integration and Image Management

**Objective IDs:** ACR-01, ACR-02, ACR-03  
**Estimated time:** 4 hours (2 h reading + 2 h lab)  
**Prerequisites:** Module 02  
**Lab:** Deploy ACR with private endpoint; push aks-store-demo images  

---

## Learning Objectives

- ACR-01: Deploy Azure Container Registry with Premium SKU and private endpoint.
- ACR-02: Attach ACR to AKS using the AcrPull managed identity role assignment.
- ACR-03: Build, tag, and push Azure-Samples/aks-store-demo images to ACR.

---

## 1. Why ACR for AKS?

Azure Container Registry (ACR) is Microsoft's managed OCI-compliant registry. When used with AKS:
- Images stay within the Azure network (when using private endpoints)
- The AKS kubelet identity can pull images without credentials by using the `AcrPull` RBAC role
- ACR Tasks automate image builds and patching

> The AKS cluster authenticates to ACR using the **AcrPull** role assigned to the cluster's kubelet managed identity.  
> **Proof link:** [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#integrate-microsoft-entra-id-for-the-cluster](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#integrate-microsoft-entra-id-for-the-cluster) — Confidence: High

---

## 2. ACR SKU Selection

| SKU      | Private endpoint | Geo-replication | Use case                                   |
| -------- | ---------------- | --------------- | ------------------------------------------ |
| Basic    | No               | No              | Dev/test                                   |
| Standard | Yes              | No              | Single-region staging                      |
| Premium  | Yes              | Yes             | Production; required for private endpoints |

**Use Premium for production.** Only Premium supports private endpoints and geo-replication.

---

## 3. Lab 03 — Deploy ACR with Private Endpoint

See [labs/lab-03-acr/](../labs/lab-03-acr/) for full Bicep files.

### Key Bicep snippet

```bicep
resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false       // Never enable admin user in production
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'AzureServices'
  }
}

resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${acrName}'
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${acrName}-conn'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: ['registry']
        }
      }
    ]
  }
}
```

### Attach ACR to AKS (AcrPull role assignment)

```bicep
// ACR-02: Grant AKS kubelet identity AcrPull on the registry
resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, aksKubeletIdentityObjectId, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull built-in role ID
    )
    principalId: aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}
```

---

## 4. Build and Push aks-store-demo Images

### 4.1 Get the sample source code

```powershell
# Follow the Learn quickstart to obtain the sample source tree,
# then switch to the local working directory.
Set-Location <PATH_TO_AKS_STORE_DEMO_SOURCE>
```

### 4.2 Build with ACR Tasks (no local Docker required)

```powershell
$acrName = 'acrakslab03'  # Set to your ACR name
$tag     = 'v1.0.0'

# Build and push store-front image
az acr build `
    --registry $acrName `
    --image "aks-store-demo/store-front:$tag" `
    --file ./src/store-front/Dockerfile `
    ./src/store-front

# Build and push store-admin image
az acr build `
    --registry $acrName `
    --image "aks-store-demo/store-admin:$tag" `
    --file ./src/store-admin/Dockerfile `
    ./src/store-admin

# Build and push order-service image
az acr build `
    --registry $acrName `
    --image "aks-store-demo/order-service:$tag" `
    --file ./src/order-service/Dockerfile `
    ./src/order-service

# Build and push product-service image
az acr build `
    --registry $acrName `
    --image "aks-store-demo/product-service:$tag" `
    --file ./src/product-service/Dockerfile `
    ./src/product-service
```

### 4.3 Verify images in ACR

```powershell
az acr repository list --name $acrName --output table

# Expected output:
# Result
# -----------------------------------
# aks-store-demo/store-front
# aks-store-demo/store-admin
# aks-store-demo/order-service
# aks-store-demo/product-service
```

---

## 5. Security Controls

| Control               | Implementation                                                          |
| --------------------- | ----------------------------------------------------------------------- |
| No admin user         | `adminUserEnabled: false` in Bicep                                      |
| No anonymous pull     | Keep auth-required pull path via RBAC and disable public network access |
| Private endpoint only | `publicNetworkAccess: 'Disabled'` in Bicep                              |
| Credential-free pull  | AcrPull role on kubelet managed identity                                |
| Image scanning        | Enable Microsoft Defender for Containers                                |

---

## Checkpoint M03

1. (ACR-01) Why is the Premium SKU required for production AKS?
2. (ACR-02) What Azure RBAC role allows AKS to pull images without credentials?
3. (ACR-03) What `az acr build` flag specifies the Dockerfile path?
4. Why should `adminUserEnabled` be `false`?

**Pass criterion:** All four correct before progressing.

---

## Proof Links

| Claim                                       | Source                                                                                                                                                                                                                                                                                     | Confidence |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------- |
| AcrPull role for AKS                        | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#integrate-microsoft-entra-id-for-the-cluster](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#integrate-microsoft-entra-id-for-the-cluster) | High       |
| ACR private endpoint                        | [learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#network-topology](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks#network-topology)                                                         | High       |
| AKS + ACR integration                       | [learn.microsoft.com/azure/aks/cluster-container-registry-integration](https://learn.microsoft.com/azure/aks/cluster-container-registry-integration)                                                                                                                                       | High       |
| aks-store-demo sample app source and layout | [learn.microsoft.com/azure/aks/learn/quick-kubernetes-deploy-cli](https://learn.microsoft.com/azure/aks/learn/quick-kubernetes-deploy-cli)                                                                                                                                                 | High       |
