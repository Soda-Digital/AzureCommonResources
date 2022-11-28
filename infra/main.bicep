
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string


@minLength(1)
@description('Primary location for all resources')
param location string = 'australiaeast'


@description('What is the name of the project')
param projectName string


var tags = { 'azd-env-name': name }

param logAnalyticsWorkspaceResourceId string
param azureContributorGroupId string
param azureContributorGroupName string

var abbrs = loadJsonContent('../abbreviations.json')

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}'
  location: location
  tags: tags
}

module environmentResources 'main-resources.bicep' = {
  name: 'main-resources'
  scope: resourceGroup
  params: {
    name: name
    location: resourceGroup.location
    tags: tags
    projectName: projectName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    sqlServerOwnerGroupId: azureContributorGroupId
    sqlServerOwnerGroupName: azureContributorGroupName
  }
}




