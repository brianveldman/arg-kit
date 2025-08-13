function Get-ArgPolicyComplianceByResourceType {
    $query = @" 
PolicyResources
| where type =~ 'Microsoft.PolicyInsights/PolicyStates' 
| extend complianceState = tostring(properties.complianceState) 
| extend resourceId = tostring(properties.resourceId), policyAssignmentId = tostring(properties.policyAssignmentId), policyAssignmentScope = tostring(properties.policyAssignmentScope), policyAssignmentName = tostring(properties.policyAssignmentName), policyDefinitionId = tostring(properties.policyDefinitionId), policyDefinitionReferenceId = tostring(properties.policyDefinitionReferenceId), stateWeight = iff(complianceState == 'NonCompliant', int(300), iff(complianceState == 'Compliant', int(200), iff(complianceState == 'Conflict', int(100), iff(complianceState == 'Exempt', int(50), int(0))))) 
| summarize max(stateWeight) by resourceId, policyAssignmentId, policyAssignmentScope, policyAssignmentName 
| summarize counts = count() by policyAssignmentId, policyAssignmentScope, max_stateWeight, policyAssignmentName 
| summarize overallStateWeight = max(max_stateWeight), nonCompliantCount = sumif(counts, max_stateWeight == 300), compliantCount = sumif(counts, max_stateWeight == 200), conflictCount = sumif(counts, max_stateWeight == 100), exemptCount = sumif(counts, max_stateWeight == 50) by policyAssignmentId, policyAssignmentScope, policyAssignmentName 
| extend totalResources = todouble(nonCompliantCount + compliantCount + conflictCount + exemptCount) 
| extend compliancePercentage = iff(totalResources == 0, todouble(100), 100 * todouble(compliantCount + exemptCount) / totalResources) 
| project policyAssignmentName, scope = policyAssignmentScope, complianceState = iff(overallStateWeight == 300, 'noncompliant', iff(overallStateWeight == 200, 'compliant', iff(overallStateWeight == 100, 'conflict', iff(overallStateWeight == 50, 'exempt', 'notstarted')))), compliancePercentage, compliantCount, nonCompliantCount, conflictCount, exemptCount"
"@
    Search-AzGraph -Query $query
}
