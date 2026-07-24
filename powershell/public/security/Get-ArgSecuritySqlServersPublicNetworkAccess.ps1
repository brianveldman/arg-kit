function Get-ArgSecuritySqlServersPublicNetworkAccess {
    $query = @"
Resources
| where type =~ 'microsoft.sql/servers'
| where tostring(properties.publicNetworkAccess) =~ 'Enabled'
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
