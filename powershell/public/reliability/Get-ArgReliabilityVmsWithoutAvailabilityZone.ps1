function Get-ArgReliabilityVmsWithoutAvailabilityZone {
    $query = @"
Resources
| where type =~ 'microsoft.compute/virtualmachines'
| where isnull(zones) or array_length(zones) == 0
| project name, resourceGroup, location, subscriptionId, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
