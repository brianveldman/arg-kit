function Get-ArgCostHybridUseBenefitsEnabled {
    $query = @"
Resources
| where type =~ 'microsoft.compute/virtualMachines'
| extend imageOffer = tostring(properties.storageProfile.imageReference.offer),
         licenseType = tostring(properties.licenseType)
| where imageOffer =~ 'WindowsServer' and licenseType == 'Windows_Server'
| project id, name, resourceGroup, location, subscriptionId, imageOffer, licenseType
| sort by name asc
"@
    Search-AzGraph -Query $query
}