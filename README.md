# Azure Common Resources

The following bicep templates will roll out:

* 'Common' resouce group, used for resources which will be used across sub environments
 -- Key Vault
 -- App Service Plan
 -- Container Registry
 -- Log Analytics Workspace
 
 
 ## Usage
 
 Log in to the client tenant with:
 
 `az login --tenant <tenant>`
 
Run the deployment:

 `az deployment sub create -f common.bicep -l australiaeast -s <subscription id>`
 
 Provide a name for the project during the deployment phase.

 Once complete, in the /infra/main.parameters.json file:
 * Enter the `projectName` as the value you entered above
 * Copy the log analytics workspace Id from the properties tab of the Azure Portal OR `az monitor log-analytics workspace list`
 * Enter the object Id and the object name of the ClientName (Azure Contributors) for the SQL credentials.

Now create the keyvault key, as we can't do this with ARM:

az keyvault key create -n "dataprotection-key" --kty "RSA" --size 2048 --vault-name "kv-<project name without dashes>"

Create new environments with ????

`azd provision`



 
