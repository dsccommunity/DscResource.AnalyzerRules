$here = $PSScriptRoot

$ProjectPath = "$here\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine' {
        Context 'When statement opening brace is not followed by a new line' {
            It 'Should return $true' {
                $testStatementOpeningBraceIsFollowedByMoreThanOneNewLineParameters = @{
                    StatementBlock = `
                        'if ($true)
                         {

                            if ($false)
                            {
                            }
                         }
                        '
                }

                $testStatementOpeningBraceIsFollowedByMoreThanOneNewLineResult = `
                    Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testStatementOpeningBraceIsFollowedByMoreThanOneNewLineParameters

                $testStatementOpeningBraceIsFollowedByMoreThanOneNewLineResult | Should -Be $true
            }
        }

        Context 'When statement follows style guideline' {
            It 'Should return $false' {
                $testStatementOpeningBraceIsFollowedByMoreThanOneNewLineParameters = @{
                    StatementBlock = `
                        'if ($true)
                         {
                            if ($false)
                            {
                            }
                         }
                        '
                }

                $testStatementOpeningBraceIsFollowedByMoreThanOneNewLineResult = `
                    Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testStatementOpeningBraceIsFollowedByMoreThanOneNewLineParameters

                $testStatementOpeningBraceIsFollowedByMoreThanOneNewLineResult | Should -Be $false
            }
        }
    }
}
