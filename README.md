# stapp-poc

Proof of concept for azure static websites behind sso.
Usecase: website published and only available to authorized users (in this case everyone in the tenant.)

## infra setup

infra contains a key vault and a static web app.
static web app uses system assigned identity to read client information from key vault.  
infra code can be found under [./build/infra](build/infra) as bicep templates.

## deployment of configuration 

> reuirements:
>   - [Static Web Apps CLI](https://azure.github.io/static-web-apps-cli/)
>   - [Azure cli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)


deploy [`./build/infra/main.bicep`](build/infra/main.bicep) to resource group:
```
# login to azure
az login
# create resource group
az group create --location <azure-location> --resource-group <resource-group-name>
# deploy resources 
az deployment group create --resource-group <resource-group-name> --template-file build/infra/main.bicep
```

create app registration for webapp according to [Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-custom?tabs=aad%2Cinvitations#configure-a-custom-identity-provider).  
When configuring [Authentication callbacks](https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-custom?tabs=aad%2Cinvitations#authentication-callbacks) use the custom domain name from [`main.bicep`](build/infra/main.bicep) as the value for `<YOUR_SITE>`
assign the appropriate users and/or groups the role `Default access` for the enterprise application.

upload client id and client secret to the create key vault as `aadClientId` and `aadClientSecret`.

replace `<TENANT_ID>` with your azure ad tenant if in the auth configuration in [`staticwebapp.config.json`](public/staticwebapp.config.json).

publish the static web app:
```bash
# login to azure
az login
# get publish key
az staticwebapp secrets list --name stapp-cn-isms --query "properties.apiKey"
# deploy using deploy key
SWA_CLI_DEPLOYMENT_TOKEN=123 swa deploy --env production
```

## resources

- [Single Sign-On, Azure static Web Apps and Azure Active Directory - rickroche.com](https://www.rickroche.com/2022/03/single-sign-on-azure-static-web-apps-and-azure-active-directory/)
- [staticwebapp.config.json - Configure Azure Static Web Apps - Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/configuration)
- [Custom authentication in Azure Static Web Apps - Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/authentication-custom?tabs=aad%2Cinvitations#configure-a-custom-identity-provider)