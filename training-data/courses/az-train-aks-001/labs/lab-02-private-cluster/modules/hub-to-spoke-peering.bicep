@description('Hub VNet name in the hub resource group.')
param hubVnetName string

@description('Resource ID of the spoke VNet.')
param spokeVnetId string

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: hubVnetName
}

// Reverse peering from hub to spoke to allow bidirectional routing.
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer-hub-to-spoke'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
}
