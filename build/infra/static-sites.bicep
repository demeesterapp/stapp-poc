@description('Resource tags.')
param tags object

@description('Resource location.')
param location string

@description('Type of managed service identity. SystemAssigned, UserAssigned. https://docs.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?tabs=bicep#managedserviceidentity')
param identityType string = 'SystemAssigned'

@description('custom domain name for static web app.')
param domainName string

@description('The list of user assigned identities associated with the resource.')
param userAssignedIdentities object = {}

@description('The SKU for the static site. https://docs.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?tabs=bicep#skudescription')
param sku object = {
  name: 'Free'
  tier: 'Free'
}

@description('Lock the config file for this static web app. https://docs.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?tabs=bicep#staticsite')
param allowConfigFileUpdates bool = true

@description('The name of the static site resource. eg stapp-swa-sso')
param staticSiteName string

@secure()
@description('Configuration for the static site.')
param appSettings object = {}

@allowed([
  'Disabled'
  'Enabled'
])
@description('State indicating whether staging environments are allowed or not allowed for a static web app.')
param stagingEnvironmentPolicy string = 'Enabled'

resource staticSite 'Microsoft.Web/staticSites@2021-02-01' = { // https://docs.microsoft.com/en-us/azure/templates/microsoft.web/staticsites?tabs=bicep
  name: staticSiteName
  location: location
  tags: tags
  identity: {
    type: identityType
    userAssignedIdentities: empty(userAssignedIdentities) ? null : userAssignedIdentities
  }
  sku: sku
  properties: {
    allowConfigFileUpdates: allowConfigFileUpdates
    stagingEnvironmentPolicy: stagingEnvironmentPolicy
  }
}

resource staticSiteAppsettings 'Microsoft.Web/staticSites/config@2021-02-01' = {
  parent: staticSite
  name: 'appsettings'
  kind: 'config'
  properties: appSettings
}

resource staticSiteCustomDomain 'Microsoft.Web/staticSites/customDomains@2022-03-01' = {
  parent: staticSite
  name: domainName
}

output defaultHostName string = staticSite.properties.defaultHostname // eg epic-shark-0db05de03.azurestaticapps.net
output siteName string = staticSite.name
output siteResourceId string = staticSite.id
output siteSystemAssignedIdentityId string = (staticSite.identity.type == 'SystemAssigned') ? staticSite.identity.principalId : ''
