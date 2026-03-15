open Types

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

let string_of_derivation = function
  | FromTerminal t -> Printf.sprintf "Terminal(%s)" t
  | FromProject hi -> Printf.sprintf "Project(%s)" (string_of_h_item hi)
  | FromLeftExpand (k, x, ri) ->
      Printf.sprintf "LeftExp(k=%d, %s, %s)" k
        (string_of_h_item_or_terminal x)
        (string_of_h_item ri)
  | FromRightExpand (k, li, y) ->
      Printf.sprintf "RightExp(k=%d, %s, %s)" k (string_of_h_item li)
        (string_of_h_item_or_terminal y)
  | FromEpsilon hi -> Printf.sprintf "Epsilon(%s)" (string_of_h_item hi)
  | FromBoundaryRight (virtual_left, real_right) ->
      Printf.sprintf "BoundaryRight(virtual_left: %s, real_right: %s)"
        (string_of_h_item_or_terminal virtual_left)
        (string_of_h_item_or_terminal real_right)
  | FromBoundaryLeft (real_left, virtual_right) ->
      Printf.sprintf "BoundaryLeft(real_left: %s, virtual_right: %s)"
        (string_of_h_item_or_terminal real_left)
        (string_of_h_item_or_terminal virtual_right)
  | FromInductiveFill (virtual_left, real_right) ->
      Printf.sprintf "InductiveFill(virtual: %s, right: %s)"
        (string_of_h_item virtual_left)
        (string_of_h_item real_right)
  | FromInductiveFillRight (real_left, virtual_right) ->
      Printf.sprintf "InductiveFillRight(left: %s, virtual: %s)"
        (string_of_h_item real_left)
        (string_of_h_item_or_terminal virtual_right)

(* Helper functions *)

let symbol_to_h_item_or_terminal = function
  | Terminal t -> HTerm t
  | Nonterminal nt -> HItem (CompleteItem nt)

let get_symbol prod pos = List.nth prod.rhs (pos - 1)

let is_reachable_partial_item prod s t =
  let pi_r = List.length prod.rhs in
  let tau_r = prod.head_pos in
  s >= 0 && s < tau_r && tau_r <= t && t <= pi_r && not (s = 0 && t = pi_r)

let is_partial = function PartialItem _ -> true | CompleteItem _ -> false

