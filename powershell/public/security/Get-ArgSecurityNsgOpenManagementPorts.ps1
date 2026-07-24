function Get-ArgSecurityNsgOpenManagementPorts {
    $query = @"
Resources
| where type =~ 'microsoft.network/networksecuritygroups'
| mv-expand rule = properties.securityRules
| extend direction = tostring(rule.properties.direction),
         access = tostring(rule.properties.access),
         protocol = tostring(rule.properties.protocol),
         destPort = tostring(rule.properties.destinationPortRange),
         source = tostring(rule.properties.sourceAddressPrefix)
| where direction =~ 'Inbound' and access =~ 'Allow'
| where source in ('*', '0.0.0.0/0', 'Internet')
| where destPort in ('*', '22', '3389')
| project id, name, resourceGroup, location, subscriptionId,
          ruleName = tostring(rule.name), protocol, destPort, source
| sort by resourceGroup asc, name asc
"@
    Search-AzGraph -Query $query
}
