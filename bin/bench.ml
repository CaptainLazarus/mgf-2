open Practice
open Types

(* Generate every grammar obtainable by reassigning head positions.
   For a production with n symbols, head_pos ranges over 1..n (0 for epsilon). *)
let all_head_grammars (g : Types.grammar) : Types.grammar list =
  let options =
    List.map (fun (p : Types.production) ->
      let n = List.length p.rhs in
      if n = 0 then [p]
      else List.init n (fun i -> { p with head_pos = i + 1 }))
      g.productions
  in
  let rec cart = function
    | []         -> [[]]
    | ps :: rest -> List.concat_map (fun p ->
        List.map (fun t -> p :: t) (cart rest)) ps
  in
  List.map (fun prods -> { g with productions = prods }) (cart options)

let cover_rule_count (c : Types.h_cover) =
  List.length c.projections
  + List.length c.left_expansions
  + List.length c.right_expansions
  + List.length c.epsilon_projections

let head_label (g : Types.grammar) =
  let ps = List.map (fun (p : Types.production) ->
    string_of_int p.head_pos) g.productions in
  "(" ^ String.concat "," ps ^ ")"

let run_experiment name (orig : Types.grammar) (input : string list) =
  let all = all_head_grammars orig in
  let orig_label = head_label orig in

  (* Compute (cover_rules, table_items, label) for every config *)
  let results =
    List.map (fun g ->
      let c    = Hcover.compute_h_cover g in
      let tbl  = Recognize.recognize g input in
      (cover_rule_count c, Query.count_table_items tbl, head_label g))
      all
  in

  let orig_rules, orig_tbl, _ =
    List.find (fun (_, _, l) -> l = orig_label) results in

  let all_rules = List.map (fun (r,_,_) -> r) results in
  let all_tbl   = List.map (fun (_,t,_) -> t) results in
  let min_rules = List.fold_left min max_int all_rules in
  let max_rules = List.fold_left max min_int all_rules in
  let min_tbl   = List.fold_left min max_int all_tbl in
  let max_tbl   = List.fold_left max min_int all_tbl in

  (* Sort by cover rules, then table items for stable display *)
  let sorted = List.sort compare results in

  Printf.printf "\n=== %s | input: [%s] (n=%d) | %d configs ===\n"
    name (String.concat " " input) (List.length input) (List.length all);
  List.iter (fun (p : Types.production) ->
    Printf.printf "  prod %d: %s -> %-20s (len=%d)\n"
      p.index p.lhs
      (String.concat " " (List.map (function
        | Types.Terminal t -> t | Types.Nonterminal n -> n) p.rhs))
      (List.length p.rhs))
    orig.productions;
  Printf.printf "\n";
  Printf.printf "  %-12s  %11s  %11s\n" "heads" "cover rules" "table items";
  Printf.printf "  %-12s  %11s  %11s\n" "-----" "-----------" "-----------";
  List.iter (fun (r, t, lbl) ->
    let marker = if lbl = orig_label then " <- original" else "" in
    Printf.printf "  %-12s  %11d  %11d%s\n" lbl r t marker)
    sorted;
  Printf.printf "\n";
  Printf.printf "  cover rules : min=%-3d  max=%-3d  original=%-3d (%s)\n"
    min_rules max_rules orig_rules
    (if orig_rules = min_rules then "minimum"
     else if orig_rules = max_rules then "MAXIMUM" else "middle");
  Printf.printf "  table items : min=%-3d  max=%-3d  original=%-3d (%s)\n"
    min_tbl max_tbl orig_tbl
    (if orig_tbl = min_tbl then "minimum"
     else if orig_tbl = max_tbl then "MAXIMUM" else "middle")

let () =
  run_experiment "GCL"
    Htable.grammar_gcl
    ["det"; "n"; "cl"; "v"; "det"; "n"];
  run_experiment "Arith"
    Htable.grammar_arith
    ["n"; "+"; "n"; "+"; "n"];
  run_experiment "Astar"
    Htable.grammar_astar
    ["a"; "a"; "a"]
