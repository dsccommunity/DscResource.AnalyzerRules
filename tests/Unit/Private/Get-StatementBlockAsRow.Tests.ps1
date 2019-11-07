$here = $PSScriptRoot

$ProjectPath = "$here\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName



Import-Module $ProjectName
InModuleScope $ProjectName {
    Describe 'Get-StatementBlockAsRow' {
        Context 'When string contains CRLF as new line' {
            BeforeAll {
                $expectedReturnValue1 = 'First line'
                $expectedReturnValue2 = 'Second line'
            }

            It 'Should return the correct array of strings' {
                $getStatementBlockAsRowsParameters = @{
                    StatementBlock = "First line`r`nSecond line"
                }

                $getStatementBlockAsRowsResult = `
                    Get-StatementBlockAsRow @getStatementBlockAsRowsParameters

                $getStatementBlockAsRowsResult[0] | Should -Be $expectedReturnValue1
                $getStatementBlockAsRowsResult[1] | Should -Be $expectedReturnValue2
            }
        }

        Context 'When string contains LF as new line' {
            It 'Should return the correct array of strings' {
                $getStatementBlockAsRowsParameters = @{
                    StatementBlock = "First line`nSecond line"
                }

                $getStatementBlockAsRowsResult = `
                    Get-StatementBlockAsRow @getStatementBlockAsRowsParameters

                $getStatementBlockAsRowsResult[0] | Should -Be $expectedReturnValue1
                $getStatementBlockAsRowsResult[1] | Should -Be $expectedReturnValue2
            }
        }
    }
}
