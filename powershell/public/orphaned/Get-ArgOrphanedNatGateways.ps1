function Get-ArgOrphanedNatGateways {
    $query = @"
Resources
| where type =~ 'microsoft.network/natgateways'
| where isnull(properties.subnets) or array_length(properties.subnets) == 0
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
