function Get-ArgCostIdleGateways {
    $query = @"
Resources
| where type =~ 'microsoft.network/applicationgateways'
| extend backendCount = toint(coalesce(
    array_length(properties.backendAddressPools), 0))
| mv-apply pool = properties.backendAddressPools on (
    summarize targets = sum(
        coalesce(array_length(pool.properties.backendAddresses), 0) +
        coalesce(array_length(pool.properties.backendIPConfigurations), 0))
)
| where isnull(targets) or targets == 0
| project id, name, resourceGroup, location, subscriptionId,
    kind = 'Application Gateway', detail = 'No backend targets configured'
| union (
    Resources
    | where type =~ 'microsoft.network/virtualnetworkgateways'
    | extend gwid = tolower(id)
    | join kind=leftouter (
        Resources
        | where type =~ 'microsoft.network/connections'
        | extend g1 = tolower(tostring(properties.virtualNetworkGateway1.id))
        | extend g2 = tolower(tostring(properties.virtualNetworkGateway2.id))
        | mv-expand g = pack_array(g1, g2) to typeof(string)
        | where isnotempty(g)
        | distinct g
    ) on \$left.gwid == \$right.g
    | where isempty(g)
    | extend kind = strcat('VNet Gateway (', tostring(properties.gatewayType), ')')
    | project id, name, resourceGroup, location, subscriptionId,
        kind, detail = 'No connections attached'
)
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
