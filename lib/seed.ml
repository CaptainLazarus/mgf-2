open Types
open Hcover
open Table

let epsilons tbl n agenda =
  let epsilon_nts =
    tbl.grammar.productions
    |> List.filter_map (fun prod ->
           if List.length prod.rhs = 0 then Some prod.lhs else None)
    |> List.sort_uniq String.compare
  in
  List.iter
    (fun nt ->
      for i = 0 to n do
        let item = CompleteItem nt in
        if add_item tbl i i item (FromTerminal "ε") then
          Queue.add (item, i, i) agenda
      done)
    epsilon_nts

let terminals tbl n agenda =
  for i = 1 to n do
    let term = tbl.input.(i - 1) in
    find_projections_from_terminal tbl.cover term
    |> List.iter (fun item ->
           if add_item tbl (i - 1) i item (FromTerminal term) then
             Queue.add (item, i - 1, i) agenda)
  done

let left_boundary tbl first_term agenda =
  tbl.cover.right_expansions
  |> List.iter (fun (result, left_item, y_h) ->
         let matches =
           match y_h with
           | HTerm t -> t = first_term
           | HItem item -> mem_item tbl 0 1 item
         in
         if matches then
           let deriv = FromBoundaryRight (HItem left_item, y_h) in
           if add_item tbl 0 1 result deriv then Queue.add (result, 0, 1) agenda);
  tbl.cover.left_expansions
  |> List.iter (fun (result, x_h, right_item) ->
         if mem_item tbl 0 1 right_item then
           let deriv = FromBoundaryRight (x_h, HItem right_item) in
           if add_item tbl 0 1 result deriv then Queue.add (result, 0, 1) agenda)

let right_boundary tbl last_term n agenda =
  tbl.cover.left_expansions
  |> List.iter (fun (result, x_h, right_item) ->
         let matches =
           match x_h with
           | HTerm t -> t = last_term
           | HItem item -> mem_item tbl (n - 1) n item
         in
         if matches then
           let deriv = FromBoundaryLeft (x_h, HItem right_item) in
           if add_item tbl (n - 1) n result deriv then
             Queue.add (result, n - 1, n) agenda);
  tbl.cover.right_expansions
  |> List.iter (fun (result, left_item, y_h) ->
         if mem_item tbl (n - 1) n left_item then
           let deriv = FromBoundaryLeft (HItem left_item, y_h) in
           if add_item tbl (n - 1) n result deriv then
             Queue.add (result, n - 1, n) agenda)
