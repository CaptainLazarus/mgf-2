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
  | PartialItem of int * int * int
  | CompleteItem of string

type h_item_or_terminal =
  | HItem of h_item
  | HTerm of string

(* The h-cover structure *)
type h_cover = {
  items: h_item list;
  projections: (h_item * h_item_or_terminal) list;
  left_expansions: (h_item * h_item_or_terminal * h_item) list;
  right_expansions: (h_item * h_item * h_item_or_terminal) list;
}

(* Recognition table entry *)
type table_entry = {
  mutable items: h_item list;
  mutable blocked_left: (h_item * int * int) list;
  mutable blocked_right: (h_item * int * int) list;
}

(* The recognition table *)
type rec_table = {
  n: int;
  entries: table_entry array array;
  input: string array;
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

let short_string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "%d^%d,%d" r s t
  | CompleteItem a -> a

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
      let x_h = symbol_to_h_item_or_terminal (get_symbol prod tau_r) in
      projections := (PartialItem (r, tau_r - 1, tau_r), x_h) :: !projections;
      
      for s = 0 to tau_r - 1 do
        for t = tau_r to pi_r do
          if is_reachable_partial_item prod s t then begin
            if s < tau_r - 1 then begin
              let x_h = symbol_to_h_item_or_terminal (get_symbol prod (s + 1)) in
              left_expansions := (PartialItem (r, s, t), x_h, PartialItem (r, s + 1, t)) :: !left_expansions
            end;
            
            if t > tau_r then begin
              let y_h = symbol_to_h_item_or_terminal (get_symbol prod t) in
              right_expansions := (PartialItem (r, s, t), PartialItem (r, s, t - 1), y_h) :: !right_expansions
            end
          end
        done
      done;
      
      if tau_r > 1 then begin
        let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
        left_expansions := (CompleteItem prod.lhs, x_h, PartialItem (r, 1, pi_r)) :: !left_expansions
      end;
      
      if tau_r < pi_r then begin
        let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
        right_expansions := (CompleteItem prod.lhs, PartialItem (r, 0, pi_r - 1), y_h) :: !right_expansions
      end;
      
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
  
  let items = Hashtbl.create 16 in
  let add hi = Hashtbl.replace items hi () in
  List.iter (fun (lhs, _) -> add lhs) !projections;
  List.iter (fun (lhs, _, rhs) -> add lhs; add rhs) !left_expansions;
  List.iter (fun (lhs, l, _) -> add lhs; add l) !right_expansions;
  
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
  { n; entries; input = Array.of_list input; grammar = g; cover }

let mem_item tbl i j item =
  List.mem item tbl.entries.(i).(j).items

let is_blocked_left tbl i j item r t =
  List.exists (fun (it, r', t') -> it = item && r = r' && t = t') 
    tbl.entries.(i).(j).blocked_left

let is_blocked_right tbl i j item r s =
  List.exists (fun (it, r', s') -> it = item && r = r' && s = s') 
    tbl.entries.(i).(j).blocked_right

let add_item tbl i j item =
  if not (mem_item tbl i j item) then begin
    tbl.entries.(i).(j).items <- item :: tbl.entries.(i).(j).items;
    true
  end else false

let block_left tbl i j item r t =
  let entry = tbl.entries.(i).(j) in
  if not (List.exists (fun (it, r', t') -> it = item && r = r' && t = t') entry.blocked_left) then
    entry.blocked_left <- (item, r, t) :: entry.blocked_left

let block_right tbl i j item r s =
  let entry = tbl.entries.(i).(j) in
  if not (List.exists (fun (it, r', s') -> it = item && r = r' && s = s') entry.blocked_right) then
    entry.blocked_right <- (item, r, s) :: entry.blocked_right

let find_projections_from_terminal cover term =
  List.filter_map (fun (lhs, rhs) ->
    match rhs with
    | HTerm t when t = term -> Some lhs
    | _ -> None
  ) cover.projections

let find_projections_from_item cover item =
  List.filter_map (fun (lhs, rhs) ->
    match rhs with
    | HItem hi when hi = item -> Some lhs
    | _ -> None
  ) cover.projections

let find_left_expansions cover right_item =
  List.filter_map (fun (result, x_h, ri) ->
    if ri = right_item then Some (result, x_h) else None
  ) cover.left_expansions

let find_right_expansions cover left_item =
  List.filter_map (fun (result, li, y_h) ->
    if li = left_item then Some (result, y_h) else None
  ) cover.right_expansions

let get_expansion_index result =
  match result with
  | PartialItem (r, s, t) -> (r, s, t)
  | CompleteItem _ -> (-1, -1, -1)

(* The main recognition algorithm *)
let recognize (g: grammar) (input: string list) : rec_table =
  let tbl = create_table g input in
  let n = tbl.n in
  let agenda = Queue.create () in
  
  for i = 1 to n do
    let term = tbl.input.(i - 1) in
    let items = find_projections_from_terminal tbl.cover term in
    List.iter (fun item ->
      if add_item tbl (i - 1) i item then
        Queue.add (item, i - 1, i) agenda
    ) items
  done;
  
  while not (Queue.is_empty agenda) do
    let (a_h, i, j) = Queue.pop agenda in
    
    let projected = find_projections_from_item tbl.cover a_h in
    List.iter (fun b_h ->
      if add_item tbl i j b_h then
        Queue.add (b_h, i, j) agenda
    ) projected;
    
    let left_exps = find_left_expansions tbl.cover a_h in
    List.iter (fun (b_h, x_h) ->
      let (r, s, t) = get_expansion_index b_h in
      if not (is_blocked_left tbl i j a_h r t) then begin
        for i' = 0 to i - 1 do
          let can_combine = match x_h with
            | HTerm term -> i' = i - 1 && tbl.input.(i - 1) = term
            | HItem x_item -> mem_item tbl i' i x_item && not (is_blocked_right tbl i' i x_item r s)
          in
          if can_combine then begin
            if add_item tbl i' j b_h then Queue.add (b_h, i', j) agenda;
            (match x_h with
             | HItem x_item when is_partial x_item -> block_left tbl i' i x_item r s
             | _ -> ());
            if is_partial a_h then block_right tbl i j a_h r t
          end
        done
      end
    ) left_exps;
    
    let right_exps = find_right_expansions tbl.cover a_h in
    List.iter (fun (b_h, y_h) ->
      let (r, s, t) = get_expansion_index b_h in
      if not (is_blocked_right tbl i j a_h r s) then begin
        for j' = j + 1 to n do
          let can_combine = match y_h with
            | HTerm term -> j' = j + 1 && tbl.input.(j) = term
            | HItem y_item -> mem_item tbl j j' y_item && not (is_blocked_left tbl j j' y_item r t)
          in
          if can_combine then begin
            if add_item tbl i j' b_h then Queue.add (b_h, i, j') agenda;
            if is_partial a_h then block_left tbl i j a_h r s;
            (match y_h with
             | HItem y_item when is_partial y_item -> block_right tbl j j' y_item r t
             | _ -> ())
          end
        done
      end
    ) right_exps
  done;
  
  tbl

