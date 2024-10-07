<#
    .SYNOPSIS
        Validates the param-block parentheses and new lines around parentheses.

    .DESCRIPTION
        Each param-block should have the opening parentheses on the same line if empty.
        If the param-block has values then the parentheses should be on a new line.

    .EXAMPLE
        Measure-ParamBlock -ParamBlockAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.ParamBlockAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

    .NOTES
        None
#>
function Measure-ParamBlock
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ParamBlockAst]
        $ParamBlockAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $ParamBlockAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $testParameters = @{
            StatementBlock = $ParamBlockAst.Extent
        }

        if ($ParamBlockAst.Parameters)
        {
            if (Test-StatementOpeningParenthsesOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $script:localizedData.ParamBlockNotEmptyParenthesesShouldBeOnNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
        else
        {
            if (-not (Test-StatementOpeningParenthsesOnSameLine @testParameters))
            {
                $script:diagnosticRecord['Message'] = $script:localizedData.ParamBlockEmptyParenthesesShouldBeOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementEmptyParenthsesHasWhitespace @testParameters)
            {
                $script:diagnosticRecord['Message'] = $script:localizedData.ParamBlockEmptyParenthesesShouldNotHaveWhitespace
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
