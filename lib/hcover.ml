(* Types for representing context-free grammars and their head covers *)

type symbol =
  | Terminal of string
  | Nonterminal of string

type production = {
  index: int;                (* production number r *)
  lhs: string;               (* Dr - left-hand side nonterminal *)
  rhs: symbol list;          (* Zr,1 ... Zr,πr *)
  head_pos: int;             (* τr - 1-indexed position of head in rhs *)
}

type grammar = {
  nonterminals: string list;
  terminals: string list;
  productions: production list;
  start: string;
}

(* H-items as defined in Definition 4, but only reachable ones *)
type h_item =
  | PartialItem of int * int * int   (* I_r^(s,t) : production index, s, t *)
  | CompleteItem of string           (* I_A for nonterminal A *)

(* H-cover productions *)
type h_production =
  | Projection of h_item * h_item_or_terminal    (* A_H -> X_H *)
  | Expansion of h_item * h_item_or_terminal * h_item_or_terminal  (* A_H -> X_H Y_H *)

and h_item_or_terminal =
  | HItem of h_item
  | HTerm of string

(* Pretty printing functions *)

let string_of_symbol = function
  | Terminal t -> Printf.sprintf "\"%s\"" t
  | Nonterminal nt -> nt

let string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "I_%d^(%d,%d)" r s t
  | CompleteItem a -> Printf.sprintf "I_%s" a

let string_of_h_item_or_terminal = function
  | HItem hi -> string_of_h_item hi
  | HTerm t -> Printf.sprintf "\"%s\"" t

let string_of_h_production = function
  | Projection (lhs, rhs) ->
      Printf.sprintf "%s -> %s"
        (string_of_h_item lhs)
        (string_of_h_item_or_terminal rhs)
  | Expansion (lhs, rhs1, rhs2) ->
      Printf.sprintf "%s -> %s %s"
        (string_of_h_item lhs)
        (string_of_h_item_or_terminal rhs1)
        (string_of_h_item_or_terminal rhs2)

(* Convert a grammar symbol to h_item_or_terminal *)
let symbol_to_h_item_or_terminal sym =
  match sym with
  | Terminal t -> HTerm t
  | Nonterminal nt -> HItem (CompleteItem nt)

(* Get the symbol at position pos (1-indexed) in the rhs *)
let get_symbol prod pos =
  List.nth prod.rhs (pos - 1)

