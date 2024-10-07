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

Describe 'Get-StatementBlockAsRow' -Tag 'Private' {
    BeforeAll {
        InModuleScope -ScriptBlock {
            Set-StrictMode -Version 1.0

            $script:expectedReturnValue1 = 'First line'
            $script:expectedReturnValue2 = 'Second line'
        }
    }

    Context 'When string contains CRLF as new line' {
        It 'Should return the correct array of strings' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getStatementBlockAsRowsParameters = @{
                    StatementBlock = "First line`r`nSecond line"
                }

                $getStatementBlockAsRowsResult = `
                    Get-StatementBlockAsRow @getStatementBlockAsRowsParameters

                $getStatementBlockAsRowsResult[0] | Should -Be $expectedReturnValue1
                $getStatementBlockAsRowsResult[1] | Should -Be $expectedReturnValue2
            }
        }
    }

    Context 'When string contains LF as new line' {
        It 'Should return the correct array of strings' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $getStatementBlockAsRowsParameters = @{
                    StatementBlock = "First line`nSecond line"
                }

                $getStatementBlockAsRowsResult = `
                    Get-StatementBlockAsRow @getStatementBlockAsRowsParameters

                $getStatementBlockAsRowsResult[0] | Should -Be $expectedReturnValue1
                $getStatementBlockAsRowsResult[1] | Should -Be $expectedReturnValue2
            }
        }
    }
}
