
<#
    .SYNOPSIS
        Validates the function block braces and new lines around braces.

    .DESCRIPTION
        Each function should have the opening brace on a separate line.
        Also, the opening brace should be followed by a new line.

    .EXAMPLE
        Measure-FunctionBlockBraces -FunctionDefinitionAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.FunctionDefinitionAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-FunctionBlockBraces
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.FunctionDefinitionAst]
        $FunctionDefinitionAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $FunctionDefinitionAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $testParameters = @{
            StatementBlock = $FunctionDefinitionAst.Extent
        }

        if (Test-StatementOpeningBraceOnSameLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.FunctionOpeningBraceNotOnSameLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.FunctionOpeningBraceShouldBeFollowedByNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if

        if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
        {
            $script:diagnosticRecord['Message'] = $localizedData.FunctionOpeningBraceShouldBeFollowedByOnlyOneNewLine
            $script:diagnosticRecord -as $diagnosticRecordType
        } # if
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}