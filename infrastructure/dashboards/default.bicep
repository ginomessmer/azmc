param location string
param projectName string

param serverContainerGroupName string
resource serverContainerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' existing = {
  name: serverContainerGroupName
}

param logAnalyticsWorkspaceName string
resource logAnalyticsWorkspace 'Microsoft.Insights/workbooks@2022-04-01' existing = {
  name: logAnalyticsWorkspaceName
}

param managedEnvironmentName string
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: managedEnvironmentName
}

param storageAccountName string
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource azmcdev_db 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              colSpan: 2
              rowSpan: 8
            }
            metadata: {
              inputs: [
                {
                  name: 'id'
                  value: serverContainerGroup.id
                  isOptional: true
                }
                {
                  name: 'resourceId'
                  isOptional: true
                }
                {
                  name: 'menuid'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/ResourcePart'
              asset: {
                idInputName: 'id'
              }
              deepLink: '#@messmer.de.com/resource${serverContainerGroup.id}/overview'
            }
          }
          {
            position: {
              x: 2
              y: 0
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'CpuUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'CPU Usage'
                          }
                        }
                      ]
                      title: 'Avg CPU Usage for azmcdev-server-cg'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'CpuUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'CPU Usage'
                          }
                        }
                      ]
                      title: 'Avg CPU Usage for azmcdev-server-cg'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
              filters: {
                MsPortalFx_TimeRange: {
                  model: {
                    format: 'local'
                    granularity: 'auto'
                    relative: '1440m'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 7
              y: 0
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'MemoryUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Memory Usage'
                          }
                        }
                      ]
                      title: 'Avg Memory Usage for azmcdev-server-cg'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'MemoryUsage'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Memory Usage'
                          }
                        }
                      ]
                      title: 'Avg Memory Usage for azmcdev-server-cg'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
              filters: {
                MsPortalFx_TimeRange: {
                  model: {
                    format: 'local'
                    granularity: 'auto'
                    relative: '1440m'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 12
              y: 0
              colSpan: 7
              rowSpan: 8
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspace.id
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: '7c3d5342-4b33-47bf-ae2b-f3ff0d04f68c'
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P1D'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'DraftRequestParameters'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: 'ContainerInstanceLog_CL\n| where ContainerName_s == \'server\'\n| sort by TimeGenerated desc\n| project TimeGenerated, Message\n'
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'AnalyticsGrid'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: 'Analytics'
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: 'azmcdev-ws'
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  isOptional: true
                }
                {
                  name: 'LegendOptions'
                  isOptional: true
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: false
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              settings: {
                content: {
                  GridColumnsWidth: {
                    Message: '672px'
                  }
                  PartTitle: 'Logs'
                  PartSubTitle: 'Server'
                }
              }
              partHeader: {
                title: 'Minecraft Server Logs'
                subtitle: ''
              }
            }
          }
          {
            position: {
              x: 20
              y: 0
              colSpan: 2
              rowSpan: 2
            }
            metadata: {
              inputs: [
                {
                  name: 'id'
                  value: managedEnvironment.id
                }
              ]
              type: 'Extension/WebsitesExtension/PartType/ContainerAppEnvironmentTile'
              deepLink: '#@messmer.de.com/resource${managedEnvironment.id}/containerAppEnvironment'
            }
          }
          {
            position: {
              x: 22
              y: 0
              colSpan: 9
              rowSpan: 8
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      logAnalyticsWorkspace.id
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: '5231be29-57b1-4c25-b6d0-4c6ba13666b2'
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P1D'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'DraftRequestParameters'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: 'ContainerAppConsoleLogs_CL\n| where ContainerGroupName_s startswith \'azmcdev-renderer-job-\'\n| order by _timestamp_d desc\n| project TimeGenerated, Log_s, ContainerGroupName_s\n'
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'AnalyticsGrid'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: 'Analytics'
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: 'azmcdev-ws'
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  isOptional: true
                }
                {
                  name: 'LegendOptions'
                  isOptional: true
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: false
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              settings: {
                content: {
                  GridColumnsWidth: {
                    ContainerGroupName_s: '255px'
                    Log_s: '470px'
                  }
                  PartTitle: 'Logs'
                  PartSubTitle: 'Map Renderer'
                }
              }
            }
          }
          {
            position: {
              x: 2
              y: 4
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'NetworkBytesReceivedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Received Per Second'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'NetworkBytesTransmittedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Transmitted Per Second'
                          }
                        }
                      ]
                      title: 'Minecraft Server Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'NetworkBytesReceivedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Received Per Second'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: serverContainerGroup.id
                          }
                          name: 'NetworkBytesTransmittedPerSecond'
                          aggregationType: 4
                          namespace: 'microsoft.containerinstance/containergroups'
                          metricVisualization: {
                            displayName: 'Network Bytes Transmitted Per Second'
                          }
                        }
                      ]
                      title: 'Minecraft Server Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
              filters: {
                MsPortalFx_TimeRange: {
                  model: {
                    format: 'local'
                    granularity: 'auto'
                    relative: '1440m'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 7
              y: 4
              colSpan: 5
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Egress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Egress'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Ingress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Ingress'
                          }
                        }
                      ]
                      title: 'Storage Account Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Egress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Egress'
                          }
                        }
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Ingress'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Ingress'
                          }
                        }
                      ]
                      title: 'Storage Account Network Activity'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
              filters: {
                MsPortalFx_TimeRange: {
                  model: {
                    format: 'local'
                    granularity: 'auto'
                    relative: '1440m'
                  }
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
        filterLocale: {
          value: 'en-us'
        }
        filters: {
          value: {
            MsPortalFx_TimeRange: {
              model: {
                format: 'utc'
                granularity: 'auto'
                relative: '24h'
              }
              displayCache: {
                name: 'UTC Time'
                value: 'Past 24 hours'
              }
              filteredPartIds: [
                'StartboardPart-MonitorChartPart-4d3c4e12-1631-4b7b-89fc-14f69cf9dd8a'
                'StartboardPart-MonitorChartPart-4d3c4e12-1631-4b7b-89fc-14f69cf9dd8c'
                'StartboardPart-LogsDashboardPart-4d3c4e12-1631-4b7b-89fc-14f69cf9dd8e'
                'StartboardPart-LogsDashboardPart-4d3c4e12-1631-4b7b-89fc-14f69cf9dd92'
                'StartboardPart-MonitorChartPart-4d3c4e12-1631-4b7b-89fc-14f69cf9dd94'
                'StartboardPart-MonitorChartPart-4d3c4e12-1631-4b7b-89fc-14f69cf9dd96'
              ]
            }
          }
        }
      }
    }
  }
  name: '${projectName}-db'
  location: location
  tags: {
    'hidden-title': 'azmcdev-db'
  }
}
