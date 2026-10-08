open Types

let grammar_gcl : grammar =
  {
    nonterminals = [ "S"; "VP"; "NP" ];
    terminals = [ "cl"; "det"; "n"; "v" ];
    productions =
      [
        {
          index = 1;
          lhs = "S";
          rhs = [ Nonterminal "NP"; Nonterminal "VP" ];
          head_pos = 2;
        };
        {
          index = 2;
          lhs = "VP";
          rhs = [ Terminal "cl"; Terminal "v"; Nonterminal "NP" ];
          head_pos = 2;
        };
        {
          index = 3;
          lhs = "NP";
          rhs = [ Terminal "det"; Terminal "n" ];
          head_pos = 1;
        };
      ];
    start = "S";
  }

let grammar_simple : grammar =
  {
    nonterminals = [ "S"; "A" ];
    terminals = [ "a"; "b" ];
    productions =
      [
        {
          index = 1;
          lhs = "S";
          rhs = [ Nonterminal "A"; Terminal "B" ];
          head_pos = 1;
        };
        {
          index = 2;
          lhs = "A";
          rhs = [ Terminal "a"; Terminal "b" ];
          head_pos = 1;
        };
        {
          index = 3;
          lhs = "A";
          rhs = [ Nonterminal "A"; Terminal "a"; Terminal "b" ];
          head_pos = 1;
        };
        {
          index = 4;
          lhs = "B";
          rhs = [ Nonterminal "B"; Terminal "a"; Terminal "a"; Terminal "b" ];
          head_pos = 2;
        };
        {
          index = 5;
          lhs = "B";
          rhs = [ Terminal "a"; Terminal "a"; Terminal "b" ];
          head_pos = 2;
        };
      ];
    start = "S";
  }

let grammar_arith : grammar =
  {
    nonterminals = [ "E"; "T" ];
    terminals = [ "+"; "n" ];
    productions =
      [
        {
          index = 1;
          lhs = "E";
          rhs = [ Nonterminal "E"; Terminal "+"; Nonterminal "T" ];
          head_pos = 2;
        };
        { index = 2; lhs = "E"; rhs = [ Nonterminal "T" ]; head_pos = 1 };
        { index = 3; lhs = "T"; rhs = [ Terminal "n" ]; head_pos = 1 };
      ];
    start = "E";
  }

(* S -> A B, A -> a | ε, B -> b *)
let grammar_epsilon : grammar =
  {
    nonterminals = [ "S"; "A"; "B" ];
    terminals = [ "a"; "b" ];
    productions =
      [
        {
          index = 1;
          lhs = "S";
          rhs = [ Nonterminal "A"; Nonterminal "B" ];
          head_pos = 1;
        };
        { index = 2; lhs = "A"; rhs = [ Terminal "a" ]; head_pos = 1 };
        { index = 3; lhs = "A"; rhs = []; head_pos = 0 };
        { index = 4; lhs = "B"; rhs = [ Terminal "b" ]; head_pos = 1 };
      ];
    start = "S";
  }

(* Astar -> A Astar | ε, A -> a *)
let grammar_abc : grammar =
  {
    nonterminals = [ "A"; "B"; "C" ];
    terminals = [ "w1"; "w2"; "w3" ];
    productions =
      [
        { index = 1; lhs = "A"; rhs = [ Nonterminal "B"; Nonterminal "C" ]; head_pos = 1 };
        { index = 2; lhs = "B"; rhs = [ Terminal "w1" ]; head_pos = 1 };
        { index = 3; lhs = "C"; rhs = [ Terminal "w2"; Terminal "w3" ]; head_pos = 1 };
      ];
    start = "A";
  }

(* Reproducer: X -> A D E (head=D), A -> B C (head=C).
   Fragment ["c";"d";"e"] — B missing from A, A missing from X.
   l_reduce must apply find_left_expansions (not just find_right_expansions_by_right)
   to infer CompleteItem "A" at T[0,1] with virtual B, enabling X at T[0,3]. *)
let grammar_lreduce_left_expansion : grammar =
  {
    nonterminals = [ "X"; "A"; "B"; "C"; "D"; "E" ];
    terminals = [ "b"; "c"; "d"; "e" ];
    productions =
      [
        {
          index = 1;
          lhs = "X";
          rhs = [ Nonterminal "A"; Nonterminal "D"; Nonterminal "E" ];
          head_pos = 2;
        };
        {
          index = 2;
          lhs = "A";
          rhs = [ Nonterminal "B"; Nonterminal "C" ];
          head_pos = 2;
        };
        { index = 3; lhs = "B"; rhs = [ Terminal "b" ]; head_pos = 1 };
        { index = 4; lhs = "C"; rhs = [ Terminal "c" ]; head_pos = 1 };
        { index = 5; lhs = "D"; rhs = [ Terminal "d" ]; head_pos = 1 };
        { index = 6; lhs = "E"; rhs = [ Terminal "e" ]; head_pos = 1 };
      ];
    start = "X";
  }

(* R-Reduce left_expansion case:
   TOP → F P (head=F, pos=1): head is leftmost, P is a right sibling.
   P → B H (head=H, pos=2): B is left sibling (x_h in left_expansion), H is head.
   B → C D (head=D, pos=2): B itself needs C from left.

   Fragment ["f";"c";"d"] — H is missing from P.
   After the agenda, CompleteItem("B") arrives at T[1,3] via C+D combination.
   r_reduce_step k=0 fires find_left_expansions_by_left(B): left_expansion rule
   (CompleteItem("P"), B, PartialItem(r_P,1,2)) → P at T[1,3] with virtual H.
   Agenda then: P at T[1,3] + PartialItem(r_TOP,0,1) at T[0,1] → TOP at T[0,3].

   Without the fix (find_right_expansions only): B has no right_expansion rule
   (P→BH has head at rightmost position), so P is never inferred at T[1,3]. *)
let grammar_rreduce_left_expansion : grammar =
  {
    nonterminals = [ "TOP"; "P"; "B"; "F"; "C"; "D"; "H" ];
    terminals = [ "f"; "c"; "d"; "h" ];
    productions =
      [
        {
          index = 1;
          lhs = "TOP";
          rhs = [ Nonterminal "F"; Nonterminal "P" ];
          head_pos = 1;
        };
        {
          index = 2;
          lhs = "P";
          rhs = [ Nonterminal "B"; Nonterminal "H" ];
          head_pos = 2;
        };
        {
          index = 3;
          lhs = "B";
          rhs = [ Nonterminal "C"; Nonterminal "D" ];
          head_pos = 2;
        };
        { index = 4; lhs = "F"; rhs = [ Terminal "f" ]; head_pos = 1 };
        { index = 5; lhs = "C"; rhs = [ Terminal "c" ]; head_pos = 1 };
        { index = 6; lhs = "D"; rhs = [ Terminal "d" ]; head_pos = 1 };
        { index = 7; lhs = "H"; rhs = [ Terminal "h" ]; head_pos = 1 };
      ];
    start = "TOP";
  }

let grammar_astar : grammar =
  {
    nonterminals = [ "Astar"; "A" ];
    terminals = [ "a" ];
    productions =
      [
        {
          index = 1;
          lhs = "Astar";
          rhs = [ Nonterminal "A"; Nonterminal "Astar" ];
          head_pos = 1;
        };
        { index = 2; lhs = "Astar"; rhs = []; head_pos = 0 };
        { index = 3; lhs = "A"; rhs = [ Terminal "a" ]; head_pos = 1 };
      ];
    start = "Astar";
  }
