function Get-ArgCostOldSnapshots {
    $query = @"
Resources
| where type =~ 'microsoft.compute/snapshots'
| extend created = todatetime(properties.timeCreated)
| where created < ago(30d)
| extend ageDays = datetime_diff('day', now(), created)
| project id, name, resourceGroup, location, subscriptionId, created, ageDays
| sort by ageDays desc
"@
    Search-AzGraph -Query $query
}
