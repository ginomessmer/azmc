param name string = resourceGroup().name

param enableOverviewer bool

@secure()
param botVmPassword string

param location string = resourceGroup().location


module minecraft 'minecraft.bicep' = {
  name: 'minecraftModule'
  params: {
    location: location
    name: name
    overviewerEnabled: enableOverviewer
  }
}

module bot 'bot.bicep' = {
  name: 'botModule'
  params: {
    location: location
    adminPasswordOrKey: botVmPassword
  }
}

output minecraftServerJoinHostname string = minecraft.outputs.joinHostname
