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

output virtualNetworkId string = virtualNetwork.id
output subnetMinecraftServerId string = virtualNetwork::subnetMinecraftServer.id
