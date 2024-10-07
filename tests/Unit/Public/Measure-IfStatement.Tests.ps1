[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
param ()

BeforeDiscovery {
    try
    {
        if (-not (Get-Module -Name 'DscResource.Test'))
        {
            # Assumes dependencies has been resolved, so if this module is not available, run 'noop' task.
            if (-not (Get-Module -Name 'DscResource.Test' -ListAvailable))
            {
                # Redirect all streams to $null, except the error stream (stream 2)
                & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
            }

            # If the dependencies has not been resolved, this will throw an error.
            Import-Module -Name 'DscResource.Test' -Force -ErrorAction 'Stop'
        }
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -ResolveDependency -Tasks build" first.'
    }
}

BeforeAll {
    $script:moduleName = 'DscResource.AnalyzerRules'

    # Make sure there are not other modules imported that will conflict with mocks.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    # Re-import the module using force to get any code changes between runs.
    $ModuleUnderTest = Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop' -PassThru
    $script:modulePath = $ModuleUnderTest.Path

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\TestHelpers\CommonTestHelper.psm1')

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:moduleName -All | Remove-Module -Force

    # Remove module common test helper.
    Get-Module -Name 'CommonTestHelper' -All | Remove-Module -Force
}

Describe 'Measure-IfStatement' -Tag 'Public' {
    Context 'When calling the function directly' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:astType = 'System.Management.Automation.Language.IfStatementAst'
                $script:ruleName = 'Measure-IfStatement'
            }
        }

        Context 'When if-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    $record.Message | Should -Be $script:localizedData.IfStatementOpeningBraceNotOnSameLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When if-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    $record.Message | Should -Be $script:localizedData.IfStatementOpeningBraceShouldBeFollowedByNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When if-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    $record.Message | Should -Be $script:localizedData.IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }
    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            InModuleScope -Parameters @{
                ModuleName = $script:moduleName
                ModulePath = $modulePath
            } -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:invokeScriptAnalyzerParameters = @{
                    CustomRulePath = $modulePath
                }

                $script:ruleName = "$ModuleName\Measure-IfStatement"
            }
        }

        Context 'When if-statement has an opening brace on the same line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-Something
                        {
                            if ($true) {
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be $script:localizedData.IfStatementOpeningBraceNotOnSameLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When two if-statements has an opening brace on the same line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    $record[0].Message | Should -Be $script:localizedData.IfStatementOpeningBraceNotOnSameLine
                    $record[1].Message | Should -Be $script:localizedData.IfStatementOpeningBraceNotOnSameLine
                }
            }
        }

        Context 'When if-statement opening brace is not followed by a new line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    $record.Message | Should -Be $script:localizedData.IfStatementOpeningBraceShouldBeFollowedByNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When if-statement opening brace is followed by more than one new line' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
                    $record.Message | Should -Be $script:localizedData.IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When if-statement follows style guideline' {
            It 'Should not write an error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
        }

        # Regression test for issue reported in review comment for PR #180.
        Context 'When if-statement is using braces in the evaluation expression' {
            It 'Should not write an error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

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
}
