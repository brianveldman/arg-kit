function Get-ArgSecurityAppServicesWithoutHttpsOnly {
    $query = @"
Resources
| where type =~ 'microsoft.web/sites'
| where tobool(properties.httpsOnly) == false
| project name, kind, resourceGroup, location, subscriptionId, id
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