(* Check if a partial item I_r^(s,t) is reachable from head-outward expansion.
   
   For production r with head at position τ_r, a partial item I_r^(s,t) is 
   reachable iff:
   - 0 ≤ s < τ_r ≤ t ≤ π_r  (the head position is covered by the interval)
   - (s,t) ≠ (0, π_r)        (it's not the complete item)
   
   This ensures the item lies on some path from the head item I_r^(τ_r-1, τ_r)
   to the complete item I_{D_r}.
*)
let is_reachable_partial_item prod s t =
  let pi_r = List.length prod.rhs in
  let tau_r = prod.head_pos in
  s >= 0 && s < tau_r && tau_r <= t && t <= pi_r && not (s = 0 && t = pi_r)

(* Compute the h-cover of a grammar, generating only reachable items *)
let compute_h_cover (g: grammar) : h_production list =
  let productions = ref [] in
  
  List.iter (fun prod ->
    let r = prod.index in
    let pi_r = List.length prod.rhs in
    let tau_r = prod.head_pos in
    
    if pi_r = 0 then
      (* Skip null productions *)
      ()
    else if pi_r = 1 then begin
      (* Case: D_r -> Z_{r,1} where π_r = 1 *)
      (* The single symbol is the head, so: I_{D_r} -> X_H *)
      let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
      productions := Projection (CompleteItem prod.lhs, x_h) :: !productions
    end
    else begin
      (* π_r > 1 *)
      
      (* Projection: I_r^(τ_r-1, τ_r) -> X_H where X_H is the head symbol *)
      let x_h = symbol_to_h_item_or_terminal (get_symbol prod tau_r) in
      productions := Projection (PartialItem (r, tau_r - 1, tau_r), x_h) :: !productions;
      
      (* Expansion productions for reachable partial items I_r^(s,t) *)
      for s = 0 to tau_r - 1 do
        for t = tau_r to pi_r do
          if is_reachable_partial_item prod s t then begin
            (* Left expansion: I_r^(s,t) -> X_H I_r^(s+1,t) 
               Valid when s+1 < τ_r (i.e., s < τ_r - 1), meaning there's 
               a reachable item to the right *)
            if s < tau_r - 1 then begin
              let x_h = symbol_to_h_item_or_terminal (get_symbol prod (s + 1)) in
              let rhs_item = HItem (PartialItem (r, s + 1, t)) in
              productions := Expansion (PartialItem (r, s, t), x_h, rhs_item) :: !productions
            end;
            
            (* Right expansion: I_r^(s,t) -> I_r^(s,t-1) Y_H
               Valid when t > τ_r, meaning there's a reachable item to the left *)
            if t > tau_r then begin
              let y_h = symbol_to_h_item_or_terminal (get_symbol prod t) in
              let lhs_item = HItem (PartialItem (r, s, t - 1)) in
              productions := Expansion (PartialItem (r, s, t), lhs_item, y_h) :: !productions
            end
          end
        done
      done;
      
      (* Productions for I_{D_r} - completing the analysis *)
      (* These connect the outermost reachable partial items to the complete item *)
      
      (* I_{D_r} -> X_H I_r^(1, π_r) when τ_r > 1 
         (left side has at least one symbol before head) *)
      if tau_r > 1 then begin
        let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
        productions := Expansion (CompleteItem prod.lhs, x_h, HItem (PartialItem (r, 1, pi_r))) :: !productions
      end;
      
      (* I_{D_r} -> I_r^(0, π_r-1) Y_H when τ_r < π_r
         (right side has at least one symbol after head) *)
      if tau_r < pi_r then begin
        let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
        productions := Expansion (CompleteItem prod.lhs, HItem (PartialItem (r, 0, pi_r - 1)), y_h) :: !productions
      end;
      
      (* Special case: when τ_r = 1, we need I_{D_r} -> X_H I_r^(1, π_r) 
         but I_r^(1, π_r) must be reachable, which requires τ_r ≤ 1.
         Actually when τ_r = 1, the partial item I_r^(0, π_r-1) handles the left,
         and we expand right from I_r^(0,1) outward.
         
         When τ_r = π_r (head is rightmost), we need I_{D_r} -> I_r^(0, π_r-1) Y_H
         but also need to handle that we expand left from I_r^(τ_r-1, τ_r).
      *)
      
      (* Edge case: head at position 1, need to complete by adding right symbols *)
      if tau_r = 1 then begin
        (* I_{D_r} -> I_r^(0, π_r-1) Y_H is already added above since τ_r < π_r *)
        (* But we also might need I_{D_r} -> X_H I_r^(1, π_r) - check if reachable *)
        if is_reachable_partial_item prod 1 pi_r then begin
          let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
          productions := Expansion (CompleteItem prod.lhs, x_h, HItem (PartialItem (r, 1, pi_r))) :: !productions
        end
      end;
      
      (* Edge case: head at last position, need to complete by adding left symbols *)
      if tau_r = pi_r then begin
        if is_reachable_partial_item prod 0 (pi_r - 1) then begin
          let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
          productions := Expansion (CompleteItem prod.lhs, HItem (PartialItem (r, 0, pi_r - 1)), y_h) :: !productions
        end
      end
    end
  ) g.productions;
  
  (* Remove duplicates *)
  let seen = Hashtbl.create 16 in
  List.filter (fun p ->
    let key = string_of_h_production p in
    if Hashtbl.mem seen key then false
    else begin
      Hashtbl.add seen key ();
      true
    end
  ) (List.rev !productions)

(* Collect all h-items that appear in the h-cover *)
let collect_h_items (prods: h_production list) : h_item list =
  let items = Hashtbl.create 16 in
  let add_item hi = Hashtbl.replace items hi () in
  let add_item_or_term = function
    | HItem hi -> add_item hi
    | HTerm _ -> ()
  in
  List.iter (function
    | Projection (lhs, rhs) ->
        add_item lhs;
        add_item_or_term rhs
    | Expansion (lhs, rhs1, rhs2) ->
        add_item lhs;
        add_item_or_term rhs1;
        add_item_or_term rhs2
  ) prods;
  Hashtbl.fold (fun k () acc -> k :: acc) items []

(* Print the h-cover with detailed explanation *)
let print_h_cover (g: grammar) =
  let h_prods = compute_h_cover g in
  let h_items = collect_h_items h_prods in
  
  Printf.printf "=== Original Grammar ===\n";
  List.iter (fun prod ->
    let rhs_str = String.concat " " (List.map string_of_symbol prod.rhs) in
    let head_sym = if List.length prod.rhs > 0 
                   then string_of_symbol (get_symbol prod prod.head_pos)
                   else "ε" in
    Printf.printf "  (%d) %s -> %s   [head: %s at position %d]\n"
      prod.index
      prod.lhs
      rhs_str
      head_sym
      prod.head_pos
  ) g.productions;
  
  Printf.printf "\n=== Reachable H-Items ===\n";
  Printf.printf "(Only items reachable via head-outward expansion)\n\n";
  
  (* Group by type *)
  let complete_items, partial_items = List.partition (function
    | CompleteItem _ -> true
    | PartialItem _ -> false
  ) (List.sort compare h_items) in
  
  Printf.printf "Complete items (I_A for nonterminals):\n";
  List.iter (fun hi ->
    Printf.printf "  %s\n" (string_of_h_item hi)
  ) complete_items;
  
  Printf.printf "\nPartial items (I_r^(s,t) covering head):\n";
  List.iter (fun hi ->
    match hi with
    | PartialItem (r, s, t) ->
        let prod = List.find (fun p -> p.index = r) g.productions in
        let covered = List.filteri (fun i _ -> i >= s && i < t) prod.rhs in
        let covered_str = String.concat " " (List.map string_of_symbol covered) in
        Printf.printf "  %s  (covers: %s)\n" (string_of_h_item hi) covered_str
    | _ -> ()
  ) partial_items;
  
  Printf.printf "\n=== H-Cover Productions ===\n";
  
  let projections, expansions = List.partition (function
    | Projection _ -> true
    | Expansion _ -> false
  ) h_prods in
  
  Printf.printf "\nProjection Productions (P_H^(1)) - introduce head:\n";
  List.iter (fun p ->
    Printf.printf "  %s\n" (string_of_h_production p)
  ) projections;
  
  Printf.printf "\nExpansion Productions (P_H^(2)) - expand outward from head:\n";
  List.iter (fun p ->
    Printf.printf "  %s\n" (string_of_h_production p)
  ) expansions;
  
  Printf.printf "\n=== Summary ===\n";
  Printf.printf "  Original grammar productions: %d\n" (List.length g.productions);
  Printf.printf "  H-cover productions: %d\n" (List.length h_prods);
  Printf.printf "  H-items (nonterminals of cover): %d\n" (List.length h_items);
  Printf.printf "    - Complete items: %d\n" (List.length complete_items);
  Printf.printf "    - Partial items: %d\n" (List.length partial_items)

(* Verify the h-cover by checking all partial items are reachable *)
let verify_h_cover (g: grammar) =
  let h_prods = compute_h_cover g in
  let h_items = collect_h_items h_prods in
  
  Printf.printf "\n=== Verification ===\n";
  
  let all_valid = List.for_all (function
    | CompleteItem _ -> true
    | PartialItem (r, s, t) ->
        let prod = List.find (fun p -> p.index = r) g.productions in
        let valid = is_reachable_partial_item prod s t in
        if not valid then
          Printf.printf "  WARNING: Unreachable item %s\n" 
            (string_of_h_item (PartialItem (r, s, t)));
        valid
  ) h_items in
  
  if all_valid then
    Printf.printf "  All partial items are reachable from their head items.\n"
  else
    Printf.printf "  Some items are unreachable!\n"

(* Example: Grammar G_cl from Example 6 in the paper *)
let example_grammar_gcl : grammar = {
  nonterminals = ["S"; "VP"; "NP"];
  terminals = ["cl"; "det"; "n"; "v"];
  productions = [
    { index = 1; lhs = "S";  rhs = [Nonterminal "NP"; Nonterminal "VP"]; head_pos = 2 };
    { index = 2; lhs = "VP"; rhs = [Terminal "cl"; Terminal "v"; Nonterminal "NP"]; head_pos = 2 };
    { index = 3; lhs = "NP"; rhs = [Terminal "det"; Terminal "n"]; head_pos = 1 };
  ];
  start = "S";
}

(* Grammar with head at different positions to test edge cases *)
let example_grammar_head_positions : grammar = {
  nonterminals = ["A"; "B"; "C"; "D"];
  terminals = ["a"; "b"; "c"; "d"];
  productions = [
    (* Head at first position *)
    { index = 1; lhs = "A"; rhs = [Terminal "a"; Terminal "b"; Terminal "c"]; head_pos = 1 };
    (* Head at middle position *)
    { index = 2; lhs = "B"; rhs = [Terminal "a"; Terminal "b"; Terminal "c"]; head_pos = 2 };
    (* Head at last position *)
    { index = 3; lhs = "C"; rhs = [Terminal "a"; Terminal "b"; Terminal "c"]; head_pos = 3 };
    (* Single symbol *)
    { index = 4; lhs = "D"; rhs = [Terminal "d"]; head_pos = 1 };
  ];
  start = "A";
}

(* Expression grammar *)
let example_grammar_expr : grammar = {
  nonterminals = ["E"; "T"; "F"];
  terminals = ["+"; "*"; "("; ")"; "id"];
  productions = [
    { index = 1; lhs = "E"; rhs = [Nonterminal "E"; Terminal "+"; Nonterminal "T"]; head_pos = 2 };
    { index = 2; lhs = "E"; rhs = [Nonterminal "T"]; head_pos = 1 };
    { index = 3; lhs = "T"; rhs = [Nonterminal "T"; Terminal "*"; Nonterminal "F"]; head_pos = 2 };
    { index = 4; lhs = "T"; rhs = [Nonterminal "F"]; head_pos = 1 };
    { index = 5; lhs = "F"; rhs = [Terminal "("; Nonterminal "E"; Terminal ")"]; head_pos = 2 };
    { index = 6; lhs = "F"; rhs = [Terminal "id"]; head_pos = 1 };
  ];
  start = "E";
}

let hcover =
  Printf.printf "****************************************\n";
  Printf.printf "* H-Cover for G_cl (from the paper)    *\n";
  Printf.printf "****************************************\n\n";
  print_h_cover example_grammar_gcl;
  verify_h_cover example_grammar_gcl;
  
  Printf.printf "\n\n";
  Printf.printf "****************************************\n";
  Printf.printf "* H-Cover with Various Head Positions  *\n";
  Printf.printf "****************************************\n\n";
  print_h_cover example_grammar_head_positions;
  verify_h_cover example_grammar_head_positions;
  
  Printf.printf "\n\n";
  Printf.printf "****************************************\n";
  Printf.printf "* H-Cover for Expression Grammar       *\n";
  Printf.printf "****************************************\n\n";
  print_h_cover example_grammar_expr;
  verify_h_cover example_grammar_expr
