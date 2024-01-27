param location string
param projectName string

@description('The name of the Log Analytics workspace to use for the bot')
param workspaceName string

@description('The docker image to use for the bot. This should be a public image. Leave the default value if you don\'t know what this is.')
param botDockerImage string = 'ghcr.io/ginomessmer/azmc/discord-bot:feature-bot'

@description('The resource ID of the container group that runs the Minecraft server. This is used to interact with the server.')
param minecraftContainerGroupName string

@description('The public key of the Discord bot. This is used to verify that the bot is the one that sent a message.')
@secure()
param discordBotPublicKey string

@description('The token of the Discord bot. This is used to authenticate the bot with Discord.')
@secure()
param discordBotToken string

@description('The role ID of the role that is allowed to launch the container app. This is used to allow the bot to launch the container app.')
param containerLaunchManagerRoleId string

var suffix = '${projectName}-services'
var containerAppName = 'ca-${projectName}-discord-bot'
var containerEnvironmentName = 'cae-${suffix}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource minecraftServerContainerGroup 'Microsoft.ContainerInstance/containerGroups@2021-03-01' existing = {
  name: minecraftContainerGroupName
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

resource discordBotContainerApp 'Microsoft.App/containerApps@2023-05-01' = {
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
      ingress: {
        allowInsecure: false
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          name: 'discord-bot'
          image: botDockerImage
          env: [
            {
              name: 'Azure__ContainerGroupResourceId'
              value: minecraftServerContainerGroup.id
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
          resources:{
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(discordBotContainerApp.id, containerLaunchManagerRoleId)
  scope: minecraftServerContainerGroup
  properties: {
    principalId: discordBotContainerApp.identity.principalId
    roleDefinitionId: containerLaunchManagerRoleId
  }
}

output containerAppUrl string = discordBotContainerApp.properties.configuration.ingress.fqdn
