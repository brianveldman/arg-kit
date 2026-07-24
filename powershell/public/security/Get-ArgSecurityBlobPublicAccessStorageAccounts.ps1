function Get-ArgSecurityBlobPublicAccessStorageAccounts {
    $query = @"
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| where tobool(properties.allowBlobPublicAccess) == true
| project name, resourceGroup, location, subscriptionId, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
