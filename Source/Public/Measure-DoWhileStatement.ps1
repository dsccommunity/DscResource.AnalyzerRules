
<#
    .SYNOPSIS
        Validates the DoWhile-statement block braces and new lines around braces.

    .DESCRIPTION
        Each DoWhile-statement should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-DoWhileStatement -DoWhileStatementAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.DoWhileStatementAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-DoWhileStatement
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.DoWhileStatementAst]
        $DoWhileStatementAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $DoWhileStatementAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $testParameters = @{
            StatementBlock = $DoWhileStatementAst.Extent
        }

        if (Test-StatementOpeningBraceOnSameLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.DoWhileStatementOpeningBraceNotOnSameLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.DoWhileStatementOpeningBraceShouldBeFollowedByNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.DoWhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}