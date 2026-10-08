// Three-level nesting cycle:  e -> t -> f -> ( e )
// Each level of parens walks the full chain again.
//   NUM + ( NUM * ( NUM + NUM ) )
e : t
  | e [PLUS] t
  ;

f : [NUM]
  | LPAREN [e] RPAREN
  ;

t : f
  | t [TIMES] f
  ;

// Lexer rules
PLUS   : '+' ;
TIMES  : '*' ;
LPAREN : '(' ;
RPAREN : ')' ;
NUM    : [0-9]+ ;

WS : [ \r\n\t]+ -> skip ;
