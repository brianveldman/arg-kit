function Get-ArgOverviewReport {
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Orphaned', 'Security', 'Cost', 'Reliability', 'Governance', 'Policy', 'Updates', 'Deprecations', 'Monitor')]
        [string[]]$Category = @('All'),

        [string]$OutputPath,

        [switch]$OpenReport
    )

    $azContext = $null
    try {
        $azContext = Get-AzContext -ErrorAction Stop
    }
    catch {
        $azContext = $null
    }

    if (-not $azContext -or -not $azContext.Account) {
        Write-Error "You are not signed in to Azure. Please sign in first using Connect-AzAccount before running Get-ArgOverviewReport."
        return
    }

    $categoryChecks = [ordered]@{
        Orphaned = @(
            'Get-ArgOrphanedNetworkSecurityGroups',
            'Get-ArgOrphanedPublicIPAddresses',
            'Get-ArgOrphanedDisks',
            'Get-ArgOrphanedNetworkInterfaceCards',
            'Get-ArgOrphanedLoadBalancers',
            'Get-ArgOrphanedAppServicePlans',
            'Get-ArgOrphanedAvailabilitySets',
            'Get-ArgOrphanedRouteTables',
            'Get-ArgOrphanedNatGateways',
            'Get-ArgOrphanedResourceGroups'
        )
        Security = @(
            'Get-ArgSecurityPublicAccessStorageAccounts',
            'Get-ArgSecurityHttpsOnlyStorageAccounts',
            'Get-ArgSecurityPublicAccessKeyVaults',
            'Get-ArgSecurityAllResourcesWithSMSI',
            'Get-ArgSecurityAllDefenderForCloudRecommendations',
            'Get-ArgSecurityDefenderForCloudCoverage',
            'Get-ArgSecurityPurgeProtectionKeyVaults',
            'Get-ArgSecurityNsgOpenManagementPorts',
            'Get-ArgSecuritySoftDeleteDisabledKeyVaults',
            'Get-ArgSecuritySqlServersPublicNetworkAccess',
            'Get-ArgSecurityBlobPublicAccessStorageAccounts',
            'Get-ArgSecurityAppServicesWithoutHttpsOnly'
        )
        Cost = @(
            'Get-ArgCostHybridUseBenefitsNotEnabled',
            'Get-ArgCostHybridUseBenefitsEnabled',
            'Get-ArgCostSavingsSummary',
            'Get-ArgCostStoppedNotDeallocatedVMs',
            'Get-ArgCostUnassociatedStandardPublicIPs',
            'Get-ArgCostOldSnapshots',
            'Get-ArgCostAvdHostPoolsWithoutScalingPlan',
            'Get-ArgCostPremiumDisksOnDeallocatedVMs'
        )
        Reliability = @(
            'Get-ArgReliabilityVmsWithoutAvailabilityZone'
        )
        Governance = @(
            'Get-ArgGovernanceResourcesMissingRequiredTags'
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
            'Get-ArgDeprecationTlsSqlServers',
            'Get-ArgDeprecationP2SEntraManualVpnGateways'
        )
        Monitor = @(
            'Get-ArgMonitorAlertsLast2Hours',
            'Get-ArgMonitorActiveServiceHealthAlerts',
            'Get-ArgMonitorActivePlannedMaintenanceEvents'
        )
    }

    $displayNames = @{
        'Get-ArgOrphanedNetworkSecurityGroups'          = 'Orphaned Network Security Groups'
        'Get-ArgOrphanedPublicIPAddresses'              = 'Orphaned Public IP Addresses'
        'Get-ArgOrphanedDisks'                          = 'Orphaned Disks'
        'Get-ArgOrphanedNetworkInterfaceCards'          = 'Orphaned Network Interface Cards'
        'Get-ArgOrphanedLoadBalancers'                  = 'Orphaned Load Balancers'
        'Get-ArgOrphanedAppServicePlans'                = 'Orphaned App Service Plans'
        'Get-ArgOrphanedAvailabilitySets'               = 'Orphaned Availability Sets'
        'Get-ArgOrphanedRouteTables'                    = 'Orphaned Route Tables'
        'Get-ArgOrphanedNatGateways'                    = 'Orphaned NAT Gateways'
        'Get-ArgOrphanedResourceGroups'                 = 'Empty Resource Groups'
        'Get-ArgSecurityPublicAccessStorageAccounts'    = 'Storage Accounts with Public Access'
        'Get-ArgSecurityHttpsOnlyStorageAccounts'       = 'Storage Accounts Not Enforcing HTTPS'
        'Get-ArgSecurityPublicAccessKeyVaults'          = 'Key Vaults with Public Access'
        'Get-ArgSecurityAllResourcesWithSMSI'           = 'Resources with System-Assigned Managed Identity'
        'Get-ArgSecurityAllDefenderForCloudRecommendations' = 'Defender for Cloud Recommendations'
        'Get-ArgSecurityDefenderForCloudCoverage'       = 'Defender for Cloud Coverage'
        'Get-ArgSecurityPurgeProtectionKeyVaults'       = 'Key Vaults without Purge Protection'
        'Get-ArgSecurityNsgOpenManagementPorts'         = 'NSGs Exposing RDP/SSH to the Internet'
        'Get-ArgSecuritySoftDeleteDisabledKeyVaults'    = 'Key Vaults without Soft Delete'
        'Get-ArgSecuritySqlServersPublicNetworkAccess'  = 'SQL Servers with Public Network Access'
        'Get-ArgSecurityBlobPublicAccessStorageAccounts' = 'Storage Accounts Allowing Blob Public Access'
        'Get-ArgSecurityAppServicesWithoutHttpsOnly'    = 'App Services Not Enforcing HTTPS'
        'Get-ArgCostHybridUseBenefitsNotEnabled'        = 'Hybrid Use Benefit Not Enabled'
        'Get-ArgCostHybridUseBenefitsEnabled'           = 'Hybrid Use Benefit Enabled'
        'Get-ArgCostSavingsSummary'                     = 'Cost Savings Summary'
        'Get-ArgCostStoppedNotDeallocatedVMs'           = 'Stopped (Not Deallocated) VMs'
        'Get-ArgCostUnassociatedStandardPublicIPs'      = 'Unassociated Standard Public IPs'
        'Get-ArgCostOldSnapshots'                       = 'Snapshots Older Than 30 Days'
        'Get-ArgCostAvdHostPoolsWithoutScalingPlan'     = 'AVD Host Pools without Scaling Plan'
        'Get-ArgCostPremiumDisksOnDeallocatedVMs'       = 'Premium Disks on Deallocated VMs'
        'Get-ArgReliabilityVmsWithoutAvailabilityZone'  = 'VMs without Availability Zone'
        'Get-ArgGovernanceResourcesMissingRequiredTags' = 'Resources Missing Required Tags'
        'Get-ArgPolicyComplianceByPolicyAssignment'     = 'Policy Compliance by Assignment'
        'Get-ArgPolicyComplianceByResourceType'         = 'Policy Compliance by Resource Type'
        'Get-ArgPolicyAllNonCompliantResources'         = 'Non-Compliant Resources'
        'Get-ArgPendingUpdates'                         = 'Pending Updates'
        'Get-ArgWindowsUpdateInstallations'             = 'Windows Update Installations'
        'Get-ArgLinuxUpdateInstallations'               = 'Linux Update Installations'
        'Get-ArgDeprecationBasicPublicIpAddresses'      = 'Basic SKU Public IP Addresses (Retiring)'
        'Get-ArgDeprecationTlsStorageAccounts'          = 'Storage Accounts with Outdated TLS'
        'Get-ArgDeprecationTlsSqlServers'               = 'SQL Servers with Outdated TLS'
        'Get-ArgDeprecationP2SEntraManualVpnGateways'   = 'P2S VPN Gateways Using Manually-Registered Entra Client (Retiring)'
        'Get-ArgMonitorAlertsLast2Hours'                = 'Alerts (Last 2 Hours)'
        'Get-ArgMonitorActiveServiceHealthAlerts'       = 'Active Service Health Alerts'
        'Get-ArgMonitorActivePlannedMaintenanceEvents'  = 'Active Planned Maintenance Events'
    }

    $selectedCategories = if ($Category -contains 'All') {
        $categoryChecks.Keys
    } else {
        $Category | Select-Object -Unique
    }

    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path (Get-Location) -ChildPath ("arg-kit-overview-{0:yyyyMMdd-HHmmss}.html" -f (Get-Date))
    }

    $summaryRows = @()
    $improvementRows = @()
    $categoryRowsByCategory = [ordered]@{}
    foreach ($cat in $selectedCategories) {
        $categoryRowsByCategory[$cat] = @()
    }

    $totalCheckCount = 0
    foreach ($cat in $selectedCategories) {
        $totalCheckCount += $categoryChecks[$cat].Count
    }
    $completedChecks = 0

    $esc = [char]27
    function Write-ArgLine {
        param([string]$Text, [string]$Color = 'Gray', [switch]$NoNewline)
        if ($NoNewline) { Write-Host $Text -ForegroundColor $Color -NoNewline }
        else { Write-Host $Text -ForegroundColor $Color }
    }

    $subName = try { $azContext.Subscription.Name } catch { $null }
    if (-not $subName) { $subName = 'current subscription' }

    Write-Host ''
    Write-ArgLine "  ╔══════════════════════════════════════════════════════════╗" 'Cyan'
    Write-ArgLine "  ║              ARG-Kit  ·  Overview Report                  ║" 'Cyan'
    Write-ArgLine "  ╚══════════════════════════════════════════════════════════╝" 'Cyan'
    Write-Host "   Subscription : " -NoNewline; Write-ArgLine $subName 'White'
    Write-Host "   Categories   : " -NoNewline; Write-ArgLine ($selectedCategories -join ', ') 'White'
    Write-Host "   Checks       : " -NoNewline; Write-ArgLine "$totalCheckCount" 'White'
    Write-Host ''

    $reportStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $lastCategory = $null

    foreach ($currentCategory in $selectedCategories) {
        foreach ($checkName in $categoryChecks[$currentCategory]) {
            $completedChecks++
            $percent = if ($totalCheckCount -gt 0) { [int](($completedChecks / $totalCheckCount) * 100) } else { 0 }
            Write-Progress -Activity "Generating ARG overview report" `
                -Status "[$completedChecks/$totalCheckCount] $currentCategory - $checkName" `
                -CurrentOperation "Running $checkName" `
                -PercentComplete $percent

            $displayName = if ($displayNames.ContainsKey($checkName)) { $displayNames[$checkName] } else { $checkName }

            if ($currentCategory -ne $lastCategory) {
                Write-Host ''
                Write-ArgLine "  ▸ $currentCategory" 'Magenta'
                $lastCategory = $currentCategory
            }

            $counter = "[{0,2}/{1}]" -f $completedChecks, $totalCheckCount
            Write-Host "   $counter " -NoNewline -ForegroundColor DarkGray
            Write-Host "$esc[38;5;245m⠿$esc[0m " -NoNewline
            Write-Host ("{0,-48}" -f $displayName) -NoNewline -ForegroundColor Gray

            $resultData = $null
            $status = 'Success'
            $errorMessage = $null
            $checkStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            try {
                $resultData = & $checkName
            }
            catch {
                $status = 'Error'
                $errorMessage = $_.Exception.Message
            }

            $checkStopwatch.Stop()
            $elapsed = "{0,5:0}ms" -f $checkStopwatch.Elapsed.TotalMilliseconds

            $resultCount = if ($null -eq $resultData) {
                0
            } else {
                @($resultData).Count
            }

            Write-Host "`r$esc[2K   $counter " -NoNewline -ForegroundColor DarkGray
            if ($status -eq 'Error') {
                Write-Host "✗ " -NoNewline -ForegroundColor Red
                Write-Host ("{0,-48}" -f $displayName) -NoNewline -ForegroundColor Gray
                Write-Host "  error" -NoNewline -ForegroundColor Red
            } elseif ($resultCount -gt 0) {
                Write-Host "● " -NoNewline -ForegroundColor Yellow
                Write-Host ("{0,-48}" -f $displayName) -NoNewline -ForegroundColor White
                Write-Host ("  {0,3} to review" -f $resultCount) -NoNewline -ForegroundColor Yellow
            } else {
                Write-Host "✓ " -NoNewline -ForegroundColor Green
                Write-Host ("{0,-48}" -f $displayName) -NoNewline -ForegroundColor DarkGray
                Write-Host "  clear" -NoNewline -ForegroundColor Green
            }
            Write-Host "  $elapsed" -ForegroundColor DarkGray

            $summaryRows += [pscustomobject]@{
                Category    = $currentCategory
                Check       = $checkName
                Status      = $status
                ResultCount = $resultCount
                Error       = $errorMessage
            }

            if ($status -eq 'Error') {
                $categoryRowsByCategory[$currentCategory] += [pscustomobject]@{
                    Check         = $displayName
                    Resource      = ''
                    ResourceGroup = ''
                    Location      = ''
                    Details       = "Error: $errorMessage"
                    RowClass      = 'row-error'
                }
            } elseif ($resultCount -gt 0) {
                $improvementRows += [pscustomobject]@{
                    Category = $currentCategory
                    Check    = $checkName
                    Count    = $resultCount
                }

                foreach ($item in @($resultData)) {
                    $props = $item.PSObject.Properties
                    $getVal = {
                        param($n)
                        ($props | Where-Object { $_.Name -ieq $n } | Select-Object -First 1).Value
                    }
                    $detailParts = $props |
                        Where-Object { $_.Name -inotin @('name', 'resourceGroup', 'location', 'subscriptionId', 'id') -and $null -ne $_.Value -and "$($_.Value)" -ne '' } |
                        ForEach-Object { "$($_.Name): $($_.Value)" }

                    $categoryRowsByCategory[$currentCategory] += [pscustomobject]@{
                        Check         = $displayName
                        Resource      = [string](& $getVal 'name')
                        ResourceGroup = [string](& $getVal 'resourceGroup')
                        Location      = [string](& $getVal 'location')
                        Details       = ($detailParts -join '; ')
                        RowClass      = ''
                    }
                }
            }
        }
    }

    Write-Progress -Activity "Generating ARG overview report" -Completed

    $reportStopwatch.Stop()
    $passedCount = @($summaryRows | Where-Object { $_.Status -ne 'Error' -and $_.ResultCount -eq 0 }).Count
    $reviewCount = @($summaryRows | Where-Object { $_.Status -ne 'Error' -and $_.ResultCount -gt 0 }).Count
    $errorCount  = @($summaryRows | Where-Object { $_.Status -eq 'Error' }).Count
    $findingsTotal = ($summaryRows | Measure-Object -Property ResultCount -Sum).Sum
    if (-not $findingsTotal) { $findingsTotal = 0 }
    $elapsedTotal = "{0:mm\:ss}" -f $reportStopwatch.Elapsed

    Write-Host ''
    Write-ArgLine "  ────────────────────────────────────────────────────────────" 'DarkGray'
    Write-Host "   Summary   " -NoNewline -ForegroundColor Cyan
    Write-Host "$($summaryRows.Count) checks in $elapsedTotal" -ForegroundColor White
    Write-Host "   " -NoNewline
    Write-Host "✓ $passedCount clear" -NoNewline -ForegroundColor Green
    Write-Host "   " -NoNewline
    Write-Host "● $reviewCount to review" -NoNewline -ForegroundColor Yellow
    Write-Host "   " -NoNewline
    Write-Host "✗ $errorCount errors" -NoNewline -ForegroundColor Red
    Write-Host "   " -NoNewline
    Write-Host "Σ $findingsTotal findings" -ForegroundColor Magenta
    Write-Host ''

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
:root {
  --bg: #0b1220;
  --panel: #111a2e;
  --muted: #94a3b8;
  --border: #1e293b;
  --accent: #60a5fa;
  --accent-soft: rgba(96,165,250,0.16);
  --error: #f87171;
  --error-soft: rgba(248,113,113,0.16);
  --ok: #4ade80;
  --ok-soft: rgba(74,222,128,0.16);
  --warn: #fbbf24;
}
* { box-sizing: border-box; }
body {
  font-family: 'Segoe UI', system-ui, -apple-system, Arial, sans-serif;
  margin: 0;
  background: var(--bg);
  color: #e2e8f0;
  line-height: 1.5;
}
.wrap { max-width: 1200px; margin: 0 auto; padding: 8px 24px 64px; }
.wrap > h2:first-child { margin-top: 8px; }
header.hero {
  background: linear-gradient(135deg, #0b1220 0%, #1e3a8a 100%);
  color: #fff;
  padding: 40px 24px;
}
header.hero .inner { max-width: 1200px; margin: 0 auto; }
header.hero h1 { margin: 0 0 8px; font-size: 28px; font-weight: 700; letter-spacing: -0.02em; }
header.hero .meta { font-size: 14px; opacity: 0.85; display: flex; flex-wrap: wrap; gap: 20px; }
header.hero .meta span strong { font-weight: 600; }
.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin: -32px auto 16px; max-width: 1200px; padding: 0 24px; position: relative; }
.stat {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 12px rgba(15,23,42,0.06);
}
.stat .value { font-size: 30px; font-weight: 700; line-height: 1; }
.stat .label { font-size: 13px; color: var(--muted); margin-top: 6px; text-transform: uppercase; letter-spacing: 0.04em; }
.stat.error .value { color: var(--error); }
.stat.ok .value { color: var(--ok); }
.stat.findings .value { color: var(--accent); }
h2 { font-size: 20px; font-weight: 700; margin: 40px 0 16px; color: #f1f5f9; }
.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 4px 20px 8px;
  box-shadow: 0 1px 3px rgba(15,23,42,0.05);
  overflow-x: auto;
}
table { border-collapse: collapse; width: 100%; font-size: 14px; }
th, td { padding: 10px 12px; text-align: left; vertical-align: top; border-bottom: 1px solid var(--border); }
th { color: var(--muted); font-weight: 600; text-transform: uppercase; font-size: 12px; letter-spacing: 0.03em; }
tbody tr:hover { background: rgba(148,163,184,0.08); }
.card {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 16px;
  box-shadow: 0 1px 3px rgba(15,23,42,0.05);
}
.card-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16px; margin-bottom: 8px; }
.card-head h3 { margin: 4px 0 0; font-size: 16px; font-weight: 600; }
.card-category { font-size: 12px; color: var(--accent); text-transform: uppercase; letter-spacing: 0.05em; font-weight: 600; }
.card .table-wrap { overflow-x: auto; margin-top: 12px; }
.panel.table-wrap { overflow-x: auto; }
tr.row-error td { color: var(--error); }
.badge { font-size: 13px; font-weight: 700; padding: 4px 12px; border-radius: 999px; white-space: nowrap; }
.badge-error { background: var(--error-soft); color: var(--error); }
.badge-clear { background: var(--ok-soft); color: var(--ok); }
.badge-findings { background: var(--accent-soft); color: var(--accent); }
.error { color: var(--error); font-weight: 500; }
.muted { color: var(--muted); }
.section-intro { color: var(--muted); font-size: 14px; margin: -8px 0 16px; max-width: 760px; }
.focus-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; margin-bottom: 8px; }
.focus-card {
  background: var(--panel);
  border: 1px solid var(--border);
  border-left: 4px solid var(--border);
  border-radius: 12px;
  padding: 18px 20px;
  box-shadow: 0 1px 3px rgba(15,23,42,0.05);
}
.focus-card.level-high { border-left-color: var(--error); }
.focus-card.level-medium { border-left-color: var(--warn); }
.focus-card.level-low { border-left-color: var(--accent); }
.focus-card.level-clear { border-left-color: var(--ok); opacity: 0.85; }
.focus-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.focus-total { font-size: 32px; font-weight: 700; line-height: 1; color: #f1f5f9; }
.focus-sub { font-size: 12px; color: var(--muted); text-transform: uppercase; letter-spacing: 0.04em; margin-top: 2px; }
.tabs { display: flex; flex-wrap: wrap; gap: 8px; margin: 8px 0 20px; border-bottom: 1px solid var(--border); }
.tab-btn {
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  padding: 10px 16px;
  font-size: 14px;
  font-weight: 600;
  color: var(--muted);
  cursor: pointer;
  border-radius: 8px 8px 0 0;
  transition: color 0.15s, border-color 0.15s, background 0.15s;
}
.tab-btn:hover { color: var(--accent); background: var(--accent-soft); }
.tab-btn.active { color: var(--accent); border-bottom-color: var(--accent); }
.tab-btn .count { font-size: 12px; color: var(--muted); font-weight: 600; margin-left: 6px; }
.tab-btn.active .count { color: var(--accent); }
.tab-pane { display: none; }
.tab-pane.active { display: block; }
footer { text-align: center; color: var(--muted); font-size: 13px; margin-top: 48px; }
</style>
"@

    $generatedAt = Get-Date
    $categoryList = ($selectedCategories | ForEach-Object { [System.Net.WebUtility]::HtmlEncode($_) }) -join ', '
    $accountName = [System.Net.WebUtility]::HtmlEncode([string]$azContext.Account.Id)
    $subscriptionName = [System.Net.WebUtility]::HtmlEncode([string]$azContext.Subscription.Name)

    $totalChecks = $summaryRows.Count
    $totalFailed = ($summaryRows | Where-Object { $_.Status -eq 'Error' }).Count
    $totalPassed = ($summaryRows | Where-Object { $_.Status -ne 'Error' }).Count
    $totalFindings = ($summaryRows | Measure-Object -Property ResultCount -Sum).Sum
    if (-not $totalFindings) { $totalFindings = 0 }
    $totalImprovements = $improvementRows.Count

    $focusData = foreach ($cat in $selectedCategories) {
        $catRows = $summaryRows | Where-Object { $_.Category -eq $cat }
        $catImprovements = $improvementRows | Where-Object { $_.Category -eq $cat }
        $catFindings = ($catRows | Measure-Object -Property ResultCount -Sum).Sum
        if (-not $catFindings) { $catFindings = 0 }
        [pscustomobject]@{
            Category     = $cat
            Findings     = $catFindings
            Failed       = ($catRows | Where-Object { $_.Status -eq 'Error' }).Count
            Improvements = @($catImprovements)
        }
    }

    $focusCards = foreach ($focus in ($focusData | Sort-Object -Property Findings -Descending)) {
        $safeCat = [System.Net.WebUtility]::HtmlEncode([string]$focus.Category)

        if ($focus.Findings -gt 0) {
            $level = if ($focus.Findings -ge 10) { 'high' } elseif ($focus.Findings -ge 3) { 'medium' } else { 'low' }
            $failedNote = if ($focus.Failed -gt 0) { "<p class='error'>$($focus.Failed) check(s) failed to run.</p>" } else { '' }
            @"
<div class="focus-card level-$level">
  <div class="focus-head">
    <span class="card-category">$safeCat</span>
    <span class="focus-total">$($focus.Findings)</span>
  </div>
  <div class="focus-sub">items to review</div>
  $failedNote
</div>
"@
        } else {
            $failedNote = if ($focus.Failed -gt 0) { "<p class='error'>$($focus.Failed) check(s) failed to run.</p>" } else { "<p class='muted'>No items to review.</p>" }
            @"
<div class="focus-card level-clear">
  <div class="focus-head">
    <span class="card-category">$safeCat</span>
    <span class="badge badge-clear">Clear</span>
  </div>
  $failedNote
</div>
"@
        }
    }

    $improvementsHtml = @"
<h2>Where to Focus</h2>
<p class="section-intro">Categories are ranked by how many items need your attention. Higher counts mean more potential clean-up, cost savings, or security and compliance improvements.</p>
<div class="focus-grid">
$($focusCards -join "`n")
</div>
"@

    $categoryOverviewHtml = $categoryOverview | ConvertTo-Html -Fragment

    $tabButtons = @()
    $tabPanes = @()
    $tabIndex = 0
    foreach ($cat in $categoryRowsByCategory.Keys) {
        $safeCat = [System.Net.WebUtility]::HtmlEncode([string]$cat)
        $tabId = "tab-$tabIndex"
        $catFindings = ($summaryRows | Where-Object { $_.Category -eq $cat } | Measure-Object -Property ResultCount -Sum).Sum
        if (-not $catFindings) { $catFindings = 0 }
        $activeClass = if ($tabIndex -eq 0) { ' active' } else { '' }
        $tabButtons += "<button class='tab-btn$activeClass' data-tab='$tabId'>$safeCat<span class='count'>$catFindings</span></button>"

        $catRows = @($categoryRowsByCategory[$cat])
        if ($catRows.Count -gt 0) {
            $tableRows = foreach ($row in $catRows) {
                $rowClass = if ($row.RowClass) { " class='$($row.RowClass)'" } else { '' }
                $cells = @(
                    "<td>$([System.Net.WebUtility]::HtmlEncode([string]$row.Check))</td>"
                    "<td>$([System.Net.WebUtility]::HtmlEncode([string]$row.Resource))</td>"
                    "<td>$([System.Net.WebUtility]::HtmlEncode([string]$row.ResourceGroup))</td>"
                    "<td>$([System.Net.WebUtility]::HtmlEncode([string]$row.Location))</td>"
                    "<td>$([System.Net.WebUtility]::HtmlEncode([string]$row.Details))</td>"
                )
                "<tr$rowClass>$($cells -join '')</tr>"
            }
            $paneBody = @"
<div class="panel table-wrap">
  <table>
    <thead><tr><th>Check</th><th>Resource</th><th>Resource Group</th><th>Location</th><th>Details</th></tr></thead>
    <tbody>
$($tableRows -join "`n")
    </tbody>
  </table>
</div>
"@
        } else {
            $paneBody = "<div class='panel'><p class='muted'>No results to review in this category. All checks came back clear.</p></div>"
        }
        $tabPanes += "<div class='tab-pane$activeClass' id='$tabId'>$paneBody</div>"
        $tabIndex++
    }
    $tabsNavHtml = $tabButtons -join "`n"
    $tabsPanesHtml = $tabPanes -join "`n"

    $tabScript = @"
<script>
document.addEventListener('DOMContentLoaded', function () {
  var buttons = document.querySelectorAll('.tab-btn');
  buttons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var target = btn.getAttribute('data-tab');
      document.querySelectorAll('.tab-btn').forEach(function (b) { b.classList.remove('active'); });
      document.querySelectorAll('.tab-pane').forEach(function (p) { p.classList.remove('active'); });
      btn.classList.add('active');
      var pane = document.getElementById(target);
      if (pane) { pane.classList.add('active'); }
    });
  });
});
</script>
"@

    $fullHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>ARG-Kit Overview Report</title>
