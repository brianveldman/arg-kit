function Get-ArgCostSavingsSummary {
    $query = @"
AdvisorResources
| where type == 'microsoft.advisor/recommendations' 
| where properties.category == 'Cost' 
| extend resources = tostring(properties.resourceMetadata.resourceId), savings = todouble(properties.extendedProperties.savingsAmount), solution = tostring(properties.shortDescription.solution), currency = tostring(properties.extendedProperties.savingsCurrency) 
| summarize Resources = dcount(resources), Savings = bin(sum(savings), 0.01) by solution, Currency = currency
| order by Savings desc
"@
    Search-AzGraph -Query $query
}
