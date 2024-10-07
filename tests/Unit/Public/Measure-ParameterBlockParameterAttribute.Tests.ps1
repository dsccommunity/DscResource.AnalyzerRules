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

Describe 'Measure-ParameterBlockParameterAttribute' -Tag 'Public' {
    Context 'When calling the function directly' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:astType = 'System.Management.Automation.Language.ParameterAst'
                $script:ruleName = 'Measure-ParameterBlockParameterAttribute'
            }
        }

        Context 'When ParameterAttribute is missing' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-ParameterBlockParameterAttribute -ParameterAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is not declared first' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [ValidateSet("one", "two")]
                                [Parameter()]
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-ParameterBlockParameterAttribute -ParameterAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeWrongPlace
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is in lower-case' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [parameter()]
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    $record = Measure-ParameterBlockParameterAttribute -ParameterAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeLowerCase
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is written correctly' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [Parameter()]
                                $ParameterName1,

                                [Parameter(Mandatory = $true)]
                                $ParameterName2
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    Measure-ParameterBlockParameterAttribute -ParameterAst $mockAst[0] | Should -BeNullOrEmpty
                    Measure-ParameterBlockParameterAttribute -ParameterAst $mockAst[1] | Should -BeNullOrEmpty
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

                $script:ruleName = "$ModuleName\Measure-ParameterBlockParameterAttribute"
            }
        }

        Context 'When ParameterAttribute is missing' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is present' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter()]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When ParameterAttribute is not declared first' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [ValidateSet("one", "two")]
                                [Parameter()]
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeWrongPlace
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is declared first' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter()]
                                [ValidateSet("one", "two")]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When ParameterAttribute is in lower-case' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [parameter()]
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeLowerCase
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is written in the correct casing' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter()]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When ParameterAttribute is missing from two parameters' {
            It 'Should write the correct records' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                $ParameterName1,

                                $ParameterName2
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 2
                    $record[0].Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record[1].Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record[0].RuleName | Should -Be $ruleName
                    $record[1].RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is missing and in lower-case' {
            It 'Should write the correct records' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                $ParameterName1,

                                [parameter()]
                                $ParameterName2
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 2
                    $record[0].Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record[1].Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeLowerCase
                    $record[0].RuleName | Should -Be $ruleName
                    $record[1].RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When ParameterAttribute is missing from a second parameter' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter()]
                                $ParameterName1,

                                $ParameterName2
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Parameter is part of a method in a class' {
            It 'Should not return any records' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        class Resource
                        {
                            [void] Get_TargetResource($ParameterName1,$ParameterName2)
                            {
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    $record | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Parameter is part of a script block that is part of a property in a class' {
            It 'Should return records for the Parameter in the script block' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        class Resource
                        {
                            [void] Get_TargetResource($ParameterName1,$ParameterName2)
                            {
                            }

                            [Func[Int,Int]] $MakeInt = {
                                [Parameter(Mandatory=$true)]
                                param
                                (
                                    [int] $Input
                                )
                                $Input * 2
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterAttributeMissing
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }
    }
}
