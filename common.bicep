
@description('Provide a name for the project like: clientname-projectname')
param projectName string

param defaultLocation string = 'australiaeast'

param sodaUserObjectId string
 
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
    sodaUserObjectId: sodaUserObjectId
  }
}


output PROJECT_NAME string =  projectName
