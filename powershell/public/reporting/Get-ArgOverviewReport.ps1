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
            'Get-ArgDeprecationP2SEntraManualVpnGateways',
            'Get-ArgDeprecationRetiredVmSizes'
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
        'Get-ArgDeprecationRetiredVmSizes'              = 'VMs on Retired/Retiring Size Series'
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
  --bg: #0a0d15;
  --bg-soft: #0d111c;
  --panel: #121826;
  --panel-hover: #161d2e;
  --muted: #8a94a7;
  --faint: #596273;
  --border: #212a3b;
  --border-soft: #1a2231;
  --text: #e8ecf4;
  --heading: #f4f7fc;
  --accent: #8ea2ff;
  --accent-2: #a78bfa;
  --accent-soft: rgba(142,162,255,0.14);
  --error: #f47174;
  --error-soft: rgba(244,113,116,0.14);
  --ok: #48d19a;
  --ok-soft: rgba(72,209,154,0.14);
  --warn: #f5b544;
  --warn-soft: rgba(245,181,68,0.14);
  --shadow: 0 8px 30px rgba(0,0,0,0.28);
}
* { box-sizing: border-box; }
html { -webkit-font-smoothing: antialiased; text-rendering: optimizeLegibility; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Inter, Roboto, Helvetica, Arial, sans-serif;
  margin: 0;
  background: var(--bg);
  background-image: radial-gradient(1200px 600px at 80% -200px, rgba(142,162,255,0.10), transparent 60%);
  color: var(--text);
  line-height: 1.55;
  font-size: 15px;
}
.num { font-variant-numeric: tabular-nums; font-feature-settings: 'tnum' 1; }
.wrap { max-width: 1160px; margin: 0 auto; padding: 8px 28px 72px; }
.wrap > section:first-of-type { margin-top: 4px; }

