// Simplified C grammar using ANTLR CLexer token names.
// Covers function definitions, declarations, and common expressions.
// Written for the head-driven parser (no inline groups, no predicates).

translationUnit
    : externalDeclaration+
    ;

externalDeclaration
    : functionDefinition
    ;

functionDefinition
    : typeSpecifier Identifier LeftParen parameterList RightParen compoundStatement
    | typeSpecifier Identifier LeftParen RightParen compoundStatement
    ;

typeSpecifier
    : Int
    | Void
    | Char
    | Short
    | Long
    | Float
    | Double
    | Unsigned
    | Signed
    ;

parameterList
    : parameterDeclaration
    | parameterList Comma parameterDeclaration
    ;

parameterDeclaration
    : typeSpecifier Identifier
    ;

compoundStatement
    : LeftBrace blockItemList RightBrace
    | LeftBrace RightBrace
    ;

blockItemList
    : blockItem+
    ;

blockItem
    : statement
    | declaration
    ;

declaration
    : typeSpecifier Identifier Semi
    | typeSpecifier Identifier Assign expression Semi
    ;

statement
    : jumpStatement
    | expressionStatement
    | compoundStatement
    ;

jumpStatement
    : Return expression Semi
    | Return Semi
    ;

expressionStatement
    : expression Semi
    | Semi
    ;

expression
    : additiveExpression
    ;

additiveExpression
    : multiplicativeExpression
    | additiveExpression Plus multiplicativeExpression
    | additiveExpression Minus multiplicativeExpression
    ;

multiplicativeExpression
    : unaryExpression
    | multiplicativeExpression Star unaryExpression
    | multiplicativeExpression Div unaryExpression
    | multiplicativeExpression Mod unaryExpression
    ;

unaryExpression
    : primaryExpression
    ;

primaryExpression
    : Identifier
    | IntegerConstant
    | LeftParen expression RightParen
    ;
