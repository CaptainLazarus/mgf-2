open Types
open Hcover
open Table

let show_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "P(%d,%d,%d)" r s t
  | CompleteItem nt -> nt

let show_hot = function
  | HItem i -> show_item i
  | HTerm t -> Printf.sprintf "'%s'" t

let enqueue_if_new tbl agenda i j item deriv =
  if add_item tbl i j item deriv then Queue.add (item, i, j) agenda

let do_project tbl agenda a_h i j =
  find_projections_from_item tbl.cover a_h
  |> List.iter (fun b_h ->
         enqueue_if_new tbl agenda i j b_h (FromProject a_h))

let do_eps_project tbl agenda a_h i j =
  find_epsilon_projections tbl.cover a_h
  |> List.iter (fun b_h ->
         enqueue_if_new tbl agenda i j b_h (FromEpsilon a_h))

let do_left_expand tbl agenda a_h i j =
  find_left_expansions tbl.cover a_h
  |> List.iter (fun (b_h, x_h) ->
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
               enqueue_if_new tbl agenda i' j b_h (FromLeftExpand (i, x_h, a_h));
               (match x_h with
               | HItem x_item when is_partial x_item ->
                   block_left tbl i' i x_item r s
               | _ -> ());
               if is_partial a_h then block_right tbl i j a_h r t)
           done)

let do_right_expand tbl agenda n a_h i j =
  find_right_expansions tbl.cover a_h
  |> List.iter (fun (b_h, y_h) ->
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
               enqueue_if_new tbl agenda i j' b_h (FromRightExpand (j, a_h, y_h));
               if is_partial a_h then block_left tbl i j a_h r s;
               match y_h with
               | HItem y_item when is_partial y_item ->
                   block_right tbl j j' y_item r t
               | _ -> ())
           done)

let do_rev_right tbl agenda a_h i j =
  find_right_expansions_by_right tbl.cover a_h
  |> List.iter (fun (result, left_item) ->
         for i' = 0 to i do
           if mem_item tbl i' i left_item then
             enqueue_if_new tbl agenda i' j result
               (FromRightExpand (i, left_item, HItem a_h))
         done)

let do_rev_left tbl agenda n a_h i j =
  find_left_expansions_by_left tbl.cover a_h
  |> List.iter (fun (result, right_item) ->
         for j' = j to n do
           if mem_item tbl j j' right_item then
             enqueue_if_new tbl agenda i j' result
               (FromLeftExpand (j, HItem a_h, right_item))
         done)

let process_agenda ?(debug = false) (tbl : rec_table)
    (agenda : (h_item * int * int) Queue.t) : unit =
  let n = tbl.n in
  let step = ref 0 in
  while not (Queue.is_empty agenda) do
    let a_h, i, j = Queue.pop agenda in
    incr step;
    if debug then
      Printf.printf "[%d] dequeue %s from T[%d,%d]\n%!" !step
        (show_item a_h) i j;
    do_project tbl agenda a_h i j;
    do_eps_project tbl agenda a_h i j;
    do_left_expand tbl agenda a_h i j;
    do_right_expand tbl agenda n a_h i j;
    do_rev_right tbl agenda a_h i j;
    do_rev_left tbl agenda n a_h i j
  done
