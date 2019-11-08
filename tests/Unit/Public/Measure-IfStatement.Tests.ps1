$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
    $(try { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName
$script:ModuleName = $ProjectName

. $PSScriptRoot\Get-AstFromDefinition.ps1

$ModuleUnderTest = Import-Module $ProjectName -PassThru
$localizedData = &$ModuleUnderTest { $Script:LocalizedData }
$modulePath = $ModuleUnderTest.Path

Describe 'Measure-IfStatement' {
    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.IfStatementAst'
            $ruleName = 'Measure-IfStatement'
        }

        Context 'When if-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something
                    {
                        if ($true) {
                        }
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-IfStatement -IfStatementAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.IfStatementOpeningBraceNotOnSameLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When if-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something
                    {
                        if ($true)
                        { return $true
                        }
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-IfStatement -IfStatementAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.IfStatementOpeningBraceShouldBeFollowedByNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When if-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $definition = '
                    function Get-Something
                    {
                        if ($true)
                        {

                            return $true
                        }
                    }
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-IfStatement -IfStatementAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
            $ruleName = "$($script:ModuleName)\Measure-IfStatement"
        }

        Context 'When if-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true) {
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $localizedData.IfStatementOpeningBraceNotOnSameLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When two if-statements has an opening brace on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true) {
                        }

                        if ($true) {
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 2
                $record[0].Message | Should -Be $localizedData.IfStatementOpeningBraceNotOnSameLine
                $record[1].Message | Should -Be $localizedData.IfStatementOpeningBraceNotOnSameLine
            }
        }

        Context 'When if-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true)
                        { return $true
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $localizedData.IfStatementOpeningBraceShouldBeFollowedByNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When if-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true)
                        {

                            return $true
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -BeExactly 1
                $record.Message | Should -Be $localizedData.IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When if-statement follows style guideline' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if ($true)
                        {
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }

        # Regression test for issue reported in review comment for PR #180.
        Context 'When if-statement is using braces in the evaluation expression' {
            It 'Should not write an error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    function Get-Something
                    {
                        if (Get-Command | Where-Object -FilterScript { $_.Name -eq ''Get-Help'' } )
                        {
                        }
                    }
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }
    }
}
