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


Describe 'Measure-TypeDefinition' {
    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.TypeDefinitionAst'
            $ruleName = 'Measure-TypeDefinition'
        }

        Context 'Enum' {
            Context 'When Enum has an opening brace on the same line' {
                It 'Should write the correct error record' {
                    $definition = '
                        enum Test {
                            Good
                            Bad
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-TypeDefinition -TypeDefinitionAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.EnumOpeningBraceNotOnSameLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Enum Opening brace is not followed by a new line' {
                It 'Should write the correct error record' {
                    $definition = '
                        enum Test
                        { Good
                            Bad
                        }
                    '
                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-TypeDefinition -TypeDefinitionAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.EnumOpeningBraceShouldBeFollowedByNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Enum opening brace is followed by more than one new line' {
                It 'Should write the correct error record' {
                    $definition = '
                        enum Test
                        {

                            Good
                            Bad
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-TypeDefinition -TypeDefinitionAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.EnumOpeningBraceShouldBeFollowedByOnlyOneNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'Class' {
            Context 'When Class has an opening brace on the same line' {
                It 'Should write the correct error record' {
                    $definition = '
                        class Test {
                            [int] $Good
                            [Void] Bad()
                            {
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-TypeDefinition -TypeDefinitionAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.ClassOpeningBraceNotOnSameLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Class Opening brace is not followed by a new line' {
                It 'Should write the correct error record' {
                    $definition = '
                        class Test
                        {   [int] $Good
                            [Void] Bad()
                            {
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-TypeDefinition -TypeDefinitionAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.ClassOpeningBraceShouldBeFollowedByNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Class opening brace is followed by more than one new line' {
                It 'Should write the correct error record' {
                    $definition = '
                        class Test
                        {

                            [int] $Good
                            [Void] Bad()
                            {
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-TypeDefinition -TypeDefinitionAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.ClassOpeningBraceShouldBeFollowedByOnlyOneNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
            $ruleName = "$($script:ModuleName)\Measure-TypeDefinition"
        }

        Context 'Enum' {
            Context 'When Enum has an opening brace on the same line' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    enum Test {
                        Good
                        Bad
                    }
                '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $localizedData.EnumOpeningBraceNotOnSameLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Enum Opening brace is not followed by a new line' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    enum Test
                    { Good
                        Bad
                    }
                '
                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $localizedData.EnumOpeningBraceShouldBeFollowedByNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Enum opening brace is followed by more than one new line' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    enum Test
                    {

                        Good
                        Bad
                    }
                '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $localizedData.EnumOpeningBraceShouldBeFollowedByOnlyOneNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'Class' {
            Context 'When Class has an opening brace on the same line' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    class Test {
                        [int] $Good
                        [Void] Bad()
                        {
                        }
                    }
                '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $localizedData.ClassOpeningBraceNotOnSameLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Class Opening brace is not followed by a new line' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    class Test
                    {   [int] $Good
                        [Void] Bad()
                        {
                        }
                    }
                '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $localizedData.ClassOpeningBraceShouldBeFollowedByNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When Class opening brace is followed by more than one new line' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                    class Test
                    {

                        [int] $Good
                        [Void] Bad()
                        {
                        }
                    }
                '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $localizedData.ClassOpeningBraceShouldBeFollowedByOnlyOneNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }
    }
}
