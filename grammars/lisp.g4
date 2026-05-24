// Parser rules
lisp_ : s_expression+ EOF ;

s_expression 
    : ATOM
    | LPAREN s_expression DOT s_expression RPAREN  // dotted pair
    | list 
    ;

list : LPAREN s_expression* RPAREN ;

// Lexer rules
LPAREN : '(' ;
RPAREN : ')' ;
DOT : '.' ;

ATOM : (LETTER | DIGIT) (LETTER | DIGIT)* ;

fragment LETTER : [a-zA-Z] ;
fragment DIGIT : [0-9] ;

WS : [ \r\n\t]+ -> skip ;
