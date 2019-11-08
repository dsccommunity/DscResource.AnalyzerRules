$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-StatementOpeningBraceIsNotFollowedByNewLine' {
        Context 'When statement opening brace is not followed by a new line' {
            It 'Should return $true' {
                $testStatementOpeningBraceIsNotFollowedByNewLineParameters = @{
                    StatementBlock = `
                        'if ($true)
                         {  if ($false)
                            {
                            }
                         }
                        '
                }

                $testStatementOpeningBraceIsNotFollowedByNewLineResult = `
                    Test-StatementOpeningBraceIsNotFollowedByNewLine @testStatementOpeningBraceIsNotFollowedByNewLineParameters

                $testStatementOpeningBraceIsNotFollowedByNewLineResult | Should -Be $true
            }
        }

        Context 'When statement follows style guideline' {
            It 'Should return $false' {
                $testStatementOpeningBraceIsNotFollowedByNewLineParameters = @{
                    StatementBlock = `
                        'if ($true)
                         {
                            if ($false)
                            {
                            }
                         }
                        '
                }

                $testStatementOpeningBraceIsNotFollowedByNewLineResult = `
                    Test-StatementOpeningBraceIsNotFollowedByNewLine @testStatementOpeningBraceIsNotFollowedByNewLineParameters

                $testStatementOpeningBraceIsNotFollowedByNewLineResult | Should -Be $false
            }
        }
    }
}
