function Get-ArgLinuxUpdateInstallations {
    $query = @"
patchinstallationresources
| where type has "softwarepatches" and isnotnull(properties.version) and isnull(properties.kbId)
| extend machineName = tostring(split(id, "/", 8)), resourceType = tostring(split(type, "/", 0)), tostring(rgName = split(id, "/", 4)), tostring(RunID = split(id, "/", 10))
| extend prop = parse_json(properties)
| extend lTime = todatetime(prop.lastModifiedDateTime), patchName = tostring(prop.patchName), version = tostring(prop.version), installationState = tostring(prop.installationState), classifications = tostring(prop.classifications)
| where lTime > ago(7d)
| project lTime, RunID, machineName, rgName, resourceType, patchName, version, classifications, installationState
| sort by RunID
"@
    Search-AzGraph -Query $query
}
