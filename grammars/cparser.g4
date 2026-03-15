compilationUnit
    : translationUnit? EOF
    ;

constant
    : IntegerConstant
    | FloatingConstant
    | CharacterConstant
    | predefinedConstant
    ;

enumerationConstant
    : Identifier
    ;

predefinedConstant
    : 'false'
    | 'true'
    | 'nullptr'
    ;

primaryExpression
    : Identifier
    | constant
    | StringLiteral+
    | '(' expression ')'
    | genericSelection
    | '__func__'
    | '__FUNCTION__'
    | '__PRETTY_FUNCTION__'
    | '__extension__'? '(' compoundStatement ')'
    | '__builtin_va_arg' '(' unaryExpression ',' typeName ')'
    | '__builtin_offsetof' '(' typeName ',' unaryExpression ')'
    | '__builtin_choose_expr' '(' unaryExpression ',' unaryExpression ',' unaryExpression ')'
    | '__builtin_types_compatible_p' '(' typeName ',' typeName ')'
    | '__builtin_tgmath' '(' exprList ')'
    | '__builtin_complex' '(' assignmentExpression ',' assignmentExpression ')'
    ;

exprList
    : assignmentExpression (',' assignmentExpression)*
    ;

genericSelection
    : '_Generic' '(' assignmentExpression ',' genericAssocList ')'
    ;

genericAssocList
    : genericAssociation (',' genericAssociation)*
    ;

genericAssociation
    : (typeName | 'default') ':' assignmentExpression
    ;

postfixExpression
    : (primaryExpression | '__extension__'? '(' typeName ')' '{' initializerList? ','? '}')
      (
        '[' expression ']'
        | '(' argumentExpressionList? ')'
        | ('.' | '->') Identifier
        | '++'
        | '--'
      )*
    ;

argumentExpressionList
    : assignmentExpression (',' assignmentExpression)*
    ;

unaryExpression
    : postfixExpression
    | '++' unaryExpression
    | '--' unaryExpression
    | ('&' | '*' | '+' | '-' | '~' | '!' | '__extension__' | '__real__' | '__imag__') castExpression
    | 'sizeof' unaryExpression
    | 'sizeof' '(' typeName ')'
    | Alignof '(' typeName ')'
    | Countof unaryExpression
    | Countof '(' typeName ')'
    | Alignof unaryExpression
    | Maxof '(' typeName ')'
    | Minof '(' typeName ')'
    | '&&' Identifier
    ;

castExpression
    : '(' typeName ')' castExpression
    | unaryExpression
    | DigitSequence
    ;

multiplicativeExpression
    : castExpression (('*' | '/' | '%') castExpression)*
    ;

additiveExpression
    : multiplicativeExpression (('+' | '-') multiplicativeExpression)*
    ;

shiftExpression
    : additiveExpression (('<<' | '>>') additiveExpression)*
    ;

relationalExpression
    : shiftExpression (('<' | '>' | '<=' | '>=') shiftExpression)*
    ;

equalityExpression
    : relationalExpression (('==' | '!=') relationalExpression)*
    ;

andExpression
    : equalityExpression ('&' equalityExpression)*
    ;

exclusiveOrExpression
    : andExpression ('^' andExpression)*
    ;

inclusiveOrExpression
    : exclusiveOrExpression ('|' exclusiveOrExpression)*
    ;

logicalAndExpression
    : inclusiveOrExpression ('&&' inclusiveOrExpression)*
    ;

logicalOrExpression
    : logicalAndExpression ('||' logicalAndExpression)*
    ;

conditionalExpression
    : logicalOrExpression ('?' expression ':' conditionalExpression)?
    ;

assignmentExpression
    : conditionalExpression
    | unaryExpression ('=' | '*=' | '/=' | '%=' | '+=' | '-=' | '<<=' | '>>=' | '&=' | '^=' | '|=') assignmentExpression
    | DigitSequence
    ;

expression
    : assignmentExpression (',' assignmentExpression)*
    ;

constantExpression
    : conditionalExpression
    ;

declaration
    : declarationSpecifiers initDeclaratorList? ';'
    | staticAssertDeclaration
    | attributeDeclaration
    ;

declarationSpecifiers
    : declarationSpecifier+
    ;

declarationSpecifier
    : storageClassSpecifier
    | typeSpecifier
    | typeQualifier
    | functionSpecifier
    | alignmentSpecifier
    ;

initDeclaratorList
    : initDeclarator (',' initDeclarator)*
    ;

initDeclarator
    : declarator ('=' initializer)?
    ;

attributeDeclaration
    : attributeSpecifierSequence ';'
    ;

storageClassSpecifier
    : 'auto'
    | 'constexpr'
    | 'extern'
    | 'register'
    | 'static'
    | ThreadLocal
    | 'typedef'
    ;

