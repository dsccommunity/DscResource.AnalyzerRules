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
            $suggestedCorrections = New-Object -TypeName Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]
            $splat = @{
                Extent      = $item.Extent
                NewString   = $item.Text.ToLower()
                Description = ('Replace {0} with {1}' -f ($item.Extent.Text, $item.Extent.Text.ToLower()))
            }
            $suggestedCorrections.Add((New-SuggestedCorrection @splat)) | Out-Null
            $suggestedCorrections.Add($suggestedCorrection) | Out-Null

            $script:diagnosticRecord['suggestedCorrections'] = $suggestedCorrections
            $script:diagnosticRecord -as $diagnosticRecordType
        }

        foreach ($item in $tokenWithNoSpace)
        {
            $script:diagnosticRecord['Extent'] = $item.Extent
            $script:diagnosticRecord['Message'] = $localizedData.OneSpaceBetweenKeywordAndParenthesis
            $suggestedCorrections = New-Object -TypeName Collections.Generic.List[Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.CorrectionExtent]
            $splat = @{
                Extent      = $item.Extent
                NewString   = "$($item.Text) "
                Description = ('Replace {0} with {1}' -f ("$($item.Extent.Text)(", "$($item.Text) ("))
            }
            $suggestedCorrections.Add((New-SuggestedCorrection @splat)) | Out-Null

            $script:diagnosticRecord['suggestedCorrections'] = $suggestedCorrections
            $script:diagnosticRecord -as $diagnosticRecordType
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
