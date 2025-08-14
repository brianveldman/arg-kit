function Get-ArgSecurityAllResourcesWithSMSI {
    $query = @"
Resources
| where identity has 'SystemAssigned'
| project subscriptionId, name, type, resourceGroup, location, identity
| order by subscriptionId asc, type asc, name asc
"@
    Search-AzGraph -Query $query
}