(* Return a copy of the grammar with one production's head_pos changed *)
let set_head ~prod_index ~head_pos (g : grammar) : grammar =
  { g with productions =
      List.map (fun p ->
        if p.index = prod_index then { p with head_pos } else p)
        g.productions }

(* Compute nullable nonterminals via fixed-point iteration *)
let compute_nullable (g : grammar) : string list =
  let nullable = Hashtbl.create 16 in
  (* Seed: nonterminals with empty RHS *)
  List.iter
    (fun prod ->
      if List.length prod.rhs = 0 then Hashtbl.replace nullable prod.lhs ())
    g.productions;
  (* Iterate until fixed point *)
  let changed = ref true in
  while !changed do
    changed := false;
    List.iter
      (fun prod ->
        if not (Hashtbl.mem nullable prod.lhs) then
          let all_nullable =
            List.for_all
              (fun sym ->
                match sym with
                | Nonterminal nt -> Hashtbl.mem nullable nt
                | Terminal _ -> false)
              prod.rhs
          in
          if all_nullable && List.length prod.rhs > 0 then (
            Hashtbl.replace nullable prod.lhs ();
            changed := true))
      g.productions
  done;
  Hashtbl.fold (fun k () acc -> k :: acc) nullable []

(* Compute the h-cover *)
let compute_h_cover (g : grammar) : h_cover =
  let projections = ref [] in
  let left_expansions = ref [] in
  let right_expansions = ref [] in

  List.iter
    (fun prod ->
      let r = prod.index in
      let pi_r = List.length prod.rhs in
      let tau_r = prod.head_pos in

      if pi_r = 0 then ()
      else if pi_r = 1 then (* i.a -> Idr = IA | Terminal *)
        let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
        projections := (CompleteItem prod.lhs, x_h) :: !projections
      else
        let x_h = symbol_to_h_item_or_terminal (get_symbol prod tau_r) in
        projections := (PartialItem (r, tau_r - 1, tau_r), x_h) :: !projections;

        for s = 0 to tau_r - 1 do
          for t = tau_r to pi_r do
            if is_reachable_partial_item prod s t then (
              (if s < tau_r - 1 then
                 let x_h =
                   symbol_to_h_item_or_terminal (get_symbol prod (s + 1))
                 in
                 left_expansions :=
                   (PartialItem (r, s, t), x_h, PartialItem (r, s + 1, t))
                   :: !left_expansions);

              if t > tau_r then
                let y_h = symbol_to_h_item_or_terminal (get_symbol prod t) in
                right_expansions :=
                  (PartialItem (r, s, t), PartialItem (r, s, t - 1), y_h)
                  :: !right_expansions)
          done
        done;

        (if tau_r > 1 then
           let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
           left_expansions :=
             (CompleteItem prod.lhs, x_h, PartialItem (r, 1, pi_r))
             :: !left_expansions);

        (if tau_r < pi_r then
           let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
           right_expansions :=
             (CompleteItem prod.lhs, PartialItem (r, 0, pi_r - 1), y_h)
             :: !right_expansions);

        (if tau_r = 1 && is_reachable_partial_item prod 1 pi_r then
           let x_h = symbol_to_h_item_or_terminal (get_symbol prod 1) in
           left_expansions :=
             (CompleteItem prod.lhs, x_h, PartialItem (r, 1, pi_r))
             :: !left_expansions);

        if tau_r = pi_r && is_reachable_partial_item prod 0 (pi_r - 1) then
          let y_h = symbol_to_h_item_or_terminal (get_symbol prod pi_r) in
          right_expansions :=
            (CompleteItem prod.lhs, PartialItem (r, 0, pi_r - 1), y_h)
            :: !right_expansions)
    g.productions;

  let items = Hashtbl.create 16 in
  let add hi = Hashtbl.replace items hi () in
  List.iter (fun (lhs, _) -> add lhs) !projections;
  List.iter
    (fun (lhs, _, rhs) ->
      add lhs;
      add rhs)
    !left_expansions;
  List.iter
    (fun (lhs, l, _) ->
      add lhs;
      add l)
    !right_expansions;

  let dedup_left = Hashtbl.create 16 in
  let dedup_right = Hashtbl.create 16 in
  List.iter (fun x -> Hashtbl.replace dedup_left x ()) !left_expansions;
  List.iter (fun x -> Hashtbl.replace dedup_right x ()) !right_expansions;

  (* Compute epsilon projections from nullable nonterminals *)
  let nullable = compute_nullable g in
  let is_nullable nt = List.mem nt nullable in
  let eps_projs = ref [] in

  (* For left expansions: (result, x_h, right_item) where x_h is nullable *)
  List.iter
    (fun (result, x_h, right_item) ->
      match x_h with
      | HItem (CompleteItem d) when is_nullable d ->
          eps_projs := (result, right_item) :: !eps_projs
      | _ -> ())
    (Hashtbl.fold (fun k () acc -> k :: acc) dedup_left []);

  (* For right expansions: (result, left_item, y_h) where y_h is nullable *)
  List.iter
    (fun (result, left_item, y_h) ->
      match y_h with
      | HItem (CompleteItem d) when is_nullable d ->
          eps_projs := (result, left_item) :: !eps_projs
      | _ -> ())
    (Hashtbl.fold (fun k () acc -> k :: acc) dedup_right []);

  (* Dedup epsilon projections *)
  let dedup_eps = Hashtbl.create 16 in
  List.iter (fun x -> Hashtbl.replace dedup_eps x ()) !eps_projs;

  {
    items = Hashtbl.fold (fun k () acc -> k :: acc) items [];
    projections = !projections;
    left_expansions = Hashtbl.fold (fun k () acc -> k :: acc) dedup_left [];
    right_expansions = Hashtbl.fold (fun k () acc -> k :: acc) dedup_right [];
    epsilon_projections =
      Hashtbl.fold (fun k () acc -> k :: acc) dedup_eps [];
  }

(* Create empty recognition table *)
let create_table (g : grammar) (input : string list) : rec_table =
  let n = List.length input in
  let cover = compute_h_cover g in
  let entries =
    Array.init (n + 1) (fun _ ->
        Array.init (n + 1) (fun _ ->
            { items = []; blocked_left = []; blocked_right = [] }))
  in
  { n; entries; input = Array.of_list input; grammar = g; cover }

(* Check if item is in entry *)
let mem_item tbl i j item =
  List.exists (fun (it, _) -> it = item) tbl.entries.(i).(j).items

(* Get derivations for an item *)
let get_derivations tbl i j item =
  match List.find_opt (fun (it, _) -> it = item) tbl.entries.(i).(j).items with
  | Some (_, derivs) -> derivs
  | None -> []

(* Add item with a derivation, returns true if item is new *)
let add_item tbl i j item deriv =
  let entry = tbl.entries.(i).(j) in
  match List.find_opt (fun (it, _) -> it = item) entry.items with
  | Some (_, derivs) ->
      (* Item exists, add derivation if not already present *)
      if not (List.mem deriv derivs) then
        entry.items <-
          List.map
            (fun (it, ds) -> if it = item then (it, deriv :: ds) else (it, ds))
            entry.items;
      false (* item wasn't new *)
  | None ->
      (* New item *)
      entry.items <- (item, [ deriv ]) :: entry.items;
      true

(* Blocking functions *)
let is_blocked_left tbl i j item r t =
  List.exists
    (fun (it, r', t') -> it = item && r = r' && t = t')
    tbl.entries.(i).(j).blocked_left

let is_blocked_right tbl i j item r s =
  List.exists
    (fun (it, r', s') -> it = item && r = r' && s = s')
    tbl.entries.(i).(j).blocked_right

let block_left tbl i j item r t =
  let entry = tbl.entries.(i).(j) in
  if
    not
      (List.exists
         (fun (it, r', t') -> it = item && r = r' && t = t')
         entry.blocked_left)
  then entry.blocked_left <- (item, r, t) :: entry.blocked_left

let block_right tbl i j item r s =
  let entry = tbl.entries.(i).(j) in
  if
    not
      (List.exists
         (fun (it, r', s') -> it = item && r = r' && s = s')
         entry.blocked_right)
  then entry.blocked_right <- (item, r, s) :: entry.blocked_right

(* Find applicable productions *)
let find_projections_from_terminal cover term =
  List.filter_map
    (fun (lhs, rhs) ->
      match rhs with HTerm t when t = term -> Some lhs | _ -> None)
    cover.projections

let find_projections_from_item cover item =
  List.filter_map
    (fun (lhs, rhs) ->
      match rhs with HItem hi when hi = item -> Some lhs | _ -> None)
    cover.projections

let find_left_expansions cover right_item =
  List.filter_map
    (fun (result, x_h, ri) ->
      if ri = right_item then Some (result, x_h) else None)
    cover.left_expansions

let find_right_expansions cover left_item =
  List.filter_map
    (fun (result, li, y_h) ->
      if li = left_item then Some (result, y_h) else None)
    cover.right_expansions

(* Find right expansions where y_h matches the given h_item *)
let find_right_expansions_by_right cover y_item =
  List.filter_map
    (fun (result, left_item, y_h) ->
      match y_h with
      | HItem hi when hi = y_item -> Some (result, left_item)
      | _ -> None)
    cover.right_expansions

(* Find left expansions where x_h matches the given h_item *)
let find_left_expansions_by_left cover x_item =
  List.filter_map
    (fun (result, x_h, right_item) ->
      match x_h with
      | HItem hi when hi = x_item -> Some (result, right_item)
      | _ -> None)
    cover.left_expansions

let find_epsilon_projections cover item =
  List.filter_map
    (fun (result, source) ->
      if source = item then Some result else None)
    cover.epsilon_projections

let get_expansion_index result =
  match result with
  | PartialItem (r, s, t) -> (r, s, t)
  | CompleteItem _ -> (-1, -1, -1)

(* Core agenda processing loop: drains the agenda, applying project/expand rules *)
let process_agenda (tbl : rec_table) (agenda : (h_item * int * int) Queue.t) : unit =
  let n = tbl.n in
  while not (Queue.is_empty agenda) do
    let a_h, i, j = Queue.pop agenda in

    (* Project step *)
    let projected = find_projections_from_item tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromProject a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
      projected;

    (* Epsilon projection step *)
    let eps_projected = find_epsilon_projections tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromEpsilon a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
      eps_projected;

    (* Left-expand step *)
    let left_exps = find_left_expansions tbl.cover a_h in
    List.iter
      (fun (b_h, x_h) ->
        let r, s, t = get_expansion_index b_h in
        if not (is_blocked_left tbl i j a_h r t) then
          for i' = 0 to i do
            let can_combine =
              match x_h with
              | HTerm term -> i' = i - 1 && tbl.input.(i - 1) = term
              | HItem x_item ->
                  mem_item tbl i' i x_item
                  && not (is_blocked_right tbl i' i x_item r s)
            in
            if can_combine then (
              let deriv = FromLeftExpand (i, x_h, a_h) in
              if add_item tbl i' j b_h deriv then Queue.add (b_h, i', j) agenda;
              (match x_h with
              | HItem x_item when is_partial x_item ->
                  block_left tbl i' i x_item r s
              | _ -> ());
              if is_partial a_h then block_right tbl i j a_h r t)
          done)
      left_exps;

    (* Right-expand step *)
    let right_exps = find_right_expansions tbl.cover a_h in
    List.iter
      (fun (b_h, y_h) ->
        let r, s, t = get_expansion_index b_h in
        if not (is_blocked_right tbl i j a_h r s) then
          for j' = j to n do
            let can_combine =
              match y_h with
              | HTerm term -> j' = j + 1 && tbl.input.(j) = term
              | HItem y_item ->
                  mem_item tbl j j' y_item
                  && not (is_blocked_left tbl j j' y_item r t)
            in
            if can_combine then (
              let deriv = FromRightExpand (j, a_h, y_h) in
              if add_item tbl i j' b_h deriv then Queue.add (b_h, i, j') agenda;
              if is_partial a_h then block_left tbl i j a_h r s;
              match y_h with
              | HItem y_item when is_partial y_item ->
                  block_right tbl j j' y_item r t
              | _ -> ())
          done)
      right_exps;

    (* Reverse right-expand: a_h acts as y_h in a right expansion *)
    let rev_right = find_right_expansions_by_right tbl.cover a_h in
    List.iter
      (fun (result, left_item) ->
        for i' = 0 to i do
          if mem_item tbl i' i left_item then (
            let deriv = FromRightExpand (i, left_item, HItem a_h) in
            if add_item tbl i' j result deriv then
              Queue.add (result, i', j) agenda)
        done)
      rev_right;

    (* Reverse left-expand: a_h acts as x_h in a left expansion *)
    let rev_left = find_left_expansions_by_left tbl.cover a_h in
    List.iter
      (fun (result, right_item) ->
        for j' = j to n do
          if mem_item tbl j j' right_item then (
            let deriv = FromLeftExpand (j, HItem a_h, right_item) in
            if add_item tbl i j' result deriv then
              Queue.add (result, i, j') agenda)
        done)
      rev_left
  done

(* The main recognition algorithm with backpointers *)
(* Core algorithm: runs on an already-initialised (empty) rec_table.
   Separated from table creation so the H-cover can be pre-computed once
   and shared across many recognize_with calls. *)
let recognize_tbl (tbl : rec_table) : rec_table =
  let n = tbl.n in
  let agenda = Queue.create () in

  (* Init step: seed epsilon productions into T[i,i] for nullable nonterminals *)
  let epsilon_nts =
    List.filter_map
      (fun prod ->
        if List.length prod.rhs = 0 then Some prod.lhs else None)
      tbl.grammar.productions
  in
  let epsilon_nts = List.sort_uniq String.compare epsilon_nts in
  List.iter
    (fun nt ->
      for i = 0 to n do
        let item = CompleteItem nt in
        let deriv = FromTerminal "ε" in
        if add_item tbl i i item deriv then Queue.add (item, i, i) agenda
      done)
    epsilon_nts;

  (* Init step: add items for terminals that are heads *)
  for i = 1 to n do
    let term = tbl.input.(i - 1) in
    let items = find_projections_from_terminal tbl.cover term in
    List.iter
      (fun item ->
        let deriv = FromTerminal term in
        if add_item tbl (i - 1) i item deriv then
          Queue.add (item, i - 1, i) agenda)
      items
  done;

  (* Boundary conditions: seed items from h-cover expansions at input boundaries *)
  if n > 0 then begin
    let first_term = tbl.input.(0) in
    let last_term = tbl.input.(n - 1) in
    (* Condition 1: seed T[0,1] *)
    (* a) right expansions where y_h matches first_term — left_item is dropped beyond left edge *)
    List.iter
      (fun (result, left_item, y_h) ->
        let matches =
          match y_h with
          | HTerm t -> t = first_term
          | HItem item -> mem_item tbl 0 1 item
        in
        if matches then (
          let deriv = FromBoundaryRight (HItem left_item, y_h) in
          if add_item tbl 0 1 result deriv then
            Queue.add (result, 0, 1) agenda))
      tbl.cover.right_expansions;
    (* b) left expansions where right_item is in T[0,1] — x_h is dropped beyond left edge *)
    List.iter
      (fun (result, x_h, right_item) ->
        if mem_item tbl 0 1 right_item then (
          let deriv = FromBoundaryRight (x_h, HItem right_item) in
          if add_item tbl 0 1 result deriv then
            Queue.add (result, 0, 1) agenda))
      tbl.cover.left_expansions;

    (* Condition 2: seed T[n-1,n] *)
    (* a) left expansions where x_h matches last_term — right_item is dropped beyond right edge *)
    List.iter
      (fun (result, x_h, right_item) ->
        let matches =
          match x_h with
          | HTerm t -> t = last_term
          | HItem item -> mem_item tbl (n - 1) n item
        in
        if matches then (
          let deriv = FromBoundaryLeft (x_h, HItem right_item) in
          if add_item tbl (n - 1) n result deriv then
            Queue.add (result, n - 1, n) agenda))
      tbl.cover.left_expansions;

    (* b) right expansions where left_item is in T[n-1,n] — y_h is dropped beyond right edge *)
    List.iter
      (fun (result, left_item, y_h) ->
        if mem_item tbl (n - 1) n left_item then (
          let deriv = FromBoundaryLeft (HItem left_item, y_h) in
          if add_item tbl (n - 1) n result deriv then
            Queue.add (result, n - 1, n) agenda))
      tbl.cover.right_expansions
  end;

  process_agenda tbl agenda;

  (* L-Reduce: triggered when T[0,k] is empty after normal inference.
     Climbs T[0,k-1] via right-child rules, inferring virtual left siblings,
     then lets the agenda right-expand into T[0,k]. *)
  for k = 1 to n do
    begin
      let frontier = ref (List.map fst tbl.entries.(0).(k - 1).items) in
      let visited = Hashtbl.create 16 in
      while !frontier <> [] do
        let next_frontier = ref [] in
        List.iter (fun b ->
          if not (Hashtbl.mem visited b) then begin
            Hashtbl.replace visited b ();
            (* Find rules X <- A B where B = b (b is RIGHT child, A is virtual) *)
            List.iter (fun (x, a) ->
              let deriv = FromInductiveFill (a, b) in
              if add_item tbl 0 (k - 1) x deriv then begin
                Queue.add (x, 0, k - 1) agenda;
                next_frontier := x :: !next_frontier
              end)
              (find_right_expansions_by_right tbl.cover b)
          end)
          !frontier;
        frontier := !next_frontier
      done;
      process_agenda tbl agenda
    end
  done;

  (* R-Reduce: only runs if T[0,n] is empty after normal recognition + L-Reduce.
     Anchored at n, fills T[k,n] upward by right-expanding items in T[k+1,n]
     with virtual right siblings, then combining with T[k,k+1]. *)
  if tbl.entries.(0).(n).items = [] then begin
    for k = n - 1 downto 0 do
      begin
        let frontier = ref (List.map fst tbl.entries.(k + 1).(n).items) in
        let visited = Hashtbl.create 16 in
        while !frontier <> [] do
          let next_frontier = ref [] in
          List.iter (fun b ->
            if not (Hashtbl.mem visited b) then begin
              Hashtbl.replace visited b ();
              List.iter (fun (x, y_h) ->
                let deriv = FromInductiveFillRight (b, y_h) in
                if add_item tbl (k + 1) n x deriv then begin
                  Queue.add (x, k + 1, n) agenda;
                  next_frontier := x :: !next_frontier
                end)
                (find_right_expansions tbl.cover b)
            end)
            !frontier;
          frontier := !next_frontier
        done;
        process_agenda tbl agenda
      end
    done;

    (* R-Reduce final pass: right-expand items in T[0,n] with virtual right
       siblings. Needed because R-Reduce may leave T[0,n] partially filled. *)
    let frontier = ref (List.map fst tbl.entries.(0).(n).items) in
    let visited = Hashtbl.create 16 in
    while !frontier <> [] do
      let next_frontier = ref [] in
      List.iter (fun b ->
        if not (Hashtbl.mem visited b) then begin
          Hashtbl.replace visited b ();
          List.iter (fun (x, y_h) ->
            let deriv = FromInductiveFillRight (b, y_h) in
            if add_item tbl 0 n x deriv then begin
              Queue.add (x, 0, n) agenda;
              next_frontier := x :: !next_frontier
            end)
            (find_right_expansions tbl.cover b)
        end)
        !frontier;
      frontier := !next_frontier
    done;
    process_agenda tbl agenda
  end;

  (* L-Reduce final pass: always runs. Applies virtual left-expansion to items
     in T[0,n] that are right children of rules. Symmetric to R-Reduce final
     pass — runs for both L-Reduce and R-Reduce produced items. *)
  let frontier = ref (List.map fst tbl.entries.(0).(n).items) in
  let visited = Hashtbl.create 16 in
  while !frontier <> [] do
    let next_frontier = ref [] in
    List.iter (fun b ->
      if not (Hashtbl.mem visited b) then begin
        Hashtbl.replace visited b ();
        List.iter (fun (x, a) ->
          let deriv = FromInductiveFill (a, b) in
          if add_item tbl 0 n x deriv then begin
            Queue.add (x, 0, n) agenda;
            next_frontier := x :: !next_frontier
          end)
          (find_right_expansions_by_right tbl.cover b)
      end)
      !frontier;
    frontier := !next_frontier
  done;
  process_agenda tbl agenda;

  tbl

