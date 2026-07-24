function Get-ArgOrphanedResourceGroups {
    $query = @"
ResourceContainers
| where type =~ 'microsoft.resources/subscriptions/resourcegroups'
| extend rgKey = strcat(tolower(subscriptionId), '/', tolower(name))
| join kind=leftouter (
    Resources
    | extend rgKey = strcat(tolower(subscriptionId), '/', tolower(resourceGroup))
    | summarize resourceCount = count() by rgKey
) on rgKey
| where isnull(resourceCount) or resourceCount == 0
| project name, resourceGroup = name, location, subscriptionId
| sort by subscriptionId asc, name asc
"@
    Search-AzGraph -Query $query
}
