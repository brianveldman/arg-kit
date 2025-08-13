function Get-ArgOrphanedNetworkSecurityGroups {
    Search-AzGraph -Query "Resources 
    | where type =~ 'microsoft.network/networksecuritygroups' and isnull(properties.networkInterfaces) and isnull(properties.subnets) 
    | project name, resourceGroup 
    | sort by name asc"
}
