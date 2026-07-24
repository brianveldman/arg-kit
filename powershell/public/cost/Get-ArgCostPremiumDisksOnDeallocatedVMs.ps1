function Get-ArgCostPremiumDisksOnDeallocatedVMs {
    $query = @"
Resources
| where type =~ 'microsoft.compute/disks'
| where tostring(sku.name) in ('Premium_LRS', 'Premium_ZRS')
| extend vmId = tolower(tostring(managedBy))
| where isnotempty(vmId)
| join kind=inner (
    Resources
    | where type =~ 'microsoft.compute/virtualmachines'
    | extend powerState = tostring(properties.extended.instanceView.powerState.code)
    | where powerState in ('PowerState/deallocated', 'PowerState/stopped')
    | project vmId = tolower(id), vmName = name, powerState
) on vmId
| project name, resourceGroup, location, subscriptionId, sku = tostring(sku.name), vmName, powerState, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
