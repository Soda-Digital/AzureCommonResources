var abbrs = loadJsonContent('../abbreviations.json')

param name string
param projectName string
param resourceToken string
param isProduction bool

param warmupPrincipleId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: '${abbrs.containerRegistryRegistries}${projectName}'
  }

resource webapp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: '${abbrs.webSitesAppService}web-${resourceToken}'
  scope: resourceGroup('${abbrs.resourcesResourceGroups}${name}')
}

module keyvaultAccessPolicy 'appservice-keyvault.bicep' = {
  name: 'keyVaultAccessPolicy'
  params: {
    projectName: projectName
    webappIdentityId:webapp.identity.principalId
  }
}


module keyvaultAccessPolicyWarmup 'appservice-keyvault.bicep' = if(isProduction) {
  name: 'keyVaultAccessPolicyWarmup'
  params: {
    projectName: projectName
    webappIdentityId: warmupPrincipleId
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
  name: guid(containerRegistry.id, warmupPrincipleId, acrPullRole.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: warmupPrincipleId
    principalType: 'ServicePrincipal'
  }
}
 
