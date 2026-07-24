function Get-ArgCostUnattachedPremiumDisks {
    $query = @"
Resources
| where type =~ 'microsoft.compute/disks'
| extend diskState = tostring(properties.diskState)
| extend skuName = tostring(sku.name)
| where skuName has 'Premium'
| where (isempty(managedBy) or managedBy == '') or diskState == 'Unattached'
| extend diskSizeGB = toint(properties.diskSizeGB)
| project id, name, resourceGroup, location, subscriptionId, sku = skuName, diskState, diskSizeGB
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
