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

Describe 'Get-LocalizedData' {
    Context 'When using the default Import-LocalizedData behavior' {
        BeforeAll {
            New-Item -Force -Path 'TestDrive:\ar-SA' -ItemType Directory
            $null = "
                    ConvertFrom-StringData @`'
                    # English strings
                    ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
                    '@
                " | Out-File -Force -FilePath 'TestDrive:\ar-SA\Strings.psd1'
            "Get-LocalizedData -FileName 'Strings' -EA Stop" |
                Out-File -Force -FilePath 'TestDrive:\execute.ps1'
        }


        It 'Should fail finding a Strings file in different locale' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $null = &'TestDrive:\execute.ps1' } | Should -Throw
            }
        }
    }

    Context 'When falling back to a DefaultUICulture' {
        BeforeAll {
            New-Item -Force -Path 'TestDrive:\ar-SA' -ItemType Directory
            $null = "
ConvertFrom-StringData @`'
# ar-SA strings
ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
'@
                " | Out-File -Force -FilePath 'TestDrive:\ar-SA\Strings.psd1'
            "Get-LocalizedData -FileName 'Strings' -DefaultUICulture 'ar-SA' -EA Stop" |
                Out-File -Force -FilePath 'TestDrive:\execute.ps1'
        }

        It 'Should retrieve the data' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                { $null = &'TestDrive:\execute.ps1' } | Should -Not -Throw
                &'TestDrive:\execute.ps1' | Should -Not -BeNullOrEmpty
            }
        }
    }
}
