$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-StatementOpeningParenthsesOnSameLine' {
        Context 'When statement has an opening parentheses on the same line' {
            It 'Should return $true' {
                $testStatementOpeningParenthsesOnSameLineParameters = @{
                    StatementBlock = `
                        'param ()'
                }

                $testStatementOpeningParenthsesOnSameLineResult = `
                    Test-StatementOpeningParenthsesOnSameLine @testStatementOpeningParenthsesOnSameLineParameters

                $testStatementOpeningParenthsesOnSameLineResult | Should -Be $true
            }
        }

        Context 'When statement does not have an opening parentheses on the same line' {
            It 'Should return $false' {
                $testStatementOpeningParenthsesOnSameLineParameters = @{
                    StatementBlock = `
                        'param
                        ()'
                }

                $testStatementOpeningParenthsesOnSameLineResult = `
                    Test-StatementOpeningParenthsesOnSameLine @testStatementOpeningParenthsesOnSameLineParameters

                $testStatementOpeningParenthsesOnSameLineResult | Should -Be $false
            }
        }
    }
}
