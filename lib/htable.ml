(* Types for representing context-free grammars and their head covers *)

type symbol =
  | Terminal of string
  | Nonterminal of string

type production = {
  index: int;
  lhs: string;
  rhs: symbol list;
  head_pos: int;
}

type grammar = {
  nonterminals: string list;
  terminals: string list;
  productions: production list;
  start: string;
}

(* H-items - only reachable ones *)
type h_item =
  | PartialItem of int * int * int   (* I_r^(s,t) *)
  | CompleteItem of string           (* I_A *)

type h_item_or_terminal =
  | HItem of h_item
  | HTerm of string

(* H-cover productions *)
type h_production =
  | Projection of h_item * h_item_or_terminal
  | LeftExpand of h_item * h_item_or_terminal * h_item   (* result -> left_sym, right_item *)
  | RightExpand of h_item * h_item * h_item_or_terminal  (* result -> left_item, right_sym *)

(* The h-cover structure *)
type h_cover = {
  items: h_item list;
  projections: (h_item * h_item_or_terminal) list;        (* lhs -> rhs *)
  left_expansions: (h_item * h_item_or_terminal * h_item) list;   (* result -> X_H, right_partial *)
  right_expansions: (h_item * h_item * h_item_or_terminal) list;  (* result -> left_partial, Y_H *)
}

(* Recognition table entry *)
type table_entry = {
  mutable items: h_item list;
  mutable blocked_left: (h_item * int * int) list;   (* (item, r, t) - blocked from left expand *)
  mutable blocked_right: (h_item * int * int) list;  (* (item, r, s) - blocked from right expand *)
}

(* The recognition table *)
type rec_table = {
  n: int;                                    (* string length *)
  entries: table_entry array array;          (* T[i,j] for 0 <= i < j <= n *)
  input: string array;                       (* input symbols *)
  grammar: grammar;
  cover: h_cover;
}

(* Pretty printing *)

let string_of_symbol = function
  | Terminal t -> Printf.sprintf "\"%s\"" t
  | Nonterminal nt -> nt

let string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "I_%d^(%d,%d)" r s t
  | CompleteItem a -> Printf.sprintf "I_%s" a

let string_of_h_item_or_terminal = function
  | HItem hi -> string_of_h_item hi
  | HTerm t -> Printf.sprintf "\"%s\"" t

(* Helper functions *)

let symbol_to_h_item_or_terminal = function
  | Terminal t -> HTerm t
  | Nonterminal nt -> HItem (CompleteItem nt)

let get_symbol prod pos =
  List.nth prod.rhs (pos - 1)

let is_reachable_partial_item prod s t =
  let pi_r = List.length prod.rhs in
  let tau_r = prod.head_pos in
  s >= 0 && s < tau_r && tau_r <= t && t <= pi_r && not (s = 0 && t = pi_r)

let is_partial = function
  | PartialItem _ -> true
  | CompleteItem _ -> false

(* Get (r, s, t) from a partial item for blocking purposes *)
let get_partial_indices = function
  | PartialItem (r, s, t) -> Some (r, s, t)
  | CompleteItem _ -> None

