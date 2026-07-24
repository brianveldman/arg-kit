function Get-ArgGovernanceResourcesMissingRequiredTags {
    param(
        [string[]]$RequiredTag = @('Owner', 'CostCenter', 'Environment')
    )

    $conditions = $RequiredTag | ForEach-Object { "isempty(tostring(tags['$_']))" }
    $whereClause = $conditions -join ' or '
    $missingProjections = $RequiredTag | ForEach-Object { "missing_$_ = isempty(tostring(tags['$_']))" }
    $projectClause = ($missingProjections -join ', ')

    $query = @"
Resources
| where $whereClause
| project name, type, resourceGroup, location, subscriptionId, $projectClause
| sort by type asc, name asc
"@
    Search-AzGraph -Query $query
}
