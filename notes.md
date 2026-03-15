Assumptions

1. Grammar rule order doesn't matter
2. Heads don't matter.




|i\j|   1   |   2    |          3          |   4   |          5          |          6          |          7          |
|   |  DOT  | LPAREN |        ATOM         |  DOT  |        ATOM         |       RPAREN        |       RPAREN        |
+===+=======+========+=====================+=======+=====================+=====================+=====================+
| 0 | 3^0,3 |   .    |          .          |   .   |          .          |        3^0,4        | lisp_, s_expression |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+
| 1 |       | 3^0,1  |        3^0,2        | 3^0,3 |        3^0,4        | lisp_, s_expression |          .          |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+
| 2 |       |        | lisp_, s_expression |   .   |          .          |          .          |          .          |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+
| 3 |       |        |                     |   .   |          .          |          .          |          .          |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+
| 4 |       |        |                     |       | lisp_, s_expression |          .          |          .          |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+
| 5 |       |        |                     |       |                     |          .          |          .          |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+
| 6 |       |        |                     |       |                     |                     |          .          |
+---+-------+--------+---------------------+-------+---------------------+---------------------+---------------------+


A -> X RPAREN
A -> RPAREN X



|i\j|   1    |          2          |   3   |          4          |          5          |   6    |
|   | RPAREN |        ATOM         |  DOT  |        ATOM         |       RPAREN        | RPAREN |
+===+========+=====================+=======+=====================+=====================+========+
| 0 | 3^0,1  |        3^0,2        | 3^0,3 |        3^0,4        | lisp_, s_expression |   .    |
+---+--------+---------------------+-------+---------------------+---------------------+--------+
| 1 |        | lisp_, s_expression |   .   |          .          |          .          |   .    |
+---+--------+---------------------+-------+---------------------+---------------------+--------+
| 2 |        |                     |   .   |          .          |          .          |   .    |
+---+--------+---------------------+-------+---------------------+---------------------+--------+
| 3 |        |                     |       | lisp_, s_expression |          .          |   .    |
+---+--------+---------------------+-------+---------------------+---------------------+--------+
| 4 |        |                     |       |                     |          .          |   .    |
+---+--------+---------------------+-------+---------------------+---------------------+--------+
| 5 |        |                     |       |                     |                     |   .    |
+---+--------+---------------------+-------+---------------------+---------------------+--------+


1. Check head issues [x]
2. Check the actual algo. [x]
3. Print out the identifier -> Readable but deterministic (all information smaller characters)
4. Test out where it breaks and where it doesn't
5. Proper definition of plus Productions -> s+ -> s s+

RPAREN--> {NT}

(({NT} RPAREN ) RPAREN ) RPAREN

{NT2} RPAREN RPAREN

LPAERN LPAERN LPAERN

(LPAERN (LPAERN {NT1}))

T[0,k] is empty --> Inductive

{NT1} RPAREN --> NT1 -> {NT1'} {RPAREN'} -->


## How the recognition table is filled

### Setup
1. Compute H-cover from grammar: projections (A → x), left/right expansions (A → x B), epsilon projections
2. Create empty (n+1)×(n+1) table. T[i,j] holds all h-items spanning input positions i..j

### Seeding
3. For every nullable nonterminal, insert CompleteItem into every T[i,i] (zero-width epsilon spans)
4. For each terminal at position i, find cover projections A → "term" and insert into T[i-1, i]
5. Boundary seeding: seed T[0,1] and T[n-1,n] from expansions where one child is dropped beyond the input edge (FromBoundaryRight / FromBoundaryLeft)

### Agenda loop (for each new item `a` at span [i,j])
6. Project — find B → a in cover, add B to T[i,j]
7. Epsilon project — same for epsilon projection rules
8. Left-expand — a is right child. Find B → x a. For every i' ≤ i, if x ∈ T[i',i], add B to T[i',j]
9. Right-expand — a is left child. Find B → a y. For every j' ≥ j, if y ∈ T[j,j'], add B to T[i,j']
10. Reverse — a can also fill the other slot of an expansion rule; combine with already-filled cells

New items only added once. Each new item queued and processed.

### L-Reduce (after normal agenda)
11. For each column k, climb T[0,k-1] via right-child rules, infer virtual left siblings, run agenda again to propagate right into T[0,k]

### R-Reduce (only if T[0,n] still empty)
12. Symmetric — anchor at n, climb T[k+1,n] via left-child rules, infer virtual right siblings, propagate left

### Final passes
13. One more R-Reduce pass on T[0,n] items directly
14. One more L-Reduce pass on T[0,n] items directly

Blocking lists (blocked_left, blocked_right) prevent the same partial item combining in the same direction twice — avoids infinite loops with cyclic grammars.
