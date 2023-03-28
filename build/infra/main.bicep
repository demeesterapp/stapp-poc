param appName string = 'demapp-isms'
param domainName string = 'isms.demeester.app'
param location string = resourceGroup().location
param tags object = {}
param SecretAdministratorGroupIds array = []
param SecretAdministratorIds array = []

var keyVaultName = 'kv-${appName}'

module refs 'get-kv-secrets-refs.bicep' = {
  name: 'get-kv-secrets-refs-${appName}'
  params: {
    keyVaultName: keyVaultName
  }
}

module stapp 'static-sites.bicep' = {
  name: 'deploy-stapp-${appName}'
  params: {
    appSettings: {
      AAD_CLIENT_ID: refs.outputs.aadClientIdRef
      AAD_CLIENT_SECRET: refs.outputs.aadClientSecretRef
    }
    location: location
    sku: {
      name: 'Standard'
      tier: 'Standard'
    }
    stagingEnvironmentPolicy: 'Enabled'
    staticSiteName: 'stapp-${appName}'
    tags: tags
    domainName: domainName
  }
}

// https://docs.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli#azure-built-in-roles-for-key-vault-data-plane-operations
var keyVaultSecretsUserRole = '4633458b-17de-408a-b874-0445c86b69e6'
var keyVaultServicePrincipalRoleAssignment = [
  {
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
    principalId: stapp.outputs.siteSystemAssignedIdentityId
  }
]

var keyVaultSecretAdministratorRole = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
var keyVaultAdministratorsRoleAssignments = map(SecretAdministratorIds, id => {
    roleDefinitionId: keyVaultSecretAdministratorRole
    principalType: 'User'
    principalId: id
  }
)
var keyvaultAdministratorGroupsRoleAssignments = map(SecretAdministratorGroupIds, id => {
  roleDefinitionId: keyVaultSecretAdministratorRole
  principalType: 'Group'
  principalId: id
}
)

module kv 'key-vault.bicep' = {
  name: 'deploy-kv-${appName}'
  params: {
    enableSoftDelete: false
    keyVaultName: keyVaultName
    location: location
    roleAssignments: concat(keyVaultServicePrincipalRoleAssignment,keyVaultAdministratorsRoleAssignments,keyvaultAdministratorGroupsRoleAssignments)
    tags: tags
  }
}

output keyVaultName string = kv.outputs.keyVaultName
output siteName string = stapp.outputs.siteName
output siteDefaultHostname string = stapp.outputs.defaultHostName
