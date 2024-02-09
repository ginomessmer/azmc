param location string
param projectName string

param retentionInDays int = 90

var const = loadJsonContent('../const.json')

var workspaceName = '${const.abbr.logAnalyticsWorkspace}-${projectName}'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
