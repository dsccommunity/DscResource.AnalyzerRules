<#
    .SYNOPSIS
        Helper function to return tokens,
        to be able to test custom rules.

    .PARAMETER ScriptDefinition
        The script definition to return ast for.
#>
function Get-TokensFromDefinition
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.Token[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScriptDefinition
    )

    $parseErrors = $token = $null
    $definitionAst = [System.Management.Automation.Language.Parser]::ParseInput($ScriptDefinition, [ref] $token, [ref] $parseErrors)

    if ($parseErrors)
    {
        throw $parseErrors
    }

    return $token
}
