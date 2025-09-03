function Get-ArgDeprecationBasicPublicIpAddresses {
    $query = @"
Resources
| where type =~ 'microsoft.network/publicIPAddresses'
| extend skuName = tostring(sku.name),
         attached = isnotempty(tostring(properties.ipConfiguration.id))
| where skuName =~ 'Basic'
| project name, resourceGroup, location, subscriptionId,
          ipAddress = tostring(properties.ipAddress),
          allocationMethod = tostring(properties.publicIPAllocationMethod),
          skuName, attached, id
| order by name asc
"@
    Search-AzGraph -Query $query
}
