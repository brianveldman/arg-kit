function Get-ArgMonitorActiveServiceHealthAlerts {
    $query = @"
servicehealthresources
| where type =~ 'Microsoft.ResourceHealth/events'
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = properties.ImpactMitigationTime
| where (eventType in ('HealthAdvisory', 'SecurityAdvisory', 'PlannedMaintenance') and impactMitigationTime > now()) or (eventType == 'ServiceIssue' and status == 'Active')
"@
    Search-AzGraph -Query $query
}
