<#
    .SYNOPSIS
        Helper function for the Test-Statement* helper functions.
        Returns the extent text as an array of strings.

    .EXAMPLE
        Get-StatementBlockAsRow -StatementBlock $ScriptBlockAst.Extent

    .INPUTS
        [System.String]

    .OUTPUTS
        [System.String[]]

   .NOTES
        None
#>
function Get-StatementBlockAsRow
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $StatementBlock
    )

    <#
        Remove carriage return since the file is different depending if it's run in
        AppVeyor or locally. Locally it contains both '\r\n', but when cloned in
        AppVeyor it only contains '\n'.
    #>
    $statementBlockWithNewLine = $StatementBlock -replace '\r', ''
    return $statementBlockWithNewLine -split '\n'
}