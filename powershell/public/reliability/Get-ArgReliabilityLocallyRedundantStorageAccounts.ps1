function Get-ArgReliabilityLocallyRedundantStorageAccounts {
    $query = @"
Resources
| where type =~ 'microsoft.storage/storageaccounts'
| extend skuName = tostring(sku.name)
| where skuName !contains 'GRS' and skuName !contains 'GZRS'
| project name, resourceGroup, location, subscriptionId, sku = skuName, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
