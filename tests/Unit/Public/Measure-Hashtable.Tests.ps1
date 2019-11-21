$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            { Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            { $false
            } )
    }).BaseName
$script:ModuleName = $ProjectName

. $PSScriptRoot\Get-AstFromDefinition.ps1

$ModuleUnderTest = Import-Module $ProjectName -PassThru -Force
$localizedData = &$ModuleUnderTest { $Script:LocalizedData }
$modulePath = $ModuleUnderTest.Path

Describe 'Measure-Hashtable' {
    Context 'When calling the function directly' {
        BeforeAll {
            $ruleName = 'Measure-Hashtable'
            $astType = 'System.Management.Automation.Language.HashtableAst'
        }

        Context 'When hashtable is not correctly formatted' {
            It 'Hashtable defined on a single line' {
                $definition = '
                        $hashtable = @{Key1 = "Value1";Key2 = 2;Key3 = "3"}
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Hashtable partially correct formatted' {
                $definition = '
                        $hashtable = @{ Key1 = "Value1"
                        Key2 = 2
                        Key3 = "3" }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Hashtable indentation not correct' {
                $definition = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                        Key3 = "3"
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Correctly formatted empty hashtable' {
                $definition = '
                        $hashtable = @{ }
                        $hashtableNoSpace = @{}
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 0
            }
        }

        Context 'When composite resource is not correctly formatted' {
            It 'Composite resource defined on a single line' -Skip:(!([bool]$IsWindows)) {
                $definition = '
                        configuration test {
                            Script test
                            { GetScript =  {}; SetScript = {}; TestScript = {}
                            }
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Composite resource partially correct formatted' -Skip:(!([bool]$IsWindows)) {
                $definition = '
                        configuration test {
                            Script test
                            { GetScript =  {}
                                SetScript = {}
                                TestScript = {}
                            }
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Composite resource indentation not correct' -Skip:(!([bool]$IsWindows)) {
                $definition = '
                        configuration test {
                            Script test
                            {
                                GetScript =  {}
                                 SetScript = {}
                                  TestScript = {}
                            }
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

        }

        Context 'When hashtable is correctly formatted' {
            It "Correctly formatted non-nested hashtable" {
                $definition = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = "3"
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 0
            }

            It 'Correctly formatted nested hashtable' {
                $definition = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = @{
                                Key3Key1 = "ExampleText"
                                Key3Key2 = 42
                            }
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 0
            }

            It 'Correctly formatted empty hashtable' {
                $definition = '
                        $hashtableNoSpace = @{}
                        $hashtable = @{ }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 0
            }
        }

        Context 'When composite resource is correctly formatted' {
            It "Correctly formatted non-nested hashtable" -Skip:(!([bool]$IsWindows)) {
                $definition = '
                        configuration test {
                            Script test
                            {
                                GetScript = {};
                                SetScript = {};
                                TestScript = {}
                            }
                        }
                    '

                $mockAst = Get-AstFromDefinition -ScriptDefinition $definition -AstType $astType
                $record = Measure-Hashtable -HashtableAst $mockAst
                ($record | Measure-Object).Count | Should -Be 0
            }

        }

    }

    Context 'When calling PSScriptAnalyzer' {
        BeforeAll {
            $invokeScriptAnalyzerParameters = @{
                CustomRulePath = $modulePath
            }
            $ruleName = "$($script:ModuleName)\Measure-Hashtable"
        }

        Context 'When hashtable is not correctly formatted' {
            It 'Hashtable defined on a single line' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{Key1 = "Value1";Key2 = 2;Key3 = "3"}
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Hashtable partially correct formatted' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{ Key1 = "Value1"
                        Key2 = 2
                        Key3 = "3" }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Hashtable indentation not correct' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                        Key3 = "3"
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            <# Commented out until PSSCriptAnalyzer fix is published.
            It 'Incorrectly formatted empty hashtable' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{ }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }
            #>
        }

        Context 'When composite resource is not correctly formatted' {
            It 'Composite resource defined on a single line' -Skip:(!([bool]$IsWindows)) {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            { GetScript =  {}; SetScript = {}; TestScript = {}
                            }
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName

            }

            It 'Composite resource partially correct formatted' -Skip:(!([bool]$IsWindows)) {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            { GetScript =  {}
                                SetScript = {}
                                TestScript = {}
                            }
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

            It 'Composite resource indentation not correct' -Skip:(!([bool]$IsWindows)) {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            {
                                GetScript =  {}
                                 SetScript = {}
                                  TestScript = {}
                            }
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 1
                $record.Message | Should -Be $localizedData.HashtableShouldHaveCorrectFormat
                $record.RuleName | Should -Be $ruleName
            }

        }

        Context 'When hashtable is correctly formatted' {
            It 'Correctly formatted non-nested hashtable' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = "3"
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 0
            }

            It 'Correctly formatted nested hashtable' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{
                            Key1 = "Value1"
                            Key2 = 2
                            Key3 = @{
                                Key3Key1 = "ExampleText"
                                Key3Key2 = 42
                            }
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 0
            }

            It 'Correctly formatted empty hashtable' {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        $hashtable = @{ }
                        $hashtableNoSpace = @{}
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 0
            }
        }

        Context 'When composite resource is correctly formatted' {
            It "Correctly formatted non-nested hashtable" -Skip:(!([bool]$IsWindows)) {
                $invokeScriptAnalyzerParameters['ScriptDefinition'] = '
                        configuration test {
                            Script test
                            {
                                GetScript = {};
                                SetScript = {};
                                TestScript = {}
                            }
                        }
                    '

                $record = Invoke-ScriptAnalyzer @invokeScriptAnalyzerParameters
                ($record | Measure-Object).Count | Should -Be 0
            }

        }

    }
}
