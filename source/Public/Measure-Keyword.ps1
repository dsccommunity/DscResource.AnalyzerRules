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
            $keywordsToIgnore -notcontains $_.Text
        }
        $upperCaseTokens = $keywords.Where{ $_.Text -cmatch '[A-Z]+' }

        $tokenWithNoSpace = $keywords.Where{ $_.Extent.StartScriptPosition.Line -match "\b$($_.Extent.Text)\(.*" }

        foreach ($item in $upperCaseTokens)
        {
            $script:diagnosticRecord['Extent'] = $item.Extent
            $script:diagnosticRecord['Message'] = $script:localizedData.StatementsContainsUpperCaseLetter -f $item.Text
            $suggestedCorrections = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
            $splat = @{
                Extent      = $item.Extent
                NewString   = $item.Text.ToLower()
                Description = ('Replace {0} with {1}' -f ($item.Extent.Text, $item.Extent.Text.ToLower()))
            }
            $null = $suggestedCorrections.Add((New-SuggestedCorrection @splat))

            $script:diagnosticRecord['suggestedCorrections'] = $suggestedCorrections
            $script:diagnosticRecord -as $diagnosticRecordType
        }

        foreach ($item in $tokenWithNoSpace)
        {
            $script:diagnosticRecord['Extent'] = $item.Extent
            $script:diagnosticRecord['Message'] = $script:localizedData.OneSpaceBetweenKeywordAndParenthesis
            $suggestedCorrections = [System.Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]]::new()
            $splat = @{
                Extent      = $item.Extent
                NewString   = "$($item.Text) "
                Description = ('Replace {0} with {1}' -f ("$($item.Extent.Text)(", "$($item.Text) ("))
            }
            $null = $suggestedCorrections.Add((New-SuggestedCorrection @splat))

            $script:diagnosticRecord['suggestedCorrections'] = $suggestedCorrections
            $script:diagnosticRecord -as $diagnosticRecordType
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
