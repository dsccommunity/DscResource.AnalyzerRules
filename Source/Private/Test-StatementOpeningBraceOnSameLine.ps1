
<#
    .SYNOPSIS
        Helper function for the Measure-*Statement PSScriptAnalyzer rules.
        Test a single statement block for opening brace on the same line.

    .EXAMPLE
        Test-StatementOpeningBraceOnSameLine -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.Boolean]

   .NOTES
        None
#>
function Test-StatementOpeningBraceOnSameLine
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
    if ($statementBlockRows.Count)
    {
        # Check so that an opening brace does not exist on the same line as the statement.
        if ($statementBlockRows[0] -match '{[\s]*$')
        {
            return $true
        } # if
    } # if

    return $false
}
