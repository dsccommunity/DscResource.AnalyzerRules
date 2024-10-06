
<#
    .SYNOPSIS
        Helper function for the Measure-*Statement PSScriptAnalyzer rules.
        Test a single statement block for only one new line after opening brace.

    .EXAMPLE
        Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

    .NOTES
        None
#>
function Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine
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
    if ($statementBlockRows.Count -ge 3)
    {
        # Check so that an opening brace is followed by only one new line.
        if (-not $statementBlockRows[2].Trim())
        {
            return $true
        } # if
    } # if

    return $false
}
