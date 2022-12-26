resource botVM 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: 'vm-azmcbot'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Basic_A0'
    }
    osProfile: {
      customData: loadFileAsBase64('bot.cloud-init')
      computerName: 'azmcbot'
      adminUsername: 'azmc'
      adminPassword: 'adminPassword'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '16.04-LTS'
        version: 'latest'
      }
      osDisk: {
        diskSizeGB: 32
        name: 'os'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: botNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'storageUri'
      }
    }
  }
}

resource botNic 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: 'nic-vm-azmcbot'
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ip-azmcbot'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: 'subnet.id'
          }
        }
      }
    ]
  }
}
