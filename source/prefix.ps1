#Requires -Version 4.0

$script:diagnosticRecordType = [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]
$script:diagnosticRecord = @{
    Message  = ''
    Extent   = $null
    RuleName = $null
    Severity = 'Warning'
}
