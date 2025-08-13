function Get-ArgOrphanedNetworkInterfaceCards {
    $query = @"
Resources
| where type =~ 'microsoft.network/networkinterfaces'
| join kind=leftouter (
    Resources
    | where type =~ 'microsoft.network/privateendpoints'
    | extend nic = todynamic(properties.networkInterfaces)
    | mv-expand nic
    | project id = tostring(nic.id)
) on id
| where isempty(id1)
| where properties !has 'virtualmachine'
| project id, resourceGroup, location, subscriptionId
"@

    Search-AzGraph -Query $query
}
