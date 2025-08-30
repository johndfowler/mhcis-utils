// ===========================================
// Shade - Cloud-Native Utility Platform - Main Template
// ===========================================
// This is the main Bicep template that orchestrates the deployment of a comprehensive
// cloud-native utility platform in Azure Container Apps.

targetScope = 'resourceGroup'

// ===========================================
// User-Defined Types
// ===========================================

@description('Container resource configuration')
type ContainerResources = {
  cpu: string
  memory: string
}

@description('Service configuration')
type ServiceConfig = {
  enabled: bool
  resources: ContainerResources
  image: string
  port: int
}

@description('Network configuration')
type NetworkConfig = {
  vnetAddressPrefix: string
  subnetAddressPrefix: string
  privateEndpointSubnetPrefix: string
}

@description('Monitoring configuration')
type MonitoringConfig = {
  enableApplicationInsights: bool
  enableDiagnostics: bool
  logAnalyticsRetentionDays: int
}

// ===========================================
// Parameters Section
// ===========================================

@description('Resource name prefix (workload identifier). Lowercase letters/numbers only.')
@minLength(3)
@maxLength(15)
param prefix string = 'shade'

@description('Deployment location.')
param location string = resourceGroup().location

@allowed(['dev', 'test', 'staging', 'prod'])
@description('Environment (dev, test, staging, prod)')
param environment string = 'dev'

@description('Region abbreviation (e.g., eus for East US, weu for West Europe)')
@minLength(2)
@maxLength(4)
param regionAbbr string = 'eus'

@description('Instance number (01, 02, etc.)')
@minLength(2)
@maxLength(3)
param instance string = '01'

@description('Network configuration for the platform')
param networkConfig NetworkConfig = {
  vnetAddressPrefix: '10.0.0.0/16'
  subnetAddressPrefix: '10.0.0.0/23'
  privateEndpointSubnetPrefix: '10.0.2.0/23'
}

@description('Monitoring and observability configuration')
param monitoringConfig MonitoringConfig = {
  enableApplicationInsights: true
  enableDiagnostics: true
  logAnalyticsRetentionDays: 30
}

@description('Core monitoring service configuration (Uptime Kuma)')
param monitoringService ServiceConfig = {
  enabled: true
  resources: {
    cpu: '0.5'
    memory: '1Gi'
  }
  image: 'louislam/uptime-kuma:1.23.13'
  port: 3001
}

@description('Visualization service configuration (Grafana)')
param visualizationService ServiceConfig = {
  enabled: false
  resources: {
    cpu: '0.5'
    memory: '1Gi'
  }
  image: 'grafana/grafana:11.0.0'
  port: 3000
}

@description('File management service configuration (Filebrowser)')
param fileManagementService ServiceConfig = {
  enabled: false
  resources: {
    cpu: '0.25'
    memory: '0.5Gi'
  }
  image: 'filebrowser/filebrowser:v2.31.0'
  port: 80
}

@description('Remote development service configuration (Code Server)')
param developmentService ServiceConfig = {
  enabled: false
  resources: {
    cpu: '0.5'
    memory: '1Gi'
  }
  image: 'codercom/code-server:4.23.1'
  port: 8080
}

@description('Enable test mode: reduces resources for cost optimization')
param isTestMode bool = environment == 'dev' || environment == 'test'

@description('Enable private endpoints for enhanced security')
param enablePrivateEndpoints bool = environment == 'prod' || environment == 'staging'

// Note: Avoid nondeterministic names per Bicep best practices; keep names reproducible across deployments.

// ===========================================
// Variables Section
// ===========================================

var workload = prefix
var commonTags = {
  environment: environment
  project: 'shade-platform'
  workload: workload
  owner: 'dev-team'
  costCenter: 'engineering'
  createdBy: 'bicep-template'
  version: '1.0.0'
}

