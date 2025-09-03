function Get-ArgSecurityPurgeProtectionKeyVaults {
    $query = @"
Resources
| where type == "microsoft.keyvault/vaults"
| where isnull(properties.enablePurgeProtection) or properties.enablePurgeProtection != "true"
"@
    Search-AzGraph -Query $query
}