typeSpecifier
    : 'void'
    | 'char'
    | 'short'
    | 'int'
    | 'long'
    | 'float'
    | 'double'
    | 'signed'
    | 'unsigned'
    | Bool
    | '_Complex'
    | '__m128'
    | '__m128d'
    | '__m128i'
    | '__extension__' '(' ('__m128' | '__m128d' | '__m128i') ')'
    | atomicTypeSpecifier
    | structOrUnionSpecifier
    | enumSpecifier
    | '__extension__'? typedefName
    | typeofSpecifier
    ;

structOrUnionSpecifier
    : structOrUnion attributeSpecifierSequence? gnuAttributes?
        ( Identifier? '{' memberDeclarationList? '}'
        | Identifier
        )
    ;

structOrUnion
    : 'struct'
    | 'union'
    ;

memberDeclarationList
    : memberDeclaration+
    ;

memberDeclaration
    : attributeSpecifierSequence? specifierQualifierList memberDeclaratorList? ';'
    | staticAssertDeclaration
    | '__extension__' memberDeclaration
    ;

specifierQualifierList
    : gnuAttributes? typeSpecifierQualifier+ attributeSpecifierSequence?
    ;

typeSpecifierQualifier
    : typeSpecifier
    | typeQualifier
    | alignmentSpecifier
    ;

memberDeclaratorList
    : memberDeclarator (',' gnuAttributes? memberDeclarator)*
    ;

memberDeclarator
    : declarator gnuAttributes?
    | declarator? ':' constantExpression gnuAttributes?
    ;

enumSpecifier
    : 'enum' attributeSpecifierSequence? gnuAttributes? Identifier? enumTypeSpecifier? '{' enumeratorList ','? '}'
    | 'enum' Identifier enumTypeSpecifier?
    ;

enumeratorList
    : enumerator (',' enumerator)*
    ;

enumerator
    : enumerationConstant attributeSpecifierSequence? gnuAttributes? ('=' constantExpression)?
    ;

enumTypeSpecifier
    : specifierQualifierList
    ;

atomicTypeSpecifier
    : '_Atomic' '(' typeName ')'
    ;

typeofSpecifier
    : (Typeof | Typeof_unqual) '(' typeofSpecifierArgument ')'
    ;

typeofSpecifierArgument
    : expression
    | typeName
    ;

typeQualifier
    : 'const'
    | Restrict
    | Volatile
    | '_Atomic'
    ;

functionSpecifier
    : Inline
    | '_Noreturn'
    | '__stdcall'
    | gnuAttribute
    | '__declspec' '(' (Identifier | Restrict | 'deprecated' '(' StringLiteral? ')') ')'
    ;

alignmentSpecifier
    : Alignas '(' (typeName | constantExpression) ')'
    ;

declarator
    : (gnuAttribute? pointer)* (gnuAttribute* directDeclarator gccDeclaratorExtension*)
    ;

directDeclarator
    : (
        Identifier attributeSpecifierSequence?
        | '(' declarator ')'
        | Identifier ':' DigitSequence
        | vcSpecificModifer Identifier
        | '(' vcSpecificModifer declarator ')'
        | gnuAttribute
      )
      ( '[' typeQualifierList? assignmentExpression? ']' attributeSpecifierSequence?
        | '[' 'static' typeQualifierList? assignmentExpression ']' attributeSpecifierSequence?
        | '[' typeQualifierList 'static' assignmentExpression ']' attributeSpecifierSequence?
        | '[' typeQualifierList? '*' ']' attributeSpecifierSequence?
        | '(' parameterTypeList ')' attributeSpecifierSequence?
      )*
    ;

pointer
    : (('*' | '^') typeQualifierList?)+
    ;

typeQualifierList
    : typeQualifier+
    ;

parameterTypeList
    : parameterList (',' '...')?
    | '...'
    ;

parameterList
    : parameterDeclaration (',' parameterDeclaration)*
    ;

parameterDeclaration
    : attributeSpecifierSequence? declarationSpecifiers? (declarator | abstractDeclarator)?
    ;

typeName
    : specifierQualifierList abstractDeclarator?
    ;

abstractDeclarator
    : vcSpecificModifer? pointer
    | vcSpecificModifer? pointer? directAbstractDeclarator gccDeclaratorExtension*
    ;

directAbstractDeclarator
    : '(' abstractDeclarator ')' gccDeclaratorExtension*
    | '[' typeQualifierList? assignmentExpression? ']'
    | '[' 'static' typeQualifierList? assignmentExpression ']'
    | '[' typeQualifierList 'static' assignmentExpression ']'
    | '[' '*' ']'
    | '(' parameterTypeList ')' gccDeclaratorExtension*
    | directAbstractDeclarator '[' typeQualifierList? assignmentExpression? ']'
    | directAbstractDeclarator '[' 'static' typeQualifierList? assignmentExpression ']'
    | directAbstractDeclarator '[' typeQualifierList 'static' assignmentExpression ']'
    | directAbstractDeclarator '[' '*' ']'
    | directAbstractDeclarator '(' parameterTypeList ')' gccDeclaratorExtension*
    ;

