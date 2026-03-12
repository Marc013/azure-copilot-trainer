using 'main.bicep'

param location = 'eastus2'
param environment = 'dev'
param kubernetesVersion = '1.29'

// Replace with your Entra ID group object ID that will have cluster admin access
param adminGroupObjectId = '<YOUR_ADMIN_GROUP_OBJECT_ID>'

// tenantId defaults to the current subscription tenant - override if needed
// param tenantId = '<YOUR_TENANT_ID>'
