function Get-ArgSecurityPublicAccessOpenAI {
    $query = @"
Resources
| where type =~ 'Microsoft.CognitiveServices/accounts'
| where properties.networkAcls.defaultAction == 'Allow'
| project id, name, resourceGroup, location, subscriptionId
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
