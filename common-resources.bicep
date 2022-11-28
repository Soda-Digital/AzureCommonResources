
param name string

param defaultLocation string = resourceGroup().location

param tenantId string

var abbrs = loadJsonContent('abbreviations.json')

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbrs.keyVaultVaults}${name}'
  location: defaultLocation

  properties: {

    enableRbacAuthorization: true
    sku: {
      family: 'A' 
      name: 'standard'
    }
    tenantId: tenantId
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
    name: 'P1V2' //TODO make this customizable, pass it in as a param
  }
  properties: {
    reserved: true
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: '${abbrs.operationalInsightsWorkspaces}${name}'
  location: defaultLocation
  //tags: tags
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

