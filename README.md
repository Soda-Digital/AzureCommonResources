# Azure Common Resources

The following bicep templates will roll out:

* 'Common' resouce group, used for resources which will be used across sub environments
 -- Key Vault
 -- App Service Plan
 -- Container Registry
 -- Log Analytics Workspace
 
 
 ## Usage
 
 Log in to the client tenant with
 
 `az login --tenant <tenant>`
 
 Set the active subscription with
 
 `az account set -s <subscription id>`
 
 `az deployment sub create -f common.bicep -l australiaeast`
 
 Provide a name for the project during the deployment phase.
 
