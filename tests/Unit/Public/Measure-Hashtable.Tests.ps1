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

Describe 'Measure-Hashtable' -Tag 'Public' {
    Context 'When calling the function directly' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:ruleName = 'Measure-Hashtable'
                $script:astType = 'System.Management.Automation.Language.HashtableAst'
            }
        }

        Context 'When hashtable is not correctly formatted' {
            It 'Hashtable defined on a single line' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtable = @{Key1 = "Value1";Key2 = 2;Key3 = "3"}
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Hashtable partially correct formatted' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtable = @{ Key1 = "Value1"
                        Key2 = 2
                        Key3 = "3" }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Hashtable indentation not correct' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                        Key3 = "3"
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Correctly formatted empty hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtable = @{ }
                        $hashtableNoSpace = @{}
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }

        Context 'When composite resource is not correctly formatted' {
            It 'Composite resource defined on a single line' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        configuration test {
                            Script test
                            { GetScript =  {}; SetScript = {}; TestScript = {}
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Composite resource partially correct formatted' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        configuration test {
                            Script test
                            { GetScript =  {}
                                SetScript = {}
                                TestScript = {}
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Composite resource indentation not correct' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        configuration test {
                            Script test
                            {
                                GetScript =  {}
                                 SetScript = {}
                                  TestScript = {}
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

        }

        Context 'When hashtable is correctly formatted' {
            It 'Correctly formatted non-nested hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = "3"
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }

            It 'Correctly formatted nested hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = @{
                                Key3Key1 = "ExampleText"
                                Key3Key2 = 42
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }

            It 'Correctly formatted empty hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        $hashtableNoSpace = @{}
                        $hashtable = @{ }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }

        Context 'When composite resource is correctly formatted' {
            It 'Correctly formatted non-nested hashtable' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        configuration test {
                            Script test
                            {
                                GetScript = {};
                                SetScript = {};
                                TestScript = {}
                            }
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-Hashtable -HashtableAst $mockAst
                    ($record | Measure-Object).Count | Should -Be 0
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

                $script:ruleName = "$ModuleName\Measure-Hashtable"
            }
        }

        Context 'When hashtable is not correctly formatted' {
            It 'Hashtable defined on a single line' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{Key1 = "Value1";Key2 = 2;Key3 = "3"}
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Hashtable partially correct formatted' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{ Key1 = "Value1"
                        Key2 = 2
                        Key3 = "3" }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Hashtable indentation not correct' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                        Key3 = "3"
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            <# Commented out until PSSCriptAnalyzer fix is published.
            It 'Incorrectly formatted empty hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{ }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            } #>
        }

        Context 'When composite resource is not correctly formatted' {
            It 'Composite resource defined on a single line' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            { GetScript =  {}; SetScript = {}; TestScript = {}
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }

            }

            It 'Composite resource partially correct formatted' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            { GetScript =  {}
                                SetScript = {}
                                TestScript = {}
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Composite resource indentation not correct' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            {
                                GetScript =  {}
                                 SetScript = {}
                                  TestScript = {}
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.HashtableShouldHaveCorrectFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When hashtable is correctly formatted' {
            It 'Correctly formatted non-nested hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = "3"
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }

            It 'Correctly formatted nested hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = @{
                                Key3Key1 = "ExampleText"
                                Key3Key2 = 42
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }

            It 'Correctly formatted empty hashtable' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{ }
                        $hashtableNoSpace = @{}
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }

        Context 'When composite resource is correctly formatted' {
            It 'Correctly formatted non-nested hashtable' -Skip:(!([bool]$IsWindows)) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            {
                                GetScript = {};
                                SetScript = {};
                                TestScript = {}
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }
    }
}
