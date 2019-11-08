<#
    .SYNOPSIS
        Validates the Class and Enum of PowerShell.

    .DESCRIPTION
        Each Class or Enum must be formatted correctly.

    .EXAMPLE
        Measure-TypeDefinition -TypeDefinitionAst $ScriptBlockAst

    .INPUTS
        [System.Management.Automation.Language.TypeDefinitionAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

   .NOTES
        None
#>
function Measure-TypeDefinition
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.TypeDefinitionAst]
        $TypeDefinitionAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $TypeDefinitionAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName

        $testParameters = @{
            StatementBlock = $TypeDefinitionAst.Extent
        }

        if ($TypeDefinitionAst.IsEnum)
        {
            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.EnumOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.EnumOpeningBraceShouldBeFollowedByNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.EnumOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        } # if
        elseif ($TypeDefinitionAst.IsClass)
        {
            if (Test-StatementOpeningBraceOnSameLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ClassOpeningBraceNotOnSameLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsNotFollowedByNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ClassOpeningBraceShouldBeFollowedByNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if

            if (Test-StatementOpeningBraceIsFollowedByMoreThanOneNewLine @testParameters)
            {
                $script:diagnosticRecord['Message'] = $localizedData.ClassOpeningBraceShouldBeFollowedByOnlyOneNewLine
                $script:diagnosticRecord -as $diagnosticRecordType
            } # if
        } # if
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
