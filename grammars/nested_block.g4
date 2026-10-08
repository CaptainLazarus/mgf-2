// Four-level nesting cycle:  block -> stmts -> stmt -> block
// Plus a second nesting path through IF, so depth can grow two ways.
//   { if ( x ) { y ; } }
program : [block]
        ;

block : LBRACE [stmts] RBRACE
      ;

stmts : [stmt]
      | stmt [stmts]
      ;

stmt : [ID] SEMI
     | [block]
     | IF LPAREN ID RPAREN [stmt]
     | WHILE LPAREN ID RPAREN [block]
     ;

// Lexer rules
LBRACE : '{' ;
RBRACE : '}' ;
LPAREN : '(' ;
RPAREN : ')' ;
SEMI   : ';' ;
IF     : 'if' ;
WHILE  : 'while' ;
ID     : [a-z]+ ;

WS : [ \r\n\t]+ -> skip ;
