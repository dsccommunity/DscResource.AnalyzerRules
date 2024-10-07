
<#
    .SYNOPSIS
        Helper function for the Measure-*Block PSScriptAnalyzer rules.
        Test a single statement block for whitespace inside the parentheses.

    .EXAMPLE
        Test-StatementEmptyParenthsesHasWhitespace -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

    .NOTES
        None
#>

function Test-StatementEmptyParenthsesHasWhitespace
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

    # Check that the parentheses does not contain whitespace.
    if ($statementBlock -match '\(\s+\)')
    {
        return $true
    } # if

    return $false
}
