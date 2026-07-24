function Get-ArgCostAvdHostPoolsWithoutScalingPlan {
    $query = @"
Resources
| where type =~ 'microsoft.desktopvirtualization/hostpools'
| extend hostPoolId = tolower(id)
| join kind=leftouter (
    Resources
    | where type =~ 'microsoft.desktopvirtualization/scalingplans'
    | mv-expand ref = properties.hostPoolReferences
    | extend hostPoolId = tolower(tostring(ref.hostPoolArmPath)),
             enabled = tobool(ref.scalingPlanEnabled)
    | where enabled == true
    | project hostPoolId, scalingPlanEnabled = enabled
) on hostPoolId
| where isnull(scalingPlanEnabled)
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
