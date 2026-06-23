// Parser rules
e : e PLUS e
  | e TIMES e
  | NUM
  ;

// Lexer rules
PLUS : '+' ;
TIMES : '*' ;
NUM : [0-9]+ ;

WS : [ \r\n\t]+ -> skip ;