let recognize (g : grammar) (input : string list) : rec_table =
  recognize_tbl (create_table g input)

let prepare (g : grammar) : prepared_grammar =
  { pg_grammar = g; pg_cover = compute_h_cover g }

(* Recognise using a pre-compiled grammar — skips H-cover recomputation.
   Identical algorithm to recognize; the only difference is the table is built
   with the already-computed cover from pg. *)
let recognize_with (pg : prepared_grammar) (input : string list) : rec_table =
  let n = List.length input in
  let entries =
    Array.init (n + 1) (fun _ ->
        Array.init (n + 1) (fun _ ->
            { items = []; blocked_left = []; blocked_right = [] }))
  in
  recognize_tbl
    { n; entries; input = Array.of_list input;
      grammar = pg.pg_grammar; cover = pg.pg_cover }

(* Bounded recognition: same as recognize_tbl but CompleteItems produced by
   multi-child rules (FromLeftExpand / FromRightExpand) do NOT project further
   upward via unit production chains. Unit productions and epsilon rules still
   propagate freely (rules 1 and 3). Multi-child completions stop there (rule 2). *)

let is_multi_child_derivation = function
  | FromLeftExpand _ | FromRightExpand _
  | FromBoundaryLeft _ | FromBoundaryRight _
  | FromInductiveFill _ | FromInductiveFillRight _ -> true
  | _ -> false

