function Get-ArgSecuritySoftDeleteDisabledKeyVaults {
    $query = @"
Resources
| where type =~ 'microsoft.keyvault/vaults'
| where isnull(properties.enableSoftDelete) or properties.enableSoftDelete == false
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
