<#
    .SYNOPSIS
        Validates use of the Mandatory named argument within a Parameter attribute.

    .DESCRIPTION
        If a parameter attribute contains the mandatory attribute the
        mandatory attribute must be formatted correctly.

    .EXAMPLE
        Measure-ParameterBlockMandatoryNamedArgument -NamedAttributeArgumentAst $namedAttributeArgumentAst

    .INPUTS
        [System.Management.Automation.Language.NamedAttributeArgumentAst]

    .OUTPUTS
        [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]

    .NOTES
        None
#>
function Measure-ParameterBlockMandatoryNamedArgument
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.NamedAttributeArgumentAst]
        $NamedAttributeArgumentAst
    )

    try
    {
        $script:diagnosticRecord['RuleName'] = $PSCmdlet.MyInvocation.InvocationName
        [System.Boolean] $inAClass = Test-IsInClass -Ast $NamedAttributeArgumentAst

        <#
            Parameter Attributes are not valid in classes, and DscProperty does
            not use the (Mandatory = $true) format just DscProperty(Mandatory)
        #>
        if (!$inAClass)
        {
            if ($NamedAttributeArgumentAst.ArgumentName -eq 'Mandatory')
            {
                $script:diagnosticRecord['Extent'] = $NamedAttributeArgumentAst.Extent

                if ($NamedAttributeArgumentAst)
                {
                    $invalidFormat = $false
                    try
                    {
                        $value = $NamedAttributeArgumentAst.Argument.SafeGetValue()
                        if ($value -eq $false)
                        {
                            $script:diagnosticRecord['Message'] = $script:localizedData.ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat

                            $script:diagnosticRecord -as $script:diagnosticRecordType
                        }
                        elseif ($NamedAttributeArgumentAst.Argument.VariablePath.UserPath -cne 'true')
                        {
                            $invalidFormat = $true
                        }
                        elseif ($NamedAttributeArgumentAst.ArgumentName -cne 'Mandatory')
                        {
                            $invalidFormat = $true
                        }
                    }
                    catch
                    {
                        $invalidFormat = $true
                    }

                    if ($invalidFormat)
                    {
                        $script:diagnosticRecord['Message'] = $script:localizedData.ParameterBlockParameterMandatoryAttributeWrongFormat

                        $script:diagnosticRecord -as $script:diagnosticRecordType
                    }
                }
            }
        }
    }
    catch
    {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}
