function Get-ArgPendingUpdates {
    $query = @"
PatchAssessmentResources
| where type !has 'softwarepatches'
| extend prop = todynamic(properties)
| extend lastTime = todatetime(prop.lastModifiedDateTime)
| extend updateRollupCount = toint(prop.availablePatchCountByClassification.updateRollup),
         featurePackCount   = toint(prop.availablePatchCountByClassification.featurePack),
         servicePackCount   = toint(prop.availablePatchCountByClassification.servicePack),
         definitionCount    = toint(prop.availablePatchCountByClassification.definition),
         securityCount      = toint(prop.availablePatchCountByClassification.security),
         criticalCount      = toint(prop.availablePatchCountByClassification.critical),
         updatesCount       = toint(prop.availablePatchCountByClassification.updates),
         toolsCount         = toint(prop.availablePatchCountByClassification.tools),
         otherCount         = toint(prop.availablePatchCountByClassification.other),
         OS                 = tostring(prop.osType)
| project lastTime, id, OS, updateRollupCount, featurePackCount, servicePackCount, definitionCount, securityCount, criticalCount, updatesCount, toolsCount, otherCount
| order by lastTime desc
"@
    Search-AzGraph -Query $query
}
