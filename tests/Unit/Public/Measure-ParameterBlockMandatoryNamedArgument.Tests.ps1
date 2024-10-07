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

Describe 'Measure-ParameterBlockMandatoryNamedArgument' -Tag 'Public' {
    Context 'When calling the function directly' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:astType = 'System.Management.Automation.Language.NamedAttributeArgumentAst'
                $script:ruleName = 'Measure-ParameterBlockMandatoryNamedArgument'
            }
        }

        Context 'When Mandatory is included and set to $false' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [Parameter(Mandatory = $false)]
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                    $record = Measure-ParameterBlockMandatoryNamedArgument -NamedAttributeArgumentAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory is lower-case' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [Parameter(mandatory = $true)]
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                    $record = Measure-ParameterBlockMandatoryNamedArgument -NamedAttributeArgumentAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory does not include an explicit argument' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [Parameter(Mandatory)]
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType

                    $record = Measure-ParameterBlockMandatoryNamedArgument -NamedAttributeArgumentAst $mockAst[0]
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory is correctly written' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Get-TargetResource
                        {
                            param (
                                [Parameter(Mandatory = $true)]
                                $ParameterName
                            )
                        }
                    '

                    $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                    Measure-ParameterBlockMandatoryNamedArgument -NamedAttributeArgumentAst $mockAst[0] | Should -BeNullOrEmpty
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

                $script:ruleName = "$ModuleName\Measure-ParameterBlockMandatoryNamedArgument"
            }
        }

        Context 'When Mandatory is included and set to $false' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory = $false)]
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory is lower-case' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(mandatory = $true)]
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory does not include an explicit argument' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory)]
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory is incorrectly written and other parameters are used' {
            It 'Should write the correct record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory = $false, ParameterSetName = "SetName")]
                                $ParameterName
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory is correctly written' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory = $true)]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Mandatory is not present and other parameters are' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(HelpMessage = "HelpMessage")]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Mandatory is correctly written and other parameters are listed' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory = $true, ParameterSetName = "SetName")]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Mandatory is correctly written and not placed first' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(ParameterSetName = "SetName", Mandatory = $true)]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Mandatory is correctly written and other attributes are listed' {
            It 'Should not write a record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory = $true)]
                                [ValidateSet("one", "two")]
                                $ParameterName
                            )
                        }
                    '

                    Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Mandatory Attribute NamedParameter is in a class' {
            It 'Should not return any records' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        [DscResource()]
                        class Resource
                        {
                            [DscProperty(Key)]
                            [string] $DscKeyString

                            [DscProperty(Mandatory)]
                            [int] $DscNum

                            [Resource] Get()
                            {
                                return $this
                            }

                            [void] Set()
                            {
                            }

                            [bool] Test()
                            {
                                return $true
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    $record | Should -BeNullOrEmpty
                }
            }
        }

        Context 'When Mandatory Attribute NamedParameter is in script block in a property in a class' {
            It 'Should return records for NameParameter in the ScriptBlock only' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        [DscResource()]
                        class Resource
                        {
                            [DscProperty(Key)]
                            [string] $DscKeyString

                            [DscProperty(Mandatory)]
                            [int] $DscNum

                            [Resource] Get()
                            {
                                return $this
                            }

                            [void] Set()
                            {
                            }

                            [bool] Test()
                            {
                                return $true
                            }

                            [Func[Int,Int]] $MakeInt = {
                                [Parameter(Mandatory=$true)]
                                param
                                (
                                    [Parameter(Mandatory)]
                                    [int] $Input
                                )
                                $Input * 2
                            }
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When Mandatory is incorrectly set on two parameters' {
            It 'Should write the correct records' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory)]
                                $ParameterName1,

                                [Parameter(Mandatory = $false)]
                                $ParameterName2
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 2
                    $record[0].Message | Should -Be $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat
                    $record[1].Message | Should -Be $script:localizedData.ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat
                }
            }
        }

        Context 'When ParameterAttribute is set to $false and in lower-case' {
            It 'Should write the correct records' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        function Get-TargetResource
                        {
                            param
                            (
                                [Parameter(Mandatory = $true)]
                                $ParameterName1,

                                [Parameter(mandatory = $false)]
                                $ParameterName2
                            )
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }
    }
}
