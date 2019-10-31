$here = $PSScriptRoot
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

$ProjectPath = "$here\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-StatementOpeningBraceOnSameLine' {
        Context 'When statement has an opening brace on the same line' {
            It 'Should return $true' {
                $testStatementOpeningBraceOnSameLineParameters = @{
                    StatementBlock = `
                        'if ($true) {
                         }
                        '
                }

                $testStatementOpeningBraceOnSameLineResult = `
                    Test-StatementOpeningBraceOnSameLine @testStatementOpeningBraceOnSameLineParameters

                $testStatementOpeningBraceOnSameLineResult | Should -Be $true
            }
        }

        # Regression test for issue reported in review comment for PR #180.
        Context 'When statement is using braces in the evaluation expression' {
            It 'Should return $false' {
                $testStatementOpeningBraceOnSameLineParameters = @{
                    StatementBlock = `
                        'if (Get-Command | Where-Object -FilterScript { $_.Name -eq ''Get-Help'' } )
                         {
                         }
                        '
                }

                $testStatementOpeningBraceOnSameLineResult = `
                    Test-StatementOpeningBraceOnSameLine @testStatementOpeningBraceOnSameLineParameters

                $testStatementOpeningBraceOnSameLineResult | Should -Be $false
            }
        }

        Context 'When statement follows style guideline' {
            It 'Should return $false' {
                $testStatementOpeningBraceOnSameLineParameters = @{
                    StatementBlock = `
                        'if ($true)
                         {
                         }
                        '
                }

                $testStatementOpeningBraceOnSameLineResult = `
                    Test-StatementOpeningBraceOnSameLine @testStatementOpeningBraceOnSameLineParameters

                $testStatementOpeningBraceOnSameLineResult | Should -Be $false
            }
        }
    }
}