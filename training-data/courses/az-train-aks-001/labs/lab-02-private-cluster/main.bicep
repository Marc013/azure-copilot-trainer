// Lab 02: Private AKS Cluster with Hub-Spoke Networking, AGIC, and Azure Firewall
// Deploy at subscription scope: az deployment sub create ...
// Objective IDs: NET-01, NET-02, NET-03, NET-04, NET-05

targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'eastus2'

@description('Environment suffix: dev, staging, prod')
param environment string = 'dev'

@description('AKS Kubernetes version')
param kubernetesVersion string = '1.29'

@description('Object ID of the Entra ID admin group for cluster access')
param adminGroupObjectId string

@description('Tenant ID for Entra ID integration')
param tenantId string = subscription().tenantId

// Resource groups
resource hubRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-aks-hub-${environment}'
  location: location
}

resource spokeRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-aks-spoke-${environment}'
  location: location
}

resource opsRg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-aks-ops-${environment}'
  location: location
}

// Deploy hub VNet and Azure Firewall
module hub './modules/hub.bicep' = {
  scope: hubRg
  params: {
    location: location
    environment: environment
  }
}

// Deploy Log Analytics workspace
module logAnalytics './modules/log-analytics.bicep' = {
  scope: opsRg
  params: {
    location: location
    environment: environment
  }
}

// Deploy spoke VNet, Application Gateway, private AKS cluster
module spoke './modules/spoke.bicep' = {
  scope: spokeRg
  params: {
    location: location
    environment: environment
    kubernetesVersion: kubernetesVersion
    hubVnetId: hub.outputs.hubVnetId
    azureFirewallPrivateIp: hub.outputs.firewallPrivateIp
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    adminGroupObjectId: adminGroupObjectId
    tenantId: tenantId
  }
}

// Create reverse peering from hub to spoke for bidirectional routing.
module hubToSpokePeering './modules/hub-to-spoke-peering.bicep' = {
  scope: hubRg
  params: {
    hubVnetName: 'vnet-hub-${environment}'
    spokeVnetId: spoke.outputs.spokeVnetId
  }
}

output aksClusterName string = spoke.outputs.aksClusterName
output aksClusterResourceGroup string = spokeRg.name
output agicApplicationGatewayId string = spoke.outputs.appGatewayId
output kubeletIdentityObjectId string = spoke.outputs.kubeletIdentityObjectId
