function Get-ArgOverviewReport {
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Orphaned', 'Security', 'Cost', 'Policy', 'Updates', 'Deprecations', 'Monitor')]
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

    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path (Get-Location) -ChildPath ("arg-kit-overview-{0:yyyyMMdd-HHmmss}.html" -f (Get-Date))
    }

    $summaryRows = @()
    $detailSectionsByCategory = [ordered]@{}
    foreach ($cat in $selectedCategories) {
        $detailSectionsByCategory[$cat] = @()
    }

    $totalCheckCount = 0
    foreach ($cat in $selectedCategories) {
        $totalCheckCount += $categoryChecks[$cat].Count
    }
    $completedChecks = 0

    foreach ($currentCategory in $selectedCategories) {
        foreach ($checkName in $categoryChecks[$currentCategory]) {
            $completedChecks++
            $percent = if ($totalCheckCount -gt 0) { [int](($completedChecks / $totalCheckCount) * 100) } else { 0 }
            Write-Progress -Activity "Generating ARG overview report" `
                -Status "[$completedChecks/$totalCheckCount] $currentCategory - $checkName" `
                -CurrentOperation "Running $checkName" `
                -PercentComplete $percent

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

            $resultCount = if ($resultData -is [array]) {
                $resultData.Count
            } elseif ($null -eq $resultData) {
                0
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

            $safeCheckName = [System.Net.WebUtility]::HtmlEncode($checkName)
            $safeCategory = [System.Net.WebUtility]::HtmlEncode($currentCategory)

            if ($status -eq 'Error') {
                $safeErrorMessage = [System.Net.WebUtility]::HtmlEncode($errorMessage)
                $badge = "<span class='badge badge-error'>Error</span>"
                $bodyHtml = "<p class='error'>$safeErrorMessage</p>"
            } elseif ($resultCount -eq 0) {
                $badge = "<span class='badge badge-clear'>Clear</span>"
                $bodyHtml = "<p class='muted'>No results returned.</p>"
            } else {
                $badge = "<span class='badge badge-findings'>$resultCount</span>"
                $bodyHtml = "<div class='table-wrap'>$($resultData | ConvertTo-Html -Fragment)</div>"
            }

            $detailSectionsByCategory[$currentCategory] += @"
<section class="card">
  <div class="card-head">
    <div>
      <span class="card-category">$safeCategory</span>
      <h3>$safeCheckName</h3>
    </div>
    $badge
  </div>
  $bodyHtml
</section>
"@
        }
    }

    Write-Progress -Activity "Generating ARG overview report" -Completed

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
  --bg: #0f172a;
  --panel: #ffffff;
  --muted: #64748b;
  --border: #e2e8f0;
  --accent: #2563eb;
  --accent-soft: #eff6ff;
  --error: #dc2626;
  --error-soft: #fef2f2;
  --ok: #16a34a;
  --ok-soft: #f0fdf4;
  --warn: #d97706;
}
* { box-sizing: border-box; }
body {
  font-family: 'Segoe UI', system-ui, -apple-system, Arial, sans-serif;
  margin: 0;
  background: #f1f5f9;
  color: #1e293b;
  line-height: 1.5;
}
.wrap { max-width: 1200px; margin: 0 auto; padding: 32px 24px 64px; }
header.hero {
  background: linear-gradient(135deg, #1e293b 0%, #2563eb 100%);
  color: #fff;
  padding: 40px 24px;
}
header.hero .inner { max-width: 1200px; margin: 0 auto; }
header.hero h1 { margin: 0 0 8px; font-size: 28px; font-weight: 700; letter-spacing: -0.02em; }
header.hero .meta { font-size: 14px; opacity: 0.85; display: flex; flex-wrap: wrap; gap: 20px; }
header.hero .meta span strong { font-weight: 600; }
.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin: -32px auto 40px; max-width: 1200px; padding: 0 24px; position: relative; }
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
.stat.findings .value { color: var(--accent); }
h2 { font-size: 20px; font-weight: 700; margin: 40px 0 16px; color: #0f172a; }
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
tbody tr:hover { background: #f8fafc; }
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
.badge { font-size: 13px; font-weight: 700; padding: 4px 12px; border-radius: 999px; white-space: nowrap; }
.badge-error { background: var(--error-soft); color: var(--error); }
.badge-clear { background: var(--ok-soft); color: var(--ok); }
.badge-findings { background: var(--accent-soft); color: var(--accent); }
.error { color: var(--error); font-weight: 500; }
.muted { color: var(--muted); }
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
    $totalFindings = ($summaryRows | Measure-Object -Property ResultCount -Sum).Sum
    if (-not $totalFindings) { $totalFindings = 0 }

    $categoryOverviewHtml = $categoryOverview | ConvertTo-Html -Fragment
    $summaryHtml = $summaryRows | ConvertTo-Html -Fragment

    $tabButtons = @()
    $tabPanes = @()
    $tabIndex = 0
    foreach ($cat in $detailSectionsByCategory.Keys) {
        $safeCat = [System.Net.WebUtility]::HtmlEncode([string]$cat)
        $tabId = "tab-$tabIndex"
        $catFindings = ($summaryRows | Where-Object { $_.Category -eq $cat } | Measure-Object -Property ResultCount -Sum).Sum
        if (-not $catFindings) { $catFindings = 0 }
        $activeClass = if ($tabIndex -eq 0) { ' active' } else { '' }
        $tabButtons += "<button class='tab-btn$activeClass' data-tab='$tabId'>$safeCat<span class='count'>$catFindings</span></button>"

        $paneBody = $detailSectionsByCategory[$cat] -join "`n"
        if (-not $paneBody) { $paneBody = "<p class='muted'>No checks in this category.</p>" }
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
  <div class="stat findings"><div class="value">$totalFindings</div><div class="label">Total Findings</div></div>
  <div class="stat error"><div class="value">$totalFailed</div><div class="label">Failed Checks</div></div>
</div>
<div class="wrap">
  <h2>Category Overview</h2>
  <div class="panel">$categoryOverviewHtml</div>
  <h2>Check Summary</h2>
  <div class="panel">$summaryHtml</div>
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
