// Log Analytics Workspace module
// Objective: OBS-01

@description('Azure region')
param location string

@description('Environment suffix')
param environment string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-aks-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled' // Container Insights agent pushes logs
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output workspaceId string = logAnalytics.id
output workspaceCustomerId string = logAnalytics.properties.customerId
