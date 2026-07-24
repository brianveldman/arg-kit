function Get-ArgCostUnassociatedStandardPublicIPs {
    $query = @"
Resources
| where type =~ 'microsoft.network/publicipaddresses'
| where isnull(properties.ipConfiguration) and isnull(properties.natGateway)
| where tostring(sku.name) =~ 'Standard'
| project id, name, resourceGroup, location, subscriptionId, sku = tostring(sku.name)
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
