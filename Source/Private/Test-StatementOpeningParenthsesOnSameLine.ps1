
<#
    .SYNOPSIS
        Helper function for the Measure-*Block PSScriptAnalyzer rules.
        Test a single statement block for opening parentheses on the same line.

    .EXAMPLE
        Test-StatementOpeningParenthsesOnSameLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

    .NOTES
        None
#>

function Test-StatementOpeningParenthsesOnSameLine
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StatementBlock
    )

    [System.String[]] $statementBlockRows = Get-StatementBlockAsRow -StatementBlock $StatementBlock
    if ($statementBlockRows.Count)
    {

        # Check so that an opening brace does not exist on the same line as the statement.
        if ($statementBlockRows[0] -match '\(')
        {
            return $true
        } # if
    } # if

    return $false
}
