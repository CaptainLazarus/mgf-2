open Types
open Hcover

let create_table (g : grammar) (input : string list) : rec_table =
  let n = List.length input in
  let cover = compute_h_cover g in
  let entries =
    Array.init (n + 1) (fun _ ->
        Array.init (n + 1) (fun _ ->
            { items = []; blocked_left = []; blocked_right = [] }))
  in
  { n; entries; input = Array.of_list input; grammar = g; cover }

let mem_item tbl i j item =
  List.exists (fun (it, _) -> it = item) tbl.entries.(i).(j).items

let get_derivations tbl i j item =
  match List.find_opt (fun (it, _) -> it = item) tbl.entries.(i).(j).items with
  | Some (_, derivs) -> derivs
  | None -> []

let add_item tbl i j item deriv =
  let entry = tbl.entries.(i).(j) in
  match List.find_opt (fun (it, _) -> it = item) entry.items with
  | Some (_, derivs) ->
      if not (List.mem deriv derivs) then
        entry.items <-
          List.map
            (fun (it, ds) -> if it = item then (it, deriv :: ds) else (it, ds))
            entry.items;
      false
  | None ->
      entry.items <- (item, [ deriv ]) :: entry.items;
      true

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
  if not (List.exists
      (fun (it, r', t') -> it = item && r = r' && t = t')
      entry.blocked_left)
  then entry.blocked_left <- (item, r, t) :: entry.blocked_left

let block_right tbl i j item r s =
  let entry = tbl.entries.(i).(j) in
  if not (List.exists
      (fun (it, r', s') -> it = item && r = r' && s = s')
      entry.blocked_right)
  then entry.blocked_right <- (item, r, s) :: entry.blocked_right
