
@description('Provide a name for the project like: clientname-projectname')
param projectName string

param defaultLocation string = 'australiaeast'
 
var abbrs = loadJsonContent('abbreviations.json')

targetScope = 'subscription'

resource commonResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${projectName}-common'
  location: defaultLocation
}

module commonResources './common-resources.bicep' = {
  name: 'commonResources'
  scope: commonResourceGroup
  params: {
    defaultLocation: commonResourceGroup.location
    tenantId: subscription().tenantId
    name: projectName
  }
}


output PROJECT_NAME string =  projectName
