
<#
    .SYNOPSIS
        Helper function for the Measure-*Statement PSScriptAnalyzer rules.
        Test a single statement block for new line after opening brace.

    .EXAMPLE
        Test-StatementOpeningBraceIsNotFollowedByNewLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

   .NOTES
        None
#>
function Test-StatementOpeningBraceIsNotFollowedByNewLine
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

    $statementBlockRows = Get-StatementBlockAsRow -StatementBlock $StatementBlock
    if ($statementBlockRows.Count -ge 2)
    {
        # Check so that an opening brace is followed by a new line.
        if ($statementBlockRows[1] -match '\{.+')
        {
            return $true
        } # if
    } # if

    return $false
}