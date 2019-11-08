<#
    .SYNOPSIS
        Validates the [Parameter()] attribute for each parameter.

    .DESCRIPTION
        All parameters in a param block must contain a [Parameter()] attribute
        and it must be the first attribute for each parameter and must start with
        a capital letter P.

    .EXAMPLE
        Measure-ParameterBlockParameterAttribute -ParameterAst $parameterAst

    .INPUTS
        [System.Management.Automation.Language.ParameterAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

    .NOTES
        None
#>
function Measure-ParameterBlockParameterAttribute
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ParameterAst]
        $ParameterAst
    )

    try
    {
        $script:diagnosticRecord['Extent'] = $ParameterAst.Extent
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName
        [System.Boolean] $inAClass = Test-IsInClass -Ast $ParameterAst

        <#
            If we are in a class the parameter attributes are not valid in Classes
            the ParameterValidation attributes are however
        #>
        if (!$inAClass)
        {
            if ($ParameterAst.Attributes.TypeName.FullName -notContains 'parameter')
            {
                $script:diagnosticRecord['Message'] = $localizedData.ParameterBlockParameterAttributeMissing

                $script:diagnosticRecord -as $script:diagnosticRecordType
            }
            elseif ($ParameterAst.Attributes[0].TypeName.FullName -ne 'parameter')
            {
                $script:diagnosticRecord['Message'] = $localizedData.ParameterBlockParameterAttributeWrongPlace

                $script:diagnosticRecord -as $script:diagnosticRecordType
            }
            elseif ($ParameterAst.Attributes[0].TypeName.FullName -cne 'Parameter')
            {
                $script:diagnosticRecord['Message'] = $localizedData.ParameterBlockParameterAttributeLowerCase

                $script:diagnosticRecord -as $script:diagnosticRecordType
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
