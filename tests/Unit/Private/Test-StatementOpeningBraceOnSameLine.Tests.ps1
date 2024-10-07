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

Describe 'Test-StatementOpeningBraceOnSameLine' {
    Context 'When statement has an opening brace on the same line' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testStatementOpeningBraceOnSameLineParameters = @{
                    StatementBlock = `
                        'if ($true) {
                         }
                        '
                }

                $testStatementOpeningBraceOnSameLineResult = `
                    Test-StatementOpeningBraceOnSameLine @testStatementOpeningBraceOnSameLineParameters

                $testStatementOpeningBraceOnSameLineResult | Should -BeTrue
            }
        }
    }

    # Regression test for issue reported in review comment for PR #180.
    Context 'When statement is using braces in the evaluation expression' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testStatementOpeningBraceOnSameLineParameters = @{
                    StatementBlock = `
                        'if (Get-Command | Where-Object -FilterScript { $_.Name -eq ''Get-Help'' } )
                         {
                         }
                        '
                }

                $testStatementOpeningBraceOnSameLineResult = `
                    Test-StatementOpeningBraceOnSameLine @testStatementOpeningBraceOnSameLineParameters

                $testStatementOpeningBraceOnSameLineResult | Should -BeFalse
            }
        }
    }

    Context 'When statement follows style guideline' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $testStatementOpeningBraceOnSameLineParameters = @{
                    StatementBlock = `
                        'if ($true)
                         {
                         }
                        '
                }

                $testStatementOpeningBraceOnSameLineResult = `
                    Test-StatementOpeningBraceOnSameLine @testStatementOpeningBraceOnSameLineParameters

                $testStatementOpeningBraceOnSameLineResult | Should -BeFalse
            }
        }
    }
}
