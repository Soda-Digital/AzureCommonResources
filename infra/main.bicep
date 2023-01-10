
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string


@minLength(1)
@description('Primary location for all resources')
param location string = 'australiaeast'


@description('What is the name of the project')
param projectName string

@description('URI where the data protection key is located')
param keyvaultDataProtectionkKeyUri string

var tags = { 'azd-env-name': name }

param logAnalyticsWorkspaceResourceId string
param azureContributorGroupId string
param azureContributorGroupName string

@description('The name that the common resources are located in')
param commonResourceGroupName string

@secure()
@description('The password set as the SQL Server admin')
param sqlServerAdminPassword string

@description('The user of the SQL admin')
param sqlServerAdminUser string

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
    commonResourceGroupName: commonResourceGroupName
    keyvaultDataProtectionkKeyUri: keyvaultDataProtectionkKeyUri
    name: name
    location: resourceGroup.location
    tags: tags
    projectName: projectName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    sqlServerOwnerGroupId: azureContributorGroupId
    sqlServerOwnerGroupName: azureContributorGroupName
    sqlServerAdminPassword: sqlServerAdminPassword
    sqlServerAdminUser: sqlServerAdminUser
  }
}




