---
Category: Usage
---

# Visual Studio Code

These analyzer rules can be used in a project being developed in Visual Studio Code.
It requires that some settings are set for both Visual Studio Code and PSScriptAnalyzer.

It also assumed the latest version of PSScriptAnalyzer is installed in a `$PSModulePath`.
It probably do, but it is not expected to with with the version of PSScriptAnalyzer
that is shipped with the Visual Studio Code PowerShell extension.

## Settings

Below are the recommend settings to be used by a project to align with the
[DSC Community style guideline](https://dsccommunity.org/styleguidelines/).
The important part here is the settings `powershell.scriptAnalysis.settingsPath`
and `powershell.scriptAnalysis.enable`.

### File `settings.json`

This file should be located in `.vscode/settings.json` relative to the root of
the project.

```json
{
    "powershell.codeFormatting.openBraceOnSameLine": false,
    "powershell.codeFormatting.newLineAfterOpenBrace": true,
    "powershell.codeFormatting.newLineAfterCloseBrace": true,
    "powershell.codeFormatting.whitespaceBeforeOpenBrace": true,
    "powershell.codeFormatting.whitespaceBeforeOpenParen": true,
    "powershell.codeFormatting.whitespaceAroundOperator": true,
    "powershell.codeFormatting.whitespaceAfterSeparator": true,
    "powershell.codeFormatting.ignoreOneLineBlock": false,
    "powershell.codeFormatting.pipelineIndentationStyle": "IncreaseIndentationForFirstPipeline",
    "powershell.codeFormatting.preset": "Custom",
    "powershell.codeFormatting.alignPropertyValuePairs": true,
    "powershell.codeFormatting.useConstantStrings": true,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "powershell.scriptAnalysis.settingsPath": ".vscode\\analyzersettings.psd1",
    "powershell.scriptAnalysis.enable": true,
    "[markdown]": {
        "files.encoding": "utf8"
    }
}
```

### File `analyzersettings.psd1`

This file should be located in `.vscode/analyzersettings.psd1` relative to the
root of the project.

If the project need to use several modules with custom rules, see [Custom rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#custom-rules).

The important part here is `CustomRulePath` which should point to the relative or
absolute path to where this module is installed. Below setting assume the project
is using [Sampler](https://github.com/gaelcolas/Sampler) build and deploy pipeline
automation, but that is not a requirement.

```powershell
@{
    CustomRulePath      = '.\output\RequiredModules\DscResource.AnalyzerRules'
    IncludeDefaultRules = $true
    IncludeRules        = @(
        # DSC Community style guideline rules.
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidInvokingEmptyMembers',
        'PSAvoidNullOrEmptyHelpMessageAttribute',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidUsingDeprecatedManifestFields',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidShouldContinueWithoutForce',
        'PSAvoidUsingWMICmdlet',
        'PSAvoidUsingWriteHost',
        'PSDSCReturnCorrectTypesForDSCFunctions',
        'PSDSCStandardDSCFunctionsInResource',
        'PSDSCUseIdenticalMandatoryParametersForDSC',
        'PSDSCUseIdenticalParametersForDSC',
        'PSMisleadingBacktick',
        'PSMissingModuleManifestField',
        'PSPossibleIncorrectComparisonWithNull',
        'PSProvideCommentHelp',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSUseApprovedVerbs',
        'PSUseCmdletCorrectly',
        'PSUseOutputTypeCorrectly',
        'PSAvoidGlobalVars',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSDSCUseVerboseMessageInDSCResource',
        'PSShouldProcess',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUsePSCredentialType',

        # Additional rules
        'PSUseConsistentWhitespace',
        'UseCorrectCasing',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'AlignAssignmentStatement',
        'AvoidUsingDoubleQuotesForConstantString',

        'Measure-*'
    )

    Rules               = @{
        PSUseConsistentWhitespace  = @{
            Enable                          = $true
            CheckOpenBrace                  = $false
            CheckInnerBrace                 = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $false
            CheckSeparator                  = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
            CheckParameter                  = $false
        }

        PSPlaceOpenBrace           = @{
            Enable             = $true
            OnSameLine         = $false
            NewLineAfter       = $true
            IgnoreOneLineBlock = $false
        }

        PSPlaceCloseBrace          = @{
            Enable             = $true
            NoEmptyLineBefore  = $true
            IgnoreOneLineBlock = $false
            NewLineAfter       = $true
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }
    }
}
```
