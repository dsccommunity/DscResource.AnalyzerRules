<#
    .SYNOPSIS
        Creates a suggested correction
    .PARAMETER Extent
        The extent that needs correction
    .PARAMETER NewString
        The string that should replace the extent
    .PARAMETER Description
        The description that should be shown
    .OUTPUTS
        Output (if any)
#>
function New-SuggestedCorrection
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'None')]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.IScriptExtent]
        $Extent,

        [Parameter()]
        [System.String]
        $NewString,

        [Parameter()]
        [System.String]
        $Description
    )

    if ($PSCmdlet.ShouldProcess("Create correction extent"))
    {
        [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]::new(
            $Extent.StartLineNumber,
            $Extent.EndLineNumber,
            $Extent.StartColumnNumber,
            $Extent.EndColumnNumber,
            $NewString,
            $Extent.File,
            $Description
        )
    }
}
