function Get-ArgSecuritySharedKeyAccessStorageAccounts {
    $query = @"
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| where isnull(properties.allowSharedKeyAccess) or tobool(properties.allowSharedKeyAccess) == true
| project name, resourceGroup, location, subscriptionId, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
