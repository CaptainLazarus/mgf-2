// Five-level nesting cycle:  value -> object -> members -> pair -> value
// Second cycle through arrays:  value -> array -> elems -> value
//   { "a" : [ 1 , { "b" : 2 } ] }
value : [NUM]
      | [STRING]
      | [object]
      | [array]
      ;

object : LBRACE [members] RBRACE
       | LBRACE RBRACE
       ;

members : [pair]
        | pair COMMA [members]
        ;

pair : STRING [COLON] value
     ;

array : LBRACK [elems] RBRACK
      | LBRACK RBRACK
      ;

elems : [value]
      | value COMMA [elems]
      ;

// Lexer rules
LBRACE : '{' ;
RBRACE : '}' ;
LBRACK : '[' ;
RBRACK : ']' ;
COMMA  : ',' ;
COLON  : ':' ;
NUM    : [0-9]+ ;
STRING : '"' ;

WS : [ \r\n\t]+ -> skip ;