header.hero {
  position: relative;
  overflow: hidden;
  padding: 44px 28px 56px;
  border-bottom: 1px solid var(--border-soft);
  background:
    radial-gradient(900px 400px at 12% -160px, rgba(167,139,250,0.16), transparent 65%),
    linear-gradient(180deg, #0d1220 0%, var(--bg) 100%);
}
header.hero .inner { max-width: 1160px; margin: 0 auto; position: relative; }
.brand { display: flex; align-items: center; gap: 14px; margin-bottom: 22px; }
.brand .mark {
  width: 40px; height: 40px; border-radius: 11px;
  display: grid; place-items: center;
  font-weight: 700; font-size: 15px; letter-spacing: 0.02em; color: #0b0e16;
  background: linear-gradient(140deg, var(--accent) 0%, var(--accent-2) 100%);
  box-shadow: 0 6px 18px rgba(142,162,255,0.35);
}
.brand .eyebrow { font-size: 12px; letter-spacing: 0.18em; text-transform: uppercase; color: rgba(255,255,255,0.6); font-weight: 600; }
header.hero h1 { margin: 0; font-size: 30px; font-weight: 700; letter-spacing: -0.03em; color: #ffffff; }
header.hero .lede { margin: 8px 0 0; color: rgba(255,255,255,0.72); font-size: 15px; max-width: 620px; }
.meta { margin-top: 24px; display: flex; flex-wrap: wrap; gap: 10px 28px; font-size: 13.5px; }
.meta .k { color: rgba(255,255,255,0.5); text-transform: uppercase; letter-spacing: 0.08em; font-size: 11px; font-weight: 600; margin-right: 8px; }
.meta .v { color: #ffffff; }

.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 14px; margin: -32px auto 0; max-width: 1160px; padding: 0 28px; position: relative; z-index: 2; }
.stat {
  background: linear-gradient(180deg, var(--panel) 0%, var(--bg-soft) 100%);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 20px 22px;
  box-shadow: var(--shadow);
}
.stat .value { font-size: 34px; font-weight: 700; line-height: 1; letter-spacing: -0.02em; color: var(--heading); }
.stat .label { font-size: 12px; color: var(--muted); margin-top: 8px; text-transform: uppercase; letter-spacing: 0.09em; font-weight: 600; }
.stat.error .value { color: var(--error); }
.stat.ok .value { color: var(--ok); }
.stat.findings .value { color: var(--accent); }

section { margin-top: 44px; }
.section-head { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; margin-bottom: 4px; }
h2 { font-size: 13px; font-weight: 700; margin: 0; color: var(--muted); text-transform: uppercase; letter-spacing: 0.12em; }
.section-intro { color: var(--muted); font-size: 14px; margin: 6px 0 20px; max-width: 640px; }

.panel {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 16px;
  overflow: hidden;
  box-shadow: var(--shadow);
}
.panel.pad { padding: 6px 4px; }
.panel .scroll { overflow-x: auto; }

table { border-collapse: collapse; width: 100%; font-size: 14px; }
thead th {
  color: var(--faint); font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: 0.08em;
  padding: 14px 18px; text-align: left; border-bottom: 1px solid var(--border);
  background: rgba(255,255,255,0.015);
}
tbody td { padding: 13px 18px; text-align: left; vertical-align: top; border-bottom: 1px solid var(--border-soft); color: var(--text); }
tbody tr:last-child td { border-bottom: none; }
tbody tr { transition: background 0.12s ease; }
tbody tr:hover { background: rgba(142,162,255,0.05); }
td.right, th.right { text-align: right; }
tr.row-error td { color: var(--error); }
.pill { display: inline-block; font-size: 12px; font-weight: 600; padding: 2px 10px; border-radius: 999px; }
.pill.zero { color: var(--faint); background: rgba(255,255,255,0.04); }
.pill.count { color: var(--accent); background: var(--accent-soft); }
.pill.bad { color: var(--error); background: var(--error-soft); }

.badge { font-size: 12px; font-weight: 600; padding: 4px 12px; border-radius: 999px; white-space: nowrap; }
.badge-clear { background: var(--ok-soft); color: var(--ok); }
.error { color: var(--error); font-weight: 500; }
.muted { color: var(--muted); }

.focus-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 14px; }
.focus-card {
  position: relative;
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 20px 22px;
  box-shadow: var(--shadow);
  transition: transform 0.14s ease, border-color 0.14s ease, background 0.14s ease;
}
.focus-card:hover { transform: translateY(-2px); background: var(--panel-hover); }
.focus-head { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
.focus-cat { display: flex; align-items: center; gap: 9px; font-size: 12.5px; color: var(--text); text-transform: uppercase; letter-spacing: 0.08em; font-weight: 600; }
.dot { width: 8px; height: 8px; border-radius: 50%; background: var(--border); flex: none; }
.focus-card.level-high .dot { background: var(--error); box-shadow: 0 0 0 4px var(--error-soft); }
.focus-card.level-medium .dot { background: var(--warn); box-shadow: 0 0 0 4px var(--warn-soft); }
.focus-card.level-low .dot { background: var(--accent); box-shadow: 0 0 0 4px var(--accent-soft); }
.focus-card.level-clear .dot { background: var(--ok); box-shadow: 0 0 0 4px var(--ok-soft); }
.focus-card.level-clear { opacity: 0.72; }
.focus-total { font-size: 34px; font-weight: 700; line-height: 1; letter-spacing: -0.02em; color: var(--heading); }
.focus-sub { font-size: 11.5px; color: var(--muted); text-transform: uppercase; letter-spacing: 0.08em; margin-top: 8px; }

.tabs { display: flex; flex-wrap: wrap; gap: 4px; margin: 4px 0 18px; }
.tab-btn {
  background: transparent; border: 1px solid transparent;
  padding: 8px 15px; font-size: 13.5px; font-weight: 600; color: var(--muted);
  cursor: pointer; border-radius: 10px; transition: all 0.14s ease;
  display: inline-flex; align-items: center; gap: 8px;
}
.tab-btn:hover { color: var(--text); background: rgba(255,255,255,0.03); }
.tab-btn.active { color: var(--heading); background: var(--accent-soft); border-color: rgba(142,162,255,0.25); }
.tab-btn .count { font-size: 11px; color: var(--faint); font-weight: 700; background: rgba(255,255,255,0.05); padding: 1px 8px; border-radius: 999px; }
.tab-btn.active .count { color: var(--accent); background: rgba(142,162,255,0.16); }
.tab-pane { display: none; }
.tab-pane.active { display: block; }
.tab-pane.active.anim { animation: fade 0.2s ease; }
@keyframes fade { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: none; } }
.empty { padding: 40px 24px; text-align: center; color: var(--muted); }
.empty .big { color: var(--ok); font-size: 15px; font-weight: 600; margin-bottom: 4px; }

footer { text-align: center; color: var(--faint); font-size: 12.5px; margin-top: 56px; padding-top: 24px; border-top: 1px solid var(--border-soft); }
footer .accent { color: var(--muted); font-weight: 600; }
</style>
"@

    $generatedAt = Get-Date
    $generatedDisplay = $generatedAt.ToString('dddd d MMMM yyyy · HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
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
            $failedNote = if ($focus.Failed -gt 0) { "<p class='error'>$($focus.Failed) check(s) couldn't run.</p>" } else { '' }
            @"
<div class="focus-card level-$level">
  <div class="focus-head">
    <span class="focus-cat"><span class="dot"></span>$safeCat</span>
    <span class="focus-total num">$($focus.Findings)</span>
  </div>
  <div class="focus-sub">to review</div>
  $failedNote
</div>
"@
        } else {
            $failedNote = if ($focus.Failed -gt 0) { "<p class='error'>$($focus.Failed) check(s) couldn't run.</p>" } else { "<div class='focus-sub'>nothing to review</div>" }
            @"
<div class="focus-card level-clear">
  <div class="focus-head">
    <span class="focus-cat"><span class="dot"></span>$safeCat</span>
    <span class="badge badge-clear">Clear</span>
  </div>
  $failedNote
</div>
"@
        }
    }

    $improvementsHtml = @"
