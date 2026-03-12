// lab-04-identity/main.bicep
// Scope: Resource group (rg-aks-spoke-<env>)
// Deploys: User-assigned managed identity + federated credential (Workload Identity)
//          + Key Vault with private endpoint + Key Vault secret for workload demo
//
// Deploy command:
//   az deployment group create \
//     --resource-group rg-aks-spoke-dev \
//     --template-file main.bicep \
//     --parameters main.bicepparam

targetScope = 'resourceGroup'

// ─────────────────────────────────────────────────────────────────────────────
// Parameters
// ─────────────────────────────────────────────────────────────────────────────
@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Short environment label: dev | staging | prod')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('OIDC issuer URL from AKS cluster (output from lab-02 spoke.bicep).')
param oidcIssuerUrl string

@description('Kubernetes namespace where the workload Service Account lives.')
param k8sNamespace string = 'aks-store-demo'

@description('Kubernetes Service Account name that will be annotated with the identity.')
param k8sServiceAccountName string = 'workload-identity-sa'

@description('Resource ID of the private-endpoints subnet inside the spoke VNet.')
param privateEndpointSubnetId string

@description('Resource ID of the spoke VNet for private DNS zone link.')
param spokeVnetId string

// ─────────────────────────────────────────────────────────────────────────────
// Variables
// ─────────────────────────────────────────────────────────────────────────────
var identityName = 'id-aks-workload-${environment}'
var keyVaultName = 'kv-aks-${environment}-${take(uniqueString(resourceGroup().id), 6)}'
var kvPrivateEndpointName = 'pe-kv-${environment}'
var kvPrivateDnsZoneName = 'privatelink.vaultcore.azure.net'

// Built-in Key Vault Secrets User role
var kvSecretsUserRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// ─────────────────────────────────────────────────────────────────────────────
// User-assigned managed identity (one per workload per environment)
// ─────────────────────────────────────────────────────────────────────────────
resource workloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// ─────────────────────────────────────────────────────────────────────────────
// Federated credential — binds the Kubernetes Service Account to this identity
// The subject format is: system:serviceaccount:<namespace>:<serviceAccountName>
// ─────────────────────────────────────────────────────────────────────────────
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: workloadIdentity
  name: 'fc-aks-${k8sNamespace}-${k8sServiceAccountName}'
  properties: {
    issuer: oidcIssuerUrl
    subject: 'system:serviceaccount:${k8sNamespace}:${k8sServiceAccountName}'
    audiences: ['api://AzureADTokenExchange']
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Key Vault (RBAC authorization, no legacy access policies)
// ─────────────────────────────────────────────────────────────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true // Use Azure RBAC — not access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled' // Private endpoint only
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Demo secret — in production use CI/CD pipeline (not Bicep) to write actual secret values
resource demoSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'store-connection-string'
  properties: {
    value: 'placeholder-replace-via-pipeline'
    attributes: {
      enabled: true
    }
  }
}

// Grant workload identity the ability to read secrets
resource kvSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, workloadIdentity.id, kvSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: kvSecretsUserRoleId
    principalId: workloadIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private endpoint + DNS zone for Key Vault
// ─────────────────────────────────────────────────────────────────────────────
resource kvPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: kvPrivateDnsZoneName
  location: 'global'
}

resource kvPrivateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: kvPrivateDnsZone
  name: 'link-kv-spoke-${environment}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: spokeVnetId
    }
    registrationEnabled: false
  }
}

resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: kvPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: kvPrivateEndpointName
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

resource kvPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: kvPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyvault-config'
        properties: {
          privateDnsZoneId: kvPrivateDnsZone.id
        }
      }
    ]
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outputs — consumed by subsequent labs and the CI/CD pipeline
// ─────────────────────────────────────────────────────────────────────────────
@description('Client ID of the workload managed identity (annotate Service Account with this).')
output workloadIdentityClientId string = workloadIdentity.properties.clientId

@description('Object ID of the workload managed identity.')
output workloadIdentityObjectId string = workloadIdentity.properties.principalId

@description('Resource ID of the Key Vault.')
output keyVaultId string = keyVault.id

@description('URI of the Key Vault (used in SecretProviderClass).')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Name of the Key Vault.')
output keyVaultName string = keyVault.name
