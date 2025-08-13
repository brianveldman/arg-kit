function Get-ArgDeprecationTlsStorageAccounts {
    $query = @"
Resources
| where type =~ 'microsoft.storage/storageAccounts'
| extend minimumTls = tostring(properties.minimumTlsVersion)
| where isempty(minimumTls) or minimumTls in ('TLS1_0','TLS1_1')
| project name, resourceGroup, location, subscriptionId, minimumTls, id
| order by name asc
"@
    Search-AzGraph -Query $query
}
