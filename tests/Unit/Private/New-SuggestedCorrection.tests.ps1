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

InModuleScope $ProjectName {
    Describe 'New-SuggestedCorrection tests' {
        Context 'When suggested correction should be created' {
            It 'Should create suggested correction' {
                $definition = '
                        if("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                $token = Get-TokensFromDefinition -ScriptDefinition $definition
                $record = Measure-Keyword -Token $token

                $record.SuggestedCorrections | Should -Exist
            }
        }
        Context 'When suggested correction should not be created' {
            It 'Should create suggested correction' {
                $definition = '
                        if("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                $token = Get-TokensFromDefinition -ScriptDefinition $definition
                $record = Measure-Keyword -Token $token

                $record | Should -Not -Exist
            }
        }
    }
}
