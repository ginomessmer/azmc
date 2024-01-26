param location string
param projectName string

@description('The name of the Log Analytics workspace to use for the bot')
param workspaceName string

@description('The docker image to use for the bot. This should be a public image. Leave the default value if you don\'t know what this is.')
param botDockerImage string = 'ghcr.io/ginomessmer/azmc/discord-bot:feature-bot'

@description('The resource ID of the container group that runs the Minecraft server. This is used to interact with the server.')
param minecraftContainerGroupId string

@description('The public key of the Discord bot. This is used to verify that the bot is the one that sent a message.')
@secure()
param discordBotPublicKey string

@description('The token of the Discord bot. This is used to authenticate the bot with Discord.')
@secure()
param discordBotToken string

var containerAppName = 'ca-${projectName}-discord-bot'
var containerEnvironmentName = 'cae-${projectName}-services'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

// Container Environment
resource containerEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerEnvironmentName
  location: location

  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: listKeys(workspace.id, workspace.apiVersion).primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: containerEnvironment.id
    configuration: {
      secrets: [
        {
          name: 'bot-public-key'
          value: discordBotPublicKey
        }
        {
          name: 'bot-token'
          value: discordBotToken
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'discord-bot'
          image: botDockerImage
          env: [
            {
              name: 'Azure__ContainerGroupResourceId'
              value: minecraftContainerGroupId
            }
            {
              name: 'Bot__PublicKey'
              secretRef: 'bot-public-key'
            }
            {
              name: 'Bot__Token'
              secretRef: 'bot-token'
            }
          ]
        }
      ]
    }
  }

}
