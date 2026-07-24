function Get-ArgCostStoppedNotDeallocatedVMs {
    $query = @"
Resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend powerState = tostring(properties.extended.instanceView.powerState.code)
| where powerState == 'PowerState/stopped'
| project id, name, resourceGroup, location, subscriptionId, powerState
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
