function Get-ArgDeprecationP2SEntraManualVpnGateways {
    $query = @"
Resources
| where type =~ 'microsoft.network/virtualnetworkgateways'
| extend aadAudience = tostring(properties.vpnClientConfiguration.aadAudience)
| where isnotempty(aadAudience)
| where aadAudience in~ (
    '41b23e61-6c1e-4545-b367-cd054e0ed4b4',
    '51bb15d4-3a4f-4ebf-9dca-40096fe32426',
    '538ee9e6-310a-468d-afef-ea97365856a9',
    '49f817b6-84ae-4cc0-928c-73f27289b3aa'
  )
| project name, resourceGroup, location, subscriptionId, aadAudience, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
