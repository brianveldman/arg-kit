function Get-ArgOrphanedDisks {
    Search-AzGraph -Query "Resources
| where type =~ 'microsoft.compute/disks'
| extend diskState = tostring(properties.diskState)
| where ((isempty(managedBy) or managedBy == '') and diskState != 'ActiveSAS') or diskState == 'Unattached'
| project id, diskState, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, id asc"
}