<section>
<div class="section-head"><h2>Where to focus</h2></div>
<p class="section-intro">Ranked by how much is waiting for you. The bigger the number, the more there is to clean up, save, or secure.</p>
<div class="focus-grid">
$($focusCards -join "`n")
</div>
</section>
"@

    $tabButtons = @()
    $tabPanes = @()
    $tabIndex = 0
    foreach ($cat in $categoryRowsByCategory.Keys) {
        $safeCat = [System.Net.WebUtility]::HtmlEncode([string]$cat)
        $tabId = "tab-$tabIndex"
        $catFindings = ($summaryRows | Where-Object { $_.Category -eq $cat } | Measure-Object -Property ResultCount -Sum).Sum
        if (-not $catFindings) { $catFindings = 0 }
        $activeClass = if ($tabIndex -eq 0) { ' active' } else { '' }
        $tabButtons += "<button class='tab-btn$activeClass' data-tab='$tabId'>$safeCat<span class='count num'>$catFindings</span></button>"

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
<div class="panel">
  <div class="scroll">
  <table>
    <thead><tr><th>Check</th><th>Resource</th><th>Resource Group</th><th>Location</th><th>Details</th></tr></thead>
    <tbody>
$($tableRows -join "`n")
    </tbody>
  </table>
  </div>
</div>
"@
        } else {
            $paneBody = "<div class='panel'><div class='empty'><div class='big'>All clear</div>Nothing to review in this category.</div></div>"
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
      document.querySelectorAll('.tab-pane').forEach(function (p) { p.classList.remove('active'); p.classList.remove('anim'); });
      btn.classList.add('active');
      var pane = document.getElementById(target);
      if (pane) { pane.classList.add('active'); pane.classList.add('anim'); }
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
    <div class="brand">
      <span class="mark">AK</span>
      <span class="eyebrow">Azure Resource Graph</span>
    </div>
    <h1>Overview Report</h1>
    <p class="lede">A quick read on what's healthy across your environment and where a little attention goes a long way.</p>
    <div class="meta">
      <span><span class="k">Generated</span><span class="v">$generatedDisplay</span></span>
      <span><span class="k">Account</span><span class="v">$accountName</span></span>
      <span><span class="k">Subscription</span><span class="v">$subscriptionName</span></span>
    </div>
  </div>
</header>
<div class="stats">
  <div class="stat"><div class="value num">$totalChecks</div><div class="label">Checks run</div></div>
  <div class="stat ok"><div class="value num">$totalPassed</div><div class="label">Passed</div></div>
  <div class="stat error"><div class="value num">$totalFailed</div><div class="label">Failed</div></div>
  <div class="stat findings"><div class="value num">$totalImprovements</div><div class="label">Areas to improve</div></div>
</div>
<div class="wrap">
  $improvementsHtml
  <section>
    <div class="section-head"><h2>Detailed results</h2></div>
    <div class="tabs">$tabsNavHtml</div>
    $tabsPanesHtml
  </section>
  <footer>Generated with <span class="accent">ARG-Kit</span> &middot; $generatedDisplay</footer>
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
