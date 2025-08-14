function Get-ArgMonitorAlertsLast2Hours {
    $query = @"
alertsmanagementresources
| where type =~ 'microsoft.alertsmanagement/alerts'   
| where todatetime(properties.essentials.startDateTime) >= ago(2h) and todatetime(properties.essentials.startDateTime) < now()  
| project Severity = tostring(properties.essentials.severity),  
MonitorCondition = tostring(properties.essentials.monitorCondition),  
ObjectState = tostring(properties.essentials.alertState),  
MonitorService = tostring(properties.essentials.monitorService),  
AlertRuleId = tostring(properties.essentials.alertRule),  
SignalType = tostring(properties.essentials.signalType),  
TargetResource = tostring(properties.essentials.targetResourceName), 
TargetResourceType = tostring(properties.essentials.targetResourceName), id 
| summarize AlertsCount = count() by Severity, MonitorService , TargetResourceType
"@
    Search-AzGraph -Query $query
}
