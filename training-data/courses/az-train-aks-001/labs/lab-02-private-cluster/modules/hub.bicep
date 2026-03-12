// Hub module: Hub VNet, Azure Firewall, Azure Bastion
// Objective: NET-01 (hub-spoke topology), NET-05 (egress via Azure Firewall)

@description('Azure region')
param location string

@description('Environment suffix')
param environment string

// Hub virtual network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-hub-${environment}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet' // Must be exactly this name for Azure Firewall
        properties: {
          addressPrefix: '10.0.1.0/26'
        }
      }
      {
        name: 'AzureBastionSubnet' // Must be exactly this name for Azure Bastion
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.3.0/27'
        }
      }
    ]
  }
}

// Azure Firewall Public IP
resource fwPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-fw-${environment}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Firewall (Standard SKU for egress filtering)
resource azFirewall 'Microsoft.Network/azureFirewalls@2023-11-01' = {
  name: 'fw-hub-${environment}'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: fwPip.id
          }
        }
      }
    ]
    // NET-05: Allow AKS required egress — permit mcr.microsoft.com, *.hcp.<region>.azmk8s.io, etc.
    // Use Azure Firewall policy (AzureFirewallPolicy) for rule management in production
    applicationRuleCollections: [
      {
        name: 'aks-required-outbound'
        properties: {
          priority: 100
          action: { type: 'Allow' }
          rules: [
            {
              name: 'allow-mcr'
              protocols: [{ protocolType: 'Https', port: 443 }]
              targetFqdns: ['*.data.mcr.microsoft.com', 'mcr.microsoft.com']
              sourceAddresses: ['10.1.0.0/16']
            }
            {
              name: 'allow-aks-api-server'
              protocols: [{ protocolType: 'Https', port: 443 }]
              targetFqdns: ['*.hcp.${location}.azmk8s.io']
              sourceAddresses: ['10.1.0.0/16']
            }
            {
              name: 'allow-ubuntu-updates'
              protocols: [
                { protocolType: 'Http', port: 80 }
                { protocolType: 'Https', port: 443 }
              ]
              targetFqdns: [
                'security.ubuntu.com'
                'azure.archive.ubuntu.com'
                'packages.microsoft.com'
              ]
              sourceAddresses: ['10.1.0.0/16']
            }
          ]
        }
      }
    ]
  }
}

// Bastion Public IP
resource bastionPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-bastion-${environment}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Bastion (for private cluster operator access)
resource bastion 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: 'bastion-hub-${environment}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[1].id
          }
          publicIPAddress: {
            id: bastionPip.id
          }
        }
      }
    ]
    enableTunneling: true // Required for `az network bastion tunnel` to AKS API server
  }
}

output hubVnetId string = hubVnet.id
output firewallPrivateIp string = azFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output bastionName string = bastion.name
