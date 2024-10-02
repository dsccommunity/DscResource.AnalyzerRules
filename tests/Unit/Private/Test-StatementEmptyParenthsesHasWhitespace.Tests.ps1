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
    Describe 'Test-StatementEmptyParenthsesHasWhitespace' {
        Context 'When statement has just whitespace in parentheses' {
            It 'Should return $true' {
                $testStatementEmptyParenthsesHasWhitespaceParameters = @{
                    StatementBlock = `
                    'param ( )'
                }

                $testStatementEmptyParenthsesHasWhitespaceResult = `
                    Test-StatementEmptyParenthsesHasWhitespace @testStatementEmptyParenthsesHasWhitespaceParameters

                $testStatementEmptyParenthsesHasWhitespaceResult | Should -Be $true
            }
        }

        Context 'When statement has a newline in parentheses' {
            It 'Should return $true' {
                $testStatementEmptyParenthsesHasWhitespaceParameters = @{
                    StatementBlock = `
                    'param (
                    )'
                }

                $testStatementEmptyParenthsesHasWhitespaceResult = `
                    Test-StatementEmptyParenthsesHasWhitespace @testStatementEmptyParenthsesHasWhitespaceParameters

                $testStatementEmptyParenthsesHasWhitespaceResult | Should -Be $true
            }
        }

        Context 'When statement follows style guideline' {
            It 'Should return $false' {
                $testStatementEmptyParenthsesHasWhitespaceParameters = @{
                    StatementBlock = `
                    'param ()'
                }

                $testStatementEmptyParenthsesHasWhitespaceResult = `
                    Test-StatementEmptyParenthsesHasWhitespace @testStatementEmptyParenthsesHasWhitespaceParameters

                $testStatementEmptyParenthsesHasWhitespaceResult | Should -Be $false
            }
        }
    }
}
