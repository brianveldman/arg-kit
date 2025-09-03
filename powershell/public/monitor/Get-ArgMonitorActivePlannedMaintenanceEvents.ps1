function Get-ArgMonitorActivePlannedMaintenanceEvents {
    $query = @"
servicehealthresources
| where type =~ 'Microsoft.ResourceHealth/events'
| extend eventType = properties.EventType, status = properties.Status, description = properties.Title, trackingId = properties.TrackingId, summary = properties.Summary, priority = properties.Priority, impactStartTime = properties.ImpactStartTime, impactMitigationTime = todatetime(tolong(properties.ImpactMitigationTime))
| where eventType == 'PlannedMaintenance' and impactMitigationTime > now()
"@
    Search-AzGraph -Query $query
}
