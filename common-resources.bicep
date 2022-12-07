
param name string

param defaultLocation string = resourceGroup().location

param tenantId string

param appServicePlanSku string = 'P1V2'

param sodaUserObjectId string

var abbrs = loadJsonContent('abbreviations.json')

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbrs.keyVaultVaults}${name}'
  location: defaultLocation
  properties: {
    enableRbacAuthorization: false
    sku: {
      family: 'A' 
      name: 'standard'
    }
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: sodaUserObjectId
        tenantId: tenantId
        permissions: {
          secrets: [
            'all'
          ]
          keys: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
      }
    ]
  }



  resource dataProtectionKey 'keys' = {
    name: 'dataprotection-key'
    properties: {
      keySize: 2048
      kty: 'RSA'
    }
  }

}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: '${abbrs.containerRegistryRegistries}${name}'
  location: defaultLocation
  sku: {
    name: 'Basic'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${abbrs.webServerFarms}${name}'
  location: defaultLocation
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: '${abbrs.operationalInsightsWorkspaces}${name}'
  location: defaultLocation
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}


