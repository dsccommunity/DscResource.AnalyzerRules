
<#
    .SYNOPSIS
        Validates the catch-clause block braces and new lines around braces.

    .DESCRIPTION
        Each catch-clause should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .PARAMETER CatchClauseAst
        AST Block used to evaluate the rule

    .EXAMPLE
        Measure-CatchClause -CatchClauseAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.CatchClauseAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-CatchClause
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.CatchClauseAst]
        $CatchClauseAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $CatchClauseAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $testParameters = @{
            StatementBlock = $CatchClauseAst.Extent
        }

        if (Test-StatementOpeningBraceOnSameLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.CatchClauseOpeningBraceNotOnSameLine
            $script:diagnosticRecord -as $diagnosticRecordType
        }

        if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.CatchClauseOpeningBraceShouldBeFollowedByNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.CatchClauseOpeningBraceShouldBeFollowedByOnlyOneNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
