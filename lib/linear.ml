open Types

type forest_node =
  | FLeaf of string
  | FVirtual of h_item_or_terminal
  | FNode of h_item * forest_node list

type state_entry = h_item * forest_node list

type state = state_entry list

(* NOTE: merge_into logic needs examination — when item already seen, we append all
   new nodes and re-project them. Verify this is correct for all callers. *)
let merge_into seen item nodes =
  match List.assoc_opt item seen with
  | None -> ((item, nodes) :: seen, nodes)
  | Some _ ->
      let seen' = List.map (fun (i, ns) -> if i = item then (i, ns @ nodes) else (i, ns)) seen in
      (seen', nodes)

let seed (cover : h_cover) (token : string) : state =
  let rec close worklist seen =
    match worklist with
    | [] -> seen
    | (item, nodes) :: rest ->
        let (seen', new_nodes) = merge_into seen item nodes in
        if new_nodes = [] then close rest seen'
        else
          let projected =
            List.filter_map (fun (result, src) ->
              match src with
              | HItem i when i = item ->
                  let ns = List.map (fun node -> FNode (result, [node])) new_nodes in
                  Some (result, ns)
              | _ -> None)
              cover.projections
          in
          close (projected @ rest) seen'
  in
  let initial =
    List.filter_map (fun (item, src) ->
      match src with
      | HTerm t when t = token -> Some (item, [FLeaf token])
      | _ -> None)
      cover.projections
  in
  close initial []

let left_boundary_fill (cover : h_cover) (s : state) : state =
  let rec close worklist seen =
    match worklist with
    | [] -> seen
    | (item, nodes) :: rest ->
        let (seen', new_nodes) = merge_into seen item nodes in
        if new_nodes = [] then close rest seen'
        else
          let new_items =
            List.filter_map (fun (result, x_h, right_item) ->
              if right_item = item then
                let ns = List.map (fun node -> FNode (result, [FVirtual x_h; node])) new_nodes in
                Some (result, ns)
              else None)
              cover.left_expansions
          in
          close (new_items @ rest) seen'
  in
  close s []

let right_boundary_fill (cover : h_cover) (s : state) : state =
  let rec close worklist seen =
    match worklist with
    | [] -> seen
    | (item, nodes) :: rest ->
        let (seen', new_nodes) = merge_into seen item nodes in
        if new_nodes = [] then close rest seen'
        else
          let new_items =
            List.filter_map (fun (result, left_item, y_h) ->
              if left_item = item then
                let ns = List.map (fun node -> FNode (result, [node; FVirtual y_h])) new_nodes in
                Some (result, ns)
              else None)
              cover.right_expansions
          in
          close (new_items @ rest) seen'
  in
  close s []

(* Binary combine: fires combinations between acc and new_items for this token only.
   Does NOT accumulate — caller is responsible for merging state across steps.
   See linear_scan_notes.md for the full history of what was tried and why. *)
let combine (cover : h_cover) (acc : state) (new_items : state) (token : string) : state =
  let raw =
    List.concat_map (fun (l_item, l_nodes) ->
      List.concat_map (fun (r_item, r_nodes) ->
        let right_hits =
          List.filter_map (fun (result, left_item, y_h) ->
            if left_item = l_item && y_h = HItem r_item then
              let nodes = List.concat_map
                (fun ln -> List.map (fun rn -> FNode (result, [ln; rn])) r_nodes) l_nodes in
              Some (result, nodes)
            else None)
            cover.right_expansions
        in
        let left_hits =
          List.filter_map (fun (result, x_h, right_item) ->
            if right_item = r_item && x_h = HItem l_item then
              let nodes = List.concat_map
                (fun ln -> List.map (fun rn -> FNode (result, [ln; rn])) r_nodes) l_nodes in
              Some (result, nodes)
            else None)
            cover.left_expansions
        in
        right_hits @ left_hits)
      new_items)
    acc
  in
  let terminal_hits =
    List.concat_map (fun (l_item, l_nodes) ->
      List.filter_map (fun (result, left_item, y_h) ->
        if left_item = l_item && y_h = HTerm token then
          let nodes = List.map (fun ln -> FNode (result, [ln; FLeaf token])) l_nodes in
          Some (result, nodes)
        else None)
        cover.right_expansions)
      acc
  in
  let raw = raw @ terminal_hits in
  let rec close worklist seen =
    match worklist with
    | [] -> seen
    | (item, nodes) :: rest ->
        let (seen', new_nodes) = merge_into seen item nodes in
        if new_nodes = [] then close rest seen'
        else
          let projected =
            List.filter_map (fun (result, src) ->
              match src with
              | HItem i when i = item ->
                  let ns = List.map (fun node -> FNode (result, [node])) new_nodes in
                  Some (result, ns)
              | _ -> None)
              cover.projections
          in
          close (projected @ rest) seen'
  in
  close raw []

let scan (pg : prepared_grammar) (tokens : string list) : state =
  let cover = pg.pg_cover in
  match tokens with
  | [] -> []
  | [t] -> left_boundary_fill cover (right_boundary_fill cover (seed cover t))
  | first :: rest ->
      let state0 = left_boundary_fill cover (seed cover first) in
      let rec loop acc = function
        | [] -> acc
        | [last] -> combine cover acc (right_boundary_fill cover (seed cover last)) last
        | t :: ts -> loop (combine cover acc (seed cover t) t) ts
      in
      loop state0 rest

let scan_steps (pg : prepared_grammar) (tokens : string list) : (string * state) list =
  let cover = pg.pg_cover in
  match tokens with
  | [] -> []
  | [t] ->
      let s = left_boundary_fill cover (right_boundary_fill cover (seed cover t)) in
      [(t, s)]
  | first :: rest ->
      let state0 = left_boundary_fill cover (seed cover first) in
      let rec loop acc steps = function
        | [] -> List.rev steps
        | [last] ->
            let s = combine cover acc (right_boundary_fill cover (seed cover last)) last in
            List.rev ((last, s) :: steps)
        | t :: ts ->
            let s = combine cover acc (seed cover t) t in
            loop s ((t, s) :: steps) ts
      in
      loop state0 [(first, state0)] rest
