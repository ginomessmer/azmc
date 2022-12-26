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
              memoryInGB: MemorySize + 1
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
    networkProfile: {
      id: networkProfile.id
    }
    restartPolicy: 'OnFailure'
    osType: 'Linux'
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    ipAddress: {
      type: 'Private'
      ports: [
        {
          protocol: 'TCP'
          port: 25565
        }
      ]
    }
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

// Networking Stuff
resource networkProfile 'Microsoft.Network/networkProfiles@2021-08-01' = {
  name: 'np-${Name}'
  location: Location
  properties: {
    containerNetworkInterfaceConfigurations: [
      {
        name: 'nic-mc-server'
        properties: {
          ipConfigurations: [
            {
              name: 'ipc-mc-server'
              properties: {
                subnet: {
                  id: subnet.id
                }
              }
            }
          ]
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-${Name}'
  location: Location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: Name
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-${Name}'
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/28'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: virtualNetwork
  name: 'snet-mc-server'
  properties: {
    addressPrefix: '10.0.0.0/28'
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

resource loadBalancerExternal 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: 'elb-${Name}'
  location: Location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'public'
        properties: {
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'container'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'mcBackendAddressPool'
              properties: {
                ipAddress: containerGroup.properties.ipAddress.ip
                subnet: {
                  id: subnet.id
                }
                virtualNetwork: {
                  id: virtualNetwork.id
                }
              }
            }
          ]
        }
      }
    ]
    inboundNatRules: [
      {
        name: 'default'
        properties: {
          backendPort: 25565
          frontendPort: 25565
          protocol: 'Tcp'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'elb-${Name}', 'public')
          }
        }
      }
    ]
  }
}
