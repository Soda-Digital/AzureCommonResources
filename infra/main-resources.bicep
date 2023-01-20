
var abbrs = loadJsonContent('../abbreviations.json')

param name string

param location string = resourceGroup().location
param tags object

param sqlServerOwnerGroupName string
param sqlServerOwnerGroupId string

param logAnalyticsWorkspaceId string

param projectName string

param keyvaultDataProtectionkKeyUri string

param isProduction bool

@secure()
@description('The password set as the SQL Server admin')
param sqlServerAdminPassword string

param sqlServerAdminUser string

@description('The name that the common resources are located in')
param commonResourceGroupName string

param dockerImage string

var resourceToken = toLower(uniqueString(subscription().id, name, location))

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing =  {
  name: '${abbrs.webServerFarms}${projectName}'
  scope: resourceGroup(commonResourceGroupName)
}

var appServiceSettings = {
  DATAPROTECTION_BLOBLOCATION: '${storageAccount.properties.primaryEndpoints.blob}${storageAccount::blobServices::dataProtectionKeys.name}'
  DATAPROTECTION_KEYVAULTLOCATION: keyvaultDataProtectionkKeyUri
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
  //Additonal keys here
}

var appServiceConnectionStrings = {
  type: 'SQLAzure'
  value: 'Server=${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlServer::database.name};User ID=${sqlServerAdminUser};Password=${sqlServerAdminPassword};MultipleActiveResultSets=False;Encrypt=True;'
}

resource web 'Microsoft.Web/sites@2021-03-01' = {
  name: '${abbrs.webSitesAppService}web-${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  kind: 'app,linux,container'

  properties: {
    reserved: true

    serverFarmId: appServicePlan.id
    scmSiteAlsoStopped: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImage}'
      acrUseManagedIdentityCreds: true
      alwaysOn: isProduction
      ftpsState: 'Disabled'
      http20Enabled: true
    }
    httpsOnly: true
    clientAffinityEnabled: false
  }
  identity: {
    type: 'SystemAssigned'
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: appServiceSettings
  }

  resource databaseconnectionstrings 'config' = {
    name: 'connectionstrings'
    properties: {
      DefaultConnection: appServiceConnectionStrings
    }
  }

  resource logs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: {
        fileSystem: {
          level: 'Verbose'
        }
      }
      detailedErrorMessages: {
        enabled: true
      }
      failedRequestsTracing: {
        enabled: true
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 1
          retentionInMb: 35
        }
      }
    }
  }

  resource warmupSlot 'slots' = if(isProduction) {
    name: 'warmup'
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      reserved: true
      scmSiteAlsoStopped: true
      siteConfig: {
        linuxFxVersion: dockerImage
        acrUseManagedIdentityCreds: true
        alwaysOn: false
        ftpsState: 'Disabled'
        http20Enabled: true
      }
      clientAffinityEnabled: false
    }

    resource appSettings 'config' = {
      name: 'appsettings'
      properties: appServiceSettings
    }
  
    resource databaseconnectionstrings 'config' = {
      name: 'connectionstrings'
      properties: {
        DefaultConnection: appServiceConnectionStrings
      }
    }
  }

}

resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: '${abbrs.sqlServers}${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'sqlServer' })
  properties: {
    administratorLogin: sqlServerAdminUser
    administratorLoginPassword: sqlServerAdminPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      login: sqlServerOwnerGroupName
      principalType: 'Group'
      sid: sqlServerOwnerGroupId
      tenantId: '2b6c67b1-5293-40a7-8aea-0dcc01491bf7' //SD Tenant
    }
  }

  resource firewall 'firewallRules' = {
    name: 'AllowAllWindowsAzureIps' //secret sauce naming convention
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
  
  //add any developer ip addresses here

  resource database 'databases@2022-02-01-preview' = {
    name: '${abbrs.sqlServersDatabases}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'database' })
    sku: isProduction ? {
      name: 'Basic' 
      tier: 'Basic'
      capacity: 5
    } : {
      name: 'GP_S_Gen5'
      tier: 'GeneralPurpose'
      family: 'Gen5'
      capacity: 1
    }
    
    properties: {
      collation: 'SQL_Latin1_General_CP1_CI_AS'
      requestedBackupStorageRedundancy: isProduction ? 'Zone' : 'Local'
      autoPauseDelay: isProduction ? -1 : 60

    }
  }
}


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  location: location
  tags:tags
  kind: 'StorageV2'
  sku: {
    name: isProduction ? 'Standard_GRS' : 'Standard_LRS'
  }

  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
    }

    resource dataProtectionKeys 'containers' = {
      name: 'dataprotectionkeys'
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${abbrs.insightsComponents}${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

var warmupSlotId = isProduction ? web::warmupSlot.id : ''
var warmupPrincipleId = isProduction ? web::warmupSlot.identity.principalId : ''


module permissions 'common-permissions.bicep' = {
  name: 'common-permissions'
  dependsOn: [
    web
  ]
  scope: resourceGroup(commonResourceGroupName)
  params: {
    warmupPrincipleId: warmupPrincipleId
    isProduction: isProduction
    resourceToken: resourceToken
    name: name
    projectName: projectName
  }
}


//ENVIRONMENT SPECIFIC PERMISSIONS

@description('This is the built-in Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource blobcontributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
}

resource webaccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, web.id, blobcontributorRoleDefinition.id)
  scope: storageAccount::blobServices::dataProtectionKeys
  properties: {
    roleDefinitionId: blobcontributorRoleDefinition.id
    principalId: web.identity.principalId
    principalType: 'ServicePrincipal'
  }
}




//even though this is behind an 'if' statement, it seems that it still tries
//to evaluate the ids in use, which don't exist if we're not in production
resource webaccessWarmup 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(isProduction) {
  name: guid(storageAccount.id, warmupSlotId, blobcontributorRoleDefinition.id)
  scope: storageAccount::blobServices::dataProtectionKeys
  properties: {
    roleDefinitionId: blobcontributorRoleDefinition.id
    principalId: warmupPrincipleId
    principalType: 'ServicePrincipal'
  }
}


