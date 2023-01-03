param name string = resourceGroup().name

@secure()
param discordBotToken string

param enableOverviewer bool = false

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
    containerGroupName: minecraft.outputs.containerGroupName
    discordToken: discordBotToken
  }
}

output minecraftServerJoinHostname string = minecraft.outputs.joinHostname
