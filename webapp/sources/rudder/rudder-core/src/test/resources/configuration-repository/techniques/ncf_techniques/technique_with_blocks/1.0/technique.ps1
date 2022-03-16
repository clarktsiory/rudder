# generated by rudderc
# @name technique with blocks
# @version 1.0

function Technique-With-Blocks {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$True)]
    [String]$ReportId,
    [Parameter(Mandatory=$True)]
    [String]$TechniqueName,
    [Switch]$AuditOnly
  )

  $LocalClasses = New-ClassContext
  $ResourcesDir = $PSScriptRoot + "\resources"
  _rudder_common_report_na -ComponentName "File absent" -ComponentKey "/tmp/block1" -Report $true -Message "Not applicable" -ReportId $ReportId -TechniqueName $TechniqueName -AuditOnly:$AuditOnly
  _rudder_common_report_na -ComponentName "File absent" -ComponentKey "/tmp/block1_1" -Report $true -Message "Not applicable" -ReportId $ReportId -TechniqueName $TechniqueName -AuditOnly:$AuditOnly
  _rudder_common_report_na -ComponentName "Command execution" -ComponentKey "/bin/true" -Report $true -Message "Not applicable" -ReportId $ReportId -TechniqueName $TechniqueName -AuditOnly:$AuditOnly
  _rudder_common_report_na -ComponentName "Command execution" -ComponentKey "/bin/true #root1" -Report $true -Message "Not applicable" -ReportId $ReportId -TechniqueName $TechniqueName -AuditOnly:$AuditOnly
  _rudder_common_report_na -ComponentName "File absent" -ComponentKey "/tmp/root2" -Report $true -Message "Not applicable" -ReportId $ReportId -TechniqueName $TechniqueName -AuditOnly:$AuditOnly
}
