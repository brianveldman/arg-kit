function Get-ArgPolicyComplianceByResourceType {
    $query = @"
PolicyResources
| where tolower(type) startswith 'microsoft.policyinsights/policystates'
| extend complianceState = tostring(properties.complianceState)
| extend resourceId                 = tostring(properties.resourceId),
         policyAssignmentId         = tostring(properties.policyAssignmentId),
         policyAssignmentScope      = tostring(properties.policyAssignmentScope),
         policyAssignmentName       = tostring(properties.policyAssignmentName),
         policyDefinitionId         = tostring(properties.policyDefinitionId),
         policyDefinitionReferenceId= tostring(properties.policyDefinitionReferenceId)
| extend stateWeight = case(
        complianceState =~ 'NonCompliant', 300,
        complianceState =~ 'Compliant',    200,
        complianceState =~ 'Conflict',     100,
        complianceState =~ 'Exempt',        50,
        0)
| summarize max_stateWeight = max(stateWeight)
    by resourceId, policyAssignmentId, policyAssignmentScope, policyAssignmentName
| summarize counts = count()
    by policyAssignmentId, policyAssignmentScope, policyAssignmentName, max_stateWeight
| summarize overallStateWeight = max(max_stateWeight),
          nonCompliantCount = sum(iif(max_stateWeight == 300, counts, 0)),
          compliantCount    = sum(iif(max_stateWeight == 200, counts, 0)),
          conflictCount     = sum(iif(max_stateWeight == 100, counts, 0)),
          exemptCount       = sum(iif(max_stateWeight == 50,  counts, 0))
  by policyAssignmentId, policyAssignmentScope, policyAssignmentName
| extend totalResources = todouble(nonCompliantCount + compliantCount + conflictCount + exemptCount)
| extend compliancePercentage = iif(totalResources == 0, 100.0, 100.0 * todouble(compliantCount + exemptCount) / totalResources)
| extend complianceStateFinal = case(
        overallStateWeight == 300, 'noncompliant',
        overallStateWeight == 200, 'compliant',
        overallStateWeight == 100, 'conflict',
        overallStateWeight == 50,  'exempt',
        'notstarted')
| project policyAssignmentName,
          scope = policyAssignmentScope,
          complianceState = complianceStateFinal,
          compliancePercentage,
          compliantCount,
          nonCompliantCount,
          conflictCount,
          exemptCount
| order by policyAssignmentName asc
"@
    Search-AzGraph -Query $query
}
