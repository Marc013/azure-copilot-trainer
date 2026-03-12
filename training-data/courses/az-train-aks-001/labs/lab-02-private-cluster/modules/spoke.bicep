// Spoke module: Spoke VNet, Application Gateway WAF v2 (for AGIC), Private AKS Cluster
// Objective IDs: NET-01, NET-02, NET-03, NET-04

@description('Azure region')
param location string

@description('Environment suffix')
param environment string

@description('Kubernetes version')
param kubernetesVersion string

@description('Resource ID of the hub VNet for peering')
param hubVnetId string

@description('Private IP of the Azure Firewall (for UDR)')
param azureFirewallPrivateIp string

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Object ID of the Entra ID admin group')
param adminGroupObjectId string

@description('Tenant ID')
param tenantId string

// Spoke VNet with dedicated subnets
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-spoke-${environment}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        // Application Gateway subnet — must be /24 or smaller for future CNI Overlay upgrades
        name: 'snet-appgw'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
      {
        // AKS node VMs
        name: 'snet-aks-nodes'
        properties: {
          addressPrefix: '10.1.2.0/22'
          routeTable: { id: udr.id } // Force egress through Azure Firewall
        }
      }
      {
        // API server VNet integration — delegated subnet
        name: 'snet-aks-apiserver'
        properties: {
          addressPrefix: '10.1.6.0/28'
          delegations: [
            {
              name: 'aks-api-server-delegation'
              properties: {
                serviceName: 'Microsoft.ContainerService/managedClusters'
              }
            }
          ]
        }
      }
      {
        // Private endpoints for ACR and Key Vault
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.1.7.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// UDR: Route all internet traffic through Azure Firewall (NET-05)
resource udr 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'rt-aks-nodes-${environment}'
  location: location
  properties: {
    routes: [
      {
        name: 'route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIp
        }
      }
    ]
  }
}

// VNet peering: spoke → hub
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  name: 'peer-spoke-to-hub'
  parent: spokeVnet
  properties: {
    remoteVirtualNetwork: { id: hubVnetId }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
}

// Application Gateway WAF v2 (NET-03)
resource appGwPip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-appgw-${environment}'
  location: location
  sku: { name: 'Standard', tier: 'Regional' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: 'agw-aks-${environment}'
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 10
    }
    // AGIC will manage backend pools, listeners, and rules — provide minimal initial config
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-config'
        properties: {
          subnet: {
            id: spokeVnet.properties.subnets[0].id // snet-appgw
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-frontend-public'
        properties: {
          publicIPAddress: { id: appGwPip.id }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-80'
        properties: { port: 80 }
      }
    ]
    backendAddressPools: [
      {
        name: 'default-backend-pool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'default-http-settings'
        properties: {
          port: 80
          protocol: 'Http'
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'default-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              'agw-aks-${environment}',
              'appgw-frontend-public'
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'agw-aks-${environment}', 'port-80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'default-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              'agw-aks-${environment}',
              'default-listener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              'agw-aks-${environment}',
              'default-backend-pool'
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              'agw-aks-${environment}',
              'default-http-settings'
            )
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}

// Private AKS Cluster (NET-02, with AGIC add-on NET-03)
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: 'aks-${environment}-01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: 'aks-${environment}-01-dns'

    // NET-02: Private cluster
    apiServerAccessProfile: {
      enablePrivateCluster: true
      enablePrivateClusterPublicFQDN: false // Prevent public DNS disclosure
    }

    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 2
        vmSize: 'Standard_D4ds_v5'
        osType: 'Linux'
        osDiskSizeGB: 0 // Use default (ephemeral disk)
        osDiskType: 'Ephemeral'
        mode: 'System'
        vnetSubnetID: spokeVnet.properties.subnets[1].id // snet-aks-nodes
        nodeTaints: ['CriticalAddonsOnly=true:NoSchedule']
        enableAutoScaling: false
        minCount: null
        maxCount: null
      }
      {
        name: 'userpool'
        count: 2
        vmSize: 'Standard_D4ds_v5'
        osType: 'Linux'
        osDiskSizeGB: 0
        osDiskType: 'Ephemeral'
        mode: 'User'
        vnetSubnetID: spokeVnet.properties.subnets[1].id
        enableAutoScaling: true
        minCount: 2
        maxCount: 10
      }
    ]

    // NET-04: Azure CNI Overlay with Azure Network Policies
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkPolicy: 'azure'
      podCidr: '192.168.0.0/16' // Overlay CIDR — separate from VNet
      serviceCidr: '172.16.0.0/16'
      dnsServiceIP: '172.16.0.10'
      outboundType: 'userDefinedRouting' // Egress via Azure Firewall (NET-05)
    }

    // IDN-01: Entra ID + Azure RBAC for Kubernetes
    enableRBAC: true
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      tenantID: tenantId
      adminGroupObjectIDs: [adminGroupObjectId]
    }
    disableLocalAccounts: true // Force Entra ID authentication only

    // OBS-01: Container Insights
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      // NET-03: AGIC add-on
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGateway.id
        }
      }
      // IDN-04: Key Vault Secrets Store CSI
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      // GOV-01: Azure Policy
      azurepolicy: {
        enabled: true
      }
    }

    // IDN-02: OIDC issuer for Workload Identity
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }

    // UPG-01: Auto-upgrade channel
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }

    // SCA-02: Cluster Autoscaler profile
    autoScalerProfile: {
      'scale-down-delay-after-add': '10m'
      'scale-down-unneeded-time': '10m'
      'scale-down-utilization-threshold': '0.5'
      'balance-similar-node-groups': 'true'
    }
  }
}

output aksClusterName string = aksCluster.name
output appGatewayId string = appGateway.id
output kubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId
output oidcIssuerUrl string = aksCluster.properties.oidcIssuerProfile.issuerURL
output spokeVnetId string = spokeVnet.id
output privateEndpointSubnetId string = spokeVnet.properties.subnets[3].id
