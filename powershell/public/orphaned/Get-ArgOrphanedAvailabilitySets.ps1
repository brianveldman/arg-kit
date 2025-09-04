function Get-ArgOrphanedAvailabilitySets {
    $query = @"
Resources
| where type == "microsoft.compute/availabilitysets"
| where array_length(properties.virtualMachines) == 0
| project 
    availabilitySetName = name,
    resourceGroup,
    location,
    subscriptionId,
    platformFaultDomainCount = properties.platformFaultDomainCount,
    platformUpdateDomainCount = properties.platformUpdateDomainCount
| sort by resourceGroup asc, availabilitySetName asc
"@

    Search-AzGraph -Query $query
}