// Resource names following CAF conventions
var resourceNames = {
  managedIdentity: 'id-${workload}-${environment}-${regionAbbr}-${instance}'
  keyVault: 'kv${toLower(take(uniqueString(resourceGroup().id), 16))}'
  storageAccount: 'st${toLower(take(uniqueString(resourceGroup().id), 18))}'
  fileShare: 'fs-${workload}-${environment}-${regionAbbr}-${instance}'
  virtualNetwork: 'vnet-${workload}-${environment}-${regionAbbr}-${instance}'
  subnet: 'snet-${workload}-${environment}-${regionAbbr}-${instance}'
  privateEndpointSubnet: 'snet-pe-${workload}-${environment}-${regionAbbr}-${instance}'
  containerAppsEnvironment: 'cae-${workload}-${environment}-${regionAbbr}-${instance}'
  logAnalytics: 'log-${workload}-${environment}-${regionAbbr}-${instance}'
  applicationInsights: 'appi-${workload}-${environment}-${regionAbbr}-${instance}'
  monitoring: 'ca-${workload}-${environment}-${regionAbbr}-${instance}'
  visualization: 'ca-grafana-${environment}-${regionAbbr}-${instance}'
  fileManagement: 'ca-filebrowser-${environment}-${regionAbbr}-${instance}'
  development: 'ca-codeserver-${environment}-${regionAbbr}-${instance}'
}

// ✅ Fresh, compliant Key Vault name every deployment; no symbols; starts with letters; <=24 chars
// Deterministic Key Vault name (<= 24 chars) based on resource group id
var kvName = 'kv${toLower(take(uniqueString(resourceGroup().id), 16))}'

@description('Optional: Object ID of the deployer (user or service principal) to grant temporary secret permissions for initial secret creation')
@minLength(0)
param deployerObjectId string = ''

var storageMountName = 'platform-data'
var storageFileDataSmbShareContributorRoleId = '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'

// ===========================================
// Networking Resources
// ===========================================

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: resourceNames.virtualNetwork
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [networkConfig.vnetAddressPrefix]
    }
    subnets: [
      {
        name: resourceNames.subnet
        properties: {
          addressPrefix: networkConfig.subnetAddressPrefix
        }
      }
      {
        name: resourceNames.privateEndpointSubnet
        properties: {
          addressPrefix: networkConfig.privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// ===========================================
// Identity & Security Resources  
// ===========================================

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: resourceNames.managedIdentity
  location: location
  tags: commonTags
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    // Using access policies model by default for compatibility
    enableRbacAuthorization: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    // Soft delete defaults to true; set retention and enable purge protection to satisfy common policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    accessPolicies: concat([
      // Managed identity for runtime access from apps
      {
        tenantId: tenant().tenantId
        objectId: managedIdentity.properties.principalId
        permissions: {
          secrets: [ 'get', 'list' ]
        }
      }
    ], empty(deployerObjectId) ? [] : [
      // Optional: grant deployer permission to create initial secrets
      {
        tenantId: tenant().tenantId
        objectId: deployerObjectId
        permissions: {
          secrets: [ 'get', 'list', 'set' ]
        }
      }
    ])
  }
}

// Removed separate accessPolicies resource; included inline during KV creation

// ===========================================
// Monitoring & Observability Resources
// ===========================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (monitoringConfig.enableApplicationInsights) {
  name: resourceNames.logAnalytics
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: monitoringConfig.logAnalyticsRetentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (monitoringConfig.enableApplicationInsights) {
  name: resourceNames.applicationInsights
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: monitoringConfig.enableApplicationInsights ? logAnalytics.id : null
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ===========================================
// Storage Resources
// ===========================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: resourceNames.storageAccount
  location: location
  tags: commonTags
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true // Required for Container Apps file share mounting
    largeFileSharesState: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: enablePrivateEndpoints ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    } : {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: environment == 'prod'
    }
  }
}

// Grant storage access to managed identity
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, storageFileDataSmbShareContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageFileDataSmbShareContributorRoleId)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/${resourceNames.fileShare}'
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
    shareQuota: environment == 'prod' ? 5120 : 1024 // 5TB prod, 1TB others
  }
}

// ===========================================
// Container Apps Environment
// ===========================================

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: resourceNames.containerAppsEnvironment
  location: location
  tags: commonTags
  properties: {
    vnetConfiguration: {
      internal: enablePrivateEndpoints
      infrastructureSubnetId: '${vnet.id}/subnets/${resourceNames.subnet}'
    }
  }
}