let is_accepted tbl =
  let start_item = CompleteItem tbl.grammar.start in
  mem_item tbl 0 tbl.n start_item

(* ============================================================ *)
(*                    NICE TABLE PRINTING                       *)
(* ============================================================ *)

(* Print a horizontal line *)
let print_hline widths =
  print_string "+";
  Array.iter (fun w -> 
    print_string (String.make w '-');
    print_string "+"
  ) widths;
  print_newline ()

let print_header_hline widths =
  print_string "+";
  Array.iter (fun w -> 
    print_string (String.make w '=');
    print_string "+"
  ) widths;
  print_newline ()
(* Pad string to width *)
let pad_center s w =
  let len = String.length s in
  if len >= w then String.sub s 0 w
  else
    let left = (w - len) / 2 in
    let right = w - len - left in
    String.make left ' ' ^ s ^ String.make right ' '

let pad_left s w =
  let len = String.length s in
  if len >= w then String.sub s 0 w
  else s ^ String.make (w - len) ' '

(* Get cell content for position (i, j) *)
let get_cell_content tbl i j =
  if j <= i then ""
  else
    let entry = tbl.entries.(i).(j) in
    if entry.items = [] then "·"
    else
      String.concat ", " (List.map short_string_of_h_item (List.sort compare entry.items))

(* Calculate column widths *)
let calc_widths tbl =
  let n = tbl.n in
  let widths = Array.make (n + 1) 3 in  (* minimum width 3 *)
  
  (* Header row: input symbols *)
  for j = 0 to n - 1 do
    widths.(j + 1) <- max widths.(j + 1) (String.length tbl.input.(j) + 2)
  done;
  
  (* Row labels *)
  widths.(0) <- max widths.(0) 3;
  
  (* Cell contents *)
  for i = 0 to n - 1 do
    for j = i + 1 to n do
      let content = get_cell_content tbl i j in
      widths.(j) <- max widths.(j) (String.length content + 2)
    done
  done;
  
  widths

(* Print the visual table *)
let print_visual_table tbl =
  let n = tbl.n in
  let widths = calc_widths tbl in
  
  Printf.printf "\n┌─ Recognition Table ─────────────────────────────────────┐\n";
  Printf.printf "│ Input: %-50s │\n" (String.concat " " (Array.to_list tbl.input));
  Printf.printf "└─────────────────────────────────────────────────────────┘\n\n";
  
  (* Column headers: j values with input below *)
  print_string "│";
  print_string (pad_center "i\\j" widths.(0));
  print_string "│";
  for j = 1 to n do
    print_string (pad_center (string_of_int j) widths.(j));
    print_string "│"
  done;
  print_newline ();
  
  (* Input symbols under column headers *)
  print_string "│";
  print_string (pad_center "" widths.(0));
  print_string "│";
  for j = 0 to n - 1 do
    print_string (pad_center tbl.input.(j) widths.(j + 1));
    print_string "│"
  done;
  print_newline ();
  
  print_header_hline widths;
  
  (* Data rows *)
  for i = 0 to n - 1 do
    print_string "│";
    print_string (pad_center (string_of_int i) widths.(0));
    print_string "│";
    
    for j = 1 to n do
      let content = if j <= i then "" else get_cell_content tbl i j in
      print_string (pad_center content widths.(j));
      print_string "│"
    done;
    print_newline ();
    
    if i < n - 1 then print_hline widths
  done;
  
  print_hline widths;
  print_newline ()

