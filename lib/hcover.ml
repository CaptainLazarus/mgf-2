open Types
open Print

let symbol_to_h_item_or_terminal = function
  | Terminal t -> HTerm t
  | Nonterminal nt -> HItem (CompleteItem nt)

let is_reachable_partial_item prod s t =
  let pi_r = List.length prod.rhs in
  let tau_r = prod.head_pos in
  s >= 0 && s < tau_r && tau_r <= t && t <= pi_r && not (s = 0 && t = pi_r)

let is_partial = function PartialItem _ -> true | CompleteItem _ -> false

(* Return a copy of the grammar with one production's head_pos changed *)
let set_head ~prod_index ~head_pos (g : grammar) : grammar =
  {
    g with
    productions =
      List.map
        (fun p -> if p.index = prod_index then { p with head_pos } else p)
        g.productions;
  }

(* Compute nullable nonterminals via fixed-point iteration *)
let compute_nullable (g : grammar) : string list =
  let nullable = Hashtbl.create 16 in
  List.iter
    (fun prod ->
      if List.length prod.rhs = 0 then Hashtbl.replace nullable prod.lhs ())
    g.productions;
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
      else if pi_r = 1 then
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

  let nullable = compute_nullable g in
  let is_nullable nt = List.mem nt nullable in
  let eps_projs = ref [] in

  List.iter
    (fun (result, x_h, right_item) ->
      match x_h with
      | HItem (CompleteItem d) when is_nullable d ->
          eps_projs := (result, right_item) :: !eps_projs
      | _ -> ())
    (Hashtbl.fold (fun k () acc -> k :: acc) dedup_left []);

  List.iter
    (fun (result, left_item, y_h) ->
      match y_h with
      | HItem (CompleteItem d) when is_nullable d ->
          eps_projs := (result, left_item) :: !eps_projs
      | _ -> ())
    (Hashtbl.fold (fun k () acc -> k :: acc) dedup_right []);

  let dedup_eps = Hashtbl.create 16 in
  List.iter (fun x -> Hashtbl.replace dedup_eps x ()) !eps_projs;

  {
    items = Hashtbl.fold (fun k () acc -> k :: acc) items [];
    projections = !projections;
    left_expansions = Hashtbl.fold (fun k () acc -> k :: acc) dedup_left [];
    right_expansions = Hashtbl.fold (fun k () acc -> k :: acc) dedup_right [];
    epsilon_projections = Hashtbl.fold (fun k () acc -> k :: acc) dedup_eps [];
  }

(* Cover lookup functions *)

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

let find_right_expansions_by_right cover y_item =
  List.filter_map
    (fun (result, left_item, y_h) ->
      match y_h with
      | HItem hi when hi = y_item -> Some (result, left_item)
      | _ -> None)
    cover.right_expansions

let find_left_expansions_by_left cover x_item =
  List.filter_map
    (fun (result, x_h, right_item) ->
      match x_h with
      | HItem hi when hi = x_item -> Some (result, right_item)
      | _ -> None)
    cover.left_expansions

let find_epsilon_projections cover item =
  List.filter_map
    (fun (result, source) -> if source = item then Some result else None)
    cover.epsilon_projections

let get_expansion_index result =
  match result with
  | PartialItem (r, s, t) -> (r, s, t)
  | CompleteItem _ -> (-1, -1, -1)