$style
</head>
<body>
<header class="hero">
  <div class="inner">
    <h1>ARG-Kit Overview Report</h1>
    <div class="meta">
      <span><strong>Generated:</strong> $generatedAt</span>
      <span><strong>Account:</strong> $accountName</span>
      <span><strong>Subscription:</strong> $subscriptionName</span>
      <span><strong>Categories:</strong> $categoryList</span>
    </div>
  </div>
</header>
<div class="stats">
  <div class="stat"><div class="value">$totalChecks</div><div class="label">Checks Run</div></div>
  <div class="stat ok"><div class="value">$totalPassed</div><div class="label">Passed</div></div>
  <div class="stat error"><div class="value">$totalFailed</div><div class="label">Failed</div></div>
  <div class="stat findings"><div class="value">$totalImprovements</div><div class="label">Possible Improvements</div></div>
</div>
<div class="wrap">
  $improvementsHtml
  <h2>Category Overview</h2>
  <div class="panel">$categoryOverviewHtml</div>
  <h2>Detailed Results</h2>
  <div class="tabs">$tabsNavHtml</div>
  $tabsPanesHtml
  <footer>Generated by ARG-Kit &middot; $generatedAt</footer>
</div>
$tabScript
</body>
</html>
"@

    $parentPath = Split-Path -Path $OutputPath -Parent
    if ($parentPath -and -not (Test-Path -Path $parentPath)) {
        New-Item -Path $parentPath -ItemType Directory -Force | Out-Null
    }

    Set-Content -Path $OutputPath -Value $fullHtml -Encoding UTF8
    Write-Verbose "Overview report generated at: $OutputPath"

    Write-Host "   Report saved to " -NoNewline -ForegroundColor Cyan
    Write-ArgLine $OutputPath 'White'
    if (-not $OpenReport) {
        Write-ArgLine "   Tip: re-run with -OpenReport to open it automatically." 'DarkGray'
    }
    Write-Host ''

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
