<#
    .SYNOPSIS
        Validates all hashtables.

    .DESCRIPTION
        Hashtables should have the correct format

    .EXAMPLE
        PS C:\> Measure-Hashtable -HashtableAst $HashtableAst

    .INPUTS
        [System.Management.Automation.Language.HashtableAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

    .NOTES
        None
#>
function Measure-Hashtable
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.HashtableAst[]]
        $HashtableAst
    )

    try
    {
        foreach ($hashtable in $HashtableAst)
        {
            # Empty hashtables should be ignored
            if ($hashtable.extent.Text -eq '@{}' -or $hashtable.extent.Text -eq '@{ }')
            {
                continue
            }

            $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

            $hashtableLines = $hashtable.Extent.Text -split '\n'

            # Hashtable should start with '@{' and end with '}'
            if ($hashtableLines[0] -notmatch '@{\r' -or $hashtableLines[-1] -notmatch '\s*}')
            {
                $script:diagnosticRecord['Extent'] = $hashtable.Extent
                $script:diagnosticRecord['Message'] = $localizedData.HashtableShouldHaveCorrectFormat
                $script:diagnosticRecord -as $diagnosticRecordType
            }
            else
            {
                # We alredy checked that the first line is correctly formatted. Getting the starting indentation here
                $initialIndent = ([regex]::Match($hashtable.Extent.StartScriptPosition.Line, '(\s*)')).Length
                $expectedLineIndent = $initialIndent + 5

                foreach ($keyValuePair in $hashtable.KeyValuePairs)
                {
                    if ($keyValuePair.Item1.Extent.StartColumnNumber -ne $expectedLineIndent)
                    {
                        $script:diagnosticRecord['Extent'] = $hashtable.Extent
                        $script:diagnosticRecord['Message'] = $localizedData.HashtableShouldHaveCorrectFormat
                        $script:diagnosticRecord -as $diagnosticRecordType
                        break
                    }
                }
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
