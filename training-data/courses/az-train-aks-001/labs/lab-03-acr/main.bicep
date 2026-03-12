// lab-03-acr/main.bicep
// Scope: Resource group (rg-aks-spoke-<env>)
// Deploys: ACR Premium + private endpoint + private DNS zone + AcrPull role for AKS kubelet identity
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

@description('Object ID of the AKS kubelet managed identity (output from lab-02 spoke.bicep).')
param kubeletIdentityObjectId string

@description('Resource ID of the spoke VNet for the private endpoint.')
param spokeVnetId string

@description('Resource ID of the private-endpoints subnet inside the spoke VNet.')
param privateEndpointSubnetId string

// ─────────────────────────────────────────────────────────────────────────────
// Variables
// ─────────────────────────────────────────────────────────────────────────────
var acrName = 'acraks${environment}${uniqueString(resourceGroup().id)}'
var acrPrivateEndpointName = 'pe-acr-${environment}'
var privateDnsZoneName = 'privatelink.azurecr.io'

// Built-in AcrPull role definition ID
// https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = resourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

// ─────────────────────────────────────────────────────────────────────────────
// ACR (Premium — required for private endpoints and geo-replication)
// ─────────────────────────────────────────────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false // Never use admin user in production
    publicNetworkAccess: 'Disabled' // Traffic only through private endpoint
    zoneRedundancy: 'Disabled' // Enable in prod regions that support it
    policies: {
      retentionPolicy: {
        days: 30
        status: 'enabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private DNS zone for ACR (privatelink.azurecr.io)
// ─────────────────────────────────────────────────────────────────────────────
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

// Link the private DNS zone to the spoke VNet so AKS can resolve ACR FQDN
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-acr-spoke-${environment}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: spokeVnetId
    }
    registrationEnabled: false
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private endpoint for ACR inside the spoke VNet
// ─────────────────────────────────────────────────────────────────────────────
resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: acrPrivateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: acrPrivateEndpointName
        properties: {
          privateLinkServiceId: acr.id
          groupIds: ['registry']
        }
      }
    ]
  }
}

// Register the private endpoint NIC IPs in the private DNS zone
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = {
  parent: acrPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'azure-cr-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AcrPull role assignment for AKS kubelet managed identity
// This allows nodes to pull images without credentials
// ─────────────────────────────────────────────────────────────────────────────
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, kubeletIdentityObjectId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outputs
// ─────────────────────────────────────────────────────────────────────────────
@description('The login server URL for this ACR instance.')
output acrLoginServer string = acr.properties.loginServer

@description('The resource ID of the ACR.')
output acrId string = acr.id

@description('The short name (not FQDN) of the ACR — used in pipeline variable ACR_NAME.')
output acrName string = acr.name
