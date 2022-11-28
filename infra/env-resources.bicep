
var abbrs = loadJsonContent('../abbreviations.json')

param appServicePlanName string

param resourceToken string
param location string = resourceGroup().location
param tags object

param sqlServerOwnerGroupName string
param sqlServerOwnerGroupId string

param logAnalyticsWorkspaceId string

var dockerValue = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' existing =  {
  name: appServicePlanName
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
      linuxFxVersion: dockerValue
      alwaysOn: true
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
    properties: {
      DATAPROTECTION_BLOBLOCATION: '${storageAccount.properties.primaryEndpoints.blob}/${storageAccount::dataProtectionKeysContainer.name}'
      DATAPROTECTION_KEYVAULTLOCATION: 'todo'  //dataprotectionKey.properties.keyUri
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    }
  }

  resource databaseconnectionstrings 'config' = {
    name: 'connectionstrings'
    properties: {
      DefaultConnection: {
        type: 'SQLAzure'
        value: 'Server=${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${sqlServer::database.name};Authentication=Active Directory Default'
      }

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

  resource warmupSlot 'slots' = {
    name: 'warmup'
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      reserved: true
      scmSiteAlsoStopped: true
      siteConfig: {
        linuxFxVersion: dockerValue
        acrUseManagedIdentityCreds: true
        alwaysOn: false
        ftpsState: 'Disabled'
        http20Enabled: true
      }
      clientAffinityEnabled: false
    }
  }

}




resource sqlServer 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: '${abbrs.sqlServers}${resourceToken}'
  location: location
  tags: union(tags, { 'azd-service-name': 'sqlServer' })
  properties: {
    administratorLogin: 'sqlserver-admin'
    administratorLoginPassword: 'Password123'
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
    sku: {
      name: 'Basic'
      tier: 'Basic'
      capacity: 5
    }
    properties: {
      collation: 'SQL_Latin1_General_CP1_CI_AS'    
    }
  }
}


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: '${abbrs.storageStorageAccounts}${resourceToken}'
  location: location
  tags:tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }

  resource dataProtectionKeysContainer 'blobServices' = {
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
