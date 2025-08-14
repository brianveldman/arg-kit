function Get-ArgOrphanedAppServicePlans {
    Search-AzGraph -Query "Resources
| where type =~ 'microsoft.web/serverfarms'
| where properties.numberOfSites == 0
"
}
