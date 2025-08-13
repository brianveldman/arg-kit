function Get-ArgPolicyAllNonCompliantResources {
    $query = @"
PolicyResources
| where type == 'microsoft.policyinsights/policystates' 
| where properties.complianceState == 'NonCompliant'
"@
    Search-AzGraph -Query $query
}