<#
    .SYNOPSIS
        The localized resource strings in English (en-US) for the
        DscResource.AnalyzerRules module. This file should only contain
        localized strings for private and public functions.
#>

ConvertFrom-StringData @'
    ParameterBlockParameterAttributeMissing    = A [Parameter()] attribute must be the first attribute of each parameter and be on its own line. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    ParameterBlockParameterAttributeLowerCase  = The [Parameter()] attribute must start with an upper case 'P'. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    ParameterBlockParameterAttributeWrongPlace = The [Parameter()] attribute must be the first attribute of each parameter. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    ParameterBlockParameterMandatoryAttributeWrongFormat = Mandatory parameters must use the correct format [Parameter(Mandatory = $true)] for the mandatory attribute. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    ParameterBlockNonMandatoryParameterMandatoryAttributeWrongFormat = Non-mandatory parameters must use the correct format [Parameter()] for the parameter attribute. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    FunctionOpeningBraceNotOnSameLine = Functions should not have the open brace on the same line as the function name. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    FunctionOpeningBraceShouldBeFollowedByNewLine = Opening brace on function should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    FunctionOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on functions should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    StatementsContainsUpperCaseLetter = '{0}' statements should not contain upper case letters See https://dsccommunity.org/styleguidelines/general/#correct-format-for-keywords
    IfStatementOpeningBraceNotOnSameLine = If-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    IfStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on if-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    IfStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on if-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    ForEachStatementOpeningBraceNotOnSameLine = Foreach-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    ForEachStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on foreach-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    ForEachStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on foreach-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    DoUntilStatementOpeningBraceNotOnSameLine = DoUntil-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    DoUntilStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on DoUntil-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    DoUntilStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on DoUntil-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    DoWhileStatementOpeningBraceNotOnSameLine = DoWhile-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    DoWhileStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on DoWhile-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    DoWhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on DoWhile-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    WhileStatementOpeningBraceNotOnSameLine = While-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    WhileStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on while-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    WhileStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on while-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    ForStatementOpeningBraceNotOnSameLine = For-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    ForStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on for-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    ForStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on for-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    SwitchStatementOpeningBraceNotOnSameLine = Switch-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    SwitchStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on switch-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    SwitchStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on switch-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    TryStatementOpeningBraceNotOnSameLine = Try-statements should not have the open brace on the same line as the statement. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    TryStatementOpeningBraceShouldBeFollowedByNewLine = Opening brace on try-statements should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    TryStatementOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on try-statements should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    CatchClauseOpeningBraceNotOnSameLine = Catch-clause should not have the open brace on the same line as the clause. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    CatchClauseOpeningBraceShouldBeFollowedByNewLine = Opening brace on catch-clause should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    CatchClauseOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on catch-clause should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    EnumOpeningBraceNotOnSameLine = Enum should not have the open brace on the same line as the declaration. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    EnumOpeningBraceShouldBeFollowedByNewLine = Opening brace on Enum should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    EnumOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on Enum should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    ClassOpeningBraceNotOnSameLine = Class should not have the open brace on the same line as the declaration. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-before-braces
    ClassOpeningBraceShouldBeFollowedByNewLine = Opening brace on Class should be followed by a new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    ClassOpeningBraceShouldBeFollowedByOnlyOneNewLine = Opening brace on Class should only be followed by one new line. See https://dsccommunity.org/styleguidelines/whitespace/#one-newline-after-opening-brace
    OneSpaceBetweenKeywordAndParenthesis = If a keyword is followed by a parenthesis, there should be single space between the keyword and the parenthesis. See https://dsccommunity.org/styleguidelines/whitespace/#one-space-between-keyword-and-parenthesis
    HashtableShouldHaveCorrectFormat = Hashtable is not correctly formatted. See https://dsccommunity.org/styleguidelines/general/#correct-format-for-hashtables-or-objects
    ParamBlockEmptyParenthesesShouldBeOnSameLine = If ParamBlock parentheses are empty they should be on the same line. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    ParamBlockEmptyParenthesesShouldNotHaveWhitespace = If ParamBlock parentheses are empty they should not contain whitespace. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
    ParamBlockNotEmptyParenthesesShouldBeOnNewLine = If ParamBlock parentheses are not empty they should be on a new line. See https://dsccommunity.org/styleguidelines/parameters/#correct-format-for-parameter-block
'@
