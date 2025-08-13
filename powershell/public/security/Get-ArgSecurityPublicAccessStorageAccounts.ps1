function Get-ArgSecurityPublicAccessStorageAccounts {
    $query = @"
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| where properties.networkAcls.defaultAction == 'Allow'
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
