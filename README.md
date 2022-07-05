# AzSqlFirewallIpUpdate

Update an Azure SQL server firewall rule with the caller ip address.

Usage: 
- Deploy the function to Azure
- Enable Managed Identity
- Add IAM access to the Managed Identity to manage SQL server
- Set function enviroment variables: ResourceGroup and SQL server name
- Call the endpoint: The endpoint is secured, auth is required

curl example:
curl -X POST https://FUNCTIONNAME.azurewebsites.net/api/SqlServerFirewallUpdate?code=ACCESSCODE
