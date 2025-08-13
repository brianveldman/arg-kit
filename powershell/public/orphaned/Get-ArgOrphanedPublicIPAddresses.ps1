function Get-ArgOrphanedPublicIPAddresses {
    Search-AzGraph -Query "Resources
| where type =~ 'microsoft.network/publicIPAddresses'
| where isnull(properties.ipConfiguration) or isempty(properties.ipConfiguration)
| project name, resourceGroup, location, subscriptionId,
          ipAddress=tostring(properties.ipAddress),
          allocationMethod=tostring(properties.publicIPAllocationMethod),
          sku=tostring(sku.name)
| sort by name asc"
}
