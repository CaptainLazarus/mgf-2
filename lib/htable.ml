open Types
open Print
open Recognize
open Query
open Reconstruct

let print_trees ?grammar ?(mode="omit") tbl nt =
  let trees =
    if mode = "virtual" then reconstruct_trees_virtual tbl nt
    else reconstruct_trees_omit tbl nt
  in
  let n = List.length trees in
  Printf.printf "+-- Parse Trees for %s (%s mode) %s+\n" nt mode
    (String.make (max 0 (27 - String.length nt - String.length mode)) '-');
  if n = 0 then
    Printf.printf "| No trees (input not accepted as %s)\n" nt
  else if n = 1 then (
    Printf.printf "| 1 parse tree:\n|\n";
    print_tree ?grammar (List.hd trees))
  else (
    Printf.printf "| AMBIGUOUS: %d parse trees:\n" n;
    List.iteri (fun i tree ->
      Printf.printf "|\n| Tree %d:\n" (i + 1);
      print_tree ?grammar tree)
      trees);
  Printf.printf "+%s+\n" (String.make 60 '-')

let print_result tbl =
  let accepted = is_accepted tbl in
  Printf.printf "+-- Result %s+\n" (String.make 50 '-');
  if accepted then
    Printf.printf "| ACCEPTED: I_%s found in T[0,%d]\n" tbl.grammar.start tbl.n
  else (
    Printf.printf "| REJECTED: I_%s not in T[0,%d]\n" tbl.grammar.start tbl.n;
    let complete = get_complete_items tbl 0 tbl.n in
    if complete <> [] then (
      Printf.printf "| But found these complete items at T[0,%d]:\n" tbl.n;
      List.iter
        (fun (it, _) -> Printf.printf "|   %s\n" (string_of_h_item it))
        complete));
  Printf.printf "+%s+\n" (String.make 60 '-')

let run_and_print g input =
  Printf.printf "\n";
  Printf.printf "============================================================\n";
  Printf.printf
    "                    RECOGNITION TEST                         \n";
  Printf.printf
    "============================================================\n\n";

  (* print_grammar g;
  print_newline (); *)

  let tbl = recognize g input in

  (* print_cover_summary tbl.cover;
  print_newline (); *)

  print_visual_table tbl;

  (* print_cell_details tbl;
  print_newline ();

  print_result tbl;
  print_newline (); *)

  tbl

(* Example grammars *)

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
        { index = 2; lhs = "A"; rhs = [ Terminal "a" ; Terminal "b" ]; head_pos = 1 };
        { index = 3; lhs = "A"; rhs = [ Nonterminal "A" ; Terminal "a" ; Terminal "b"]; head_pos = 1 };
        { index = 4; lhs = "B"; rhs = [Nonterminal "B" ; Terminal "a"; Terminal "a" ; Terminal "b" ]; head_pos = 2 };
        { index = 5; lhs = "B"; rhs = [ Terminal "a" ; Terminal "a" ; Terminal "b" ]; head_pos = 2 };
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

(* Grammar with epsilon: S -> A B, A -> a | ε, B -> b *)
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

(* A* grammar: Astar -> A Astar | ε, A -> a *)
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

let htable =
  (* let _ = run_and_print grammar_simple ["a" ; "b" ; "a"; "b"] in
  let _ = run_and_print grammar_simple ["a" ; "a" ; "b" ; "a"; "b"] in
  let _ = run_and_print grammar_simple ["a" ; "b" ; "a"; "b" ; "b" ; "b"] in
  let _ = run_and_print grammar_simple ["a"; "b" ; "a" ; "a" ; "a" ; "b"] in *)
  (* let _ = run_and_print grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ] in
  let _ = run_and_print grammar_gcl [ "det"; "n"; "cl"; "v"; "det" ] in
  let _ = run_and_print grammar_gcl [ "n"; "cl"; "v"; "det"; "n" ] in
  let _ = run_and_print grammar_gcl [ "cl"; "v"; "det"; "n" ] in
  let _ = run_and_print grammar_gcl [ "n"; "cl"; "v"; "det" ] in
  let _ = run_and_print grammar_gcl [ "cl"; "v"; "det"] in  
  let _ = run_and_print grammar_gcl ["cl"; "v"] in
  let _ = run_and_print grammar_gcl ["v"] in *)
  (* Epsilon grammar tests *)
  (* let _ = run_and_print grammar_epsilon ["a"; "b"] in
  let _ = run_and_print grammar_epsilon ["b"] in
  let _ = run_and_print grammar_astar ["a"; "a"; "a"] in
  let _ = run_and_print grammar_astar ["a"] in
  let _ = run_and_print grammar_astar [] in *)
  ()
