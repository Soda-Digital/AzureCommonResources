
param name string

param defaultLocation string = 'australiaeast'
 
var abbrs = loadJsonContent('abbreviations.json')

targetScope = 'subscription'

resource commonResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}-common'
  location: defaultLocation
}

module commonResources './common-resources.bicep' = {
  name: 'commonResources'
  scope: commonResourceGroup
  params: {
    defaultLocation: commonResourceGroup.location
    tenantId: subscription().tenantId
    name: name
  }
}
