open Types

let grammar_gcl : grammar =
  {
    nonterminals = [ "S"; "VP"; "NP" ];
    terminals = [ "cl"; "det"; "n"; "v" ];
    productions =
      [
        { index = 1; lhs = "S";  rhs = [ Nonterminal "NP"; Nonterminal "VP" ]; head_pos = 2 };
        { index = 2; lhs = "VP"; rhs = [ Terminal "cl"; Terminal "v"; Nonterminal "NP" ]; head_pos = 2 };
        { index = 3; lhs = "NP"; rhs = [ Terminal "det"; Terminal "n" ]; head_pos = 1 };
      ];
    start = "S";
  }

let grammar_simple : grammar =
  {
    nonterminals = [ "S"; "A" ];
    terminals = [ "a"; "b" ];
    productions =
      [
        { index = 1; lhs = "S"; rhs = [ Nonterminal "A"; Terminal "B" ]; head_pos = 1 };
        { index = 2; lhs = "A"; rhs = [ Terminal "a"; Terminal "b" ]; head_pos = 1 };
        { index = 3; lhs = "A"; rhs = [ Nonterminal "A"; Terminal "a"; Terminal "b" ]; head_pos = 1 };
        { index = 4; lhs = "B"; rhs = [ Nonterminal "B"; Terminal "a"; Terminal "a"; Terminal "b" ]; head_pos = 2 };
        { index = 5; lhs = "B"; rhs = [ Terminal "a"; Terminal "a"; Terminal "b" ]; head_pos = 2 };
      ];
    start = "S";
  }

let grammar_arith : grammar =
  {
    nonterminals = [ "E"; "T" ];
    terminals = [ "+"; "n" ];
    productions =
      [
        { index = 1; lhs = "E"; rhs = [ Nonterminal "E"; Terminal "+"; Nonterminal "T" ]; head_pos = 2 };
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
        { index = 1; lhs = "S"; rhs = [ Nonterminal "A"; Nonterminal "B" ]; head_pos = 1 };
        { index = 2; lhs = "A"; rhs = [ Terminal "a" ]; head_pos = 1 };
        { index = 3; lhs = "A"; rhs = []; head_pos = 0 };
        { index = 4; lhs = "B"; rhs = [ Terminal "b" ]; head_pos = 1 };
      ];
    start = "S";
  }

(* Astar -> A Astar | ε, A -> a *)
let grammar_astar : grammar =
  {
    nonterminals = [ "Astar"; "A" ];
    terminals = [ "a" ];
    productions =
      [
        { index = 1; lhs = "Astar"; rhs = [ Nonterminal "A"; Nonterminal "Astar" ]; head_pos = 1 };
        { index = 2; lhs = "Astar"; rhs = []; head_pos = 0 };
        { index = 3; lhs = "A"; rhs = [ Terminal "a" ]; head_pos = 1 };
      ];
    start = "Astar";
  }
