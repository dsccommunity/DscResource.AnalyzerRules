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
    $ModuleUnderTest = Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop' -PassThru
    $script:modulePath = $ModuleUnderTest.Path

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

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
}

Describe 'New-SuggestedCorrection' -Tag 'Private' {
    BeforeAll {
        InModuleScope -Parameters @{
            ModulePath = $modulePath
        } -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
                IncludeRule    = 'Measure-Keyword'
            }
        }
    }

    Context 'When suggested correction should be created' {
        It 'Should create suggested correction' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        if("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record.SuggestedCorrections | Should -Not -BeNullOrEmpty
            }
        }
    }
    Context 'When suggested correction should not be created' {
        It 'Should create suggested correction' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        if ("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters

                $record | Should -BeNullOrEmpty
            }
        }
    }
}
