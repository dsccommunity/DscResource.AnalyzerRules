
function Get-LocalizedData {
    [CmdletBinding(HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113342')]
    param(
        [Parameter(Position = 0)]
        [Alias('Variable')]
        [ValidateNotNullOrEmpty()]
        [string]
        ${BindingVariable},

        [Parameter(Position = 1)]
        [string]
        ${UICulture},

        [string]
        ${BaseDirectory},

        [string]
        ${FileName},

        [string[]]
        ${SupportedCommand},

        [Parameter(Position = 1)]
        [string]
        ${DefaultUICulture}

    )

    begin {
        # Because Proxy Command changes the Invocation origin, we need to be explicit
        # when handing the pipeline back to original command
        if (!$PSBoundParameters.ContainsKey('FileName')) {
            if ($myInvocation.ScriptName) {
                $file = ([io.FileInfo]$myInvocation.ScriptName)
            }
            else {
                $file = [io.FileInfo]$myInvocation.MyCommand.Module.Path
            }
            $FileName = $file.BaseName
            $PSBoundParameters.add('FileName', $file.Name)
        }

        if ($PSBoundParameters.ContainsKey('BaseDirectory')) {
            $CallingScriptRoot = $BaseDirectory
        }
        else {
            $CallingScriptRoot = $myInvocation.PSScriptRoot
            $PSBoundParameters.add('BaseDirectory', $CallingScriptRoot)
        }

        if ($PSBoundParameters.ContainsKey('DefaultUICulture') -and !$PSBoundParameters.ContainsKey('UICulture')) {
            # We don't want the resolution to eventually return the ModuleManifest
            # So we run the same GetFilePath() logic than here:
            # https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.Commands.Utility/commands/utility/Import-LocalizedData.cs#L302-L333
            # and if we see it will return the wrong thing, set the UICulture to DefaultUI culture, and return the logic to Import-LocalizedData
            $currentCulture = Get-UICulture

            $fullFileName = $FileName + ".psd1"
            $LanguageFile = $null

            while ($null -ne $currentCulture -and $currentCulture.Name -and !$LanguageFile) {
                $filePath = [io.Path]::Combine($CallingScriptRoot, $CurrentCulture.Name, $fullFileName)
                if (Test-Path $filePath) {
                    Write-Debug "Found $filePath"
                    $LanguageFile = $filePath
                }
                else {
                    Write-Debug "File $filePath not found"
                }
                $currentCulture = $currentCulture.Parent
            }

            if (!$LanguageFile) {
                $PSBoundParameters.Add('UICulture', $DefaultUICulture)
            }
            $null = $PSBoundParameters.remove('DefaultUICulture')
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Import-LocalizedData', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        if ($BindingVariable -and ($valueToBind = Get-Variable -Name $BindingVariable -ValueOnly -ErrorAction Ignore)) {
            # Bringing the variable to the parent scope
            Set-Variable -Scope 1 -Name $BindingVariable -Force -ErrorAction SilentlyContinue -Value $valueToBind
        }
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }
    <#

.ForwardHelpTargetName Microsoft.PowerShell.Utility\Import-LocalizedData
.ForwardHelpCategory Cmdlet

#>
}