<#
    .SYNOPSIS
        Validates all keywords.

    .DESCRIPTION
        Each keyword should be in all lower case.

    .EXAMPLE
        Measure-Keyword -Token $Token

    .INPUTS
        [System.Management.Automation.Language.Token[]]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-Keyword
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Token[]]
        $Token
    )

    try
    {
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $keywordsToIgnore = @('configuration')
        $keywordFlag = [System.Management.Automation.Language.TokenFlags]::Keyword
        $keywords = $Token.Where{ $_.TokenFlags.HasFlag($keywordFlag) -and
            $_.Kind -ne 'DynamicKeyword' -and
            $keywordsToIgnore -notContains $_.Text
        }
        $upperCaseTokens = $keywords.Where{ $_.Text -cMatch '[A-Z]+' }

        $tokenWithNoSpace = $keywords.Where{ $_.Extent.StartScriptPosition.Line -match "$($_.Extent.Text)\(.*" }

        foreach ($item in $upperCaseTokens)
        {
            $script:diagnosticRecord['Extent'] = $item.Extent
            $script:diagnosticRecord['Message'] = $localizedData.StatementsContainsUpperCaseLetter -f $item.Text
            $script:diagnosticRecord -as $diagnosticRecordType
        }

        foreach ($item in $tokenWithNoSpace)
        {
            $script:diagnosticRecord['Extent'] = $item.Extent
            $script:diagnosticRecord['Message'] = $localizedData.OneSpaceBetweenKeywordAndParenthesis
            $script:diagnosticRecord -as $diagnosticRecordType
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
