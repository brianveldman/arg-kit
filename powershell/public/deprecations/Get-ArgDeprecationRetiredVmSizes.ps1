function Get-ArgDeprecationRetiredVmSizes {
    $query = @"
Resources
| where type =~ 'microsoft.compute/virtualmachines'
| extend vmSizeRaw = tostring(properties.hardwareProfile.vmSize)
| extend vmSize = tolower(vmSizeRaw)
| extend retiredSeries = case(
    vmSize matches regex @'^standard_ds\d+(-\d+)?_v2$', 'Dsv2-series',
    vmSize matches regex @'^standard_d\d+(-\d+)?_v2$', 'Dv2-series',
    vmSize matches regex @'^standard_ds\d+(-\d+)?$', 'Ds-series',
    vmSize matches regex @'^standard_d\d+(-\d+)?$', 'D-series',
    vmSize matches regex @'^standard_a\d+m?_v2$', 'Av2/Amv2-series',
    vmSize matches regex @'^standard_b\d+[lm]*s$', 'B-series (V1)',
    vmSize matches regex @'^standard_f\d+(-\d+)?s_v2$', 'Fsv2-series',
    vmSize matches regex @'^standard_f\d+s$', 'Fs-series',
    vmSize matches regex @'^standard_f\d+$', 'F-series',
    vmSize matches regex @'^standard_gs\d+(-\d+)?$', 'Gs-series',
    vmSize matches regex @'^standard_g\d+$', 'G-series',
    vmSize matches regex @'^standard_m192i[dm]*s_v2$', 'Msv2/Mdsv2 (M192)',
    vmSize matches regex @'^standard_l\d+s_v2$', 'Lsv2-series',
    vmSize matches regex @'^standard_l\d+s$', 'Ls-series',
    vmSize matches regex @'^standard_nc\d+r?s_v3$', 'NCv3-series',
    vmSize matches regex @'^standard_nv\d+s_v3$', 'NVv3-series',
    vmSize matches regex @'^standard_nv\d+as_v4$', 'NVv4-series',
    vmSize matches regex @'^standard_np\d+s$', 'NP-series',
    ''
  )
| where isnotempty(retiredSeries)
| extend retirementStatus = iff(retiredSeries == 'NCv3-series', 'Retired', 'Announced')
| extend plannedRetirementDate = case(
    retiredSeries in ('D-series', 'Ds-series', 'Dv2-series', 'Dsv2-series', 'Ls-series'), '2028-05-01',
    retiredSeries in ('Av2/Amv2-series', 'B-series (V1)', 'F-series', 'Fs-series', 'Fsv2-series', 'G-series', 'Gs-series', 'Lsv2-series'), '2028-11-15',
    retiredSeries == 'Msv2/Mdsv2 (M192)', '2027-03-31',
    retiredSeries in ('NVv3-series', 'NVv4-series'), '2026-09-30',
    retiredSeries == 'NCv3-series', '2025-09-30',
    retiredSeries == 'NP-series', '2027-05-31',
    'See retired sizes list'
  )
| project name, resourceGroup, location, subscriptionId, vmSize = vmSizeRaw, retiredSeries, retirementStatus, plannedRetirementDate, id
| sort by plannedRetirementDate asc, name asc
"@
    Search-AzGraph -Query $query
}
