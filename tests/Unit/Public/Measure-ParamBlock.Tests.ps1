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

Describe 'Measure-ParamBlock' {
    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.ParamBlockAst'
            $ruleName = 'Measure-ParamBlock'
        }

        Context 'When ParamBlock is empty but parentheses have a space' {
            It 'Should write the correct error record' {
                $definition = '
                    param (   )
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-ParamBlock -ParamBlockAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.ParamBlockEmptyParenthesesShouldNotHaveWhitespace
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParamBlock is empty but parentheses are not on the same line' {
            It 'Should write the correct error record' {
                $definition = '
                    param
                    ()
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-ParamBlock -ParamBlockAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.ParamBlockEmptyParenthesesShouldBeOnSameLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParamBlock is not empty but parentheses start on the same line' {
            It 'Should write the correct error record' {
                $definition = '
                    param (
                        [Parameter()]
                        [string]$someString
                    )
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-ParamBlock -ParamBlockAst $mockAst[0]
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.ParamBlockNotEmptyParenthesesShouldBeOnNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParamBlock is not empty and parentheses start on the next line' {
            It 'Should write the correct error record' {
                $definition = '
                    param
                    (
                        [Parameter()]
                        [string]$someString
                    )
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-ParamBlock -ParamBlockAst $mockAst[0]
                ($record | Measure-Object).Count | Should -BeExactly 0
            }
        }

        Context 'When ParamBlock is empty and parentheses are empty' {
            It 'Should write the correct error record' {
                $definition = '
                    param ()
                '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-ParamBlock -ParamBlockAst $mockAst[0]
                ($record | Measure-Object).Count | Should -BeExactly 0
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
            $ruleName = "$($script:ModuleName)\Measure-ParamBlock"
        }

        Context 'When ParamBlock is empty but parentheses have a space' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    param (   )
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.ParamBlockEmptyParenthesesShouldNotHaveWhitespace
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParamBlock is empty but parentheses are not on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    param
                    ()
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.ParamBlockEmptyParenthesesShouldBeOnSameLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParamBlock is not empty but parentheses start on the same line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    param (
                        [Parameter()]
                        [string]$someString
                    )
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.ParamBlockNotEmptyParenthesesShouldBeOnNewLine
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParamBlock is not empty and parentheses start on the next line' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    param
                    (
                        [Parameter()]
                        [string]$someString
                    )
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }

        Context 'When ParamBlock is empty and parentheses are empty' {
            It 'Should write the correct error record' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    param ()
                '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record | Should -BeNullOrEmpty
            }
        }
    }
}
