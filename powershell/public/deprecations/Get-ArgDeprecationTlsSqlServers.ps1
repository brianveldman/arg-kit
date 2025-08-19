function Get-ArgDeprecationTlsSqlServers {
    $query = @"
Resources
| where type == 'microsoft.sql/servers'
| where properties.minimalTlsVersion contains "None" 
| project name, resourceGroup, location, subscriptionId
| order by name asc
"@
    Search-AzGraph -Query $query
}
