// Rekers-Koorn example grammar (Figure 1)
start : stat | exp ;

stat : IF exp [THEN] stat
     | IF exp THEN stat [ELSE] stat
     | ID [ASSIGN] exp
     ;

exp : ID
    | INT
    | exp [PLUS] exp
    | exp [TIMES] exp
    | LPAREN exp [RPAREN]
    ;
