

$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'Test-isInClass' {
        Context 'Non Class AST' {
            It 'Should return false for an AST not in a Class AST' {
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
                ($ParameterAst -is [System.Management.Automation.Language.ParameterAst]) | Should -Be $true
                $isInClass = Test-isInClass -Ast $ParameterAst
                $isInClass | Should -Be $false
            }
        }

        Context 'Class AST' {
            It 'Should Return True for an AST contained in a class AST' {
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
                ($ParameterAst -is [System.Management.Automation.Language.ParameterAst]) | Should -Be $true
                $isInClass = Test-isInClass -Ast $ParameterAst
                $isInClass | Should -Be $true
            }

            It "Should return false for an AST contained in a ScriptBlock`r`n`t that is a value assignment for a property or method in a class AST" {
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
                ($ParameterAst -is [System.Management.Automation.Language.ParameterAst]) | Should -Be $true
                $isInClass = Test-isInClass -Ast $ParameterAst
                $isInClass | Should -Be $false

            }
        }
    }
}
