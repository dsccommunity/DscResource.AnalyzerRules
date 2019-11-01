<#
    .SYNOPSIS
        Helper function to check if an Ast is part of a class.
        Returns true or false

    .EXAMPLE
        Test-IsInClass -Ast $ParameterBlockAst

    .INPUTS
        [System.Management.Automation.Language.Ast]

    .OUTPUTS
        [System.Boolean]

   .NOTES
        I initially just walked up the AST tree till I hit
        a TypeDefinitionAst that was a class

        But...

        That means it would throw false positives for things like

        class HasAFunctionInIt
        {
            [Func[int,int]] $MyFunc = {
                param
                (
                    [Parameter(Mandatory=$true)]
                    [int]
                    $Input
                )

                $Input
            }
        }

        Where the param block and all its respective items ARE
        valid being in their own anonymous function definition
        that just happens to be inside a class property's
        assignment value

        So This check has to be a DELIBERATE step by step up the
        AST Tree ONLY far enough to validate if it is directly
        part of a class or not
#>
function Test-IsInClass
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast]
        $Ast
    )

    [System.Boolean] $inAClass = $false
    # Is a Named Attribute part of Class Property?
    if ($Ast -is [System.Management.Automation.Language.NamedAttributeArgumentAst])
    {
        # Parent is an Attribute Ast AND
        $inAClass = $Ast.Parent -is [System.Management.Automation.Language.AttributeAst] -and
            # Grandparent is a Property Member Ast (This Ast Type ONLY shows up inside a TypeDefinitionAst) AND
            $Ast.Parent.Parent -is [System.Management.Automation.Language.PropertyMemberAst] -and
            # Great Grandparent is a Type Definition Ast AND
            $Ast.Parent.Parent.Parent -is [System.Management.Automation.Language.TypeDefinitionAst] -and
            # Great Grandparent is a Class
            $ast.Parent.Parent.Parent.IsClass
    }
    # Is a Parameter part of a Class Method?
    elseif ($Ast -is [System.Management.Automation.Language.ParameterAst])
    {
        # Parent is a Function Definition Ast AND
        $inAClass = $Ast.Parent -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            # Grandparent is a Function Member Ast (This Ast Type ONLY shows up inside a TypeDefinitionAst) AND
            $Ast.Parent.Parent -is [System.Management.Automation.Language.FunctionMemberAst] -and
            # Great Grandparent is a Type Definition Ast AND
            $Ast.Parent.Parent.Parent -is [System.Management.Automation.Language.TypeDefinitionAst] -and
            # Great Grandparent is a Class
            $Ast.Parent.Parent.Parent.IsClass
    }

    $inAClass
}
