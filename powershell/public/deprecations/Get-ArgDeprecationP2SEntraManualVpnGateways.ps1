function Get-ArgDeprecationP2SEntraManualVpnGateways {
    $query = @"
Resources
| where type =~ 'microsoft.network/virtualnetworkgateways'
| extend aadAudience = tostring(properties.vpnClientConfiguration.aadAudience)
| where isnotempty(aadAudience)
| where aadAudience != 'c632b3df-fb67-4d84-bdcf-b95ad541b5c8'
| project name, resourceGroup, location, subscriptionId, aadAudience, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
