$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            { $false
            } )
    }).BaseName


Import-Module $ProjectName

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

InModuleScope $ProjectName {
    Describe 'New-SuggestedCorrection tests' {
            $projectRootPath = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
            $moduleRootPath = Join-Path -Path $projectRootPath -ChildPath 'DscResource.AnalyzerRules'
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $moduleRootPath
                IncludeRule    = 'Measure-Keyword'
            }

            Context 'When suggested correction should be created' {
                It 'Should create suggested correction' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        if("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                    $record.SuggestedCorrections | Should -Not -BeNullOrEmpty
                }
            }
            Context 'When suggested correction should not be created' {
                It 'Should create suggested correction' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        if ("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                    $record | Should -BeNullOrEmpty
                }
            }
        }
}