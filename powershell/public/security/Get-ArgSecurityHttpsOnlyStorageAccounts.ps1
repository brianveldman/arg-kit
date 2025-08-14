function Get-ArgSecurityHttpsOnlyStorageAccounts {
    $query = @"
Resources
| where type == 'microsoft.storage/storageaccounts'
| where tobool(properties.supportsHttpsTrafficOnly) == false
| project subscriptionId, name, resourceGroup, location
| order by subscriptionId asc, name asc
"@
    Search-AzGraph -Query $query
}
