// Nested (centre-embedded) recursion.
//   s -> ( s )  nests to arbitrary depth:  ( ( ( NUM ) ) )
//
// The head is marked on the nested s, so 1 < tau < pi and every cover
// rule shape fires: left-expand, right-expand, and BOTH close rules.
s : LPAREN [s] RPAREN
  | [NUM]
  ;

// Lexer rules
LPAREN : '(' ;
RPAREN : ')' ;
NUM    : [0-9]+ ;

WS : [ \r\n\t]+ -> skip ;
