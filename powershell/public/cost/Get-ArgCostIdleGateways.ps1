function Get-ArgCostIdleGateways {
    $query = @"
Resources
| where type =~ 'microsoft.network/applicationgateways'
| mv-expand pool = properties.backendAddressPools
| extend targets = coalesce(array_length(pool.properties.backendAddresses), 0) + coalesce(array_length(pool.properties.backendIPConfigurations), 0)
| summarize totalTargets = sum(targets) by id, name, resourceGroup, location, subscriptionId
| where totalTargets == 0
| extend gwKind = 'Application Gateway', detail = 'No backend targets configured'
| project id, name, resourceGroup, location, subscriptionId, gwKind, detail
| union (
    Resources
    | where type =~ 'microsoft.network/virtualnetworkgateways'
    | extend gwid = tolower(id)
    | join kind=leftouter (
        Resources
        | where type =~ 'microsoft.network/connections'
        | extend g1 = tolower(tostring(properties.virtualNetworkGateway1.id))
        | extend g2 = tolower(tostring(properties.virtualNetworkGateway2.id))
        | mv-expand gwid = pack_array(g1, g2) to typeof(string)
        | where isnotempty(gwid)
        | distinct gwid
        | extend hasConnection = 1
    ) on gwid
    | where isnull(hasConnection)
    | extend gwKind = strcat('VNet Gateway (', tostring(properties.gatewayType), ')'), detail = 'No connections attached'
    | project id, name, resourceGroup, location, subscriptionId, gwKind, detail
)
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
