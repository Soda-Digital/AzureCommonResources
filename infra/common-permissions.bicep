
var abbrs = loadJsonContent('../abbreviations.json')

param name string
param projectName string
param resourceToken string
param isProduction bool


resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: '${abbrs.containerRegistryRegistries}${projectName}'
  }

resource webapp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: '${abbrs.webSitesAppService}web-${resourceToken}'
  scope: resourceGroup('${abbrs.resourcesResourceGroups}${name}')
}


resource webappWarmup 'Microsoft.Web/sites/slots@2022-03-01' existing = if(isProduction)  {
  name: '${abbrs.webSitesAppService}web-${resourceToken}/warmup'
  scope: resourceGroup('${abbrs.resourcesResourceGroups}${name}')
}

//-----------IAM ROLES

//Note that you can't use these roles across tenant boundaries
//So we have to use the key vault access policies instead
// resource keyVaultCryptoUser 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
//   scope: subscription()
//   name: '12338af0-0e69-4776-bea7-57ae8d297424'
// }

module keyvaultAccessPolicy 'appservice-keyvault.bicep' = {
  name: 'keyVaultAccessPolicy'
  params: {
    projectName: projectName
    webapp:webapp
  }
}

module keyvaultAccessPolicyWarmup 'appservice-keyvault.bicep' = if(isProduction) {
  name: 'keyVaultAccessPolicyWarmup'
  params: {
    projectName: projectName
    webapp:webappWarmup
  }
}


resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d' //https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
}


resource webAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, webapp.id, acrPullRole.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: webapp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource webWarmupAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(isProduction) {
  name: guid(containerRegistry.id, webappWarmup.id, acrPullRole.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: webappWarmup.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
 
