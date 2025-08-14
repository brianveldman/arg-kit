function Get-ArgSecurityAllDefenderForCloudRecommendations {
    $query = @"
securityresources
| where type == 'microsoft.security/assessments'
| extend resourceId = id,
    recommendationId = name,
    recommendationName = properties.displayName,
    recommendationState = properties.status.code,
    description = properties.metadata.description,
    assessmentType = properties.metadata.assessmentType,
    remediationDescription = properties.metadata.remediationDescription,
    policyDefinitionId = properties.metadata.policyDefinitionId,
    implementationEffort = properties.metadata.implementationEffort,
    recommendationSeverity = properties.metadata.severity,
    category = properties.metadata.categories,
    userImpact = properties.metadata.userImpact,
    threats = properties.metadata.threats
| project tenantId, subscriptionId, resourceId, recommendationName, recommendationId, recommendationState, recommendationSeverity, description, remediationDescription, assessmentType, policyDefinitionId, implementationEffort, userImpact, category, threats
"@
    Search-AzGraph -Query $query
}
