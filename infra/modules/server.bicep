param location string
param projectName string

param containers {
  name: string
  properties: {
    image: string
    resources: {
      requests: {
        cpu: string
        memoryInGB: int
      }
    }
    ports: containerPort[]
    environmentVariables: containerEnvironmentVariable[]
    volumeMounts: {
      name: string
      mountPath: string
      readOnly: bool
    }[]
  }
}[]

type containerEnvironmentVariable = {
  name: string
  value: string
}

type containerPort = {
  port: int
  protocol: string
}

param volumes {
  name: string
  azureFile: {
    readOnly: bool
    shareName: string
    storageAccountName: string
    storageAccountKey: string
  }
}[]

param gamePort int

// Log Analytics settings
param workspaceName string

var containerGroupName = 'ci-${projectName}-server'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    osType: 'Linux'
    containers: containers
    volumes: volumes
    restartPolicy: 'OnFailure'
    diagnostics: {
      logAnalytics: {
        workspaceId: workspace.properties.customerId
        workspaceKey: workspace.listKeys().primarySharedKey
      }
    }
    ipAddress: {
      type: 'Public'
      dnsNameLabel: projectName
      ports: [
        {
          protocol: 'TCP'
          port: gamePort
        }
      ]
    }
  }
}

output containerGroupFqdn string = containerGroup.properties.ipAddress.fqdn
output containerGroupId string = containerGroup.id
output containerGroupName string = containerGroup.name
