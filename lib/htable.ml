open Types
open Print
open Table
open Recognize

let is_accepted tbl =
  let start_item = CompleteItem tbl.grammar.start in
  mem_item tbl 0 tbl.n start_item

(* Get all complete items at a span *)
let get_complete_items tbl i j =
  List.filter_map
    (fun (item, derivs) ->
      match item with
      | CompleteItem _ -> Some (item, derivs)
      | PartialItem _ -> None)
    tbl.entries.(i).(j).items

(* Get all items at a span *)
let get_all_items tbl i j = tbl.entries.(i).(j).items

(* Count total distinct h-items placed across all cells *)
let count_table_items tbl =
  let total = ref 0 in
  for i = 0 to tbl.n do
    for j = i to tbl.n do
      total := !total + List.length tbl.entries.(i).(j).items
    done
  done;
  !total

let find_production tbl r =
  List.find (fun p -> p.index = r) tbl.grammar.productions

(* For each item in T[0,n]:
   - CompleteItem nt   → root = nt, nothing missing
   - PartialItem(r,s,t) → root = lhs of production r,
                          missing_left  = rhs[0..s-1],
                          missing_right = rhs[t..end]
   Also climbs one level: for each CompleteItem nt, finds productions
   where nt appears in the RHS and reports what siblings are absent. *)
let infer_parse_roots tbl =
  let n = tbl.n in
  let items = get_all_items tbl 0 n in
  let rhs_arr prod = Array.of_list prod.rhs in
  let direct =
    List.filter_map (fun (item, _) ->
      match item with
      | CompleteItem nt ->
        Some { root = nt; missing_left = []; missing_right = [] }
      | PartialItem (r, s, t) ->
        let prod = find_production tbl r in
        let rhs = rhs_arr prod in
        let len = Array.length rhs in
        Some {
          root = prod.lhs;
          missing_left  = Array.to_list (Array.sub rhs 0 s);
          missing_right = Array.to_list (Array.sub rhs t (len - t));
        })
      items
  in
  (* Climb one level: for CompleteItems, check which productions use them *)
  let complete_nts =
    List.filter_map (fun (item, _) ->
      match item with CompleteItem nt -> Some nt | _ -> None)
      items
  in
  let inferred =
    List.concat_map (fun nt ->
      List.filter_map (fun prod ->
        let rhs = prod.rhs in
        let positions =
          List.filteri (fun i sym ->
            match sym with Nonterminal s -> s = nt && i >= 0 | _ -> false)
            rhs
          |> List.mapi (fun _ sym -> sym)
        in
        if positions = [] then None
        else
          (* Report missing siblings (everything in RHS except nt itself) *)
          let missing =
            List.filter (fun sym ->
              match sym with Nonterminal s -> s <> nt | Terminal _ -> true)
              rhs
          in
          if missing = [] then None  (* already captured as direct complete *)
          else Some { root = prod.lhs; missing_left = missing; missing_right = [] })
        tbl.grammar.productions)
      complete_nts
  in
  let all = direct @ inferred in
  List.sort_uniq compare all

(* ============================================================ *)
(*                   TREE RECONSTRUCTION                        *)
(* ============================================================ *)

(* Cartesian product: combine every left child-list with every right child-list *)
let cartesian xs ys =
  List.concat_map (fun x -> List.map (fun y -> x @ y) ys) xs

(* get_subtrees mode visited tbl item i j
   Returns all possible "child contributions" for item spanning [i,j].
   - CompleteItem nt  : each contribution is [Node(nt, children)]
   - PartialItem(r,s,t): each contribution is the flat child list for
                         RHS positions s+1..t of production r
   visited tracks (item,i,j) triples currently on the call stack to
   detect and break derivation cycles (returning [] for cyclic paths). *)
let rec get_subtrees mode visited tbl item i j : tree list list =
  let key = (item, i, j) in
  if Hashtbl.mem visited key then []  (* cycle: cut here *)
  else begin
    Hashtbl.replace visited key ();
    let derivs = get_derivations tbl i j item in
    let result = List.sort_uniq compare
      (List.concat_map (subtrees_for_deriv mode visited tbl item i j) derivs) in
    Hashtbl.remove visited key;
    result
  end