// Environment storage - Note: Container Apps still requires account keys for Azure Files
resource environmentStorage 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  parent: containerAppsEnvironment
  name: storageMountName
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      accountName: storageAccount.name
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: resourceNames.fileShare
    }
  }
  dependsOn: [
    fileShare
    storageRoleAssignment
  ]
}

// ===========================================
// Key Vault Secrets
// ===========================================

// Create initial secrets only when deployerObjectId is provided (to ensure data plane permissions exist)
resource grafanaPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(deployerObjectId)) {
  parent: keyVault
  name: 'grafana-admin-password'
  properties: {
    value: 'GrafanaSecure${uniqueString(resourceGroup().id, 'grafana')}!'
    contentType: 'text/plain'
  }
}

resource codeServerPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!empty(deployerObjectId)) {
  parent: keyVault
  name: 'codeserver-password'
  properties: {
    value: 'CodeServerSecure${uniqueString(resourceGroup().id, 'codeserver')}!'
    contentType: 'text/plain'
  }
}

// ===========================================
// Platform Services
// ===========================================

resource monitoringApp 'Microsoft.App/containerApps@2024-03-01' = if (monitoringService.enabled) {
  name: resourceNames.monitoring
  location: location
  tags: union(commonTags, { service: 'monitoring' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: monitoringService.port
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'uptime-kuma'
          image: monitoringService.image
          resources: {
            cpu: json(isTestMode ? '0.25' : monitoringService.resources.cpu)
            memory: isTestMode ? '0.5Gi' : monitoringService.resources.memory
          }
          env: monitoringConfig.enableApplicationInsights ? [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights!.properties.ConnectionString
            }
          ] : []
          volumeMounts: [
            {
              volumeName: storageMountName
              mountPath: '/app/data'
            }
          ]
          probes: [
            {
              type: 'readiness'
              tcpSocket: {
                port: monitoringService.port
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: isTestMode ? 0 : 1
        maxReplicas: isTestMode ? 1 : 3
      }
      volumes: [
        {
          name: storageMountName
          storageType: 'AzureFile'
          storageName: storageMountName
        }
      ]
    }
  }
  dependsOn: [
    environmentStorage
  ]
}

resource grafanaApp 'Microsoft.App/containerApps@2024-03-01' = if (visualizationService.enabled) {
  name: resourceNames.visualization
  location: location
  tags: union(commonTags, { service: 'visualization' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: visualizationService.port
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      secrets: (empty(deployerObjectId) ? [] : [
        {
          name: 'grafana-password'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/grafana-admin-password'
          identity: managedIdentity.id
        }
      ])
    }
    template: {
      containers: [
        {
          name: 'grafana'
          image: visualizationService.image
          resources: {
            cpu: json(isTestMode ? '0.25' : visualizationService.resources.cpu)
            memory: isTestMode ? '0.5Gi' : visualizationService.resources.memory
          }
          env: concat([
            {
              name: 'GF_SECURITY_ADMIN_USER'
              value: 'admin'
            }
          ], empty(deployerObjectId) ? [] : [
            {
              name: 'GF_SECURITY_ADMIN_PASSWORD'
              secretRef: 'grafana-password'
            }
          ])
          volumeMounts: [
            {
              volumeName: storageMountName
              mountPath: '/var/lib/grafana'
              subPath: 'grafana'
            }
          ]
          probes: [
            {
              type: 'readiness'
              httpGet: {
                path: '/api/health'
                port: visualizationService.port
              }
              initialDelaySeconds: 30
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: isTestMode ? 0 : 1
        maxReplicas: isTestMode ? 1 : 2
      }
      volumes: [
        {
          name: storageMountName
          storageType: 'AzureFile'
          storageName: storageMountName
        }
      ]
    }
  }
  dependsOn: [
    environmentStorage
  ]
}

resource filebrowserApp 'Microsoft.App/containerApps@2024-03-01' = if (fileManagementService.enabled) {
  name: resourceNames.fileManagement
  location: location
  tags: union(commonTags, { service: 'file-management' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: fileManagementService.port
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'filebrowser'
          image: fileManagementService.image
          resources: {
            cpu: json(isTestMode ? '0.25' : fileManagementService.resources.cpu)
            memory: isTestMode ? '0.5Gi' : fileManagementService.resources.memory
          }
          env: [
            {
              name: 'FB_BASEURL'
              value: '/'
            }
          ]
          volumeMounts: [
            {
              volumeName: storageMountName
              mountPath: '/srv'
              subPath: 'files'
            }
          ]
          probes: [
            {
              type: 'readiness'
              httpGet: {
                path: '/'
                port: fileManagementService.port
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: isTestMode ? 0 : 1
        maxReplicas: 1
      }
      volumes: [
        {
          name: storageMountName
          storageType: 'AzureFile'
          storageName: storageMountName
        }
      ]
    }
  }
  dependsOn: [
    environmentStorage
  ]
}

resource codeServerApp 'Microsoft.App/containerApps@2024-03-01' = if (developmentService.enabled) {
  name: resourceNames.development
  location: location
  tags: union(commonTags, { service: 'remote-development' })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: developmentService.port
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      secrets: (empty(deployerObjectId) ? [] : [
        {
          name: 'codeserver-password'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/codeserver-password'
          identity: managedIdentity.id
        }
      ])
    }
    template: {
      containers: [
        {
          name: 'code-server'
          image: developmentService.image
          resources: {
            cpu: json(isTestMode ? '0.25' : developmentService.resources.cpu)
            memory: isTestMode ? '0.5Gi' : developmentService.resources.memory
          }
          env: (empty(deployerObjectId) ? [] : [
            {
              name: 'PASSWORD'
              secretRef: 'codeserver-password'
            }
          ])
          volumeMounts: [
            {
              volumeName: storageMountName
              mountPath: '/home/coder'
              subPath: 'code-server'
            }
          ]
          probes: [
            {
              type: 'readiness'
              httpGet: {
                path: '/'
                port: developmentService.port
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: isTestMode ? 0 : 1
        maxReplicas: 1
      }
      volumes: [
        {
          name: storageMountName
          storageType: 'AzureFile'
          storageName: storageMountName
        }
      ]
    }
  }
  dependsOn: [
    environmentStorage
  ]
}

// ===========================================
// Outputs Section
// ===========================================

@description('Platform service endpoints and management information')
output platformEndpoints object = {
  monitoringService: monitoringService.enabled ? 'https://${resourceNames.monitoring}.${containerAppsEnvironment.properties.defaultDomain}' : ''
  visualizationService: visualizationService.enabled ? 'https://${resourceNames.visualization}.${containerAppsEnvironment.properties.defaultDomain}' : ''
  fileManagementService: fileManagementService.enabled ? 'https://${resourceNames.fileManagement}.${containerAppsEnvironment.properties.defaultDomain}' : ''
  developmentService: developmentService.enabled ? 'https://${resourceNames.development}.${containerAppsEnvironment.properties.defaultDomain}' : ''
}

@description('Resource identifiers for management and integration')
output resourceInfo object = {
  resourceGroupName: resourceGroup().name
  managedIdentityId: managedIdentity.id
  keyVaultName: keyVault.name
  storageAccountName: storageAccount.name
  containerAppsEnvironmentName: containerAppsEnvironment.name
  applicationInsightsName: monitoringConfig.enableApplicationInsights ? resourceNames.applicationInsights : ''
  logAnalyticsWorkspaceName: monitoringConfig.enableApplicationInsights ? resourceNames.logAnalytics : ''
}

@description('Security and access information')
output securityInfo object = {
  keyVaultUri: keyVault.properties.vaultUri
  managedIdentityClientId: managedIdentity.properties.clientId
  storageAccountEndpoints: storageAccount.properties.primaryEndpoints
}

@description('Management commands for platform operations')
output managementCommands object = {
  deleteResourceGroup: 'az group delete --name ${resourceGroup().name} --yes --no-wait'
  viewLogs: monitoringConfig.enableApplicationInsights ? 'az monitor app-insights query --app ${applicationInsights.name} --analytics-query "requests | limit 10"' : ''
  connectToKeyVault: 'az keyvault secret list --vault-name ${keyVault.name}'
  storageAccountKey: 'Disabled - Using managed identity authentication'
}

@description('Generated Key Vault name for this deployment')
output keyVaultName string = kvName
