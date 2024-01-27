targetScope = 'resourceGroup'

var roleDefinitionContainerLaunchManagerRoleName = 'Container App Launch Manager'
var roleDefinitionContainerLaunchManagerActions = [
  'Microsoft.ContainerInstance/containerGroups/start/action'
  'Microsoft.ContainerInstance/containerGroups/stop/action'
  'Microsoft.ContainerInstance/containerGroups/restart/action'
]
var roleDefinitionContainerLaunchManagerNotActions = []
var roleDefinitionContainerLaunchManagerName = guid(subscription().id,
  roleDefinitionContainerLaunchManagerRoleName,
  string(roleDefinitionContainerLaunchManagerActions),
  string(roleDefinitionContainerLaunchManagerNotActions))

// Role definition so that the identity can start/stop/restart the container group
resource roleDefinitionContainerLaunchManager 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefinitionContainerLaunchManagerName
  properties: {
    roleName: roleDefinitionContainerLaunchManagerRoleName
    description: 'Allows start/stop/restart the container group'
    assignableScopes: [
      resourceGroup().id
    ]
    permissions: [
      {
        actions: roleDefinitionContainerLaunchManagerActions
        notActions: roleDefinitionContainerLaunchManagerNotActions
        dataActions: []
        notDataActions: []
      }
    ]
  }
}

output roleDefinitionContainerLaunchManagerId string = roleDefinitionContainerLaunchManager.id