typedefName
    : Identifier
    ;

initializer
    : assignmentExpression
    | '{' initializerList ','? '}'
    | '{' '}'
    ;

initializerList
    : designation? initializer (',' designation? initializer)*
    ;

designation
    : designatorList '='
    | gnuArrayDesignator
    | gnuIdentifier ':'
    ;

designatorList
    : designator+
    ;

designator
    : gnuArrayDesignator
    | '.' Identifier
    ;

staticAssertDeclaration
    : '_Static_assert' '(' constantExpression (',' StringLiteral)? ')' ';'
    ;

attributeSpecifierSequence
    : attributeSpecifier+
    ;

attributeSpecifier
    : '[' '[' attributeList ']' ']'
    ;

attributeList
    : attribute (',' attribute)*
    ;

attribute
    : attributeToken attributeArgumentClause?
    ;

attributeToken
    : Identifier
    | Identifier ':' ':' Identifier
    ;

attributeArgumentClause
    : '(' balancedTokenSequence? ')'
    ;

balancedTokenSequence
    : balancedToken+
    ;

balancedToken
    : '(' balancedTokenSequence? ')'
    | '[' balancedTokenSequence? ']'
    | '{' balancedTokenSequence? '}'
    ;

statement
    : labeledStatement
    | compoundStatement
    | expressionStatement
    | selectionStatement
    | iterationStatement
    | jumpStatement
    | asmStatement
    ;

labeledStatement
    : Identifier ':' statement?
    | Label Identifier ';'
    | 'case' constantExpression ':' statement
    | 'default' ':' statement
    ;

compoundStatement
    : '{' blockItemList? '}'
    ;

blockItemList
    : blockItem+
    ;

blockItem
    : statement
    | declaration
    ;

expressionStatement
    : expression? ';'
    ;

selectionStatement
    : 'if' '(' expression ')' statement ('else' statement)?
    | 'switch' '(' expression ')' statement
    ;

iterationStatement
    : While '(' expression ')' statement
    | Do statement While '(' expression ')' ';'
    | For '(' forCondition ')' statement
    ;

forCondition
    : (forDeclaration | expression?) ';' forExpression? ';' forExpression?
    ;

forDeclaration
    : declarationSpecifiers initDeclaratorList?
    ;

forExpression
    : assignmentExpression (',' assignmentExpression)*
    ;

jumpStatement
    : 'goto' Identifier ';'
    | 'continue' ';'
    | 'break' ';'
    | 'return' expression? ';'
    | 'goto' unaryExpression ';'
    ;

translationUnit
    : externalDeclaration+
    ;

externalDeclaration
    : '__extension__'? (
        functionDefinition
        | declaration
        | ';'
        | asmDefinition
      )
    ;

functionDefinition
    : attributeSpecifierSequence? declarationSpecifiers? declarator declarationList? functionBody
    ;

declarationList
    : declaration+
    ;

functionBody
    : compoundStatement
    ;

identifierList
    : Identifier (',' Identifier)*
    ;

gnuArrayDesignator
    : '[' constantExpression ('...' constantExpression)? ']'
    ;

gnuIdentifier
    : Identifier
    ;

asmArgument
    : asmStringLiteral
    | asmStringLiteral ':' asmOperands? (':' asmOperands? (':' asmClobbers?)* )?
    ;

asmClobbers
    : (asmStringLiteral | Identifier) (',' (asmStringLiteral | Identifier))*
    ;

asmDefinition
    : simpleAsmExpr
    | Asm '(' toplevelAsmArgument ')'
    ;

toplevelAsmArgument
    : asmStringLiteral
    | asmStringLiteral ':' asmOperands?
    | asmStringLiteral ':' asmOperands? ':' asmOperands?
    ;

asmOperand
    : asmStringLiteral '(' expression ')'
    | '[' Identifier ']' asmStringLiteral '(' expression ')'
    ;

asmOperands
    : asmOperand (',' asmOperand)*
    ;

asmQualifier
    : Volatile
    | Inline
    | 'goto'
    ;

asmQualifierList
    : asmQualifier+
    ;

asmStatement
    : Asm asmQualifierList? '(' asmArgument ')' ';'
    ;

asmStringLiteral
    : StringLiteral
    ;

gccDeclaratorExtension
    : asmDefinition
    | gnuAttribute
    ;

gnuAttribute
    : Attribute '(' '(' gnuAttributeList ')' ')'
    ;

gnuAttributeList
    : gnuSingleAttribute*
    ;

gnuAttributes
    : gnuAttribute+
    ;

gnuSingleAttribute
    : '(' gnuAttributeList ')'
    ;

simpleAsmExpr
    : Asm '(' asmStringLiteral ')'
    ;

vcSpecificModifer
    : '__cdecl'
    | '__clrcall'
    | '__stdcall'
    | '__fastcall'
    | '__thiscall'
    | '__vectorcall'
    ;