(* Compute the h-cover *)
let compute_h_cover (g: grammar) : h_cover =
  let projections = ref [] in
  let left_expansions = ref [] in
  let right_expansions = ref [] in
  
  List.iter (fun prod ->
    let r = prod.index in
    let pi_r = List.length prod.rhs in
    let tau_r = prod.head_pos in
    
    if pi_r = 0 then ()
    else if pi_r = 1 then begin
      let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
      projections := (CompleteItem prod.lhs, x_h) :: !projections
    end
    else begin
      (* Projection for head item *)
      let x_h = symbol_to_h_item_or_terminal (get_symbol prod tau_r) in
      projections := (PartialItem (r, tau_r - 1, tau_r), x_h) :: !projections;
      
      (* Expansions for reachable partial items *)
      for s = 0 to tau_r - 1 do
        for t = tau_r to pi_r do
          if is_reachable_partial_item prod s t then begin
            (* Left expansion: I_r^(s,t) <- X_H I_r^(s+1,t) *)
            if s < tau_r - 1 then begin
              let x_h = symbol_to_h_item_or_terminal (get_symbol prod (s + 1)) in
              left_expansions := (PartialItem (r, s, t), x_h, PartialItem (r, s + 1, t)) :: !left_expansions
            end;
            
            (* Right expansion: I_r^(s,t) <- I_r^(s,t-1) Y_H *)
            if t > tau_r then begin
              let y_h = symbol_to_h_item_or_terminal (get_symbol prod t) in
              right_expansions := (PartialItem (r, s, t), PartialItem (r, s, t - 1), y_h) :: !right_expansions
            end
          end
        done
      done;
      
      (* Complete item expansions *)
      if tau_r > 1 then begin
        let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
        left_expansions := (CompleteItem prod.lhs, x_h, PartialItem (r, 1, pi_r)) :: !left_expansions
      end;
      
      if tau_r < pi_r then begin
        let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
        right_expansions := (CompleteItem prod.lhs, PartialItem (r, 0, pi_r - 1), y_h) :: !right_expansions
      end;
      
      (* Edge cases *)
      if tau_r = 1 && is_reachable_partial_item prod 1 pi_r then begin
        let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
        left_expansions := (CompleteItem prod.lhs, x_h, PartialItem (r, 1, pi_r)) :: !left_expansions
      end;
      
      if tau_r = pi_r && is_reachable_partial_item prod 0 (pi_r - 1) then begin
        let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
        right_expansions := (CompleteItem prod.lhs, PartialItem (r, 0, pi_r - 1), y_h) :: !right_expansions
      end
    end
  ) g.productions;
  
  (* Collect all items *)
  let items = Hashtbl.create 16 in
  let add hi = Hashtbl.replace items hi () in
  List.iter (fun (lhs, _) -> add lhs) !projections;
  List.iter (fun (lhs, _, rhs) -> add lhs; add rhs) !left_expansions;
  List.iter (fun (lhs, l, _) -> add lhs; add l) !right_expansions;
  
  (* Remove duplicates from expansions *)
  let dedup_left = Hashtbl.create 16 in
  let dedup_right = Hashtbl.create 16 in
  List.iter (fun x -> Hashtbl.replace dedup_left x ()) !left_expansions;
  List.iter (fun x -> Hashtbl.replace dedup_right x ()) !right_expansions;
  
  {
    items = Hashtbl.fold (fun k () acc -> k :: acc) items [];
    projections = !projections;
    left_expansions = Hashtbl.fold (fun k () acc -> k :: acc) dedup_left [];
    right_expansions = Hashtbl.fold (fun k () acc -> k :: acc) dedup_right [];
  }

(* Create empty recognition table *)
let create_table (g: grammar) (input: string list) : rec_table =
  let n = List.length input in
  let cover = compute_h_cover g in
  let entries = Array.init (n + 1) (fun _ ->
    Array.init (n + 1) (fun _ ->
      { items = []; blocked_left = []; blocked_right = [] }
    )
  ) in
  {
    n;
    entries;
    input = Array.of_list input;
    grammar = g;
    cover;
  }

(* Check if item is in entry *)
let mem_item tbl i j item =
  List.mem item tbl.entries.(i).(j).items

(* Check if blocked *)
let is_blocked_left tbl i j item r t =
  List.exists (fun (it, r', t') -> it = item && r = r' && t = t') 
    tbl.entries.(i).(j).blocked_left

let is_blocked_right tbl i j item r s =
  List.exists (fun (it, r', s') -> it = item && r = r' && s = s') 
    tbl.entries.(i).(j).blocked_right

(* Add item to entry, returns true if new *)
let add_item tbl i j item =
  if not (mem_item tbl i j item) then begin
    tbl.entries.(i).(j).items <- item :: tbl.entries.(i).(j).items;
    true
  end else false

(* Add blocking *)
let block_left tbl i j item r t =
  let entry = tbl.entries.(i).(j) in
  if not (List.exists (fun (it, r', t') -> it = item && r = r' && t = t') entry.blocked_left) then
    entry.blocked_left <- (item, r, t) :: entry.blocked_left

let block_right tbl i j item r s =
  let entry = tbl.entries.(i).(j) in
  if not (List.exists (fun (it, r', s') -> it = item && r = r' && s = s') entry.blocked_right) then
    entry.blocked_right <- (item, r, s) :: entry.blocked_right

(* Find productions that project from a terminal *)
let find_projections_from_terminal cover term =
  List.filter_map (fun (lhs, rhs) ->
    match rhs with
    | HTerm t when t = term -> Some lhs
    | _ -> None
  ) cover.projections

(* Find productions that project from an h-item *)
let find_projections_from_item cover item =
  List.filter_map (fun (lhs, rhs) ->
    match rhs with
    | HItem hi when hi = item -> Some lhs
    | _ -> None
  ) cover.projections

(* Find left expansions: result <- X_H right_item *)
let find_left_expansions cover right_item =
  List.filter_map (fun (result, x_h, ri) ->
    if ri = right_item then Some (result, x_h) else None
  ) cover.left_expansions

(* Find right expansions: result <- left_item Y_H *)
let find_right_expansions cover left_item =
  List.filter_map (fun (result, li, y_h) ->
    if li = left_item then Some (result, y_h) else None
  ) cover.right_expansions

