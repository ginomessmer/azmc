@description('Container group name of the game server.')
param containerGroupName string

@description('Discord bot token.')
param discordToken string

@description('Name of the server')
param name string

@description('Username for the Virtual Machine.')
param adminUsername string = 'azmc'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string


@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '18.04-LTS'
])
param ubuntuOSVersion string = '18.04-LTS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_B1ls'

@description('Name of the subnet in the virtual network')
param subnetName string = 'Subnet-1'

var vmName = 'vm-${name}-bot'
var dnsLabelPrefix = toLower('${name}-bot')
var virtualNetworkName = 'vnet-${vmName}'
var networkSecurityGroupName = 'nsg-${vmName}'
var publicIPAddressName = 'pip-${vmName}'
var networkInterfaceName = 'nic-${vmName}'
var keyVaultName = take('kv-${vmName}-${uniqueString(resourceGroup().id)}', 24)
var osDiskType = 'Standard_LRS'
var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'public'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
      customData: base64(format(loadTextContent('bot.cloud-init'), keyVaultName))
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Key Vault for secret management
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    tenantId: vm.identity.tenantId
    accessPolicies: [
      {
        tenantId: vm.identity.tenantId
        objectId: vm.identity.principalId
        permissions: {
          keys: [
            'get'
          ]
          secrets: [
            'list'
            'get'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }

  resource tenantIdSecret 'secrets@2022-07-01' = {
    name: 'Bot--TenantId'
    properties: {
      value: tenant().tenantId
    }
  }

  resource subscriptionIdSecret 'secrets@2022-07-01' = {
    name: 'Bot--SubscriptionId'
    properties: {
      value: subscription().subscriptionId
    }
  }

  resource rgNameSecret 'secrets@2022-07-01' = {
    name: 'Bot--ResourceGroupName'
    properties: {
      value: resourceGroup().name
    }
  }

  resource containerNameSecret 'secrets@2022-07-01' = {
    name: 'Bot--ContainerGroupName'
    properties: {
      value: containerGroupName
    }
  }

  resource discordTokenSecret 'secrets@2022-07-01' = {
    name: 'Bot--DiscordToken'
    properties: {
      value: discordToken
    }
  }

  resource vmBotPasswordSecret 'secrets@2022-07-01' = {
    name: 'VmBotSecret'
    properties: {
      value: adminPasswordOrKey
    }
  }
}

output adminUsername string = adminUsername
output hostname string = publicIP.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIP.properties.dnsSettings.fqdn}'
output vmPrincipalId string = vm.identity.principalId
