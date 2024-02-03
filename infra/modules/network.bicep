param projectName string
param location string

var virtualNetworkName = 'vnet-${projectName}'
var loadBalancerName = 'lb-${projectName}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
  }

  resource subnetMinecraftServer 'subnets' = {
    name: 'MinecraftServer'
    properties: {
      addressPrefix: '10.0.0.0/28'
    }
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: 'pip-${loadBalancerName}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-06-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'FrontendIPConfiguration'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendAddressPool'
        properties: {
          virtualNetwork: virtualNetwork
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'Minecraft'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'FrontendIPConfiguration')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'BackendAddressPool')
          }
          protocol: 'TCP'
          frontendPort: 25565
          backendPort: 25565
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
output subnetMinecraftServerId string = virtualNetwork::subnetMinecraftServer.id