(* Get index info for blocking from expansion *)
let get_expansion_index_left result =
  match result with
  | PartialItem (r, s, t) -> (r, s, t)
  | CompleteItem _ -> (-1, -1, -1)  (* Complete items use special handling *)

let get_expansion_index_right result =
  match result with
  | PartialItem (r, s, t) -> (r, s, t)
  | CompleteItem _ -> (-1, -1, -1)

(* The main recognition algorithm *)
let recognize (g: grammar) (input: string list) : rec_table =
  let tbl = create_table g input in
  let n = tbl.n in
  let agenda = Queue.create () in
  
  (* Init step: add items for terminals that are heads *)
  for i = 1 to n do
    let term = tbl.input.(i - 1) in
    let items = find_projections_from_terminal tbl.cover term in
    List.iter (fun item ->
      if add_item tbl (i - 1) i item then
        Queue.add (item, i - 1, i) agenda
    ) items
  done;
  
  (* Process agenda *)
  while not (Queue.is_empty agenda) do
    let (a_h, i, j) = Queue.pop agenda in
    
    (* Project step: if A_H was added, add any B_H where B_H -> A_H *)
    let projected = find_projections_from_item tbl.cover a_h in
    List.iter (fun b_h ->
      if add_item tbl i j b_h then
        Queue.add (b_h, i, j) agenda
    ) projected;
    
    (* Left-expand step: find B_H -> X_H A_H and look for X_H to the left *)
    let left_exps = find_left_expansions tbl.cover a_h in
    List.iter (fun (b_h, x_h) ->
      let (r, s, t) = get_expansion_index_left b_h in
      
      (* Check if A_H is blocked from left expansion *)
      if not (is_blocked_left tbl i j a_h r t) then begin
        for i' = 0 to i - 1 do
          let can_combine = match x_h with
            | HTerm term -> 
                i' = i - 1 && tbl.input.(i - 1) = term
            | HItem x_item ->
                mem_item tbl i' i x_item && 
                not (is_blocked_right tbl i' i x_item r s)
          in
          if can_combine then begin
            if add_item tbl i' j b_h then
              Queue.add (b_h, i', j) agenda;
            
            (* Block X_H from being used in right expansion for this production *)
            (match x_h with
             | HItem x_item when is_partial x_item ->
                 block_left tbl i' i x_item r s
             | _ -> ());
            
            (* Block A_H from being used in right expansion *)
            if is_partial a_h then
              block_right tbl i j a_h r t
          end
        done
      end
    ) left_exps;
    
    (* Right-expand step: find B_H -> A_H X_H and look for X_H to the right *)
    let right_exps = find_right_expansions tbl.cover a_h in
    List.iter (fun (b_h, y_h) ->
      let (r, s, t) = get_expansion_index_right b_h in
      
      (* Check if A_H is blocked from right expansion *)
      if not (is_blocked_right tbl i j a_h r s) then begin
        for j' = j + 1 to n do
          let can_combine = match y_h with
            | HTerm term ->
                j' = j + 1 && tbl.input.(j) = term
            | HItem y_item ->
                mem_item tbl j j' y_item &&
                not (is_blocked_left tbl j j' y_item r t)
          in
          if can_combine then begin
            if add_item tbl i j' b_h then
              Queue.add (b_h, i, j') agenda;
            
            (* Block A_H from being used in left expansion *)
            if is_partial a_h then
              block_left tbl i j a_h r s;
            
            (* Block Y_H from being used in left expansion for this production *)
            (match y_h with
             | HItem y_item when is_partial y_item ->
                 block_right tbl j j' y_item r t
             | _ -> ())
          end
        done
      end
    ) right_exps
  done;
  
  tbl

(* Check if string is accepted *)
let is_accepted tbl =
  let start_item = CompleteItem tbl.grammar.start in
  mem_item tbl 0 tbl.n start_item

(* Print the recognition table *)
let print_table tbl =
  Printf.printf "=== Recognition Table ===\n";
  Printf.printf "Input: %s\n\n" (String.concat " " (Array.to_list tbl.input));
  
  for i = 0 to tbl.n - 1 do
    for j = i + 1 to tbl.n do
      let entry = tbl.entries.(i).(j) in
      if entry.items <> [] then begin
        Printf.printf "T[%d,%d] (spans: %s):\n" i j
          (String.concat " " (Array.to_list (Array.sub tbl.input i (j - i))));
        List.iter (fun item ->
          Printf.printf "  %s\n" (string_of_h_item item)
        ) (List.sort compare entry.items);
        
        if entry.blocked_left <> [] then begin
          Printf.printf "  blocked_left: ";
          List.iter (fun (it, r, t) ->
            Printf.printf "(%s,r=%d,t=%d) " (string_of_h_item it) r t
          ) entry.blocked_left;
          Printf.printf "\n"
        end;
        
        if entry.blocked_right <> [] then begin
          Printf.printf "  blocked_right: ";
          List.iter (fun (it, r, s) ->
            Printf.printf "(%s,r=%d,s=%d) " (string_of_h_item it) r s
          ) entry.blocked_right;
          Printf.printf "\n"
        end
      end
    done
  done;
  
  Printf.printf "\n=== Result ===\n";
  if is_accepted tbl then
    Printf.printf "ACCEPTED: I_%s in T[0,%d]\n" tbl.grammar.start tbl.n
  else
    Printf.printf "REJECTED: I_%s not in T[0,%d]\n" tbl.grammar.start tbl.n

(* Print the h-cover for reference *)
let print_cover cover =
  Printf.printf "=== H-Cover ===\n";
  
  Printf.printf "\nProjections:\n";
  List.iter (fun (lhs, rhs) ->
    Printf.printf "  %s -> %s\n" (string_of_h_item lhs) (string_of_h_item_or_terminal rhs)
  ) cover.projections;
  
  Printf.printf "\nLeft Expansions (result <- X_H right_item):\n";
  List.iter (fun (result, x_h, right) ->
    Printf.printf "  %s <- %s %s\n" 
      (string_of_h_item result)
      (string_of_h_item_or_terminal x_h)
      (string_of_h_item right)
  ) cover.left_expansions;
  
  Printf.printf "\nRight Expansions (result <- left_item Y_H):\n";
  List.iter (fun (result, left, y_h) ->
    Printf.printf "  %s <- %s %s\n"
      (string_of_h_item result)
      (string_of_h_item left)
      (string_of_h_item_or_terminal y_h)
  ) cover.right_expansions;
  
  Printf.printf "\n"

(* Example grammars *)

let grammar_gcl : grammar = {
  nonterminals = ["S"; "VP"; "NP"];
  terminals = ["cl"; "det"; "n"; "v"];
  productions = [
    { index = 1; lhs = "S";  rhs = [Nonterminal "NP"; Nonterminal "VP"]; head_pos = 2 };
    { index = 2; lhs = "VP"; rhs = [Terminal "cl"; Terminal "v"; Nonterminal "NP"]; head_pos = 2 };
    { index = 3; lhs = "NP"; rhs = [Terminal "det"; Terminal "n"]; head_pos = 1 };
  ];
  start = "S";
}

let grammar_simple : grammar = {
  nonterminals = ["S"; "A"];
  terminals = ["a"; "b"];
  productions = [
    { index = 1; lhs = "S"; rhs = [Nonterminal "A"; Terminal "b"]; head_pos = 1 };
    { index = 2; lhs = "A"; rhs = [Terminal "a"]; head_pos = 1 };
  ];
  start = "S";
}

let grammar_ambig : grammar = {
  nonterminals = ["S"; "A"];
  terminals = ["a"];
  productions = [
    { index = 1; lhs = "S"; rhs = [Nonterminal "A"; Nonterminal "A"]; head_pos = 1 };
    { index = 2; lhs = "A"; rhs = [Terminal "a"]; head_pos = 1 };
    { index = 3; lhs = "A"; rhs = [Nonterminal "A"; Nonterminal "A"]; head_pos = 1 };
  ];
  start = "S";
}

let htable =
  Printf.printf "========================================\n";
  Printf.printf "  Test 1: Simple grammar (a b)\n";
  Printf.printf "========================================\n\n";
  let cover1 = compute_h_cover grammar_simple in
  print_cover cover1;
  let tbl1 = recognize grammar_simple ["a"; "b"] in
  print_table tbl1;
  
  Printf.printf "\n\n";
  Printf.printf "========================================\n";
  Printf.printf "  Test 2: G_cl (det n cl v det n)\n";
  Printf.printf "========================================\n\n";
  let cover2 = compute_h_cover grammar_gcl in
  print_cover cover2;
  let tbl2 = recognize grammar_gcl ["det"; "n"; "cl"; "v"; "det"; "n"] in
  print_table tbl2;
  
  Printf.printf "\n\n";
  Printf.printf "========================================\n";
  Printf.printf "  Test 3: G_cl - should reject (det n)\n";
  Printf.printf "========================================\n\n";
  let tbl3 = recognize grammar_gcl ["det"; "n"] in
  print_table tbl3;
  
  Printf.printf "\n\n";
  Printf.printf "========================================\n";
  Printf.printf "  Test 4: Ambiguous grammar (a a a a)\n";
  Printf.printf "========================================\n\n";
  let cover4 = compute_h_cover grammar_ambig in
  print_cover cover4;
  let tbl4 = recognize grammar_ambig ["a"; "a"; "a"; "a"] in
  print_table tbl4