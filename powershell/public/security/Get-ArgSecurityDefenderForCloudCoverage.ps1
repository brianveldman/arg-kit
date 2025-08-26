function Get-ArgSecurityDefenderForCloudCoverage {
    $query = @"
securityresources
| where type == "microsoft.security/pricings"
| project subscriptionId, name, pricingTier = properties.pricingTier
| order by name asc
"@
    Search-AzGraph -Query $query
}
