
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string


@minLength(1)
@description('Primary location for all resources')
param location string

var tags = { 'azd-env-name': name }

param appServicePlanName string
param logAnalyticsWorkspaceId string
param resourceToken string
param sqlServerOwnerGroupId string
param sqlServerOwnerGroupName string

var abbrs = loadJsonContent('abbreviations.json')

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}'
  location: location
  tags: tags
}

module environmentResources 'env-resources.bicep' = {
  name: 'env'
  scope: resourceGroup
  params: {
    location: resourceGroup.location
    tags: tags
    appServicePlanName: appServicePlanName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    resourceToken: resourceToken
    sqlServerOwnerGroupId: sqlServerOwnerGroupId
    sqlServerOwnerGroupName: sqlServerOwnerGroupName
  }
}