let should_project_upward tbl item i j =
  match item with
  | PartialItem _ -> true
  | CompleteItem _ ->
    match List.find_opt (fun (it, _) -> it = item) tbl.entries.(i).(j).items with
    | None -> true
    | Some (_, derivs) -> not (List.exists is_multi_child_derivation derivs)

let process_bounded_agenda (tbl : rec_table) (agenda : (h_item * int * int) Queue.t) : unit =
  let n = tbl.n in
  while not (Queue.is_empty agenda) do
    let a_h, i, j = Queue.pop agenda in

    (* Project step — always runs (unit productions always propagate) *)
    let projected = find_projections_from_item tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromProject a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
      projected;

    (* Epsilon projection — always fires (rule 3) *)
    let eps_projected = find_epsilon_projections tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromEpsilon a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
      eps_projected;

    (* Left-expand step *)
    let left_exps = find_left_expansions tbl.cover a_h in
    List.iter
      (fun (b_h, x_h) ->
        let r, s, t = get_expansion_index b_h in
        if not (is_blocked_left tbl i j a_h r t) then
          for i' = 0 to i do
            let can_combine =
              match x_h with
              | HTerm term -> i' = i - 1 && tbl.input.(i - 1) = term
              | HItem x_item ->
                  mem_item tbl i' i x_item
                  && not (is_blocked_right tbl i' i x_item r s)
            in
            if can_combine then (
              let deriv = FromLeftExpand (i, x_h, a_h) in
              if add_item tbl i' j b_h deriv then Queue.add (b_h, i', j) agenda;
              (match x_h with
              | HItem x_item when is_partial x_item ->
                  block_left tbl i' i x_item r s
              | _ -> ());
              if is_partial a_h then block_right tbl i j a_h r t)
          done)
      left_exps;

    (* Right-expand step *)
    let right_exps = find_right_expansions tbl.cover a_h in
    List.iter
      (fun (b_h, y_h) ->
        let r, s, t = get_expansion_index b_h in
        if not (is_blocked_right tbl i j a_h r s) then
          for j' = j to n do
            let can_combine =
              match y_h with
              | HTerm term -> j' = j + 1 && tbl.input.(j) = term
              | HItem y_item ->
                  mem_item tbl j j' y_item
                  && not (is_blocked_left tbl j j' y_item r t)
            in
            if can_combine then (
              let deriv = FromRightExpand (j, a_h, y_h) in
              if add_item tbl i j' b_h deriv then Queue.add (b_h, i, j') agenda;
              if is_partial a_h then block_left tbl i j a_h r s;
              match y_h with
              | HItem y_item when is_partial y_item ->
                  block_right tbl j j' y_item r t
              | _ -> ())
          done)
      right_exps;

    (* Reverse right-expand: a_h acts as y_h in a right expansion *)
    let rev_right = find_right_expansions_by_right tbl.cover a_h in
    List.iter
      (fun (result, left_item) ->
        for i' = 0 to i do
          if mem_item tbl i' i left_item then (
            let deriv = FromRightExpand (i, left_item, HItem a_h) in
            if add_item tbl i' j result deriv then
              Queue.add (result, i', j) agenda)
        done)
      rev_right;

    (* Reverse left-expand: a_h acts as x_h in a left expansion *)
    let rev_left = find_left_expansions_by_left tbl.cover a_h in
    List.iter
      (fun (result, right_item) ->
        for j' = j to n do
          if mem_item tbl j j' right_item then (
            let deriv = FromLeftExpand (j, HItem a_h, right_item) in
            if add_item tbl i j' result deriv then
              Queue.add (result, i, j') agenda)
        done)
      rev_left
  done

let recognize_bounded_with (pg : prepared_grammar) (input : string list) : rec_table =
  let n = List.length input in
  let entries =
    Array.init (n + 1) (fun _ ->
        Array.init (n + 1) (fun _ ->
            { items = []; blocked_left = []; blocked_right = [] }))
  in
  let tbl =
    { n; entries; input = Array.of_list input;
      grammar = pg.pg_grammar; cover = pg.pg_cover }
  in
  let agenda = Queue.create () in
  let epsilon_nts =
    List.filter_map
      (fun prod -> if List.length prod.rhs = 0 then Some prod.lhs else None)
      tbl.grammar.productions
    |> List.sort_uniq String.compare
  in
  List.iter
    (fun nt ->
      for i = 0 to n do
        let item = CompleteItem nt in
        if add_item tbl i i item (FromTerminal "ε") then Queue.add (item, i, i) agenda
      done)
    epsilon_nts;
  for i = 1 to n do
    let term = tbl.input.(i - 1) in
    let items = find_projections_from_terminal tbl.cover term in
    List.iter
      (fun item ->
        if add_item tbl (i - 1) i item (FromTerminal term) then
          Queue.add (item, i - 1, i) agenda)
      items
  done;
  process_bounded_agenda tbl agenda;
  tbl

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

let print_root_candidates candidates =
  Printf.printf "+-- Parse Root Inference %s+\n" (String.make 36 '-');
  if candidates = [] then
    Printf.printf "| No items found in T[0,n]\n"
  else
    List.iter (fun c ->
      if c.missing_left = [] && c.missing_right = [] then
        Printf.printf "| COMPLETE : %s\n" c.root
      else
        let fmt syms = String.concat " " (List.map string_of_symbol syms) in
        Printf.printf "| PARTIAL  : %s  (missing left: [%s]  right: [%s])\n"
          c.root (fmt c.missing_left) (fmt c.missing_right))
      candidates;
  Printf.printf "+%s+\n" (String.make 60 '-')

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

(* ============================================================ *)
(*                    TREE PRINTING                             *)
(* ============================================================ *)

let expand_virtual g x =
  match x with
  | HTerm t -> Printf.sprintf "\"%s\"" t
  | HItem (CompleteItem nt) -> nt
  | HItem (PartialItem (r, s, t)) ->
      let prod = List.find (fun p -> p.index = r) g.productions in
      let syms = Array.of_list prod.rhs in
      (* positions s+1..t in the RHS (1-indexed) → indices s..t-1 (0-indexed) *)
      Array.to_list (Array.sub syms s (t - s))
      |> List.map string_of_symbol
      |> String.concat " "

let label_virtual ?grammar x =
  match grammar with
  | Some g -> expand_virtual g x
  | None   -> string_of_h_item_or_terminal x

let rec print_tree_aux ?grammar prefix is_last tree =
  let connector    = if is_last then "└── " else "├── " in
  let child_prefix = prefix ^ (if is_last then "    " else "│   ") in
  match tree with
  | Leaf t ->
    Printf.printf "%s%s\"%s\"\n" prefix connector t
  | Virtual x ->
    Printf.printf "%s%s<virtual: %s>\n" prefix connector (label_virtual ?grammar x)
  | Node (nt, children) ->
    Printf.printf "%s%s%s\n" prefix connector nt;
    let n = List.length children in
    List.iteri (fun i child ->
      print_tree_aux ?grammar child_prefix (i = n - 1) child)
      children

let print_tree ?grammar tree =
  match tree with
  | Leaf t    -> Printf.printf "\"%s\"\n" t
  | Virtual x -> Printf.printf "<virtual: %s>\n" (label_virtual ?grammar x)
  | Node (nt, children) ->
    Printf.printf "%s\n" nt;
    let n = List.length children in
    List.iteri (fun i child ->
      print_tree_aux ?grammar "" (i = n - 1) child)
      children

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

(* ============================================================ *)
(*                    PRINTING FUNCTIONS                        *)
(* ============================================================ *)

let repeat_string s n = String.concat "" (List.init n (fun _ -> s))

let print_hline widths =
  print_string "+";
  Array.iter
    (fun w ->
      print_string (String.make w '-');
      print_string "+")
    widths;
  print_newline ()

let print_header_hline widths =
  print_string "+";
  Array.iter
    (fun w ->
      print_string (String.make w '=');
      print_string "+")
    widths;
  print_newline ()

let pad_center s w =
  let len = String.length s in
  if len >= w then String.sub s 0 w
  else
    let left = (w - len) / 2 in
    let right = w - len - left in
    String.make left ' ' ^ s ^ String.make right ' '

let get_cell_content tbl i j =
  if j < i then ""
  else
    let items = tbl.entries.(i).(j).items in
    if items = [] then "."
    else
      String.concat ", "
        (List.map
           (fun (it, _) -> short_string_of_h_item it)
           (List.sort compare items))

let calc_widths tbl =
  let n = tbl.n in
  let widths = Array.make (n + 1) 3 in
  for j = 0 to n - 1 do
    widths.(j + 1) <- max widths.(j + 1) (String.length tbl.input.(j) + 2)
  done;
  widths.(0) <- max widths.(0) 3;
  for i = 0 to n - 1 do
    for j = i + 1 to n do
      let content = get_cell_content tbl i j in
      widths.(j) <- max widths.(j) (String.length content + 2)
    done
  done;
  widths

let print_visual_table tbl =
  let n = tbl.n in
  let widths = calc_widths tbl in

  Printf.printf "\n+-- Recognition Table %s+\n" (String.make 40 '-');
  Printf.printf "| Input: %-51s|\n"
    (String.concat " " (Array.to_list tbl.input));
  Printf.printf "+%s+\n\n" (String.make 60 '-');

  print_string "|";
  print_string (pad_center "i\\j" widths.(0));
  print_string "|";
  for j = 1 to n do
    print_string (pad_center (string_of_int j) widths.(j));
    print_string "|"
  done; 
  print_newline ();

  print_string "|";
  print_string (pad_center "" widths.(0));
  print_string "|";
  for j = 0 to n - 1 do
    print_string (pad_center tbl.input.(j) widths.(j + 1));
    print_string "|"
  done;
  print_newline ();

  print_header_hline widths;

  for i = 0 to n - 1 do
    print_string "|";
    print_string (pad_center (string_of_int i) widths.(0));
    print_string "|";

    for j = 1 to n do
      let content = if j <= i then "" else get_cell_content tbl i j in
      print_string (pad_center content widths.(j));
      print_string "|"
    done;
    print_newline ();

    if i < n - 1 then print_hline widths
  done;

  print_hline widths;
  print_newline ()

let print_cell_details tbl =
  Printf.printf "+-- Cell Details %s+\n" (String.make 44 '-');

  for i = 0 to tbl.n do
    for j = i to tbl.n do
      let items = tbl.entries.(i).(j).items in
      if items <> [] then (
        let span =
          if j > i then
            String.concat " " (Array.to_list (Array.sub tbl.input i (j - i)))
          else "ε"
        in
        Printf.printf "| T[%d,%d] spans \"%s\":\n" i j span;
        List.iter
          (fun (item, derivs) ->
            Printf.printf "|   %s\n" (string_of_h_item item);
            List.iter
              (fun d -> Printf.printf "|     <- %s\n" (string_of_derivation d))
              derivs)
          (List.sort compare items))
    done
  done;

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

let print_grammar g =
  Printf.printf "+-- Grammar %s+\n" (String.make 49 '-');
  List.iter
    (fun prod ->
      let rhs_str = String.concat " " (List.map string_of_symbol prod.rhs) in
      let head_sym =
        if List.length prod.rhs > 0 then
          string_of_symbol (get_symbol prod prod.head_pos)
        else "e"
      in
      Printf.printf "| %d. %s -> %-25s [head: %s]\n" prod.index prod.lhs rhs_str
        head_sym)
    g.productions;
  Printf.printf "+%s+\n" (String.make 60 '-')

let print_cover_summary (cover : h_cover) =
  Printf.printf "+-- H-Cover Summary %s+\n" (String.make 41 '-');
  Printf.printf "| Items: %d\n" (List.length cover.items);
  Printf.printf "| Projections: %d\n" (List.length cover.projections);
  Printf.printf "| Left expansions: %d\n" (List.length cover.left_expansions);
  Printf.printf "| Right expansions: %d\n" (List.length cover.right_expansions);
  Printf.printf "| Epsilon projections: %d\n"
    (List.length cover.epsilon_projections);
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

 let print_cover (cover : h_cover) =                                                                                                                                                                                                         
    Printf.printf "+-- H-Cover %s+\n" (String.make 49 '-'); 
    Printf.printf "| Items (%d):\n" (List.length cover.items);                                                                                                                                                                                
    List.iter (fun it ->                                    
      Printf.printf "|   %s\n" (string_of_h_item it))
      (List.sort compare cover.items);
    Printf.printf "| Projections (%d):\n" (List.length cover.projections);
    List.iter (fun (lhs, rhs) ->
      Printf.printf "|   %s  <-  %s\n"
        (string_of_h_item lhs) (string_of_h_item_or_terminal rhs))
      cover.projections;
    Printf.printf "| Left expansions (%d):\n" (List.length cover.left_expansions);
    List.iter (fun (result, x_h, right_item) ->
      Printf.printf "|   %s  <-  %s  %s\n"
        (string_of_h_item result)
        (string_of_h_item_or_terminal x_h)
        (string_of_h_item right_item))
      cover.left_expansions;
    Printf.printf "| Right expansions (%d):\n" (List.length cover.right_expansions);
    List.iter (fun (result, left_item, y_h) ->
      Printf.printf "|   %s  <-  %s  %s\n"
        (string_of_h_item result)
        (string_of_h_item left_item)
        (string_of_h_item_or_terminal y_h))
      cover.right_expansions;
    Printf.printf "| Epsilon projections (%d):\n" (List.length cover.epsilon_projections);
    List.iter (fun (result, source) ->
      Printf.printf "|   %s  <-  %s  [ε]\n"
        (string_of_h_item result)
        (string_of_h_item source))
      cover.epsilon_projections;
    Printf.printf "+%s+\n" (String.make 60 '-')


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
