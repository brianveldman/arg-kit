function Get-ArgOrphanedLoadBalancers {
    Search-AzGraph -Query "Resources
| where type == 'microsoft.network/loadbalancers'
| extend pipId=parse_json(properties.frontendIPConfigurations[0].properties.publicIPAddress.id)
| where properties.backendAddressPools == '[]'
| project name,location,resourceGroup,subscriptionId,sku.name,pipId
"
}
