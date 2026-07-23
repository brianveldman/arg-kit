function Get-ArgOverviewReport {
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Orphaned', 'Security', 'Cost', 'Policy', 'Updates', 'Deprecations', 'Monitor')]
        [string[]]$Category = @('All'),

        [string]$OutputPath = (Join-Path -Path (Get-Location) -ChildPath ("arg-kit-overview-{0:yyyyMMdd-HHmmss}.html" -f (Get-Date))),

        [switch]$OpenReport
    )

    $categoryChecks = [ordered]@{
        Orphaned = @(
            'Get-ArgOrphanedNetworkSecurityGroups',
            'Get-ArgOrphanedPublicIPAddresses',
            'Get-ArgOrphanedDisks',
            'Get-ArgOrphanedNetworkInterfaceCards',
            'Get-ArgOrphanedLoadBalancers',
            'Get-ArgOrphanedAppServicePlans',
            'Get-ArgOrphanedAvailabilitySets'
        )
        Security = @(
            'Get-ArgSecurityPublicAccessStorageAccounts',
            'Get-ArgSecurityHttpsOnlyStorageAccounts',
            'Get-ArgSecurityPublicAccessKeyVaults',
            'Get-ArgSecurityAllResourcesWithSMSI',
            'Get-ArgSecurityAllDefenderForCloudRecommendations',
            'Get-ArgSecurityDefenderForCloudCoverage',
            'Get-ArgSecurityPurgeProtectionKeyVaults'
        )
        Cost = @(
            'Get-ArgCostHybridUseBenefitsNotEnabled',
            'Get-ArgCostHybridUseBenefitsEnabled',
            'Get-ArgCostSavingsSummary'
        )
        Policy = @(
            'Get-ArgPolicyComplianceByPolicyAssignment',
            'Get-ArgPolicyComplianceByResourceType',
            'Get-ArgPolicyAllNonCompliantResources'
        )
        Updates = @(
            'Get-ArgPendingUpdates',
            'Get-ArgWindowsUpdateInstallations',
            'Get-ArgLinuxUpdateInstallations'
        )
        Deprecations = @(
            'Get-ArgDeprecationBasicPublicIpAddresses',
            'Get-ArgDeprecationTlsStorageAccounts',
            'Get-ArgDeprecationTlsSqlServers'
        )
        Monitor = @(
            'Get-ArgMonitorAlertsLast2Hours',
            'Get-ArgMonitorActiveServiceHealthAlerts',
            'Get-ArgMonitorActivePlannedMaintenanceEvents'
        )
    }

    $selectedCategories = if ($Category -contains 'All') {
        $categoryChecks.Keys
    } else {
        $Category | Select-Object -Unique
    }

    $summaryRows = @()
    $detailSections = @()

    foreach ($currentCategory in $selectedCategories) {
        foreach ($checkName in $categoryChecks[$currentCategory]) {
            $resultData = $null
            $status = 'Success'
            $errorMessage = $null

            try {
                $resultData = & $checkName
            }
            catch {
                $status = 'Error'
                $errorMessage = $_.Exception.Message
            }

            $resultCount = if ($null -eq $resultData) {
                0
            } elseif ($resultData -is [array]) {
                $resultData.Count
            } else {
                1
            }

            $summaryRows += [pscustomobject]@{
                Category    = $currentCategory
                Check       = $checkName
                Status      = $status
                ResultCount = $resultCount
                Error       = $errorMessage
            }

            if ($status -eq 'Error') {
                $detailSections += "<h3>$checkName</h3><p class='error'>$errorMessage</p>"
            } elseif ($resultCount -eq 0) {
                $detailSections += "<h3>$checkName</h3><p>No results returned.</p>"
            } else {
                $detailHtml = $resultData | ConvertTo-Html -Fragment
                $detailSections += "<h3>$checkName</h3>$detailHtml"
            }
        }
    }

    $categoryOverview = $summaryRows |
        Group-Object -Property Category |
        ForEach-Object {
            [pscustomobject]@{
                Category      = $_.Name
                Checks        = $_.Count
                FailedChecks  = ($_.Group | Where-Object { $_.Status -eq 'Error' }).Count
                TotalFindings = ($_.Group | Measure-Object -Property ResultCount -Sum).Sum
            }
        }

    $style = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; color: #1f2937; }
h1, h2, h3 { color: #111827; }
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
th, td { border: 1px solid #d1d5db; padding: 8px; text-align: left; vertical-align: top; }
th { background-color: #f3f4f6; }
.error { color: #b91c1c; font-weight: 600; }
</style>
"@

    $generatedAt = Get-Date
    $categoryList = $selectedCategories -join ', '
    $categoryOverviewHtml = $categoryOverview | ConvertTo-Html -Fragment
    $summaryHtml = $summaryRows | ConvertTo-Html -Fragment
    $detailsHtml = $detailSections -join "`n"

    $fullHtml = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<title>ARG-Kit Overview Report</title>
$style
</head>
<body>
<h1>ARG-Kit Overview Report</h1>
<p><strong>Generated:</strong> $generatedAt</p>
<p><strong>Categories:</strong> $categoryList</p>
<h2>Category Overview</h2>
$categoryOverviewHtml
<h2>Check Summary</h2>
$summaryHtml
<h2>Detailed Results</h2>
$detailsHtml
</body>
</html>
"@

    $parentPath = Split-Path -Path $OutputPath -Parent
    if ($parentPath -and -not (Test-Path -Path $parentPath)) {
        New-Item -Path $parentPath -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $OutputPath -Value $fullHtml -Encoding UTF8
    Write-Verbose "Overview report generated at: $OutputPath"

    if ($OpenReport) {
        Invoke-Item -Path $OutputPath
    }

    [pscustomobject]@{
        GeneratedAt = $generatedAt
        Categories  = $selectedCategories
        OutputPath  = $OutputPath
        Summary     = $summaryRows
    }
}