and subtrees_for_deriv mode visited tbl item i j = function
  | FromTerminal t ->
    (match item with
     | CompleteItem nt ->
       let children = if t = "ε" then [] else [Leaf t] in
       [[Node (nt, children)]]
     | PartialItem _ ->
       if t = "ε" then [[]] else [[Leaf t]])

  | FromProject inner ->
    let inner_subs = get_subtrees mode visited tbl inner i j in
    (match item with
     | CompleteItem nt ->
       List.map (fun sub -> [Node (nt, sub)]) inner_subs
     | PartialItem _ ->
       inner_subs)

  | FromLeftExpand (k, x_h, right_item) ->
    let left_subs  = subs_for_x mode visited tbl x_h i k in
    let right_subs = get_subtrees mode visited tbl right_item k j in
    let combined   = cartesian left_subs right_subs in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) combined
     | PartialItem _   -> combined)

  | FromRightExpand (k, left_item, y_h) ->
    let left_subs  = get_subtrees mode visited tbl left_item i k in
    let right_subs = subs_for_x mode visited tbl y_h k j in
    let combined   = cartesian left_subs right_subs in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) combined
     | PartialItem _   -> combined)

  | FromEpsilon inner ->
    let inner_subs = get_subtrees mode visited tbl inner i j in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) inner_subs
     | PartialItem _   -> inner_subs)

  | FromBoundaryRight (virtual_left, real_right) ->
    (* result <- virtual_left  real_right: real_right spans [i,j], virtual_left is dropped *)
    let right_subs = subs_for_x mode visited tbl real_right i j in
    let virt = match mode with
      | `Virtual -> [Virtual virtual_left]
      | `Omit    -> []
    in
    let combined = List.map (fun sub -> virt @ sub) right_subs in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) combined
     | PartialItem _   -> combined)

  | FromBoundaryLeft (real_left, virtual_right) ->
    (* result <- real_left  virtual_right: real_left spans [i,j], virtual_right is dropped *)
    let left_subs = subs_for_x mode visited tbl real_left i j in
    let virt = match mode with
      | `Virtual -> [Virtual virtual_right]
      | `Omit    -> []
    in
    let combined = List.map (fun sub -> sub @ virt) left_subs in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) combined
     | PartialItem _   -> combined)

  | FromInductiveFill (virtual_left, real_right) ->
    (* real_right spans [i,j] (same span as item, virtual_left is zero-span virtual) *)
    let right_subs = get_subtrees mode visited tbl real_right i j in
    let virt = match mode with
      | `Virtual -> [Virtual (HItem virtual_left)]
      | `Omit    -> []
    in
    let combined = List.map (fun sub -> virt @ sub) right_subs in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) combined
     | PartialItem _   -> combined)

  | FromInductiveFillRight (real_left, virtual_right) ->
    (* real_left spans [i,j] (same span as item, virtual_right is zero-span virtual) *)
    let left_subs = get_subtrees mode visited tbl real_left i j in
    let virt = match mode with
      | `Virtual -> [Virtual virtual_right]
      | `Omit    -> []
    in
    let combined = List.map (fun sub -> sub @ virt) left_subs in
    (match item with
     | CompleteItem nt -> List.map (fun sub -> [Node (nt, sub)]) combined
     | PartialItem _   -> combined)

and subs_for_x mode visited tbl x i j =
  match x with
  | HTerm t      -> [[Leaf t]]
  | HItem h_item -> get_subtrees mode visited tbl h_item i j

(* Reconstruct all parse trees for nonterminal nt spanning the full input.
   Virtual variant: dropped boundary constituents appear as Virtual nodes.
   Omit variant:    dropped boundary constituents are silently excluded.  *)
let reconstruct_trees_virtual tbl nt =
  let visited = Hashtbl.create 16 in
  let subs = get_subtrees `Virtual visited tbl (CompleteItem nt) 0 tbl.n in
  List.sort_uniq compare (List.filter_map (function [t] -> Some t | _ -> None) subs)

let reconstruct_trees_omit tbl nt =
  let visited = Hashtbl.create 16 in
  let subs = get_subtrees `Omit visited tbl (CompleteItem nt) 0 tbl.n in
  List.sort_uniq compare (List.filter_map (function [t] -> Some t | _ -> None) subs)

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
