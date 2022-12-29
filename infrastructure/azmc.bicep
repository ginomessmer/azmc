param name string

@secure()
param botVmPassword string

param location string = resourceGroup().location


module minecraft 'minecraft.bicep' = {
  name: 'minecraftModule'
  params: {
    Location: location
    Name: name
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
