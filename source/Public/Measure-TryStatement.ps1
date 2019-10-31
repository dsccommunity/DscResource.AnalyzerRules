<#
    .SYNOPSIS
        Validates the try-statement block braces and new lines around braces.

    .DESCRIPTION
        Each try-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-TryStatement -TryStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.TryStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-TryStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.TryStatementAst]
        $TryStatementAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $TryStatementAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $testParameters = @{
            StatementBlock = $TryStatementAst.Extent
        }

        if (Test-StatementOpeningBraceOnSameLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.TryStatementOpeningBraceNotOnSameLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.TryStatementOpeningBraceShouldBeFollowedByNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.TryStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
