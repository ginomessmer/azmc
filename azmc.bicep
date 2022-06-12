param Location string = resourceGroup().location
param Name string = 'azmc'
param MinecraftVersion string = 'LATEST'
param MemorySize int = 3
param CpuCores int = 2

@allowed([
  'TRUE'
  'FALSE'
])
param IsAutostopEnabled string = 'TRUE'

var ServerShareName = 'server'
var ServerMountPath = '/data'
var ServerType = 'SPIGOT'


@description('Address prefix')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet prefix')
param subnetAddressPrefix string = '10.0.2.0/24'


/*
 * STORAGE
 */
resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: Name
  location: Location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource serverShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-09-01' = {
  name: '${storage.name}/default/${ServerShareName}'
  properties: {
    accessTier: 'Hot'
    shareQuota: 1024
  }
}


/*
 * NETWORKING
 */
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: Name
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

// resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
//   name: 'AzureFirewallSubnet'
//   parent: virtualNetwork
//   properties: {
//     addressPrefix: '10.0.1.0/26'
//   }
// }

resource workloadSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  name: 'Workload-SN'
  parent: virtualNetwork
  properties: {
    addressPrefix: subnetAddressPrefix
    delegations: [
      {
        name: 'DelegationService'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
      }
    ]
  }
}

resource networkProfile 'Microsoft.Network/networkProfiles@2021-08-01' = {
  name: 'server-np'
  location: Location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'server-nic'
        properties: {
          ipConfigurations: [
            {
              name: 'server-ip'
              properties: {
                subnet: {
                  id: workloadSubnet.id
                }
              }
            }
          ]
        }
      }
    ]
  }
}


/*
 * COMPUTE
 */
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = {
  name: Name
  location: Location
  properties: {
    containers: [
      {
        name: 'server'
        properties: {
          image: 'itzg/minecraft-server'
          ports: [
            {
              port: 25565
            }
          ]
          environmentVariables: [
            {
              name: 'EULA'
              value: 'true'
            }
            {
              name: 'TYPE'
              value: ServerType
            }
            {
              name: 'VERSION'
              value: MinecraftVersion
            }
            {
              name: 'ENABLE_AUTOSTOP'
              value: IsAutostopEnabled
            }
            {
              name: 'MEMORY'
              value: '${MemorySize}G'
            }
          ]
          volumeMounts: [
            {
              name: 'server'
              mountPath: ServerMountPath
              readOnly: false
            }
          ]
          resources: {
            requests: {
              cpu: CpuCores
              memoryInGB: MemorySize
            }
          }
        }
      }
    ]
    volumes: [
      {
        name: 'server'
        azureFile: {
          readOnly: false
          shareName: ServerShareName
          storageAccountName: storage.name
          storageAccountKey: storage.listKeys().keys[0].value
        }
      }
    ]
    restartPolicy: 'OnFailure'
    osType: 'Linux'
    networkProfile: {
      id: networkProfile.id
    }
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    // ipAddress: {
    //   type: 'Private'
    //   ports: [
    //     {
    //       protocol: 'TCP'
    //       port: 25565
    //     }
    //   ]
    // }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${Name}-workspace'
  location: Location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}
