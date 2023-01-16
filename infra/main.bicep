
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

@description('The name that the common resources are located in')
param commonResourceGroupName string

param dockerImage string  = 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'

@description('The user of the SQL admin')
param sqlServerAdminUser string

var abbrs = loadJsonContent('../abbreviations.json')

var isProduction = endsWith(name, 'prod')

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${name}'
  location: location
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: '${abbrs.keyVaultVaults}${projectName}'
  scope: az.resourceGroup(commonResourceGroupName)
}

module environmentResources 'main-resources.bicep' = {
  name: 'main-resources'
  scope: resourceGroup
  params: {
    dockerImage: dockerImage
    isProduction: isProduction
    commonResourceGroupName: commonResourceGroupName
    keyvaultDataProtectionkKeyUri: '${keyVault.properties.vaultUri}/keys/dataprotection-key'
    name: name
    location: resourceGroup.location
    tags: tags
    projectName: projectName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    sqlServerOwnerGroupId: azureContributorGroupId
    sqlServerOwnerGroupName: azureContributorGroupName
    sqlServerAdminPassword: keyVault.getSecret('SqlServerAdminPassword')
    sqlServerAdminUser: sqlServerAdminUser
  }
}
