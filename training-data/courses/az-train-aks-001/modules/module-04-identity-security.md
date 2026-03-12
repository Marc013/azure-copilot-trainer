# Module 04 — Identity and Security

**Objective IDs:** IDN-01, IDN-02, IDN-03, IDN-04  
**Estimated time:** 6 hours (3 h reading + 3 h lab)  
**Prerequisites:** Module 02, Module 03  
**Lab:** Configure Entra ID integration, Workload Identity, Kubernetes RBAC, and Key Vault CSI  

---

## Learning Objectives

- IDN-01: Enable AKS-managed Microsoft Entra ID integration and Azure RBAC for Kubernetes.
- IDN-02: Configure Workload Identity with federated credentials for pod-level identity.
- IDN-03: Apply Kubernetes RBAC (ClusterRole, RoleBinding) for least-privilege access.
- IDN-04: Integrate Azure Key Vault with AKS using Secrets Store CSI driver.

---

## 1. Microsoft Entra ID Integration

### 1.1 AKS-managed Entra ID (managed AAD)

When Entra ID integration is enabled, all `kubectl` connections require a valid Entra ID token. There are no local cluster admin accounts by default — this is the recommended production configuration.

```bicep
// IDN-01: Entra ID + Azure RBAC for Kubernetes
aadProfile: {
  managed: true
  enableAzureRBAC: true  // Uses Azure RBAC, not Kubernetes RBAC roles, for cluster access decisions
  tenantID: tenantId
  adminGroupObjectIDs: [adminGroupObjectId]
}
```

### 1.2 Azure RBAC built-in Kubernetes roles

| Role | Permissions |
|------|------------|
| Azure Kubernetes Service RBAC Admin | Full access within a namespace |
| Azure Kubernetes Service RBAC Cluster Admin | Full cluster access |
| Azure Kubernetes Service RBAC Reader | Read-only in namespace |
| Azure Kubernetes Service RBAC Writer | Read-write in namespace |

**Proof link:** [learn.microsoft.com/azure/aks/manage-azure-rbac](https://learn.microsoft.com/azure/aks/manage-azure-rbac) — Confidence: High

---

## 2. Workload Identity

Workload Identity allows pods to authenticate to Azure services using a Kubernetes service account federated to a managed identity — **no secrets or environment variable credentials needed**.

### 2.1 How it works

```
Kubernetes Service Account  ──── federated credential ────► Managed Identity
        │                                                         │
   Pod requests                                           Azure token issued
   OIDC token from                                        (via OIDC trust)
   cluster OIDC issuer
```

### 2.2 Bicep configuration

```bicep
// IDN-02: Enable OIDC issuer and Workload Identity on the cluster
oidcIssuerProfile: {
  enabled: true
}
securityProfile: {
  workloadIdentity: {
    enabled: true
  }
}
```

### 2.3 Managed identity and federated credential

```bicep
resource workloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-aks-workload'
  location: location
}

resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'fc-aks-store-demo'
  parent: workloadIdentity
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: aksCluster.properties.oidcIssuerProfile.issuerURL
    subject: 'system:serviceaccount:aks-store-demo:store-front-sa'
  }
}
```

### 2.4 Kubernetes service account annotation

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: store-front-sa
  namespace: aks-store-demo
  annotations:
    azure.workload.identity/client-id: "<MANAGED_IDENTITY_CLIENT_ID>"
```

**Proof link:** [learn.microsoft.com/azure/aks/workload-identity-overview](https://learn.microsoft.com/azure/aks/workload-identity-overview) — Confidence: High

---

## 3. Kubernetes RBAC

Even with Azure RBAC enabled, Kubernetes-native RBAC controls access within the cluster.

```yaml
# IDN-03: Read-only access to the aks-store-demo namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: store-reader
  namespace: aks-store-demo
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: store-reader-binding
  namespace: aks-store-demo
subjects:
  - kind: User
    name: "<ENTRA_USER_UPN>"
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: store-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 4. Key Vault Integration (Secrets Store CSI)

The Secrets Store CSI driver mounts Azure Key Vault secrets as Kubernetes volumes or environment variables — without storing secrets in Kubernetes `Secret` objects.

### 4.1 Enable the add-on

```bicep
addonProfiles: {
  azureKeyvaultSecretsProvider: {
    enabled: true
    config: {
      enableSecretRotation: 'true'
      rotationPollInterval: '2m'
    }
  }
}
```

### 4.2 SecretProviderClass manifest

```yaml
# IDN-04: Mount Key Vault secret as a volume
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: kv-store-demo
  namespace: aks-store-demo
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: "<WORKLOAD_IDENTITY_CLIENT_ID>"
    keyvaultName: "<KEY_VAULT_NAME>"
    objects: |
      array:
        - |
          objectName: order-service-db-password
          objectType: secret
          objectVersion: ""
    tenantId: "<TENANT_ID>"
```

**Proof link:** [learn.microsoft.com/azure/aks/csi-secrets-store-driver](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver) — Confidence: High

---

## 5. Security Hardening Checklist

- [ ] Disable local accounts: `--disable-local-accounts` (or `disableLocalAccounts: true` in Bicep)
- [ ] Enable private cluster (`enablePrivateCluster: true`)
- [ ] Enable Workload Identity + OIDC issuer
- [ ] Assign only required RBAC roles to managed identities
- [ ] Enable Microsoft Defender for Containers
- [ ] Use Pod Security Admission (enforce `restricted` or `baseline` for workload namespaces)
- [ ] Enable Azure Policy for AKS (see Module 10)

---

## Checkpoint M04

1. (IDN-01) How do operators authenticate to a private AKS cluster with Entra ID integration enabled?
2. (IDN-02) What does the `subject` field in a federated credential represent?
3. (IDN-03) What is the difference between a `Role` and a `ClusterRole`?
4. (IDN-04) Why is Secrets Store CSI preferred over Kubernetes `Secret` objects?

**Pass criterion:** All four correct.

---

## Proof Links

| Claim | Source | Confidence |
|-------|--------|------------|
| AKS Entra ID managed integration | [learn.microsoft.com/azure/aks/managed-aad](https://learn.microsoft.com/azure/aks/managed-aad) | High |
| Azure RBAC for Kubernetes | [learn.microsoft.com/azure/aks/manage-azure-rbac](https://learn.microsoft.com/azure/aks/manage-azure-rbac) | High |
| Workload Identity overview | [learn.microsoft.com/azure/aks/workload-identity-overview](https://learn.microsoft.com/azure/aks/workload-identity-overview) | High |
| Secrets Store CSI driver | [learn.microsoft.com/azure/aks/csi-secrets-store-driver](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver) | High |
| Disable local accounts | [learn.microsoft.com/azure/aks/managed-aad#disable-local-accounts](https://learn.microsoft.com/azure/aks/managed-aad#disable-local-accounts) | High |
