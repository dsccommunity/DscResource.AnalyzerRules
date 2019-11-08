$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName
$script:ModuleName = $ProjectName

. $PSScriptRoot\Get-AstFromDefinition.ps1
. $PSScriptRoot\Get-TokensFromDefinition.ps1

$ModuleUnderTest = Import-Module $ProjectName -PassThru -Force
$localizedData = &$ModuleUnderTest { $Script:LocalizedData }
$modulePath = $ModuleUnderTest.Path
Describe 'Measure-Keyword' {
    Context 'When calling the function directly' {
        BeforeAll {
            $ruleName = 'Measure-Keyword'
        }

        Context 'When keyword contains upper case letters' {
            It 'Should write the correct error record' {
                $definition = '
                        Function Test
                        {
                           return $true
                        }
                    '

                $token = Get-TokensFromDefinition -ScriptDefinition $definition
                $record = Measure-Keyword -Token $token
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be ($localizedData.StatementsContainsUpperCaseLetter -f 'function')
                $record.RuleName | Should -Be $ruleName
            }

            It 'Should ignore DSC keywords' -Skip:(![bool]$IsWindows) {
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

        Context 'When keyword is not followed by a single space' {
            It 'Should write the correct error record' {
                $definition = '
                        if("example" -eq "example" -or "magic")
                        {
                            Write-Verbose -Message "Example found."
                        }
                    '

                $token = Get-TokensFromDefinition -ScriptDefinition $definition
                $record = Measure-Keyword -Token $token
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.OneSpaceBetweenKeywordAndParenthesis
                $record.RuleName | Should -Be $ruleName
            }
        }

        Context 'When keyword does not contain upper case letters' {
            It 'Should not return an error record' {
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

        Context 'When keyword is followed by a single space' {
            It 'Should not return an error record' {
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

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
                IncludeRule    = 'Measure-Keyword'
            }
            $ruleName = "$($script:ModuleName)\Measure-Keyword"
        }

        Context 'When measuring the keyword' {
            Context 'When keyword contains upper case letters' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        Function Test
                        {
                            return $true
                        }
                    '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -BeExactly 1
                    $record.Message | Should -Be ($localizedData.StatementsContainsUpperCaseLetter -f 'function')
                    $record.RuleName | Should -Be $ruleName
                }

                It 'Should ignore DSC keywords' -Skip:(![bool]$IsWindows) {
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

            Context 'When keyword is not followed by a single space' {
                It 'Should write the correct error record' {
                    $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                            if("example" -eq "example" -or "magic")
                            {
                                Write-Verbose -Message "Example found."
                            }
                        '

                    $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                    ($record | Measure-Object).Count | Should -Be 1
                    $record.Message | Should -Be $localizedData.OneSpaceBetweenKeywordAndParenthesis
                    $record.RuleName | Should -Be $ruleName
                }
            }

            Context 'When keyword does not contain upper case letters' {
                It 'Should not return an error record' {
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

            Context 'When keyword is followed by a single space' {
                It 'Should not return an error record' {
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
    }
}
