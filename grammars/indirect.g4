// Purely indirect (mutual) recursion:
//   a -> b PLUS a -> (a TIMES b) PLUS a -> ...
// Neither rule mentions itself on its RHS; the recursion only closes
// through the cycle  a -> b -> a.
a : b
  | b [PLUS] a
  ;

b : [NUM]
  | a [TIMES] b
  ;

// Lexer rules
PLUS  : '+' ;
TIMES : '*' ;
NUM   : [0-9]+ ;

WS : [ \r\n\t]+ -> skip ;
