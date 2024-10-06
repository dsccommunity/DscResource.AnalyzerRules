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

Describe 'Measure-ParameterBlockParameterAttribute' {
    Context 'When calling the function directly' {
        BeforeAll {
            $astType = 'System.Management.Automation.Language.ParameterAst'
            $ruleName = 'Measure-ParameterBlockParameterAttribute'
        }

        Context 'When ParameterAttribute is missing' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is not declared first' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeWrongPlace
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is in lower-case' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeLowerCase
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is written correctly' {
            It 'Should not write a record' {
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

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
            $ruleName = "$($script:ModuleName)\Measure-ParameterBlockParameterAttribute"
        }

        Context 'When ParameterAttribute is missing' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is present' {
            It 'Should not write a record' {
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

        Context 'When ParameterAttribute is not declared first' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeWrongPlace
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is declared first' {
            It 'Should not write a record' {
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

        Context 'When ParameterAttribute is in lower-case' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeLowerCase
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is written in the correct casing' {
            It 'Should not write a record' {
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

        Context 'When ParameterAttribute is missing from two parameters' {
            It 'Should write the correct records' {
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
                $record[0].Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record[1].Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record[0].RuleName | Should -Be $ruleName
                $record[1].RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is missing and in lower-case' {
            It 'Should write the correct records' {
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
                $record[0].Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record[1].Message | Should -Be $localizedData.ParameterBlockParameterAttributeLowerCase
                $record[0].RuleName | Should -Be $ruleName
                $record[1].RuleName | Should -Be $ruleName
            }
        }

        Context 'When ParameterAttribute is missing from a second parameter' {
            It 'Should write the correct record' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When Parameter is part of a method in a class' {
            It 'Should not return any records' {
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

        Context 'When Parameter is part of a script block that is part of a property in a class' {
            It 'Should return records for the Parameter in the script block' {
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
                $record.Message | Should -Be $localizedData.ParameterBlockParameterAttributeMissing
                $record.RuleName | Should -Be $ruleName
            }
        }
    }
}
