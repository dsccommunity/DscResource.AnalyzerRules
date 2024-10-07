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

Describe 'Test-isInClass' -Tag 'Private' {
    Context 'Non Class AST' {
        It 'Should return false for an AST not in a Class AST' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $definition = '
                function Get-Something
                {
                    Param
                    (
                        [Parameter(Mandatory=$true)]
                        [string]
                        $Path
                    )

                    $Path
                }
            '
                $Ast = [System.Management.Automation.Language.Parser]::ParseInput($definition, [ref] $null, [ref] $null)
                $ParameterAst = $Ast.Find( {
                        param
                        (
                            [System.Management.Automation.Language.Ast]
                            $AST
                        )
                        $Ast -is [System.Management.Automation.Language.ParameterAst]
                    }, $true)
                ($ParameterAst -is [System.Management.Automation.Language.ParameterAst]) | Should -BeTrue
                $isInClass = Test-isInClass -Ast $ParameterAst
                $isInClass | Should -BeFalse
            }
        }
    }

    Context 'Class AST' {
        It 'Should return True for an AST contained in a class AST' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $definition = '
                class Something
                {
                    [void] Write([int] $Num)
                    {
                        Write-Host "Writing $Num"
                    }
                }
            '
                $Ast = [System.Management.Automation.Language.Parser]::ParseInput($definition, [ref] $null, [ref] $null)
                $ParameterAst = $Ast.Find( {
                        param
                        (
                            [System.Management.Automation.Language.Ast]
                            $AST
                        )
                        $Ast -is [System.Management.Automation.Language.ParameterAst]
                    }, $true)
                ($ParameterAst -is [System.Management.Automation.Language.ParameterAst]) | Should -BeTrue
                $isInClass = Test-isInClass -Ast $ParameterAst
                $isInClass | Should -BeTrue
            }
        }

        It 'Should return false for an AST contained in a ScriptBlock that is a value assignment for a property or method in a class AST' {
            InModuleScope -ScriptBlock {
                Set-StrictMode -Version 1.0

                $definition = '
                class Something
                {
                    [Func[Int,Int]] $MakeInt = {
                        [Parameter(Mandatory=$true)]
                        Param
                        (
                            [Parameter(Mandatory)]
                            [int] $Input
                        )
                        $Input * 2
                    }
                }
            '
                $Ast = [System.Management.Automation.Language.Parser]::ParseInput($definition, [ref] $null, [ref] $null)
                $ParameterAst = $Ast.Find( {
                        param
                        (
                            [System.Management.Automation.Language.Ast]
                            $AST
                        )
                        $Ast -is [System.Management.Automation.Language.ParameterAst]
                    }, $true)
                ($ParameterAst -is [System.Management.Automation.Language.ParameterAst]) | Should -BeTrue
                $isInClass = Test-isInClass -Ast $ParameterAst
                $isInClass | Should -BeFalse
            }
        }
    }
}
