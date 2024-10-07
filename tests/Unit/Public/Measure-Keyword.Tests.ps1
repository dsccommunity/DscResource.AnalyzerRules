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

Describe 'Measure-Keyword' -Tag 'Public' {
    Context 'When calling the function directly' {
        BeforeAll {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $script:ruleName = 'Measure-Keyword'
            }
        }

        Context 'When keyword contains upper case letters' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0
                    
                    $definition = '
                        Function Test
                        {
                           return $true
                        }
                    '

                    $token = Get-TokensFromDefinition -ScriptDefinition $definition
                    $record = Measure-Keyword -Token $token
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be ($script:localizedData.StatementsContainsUpperCaseLetter -f 'function')
                    $record.RuleName | Should -Be $ruleName
                }
            }

            It 'Should ignore DSC keywords' -Skip:(![bool]$IsWindows) {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        Configuration FileDSC
                        {

                            Node $AllNodes.NodeName
                            {
                                File "Fil1"
                                {
                                    Ensure       = "Absent"
                                    DestinationPath = C:\temp\test.txt
                                }
                            }
                        }
                    '

                    $token = Get-TokensFromDefinition -ScriptDefinition $definition
                    $record = Measure-Keyword -Token $token
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }

        Context 'When keyword is not followed by a single space' {
            It 'Should write the correct error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        if("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                    $token = Get-TokensFromDefinition -ScriptDefinition $definition
                    $record = Measure-Keyword -Token $token
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $script:localizedData.OneSpaceBetweenKeywordAndParenthesis
                    $record.RuleName | Should -Be $ruleName
                }
            }
        }

        Context 'When keyword does not contain upper case letters' {
            It 'Should not return an error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        function Test
                        {
                           return $true
                        }
                    '

                    $token = Get-TokensFromDefinition -ScriptDefinition $definition
                    $record = Measure-Keyword -Token $token
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }

        Context 'When keyword is followed by a single space' {
            It 'Should not return an error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        if ("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                    $token = Get-TokensFromDefinition -ScriptDefinition $definition
                    $record = Measure-Keyword -Token $token
                    ($record | Measure-Object).Count | Should -Be 0
                }
            }
        }

        Context 'When another word contains ''base'' but has other characters preceeding it' {
            It 'Should not return an error record' {
                InModuleScope -ScriptBlock {
                    Set-StrictMode -Version 1.0

                    $definition = '
                        class SqlSetupBase
                        {
                            SqlSetupBase() : base ()
                            {
                                Write-Verbose -Message "Example found."
                            }
                        }
                    '

                    $token = Get-TokensFromDefinition -ScriptDefinition $definition
                    $record = Measure-Keyword -Token $token
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
                    IncludeRule    = 'Measure-Keyword'
                }

                $script:ruleName = "$ModuleName\Measure-Keyword"
            }
        }

        Context 'When measuring the keyword' {
            Context 'When keyword contains upper case letters' {
                It 'Should write the correct error record' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            Function Test
                            {
                                return $true
                            }
                        '

                        $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                        ($record | Measure-Object).Count | Should -BeExactly 1
                        $record.Message | Should -Be ($script:localizedData.StatementsContainsUpperCaseLetter -f 'function')
                        $record.RuleName | Should -Be $ruleName
                    }
                }

                It 'Should ignore DSC keywords' -Skip:(![bool]$IsWindows) {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            Configuration FileDSC
                            {
                                Node $AllNodes.NodeName
                                {
                                    File "Fil1"
                                    {
                                        Ensure       = "Absent"
                                        DestinationPath = C:\temp\test.txt
                                    }
                                }
                            }
                        '

                        $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                        ($record | Measure-Object).Count | Should -BeExactly 0
                    }
                }
            }

            Context 'When keyword is not followed by a single space' {
                It 'Should write the correct error record' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            if("example" -eq "example" -or "magic")
                            {
                                Write-Verbose -Message "Example found."
                            }
                        '

                        $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                        ($record | Measure-Object).Count | Should -Be 1
                        $record.Message | Should -Be $script:localizedData.OneSpaceBetweenKeywordAndParenthesis
                        $record.RuleName | Should -Be $ruleName
                    }
                }
            }

            Context 'When keyword does not contain upper case letters' {
                It 'Should not return an error record' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            function Test
                            {
                               return $true
                            }
                        '

                        $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                        ($record | Measure-Object).Count | Should -BeExactly 0
                    }
                }
            }

            Context 'When keyword is followed by a single space' {
                It 'Should not return an error record' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            if ("example" -eq "example" -or "magic")
                            {
                                Write-Verbose -Message "Example found."
                            }
                        '

                        $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                        ($record | Measure-Object).Count | Should -Be 0
                    }
                }
            }

            Context 'When another word contains ''base'' but has other characters preceeding it' {
                It 'Should not return an error record' {
                    InModuleScope -ScriptBlock {
                        Set-StrictMode -Version 1.0

                        $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            class SqlSetupBase
                            {
                                SqlSetupBase() : base ()
                                {
                                    Write-Verbose -Message "Example found."
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
}
