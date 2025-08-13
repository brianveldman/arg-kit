function Get-ArgSecurityPublicAccessKeyVaults {
    $query = @"
Resources
| where type =~ 'microsoft.keyvault/vaults'
| where properties.networkAcls.defaultAction == 'Allow'
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