(* Print detailed cell information *)
let print_cell_details tbl =
  Printf.printf "┌─ Cell Details ──────────────────────────────────────────┐\n";
  
  for i = 0 to tbl.n - 1 do
    for j = i + 1 to tbl.n do
      let entry = tbl.entries.(i).(j) in
      if entry.items <> [] then begin
        let span = String.concat " " 
          (Array.to_list (Array.sub tbl.input i (j - i))) in
        Printf.printf "│ T[%d,%d] spans \"%s\":\n" i j span;
        List.iter (fun item ->
          Printf.printf "│   • %s\n" (string_of_h_item item)
        ) (List.sort compare entry.items);
      end
    done
  done;
  
  Printf.printf "└─────────────────────────────────────────────────────────┘\n"

(* Print parse result *)
let print_result tbl =
  let accepted = is_accepted tbl in
  Printf.printf "┌─ Result ────────────────────────────────────────────────┐\n";
  if accepted then
    Printf.printf "│ ✓ ACCEPTED: I_%s found in T[0,%d]%s│\n" 
      tbl.grammar.start tbl.n 
      (String.make (37 - String.length tbl.grammar.start - String.length (string_of_int tbl.n)) ' ')
  else
    Printf.printf "│ ✗ REJECTED: I_%s not in T[0,%d]%s│\n"
      tbl.grammar.start tbl.n
      (String.make (33 - String.length tbl.grammar.start - String.length (string_of_int tbl.n)) ' ');
  Printf.printf "└─────────────────────────────────────────────────────────┘\n"

(* Print grammar *)
let print_grammar g =
  Printf.printf "┌─ Grammar ───────────────────────────────────────────────┐\n";
  List.iter (fun prod ->
    let rhs_str = String.concat " " (List.map string_of_symbol prod.rhs) in
    let head_sym = if List.length prod.rhs > 0 
                   then string_of_symbol (get_symbol prod prod.head_pos)
                   else "ε" in
    Printf.printf "│ %d. %s → %-20s  [head: %s]%s│\n"
      prod.index prod.lhs rhs_str head_sym
      (String.make (max 0 (15 - String.length head_sym)) ' ')
  ) g.productions;
  Printf.printf "└─────────────────────────────────────────────────────────┘\n"

(* Print h-cover summary *)
let print_cover_summary (c: h_cover) =
  Printf.printf "┌─ H-c Summary ───────────────────────────────────────┐\n";
  Printf.printf "│ Items: %d                                                │\n" (List.length c.items);
  Printf.printf "│ Projections: %d                                          │\n" (List.length c.projections);
  Printf.printf "│ Left expansions: %d                                      │\n" (List.length c.left_expansions);
  Printf.printf "│ Right expansions: %d                                     │\n" (List.length c.right_expansions);
  Printf.printf "└─────────────────────────────────────────────────────────┘\n"

(* Main combined output *)
let run_and_print g input =
  Printf.printf "\n";
  Printf.printf "══════════════════════════════════════════════════════════\n";
  Printf.printf "                    RECOGNITION TEST                       \n";
  Printf.printf "══════════════════════════════════════════════════════════\n\n";
  
  print_grammar g;
  print_newline ();
  
  let tbl = recognize g input in
  
  print_cover_summary tbl.cover;
  print_newline ();
  
  print_visual_table tbl;
  
  print_cell_details tbl;
  print_newline ();
  
  print_result tbl;
  print_newline ()

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

let grammar_arith : grammar = {
  nonterminals = ["E"; "T"];
  terminals = ["+"; "n"];
  productions = [
    { index = 1; lhs = "E"; rhs = [Nonterminal "E"; Terminal "+"; Nonterminal "T"]; head_pos = 2 };
    { index = 2; lhs = "E"; rhs = [Nonterminal "T"]; head_pos = 1 };
    { index = 3; lhs = "T"; rhs = [Terminal "n"]; head_pos = 1 };
  ];
  start = "E";
}

let htable =
  run_and_print grammar_simple ["a"; "b"];
  run_and_print grammar_simple ["a"; "a"];  (* should reject *)
  run_and_print grammar_gcl ["det"; "n"; "cl"; "v"; "det"; "n"];
  run_and_print grammar_gcl ["det"; "n"];  (* should reject - just NP *)
  run_and_print grammar_arith ["n"; "+"; "n"; "+"; "n"]
