open Types
open Hcover
open Table

let show_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "P(%d,%d,%d)" r s t
  | CompleteItem nt -> nt

let show_hot = function
  | HItem i -> show_item i
  | HTerm t -> Printf.sprintf "'%s'" t

let trace_add _tag i j item =
  Printf.printf "    + %-12s -> T[%d,%d]\n%!" (show_item item) i j

let process_agenda ?(debug = false) (tbl : rec_table)
    (agenda : (h_item * int * int) Queue.t) : unit =
  let n = tbl.n in
  let step = ref 0 in
  while not (Queue.is_empty agenda) do
    let a_h, i, j = Queue.pop agenda in
    incr step;
    if debug then
      Printf.printf "[%d] dequeue %-12s from T[%d,%d]\n%!" !step (show_item a_h) i j;

    let projected = find_projections_from_item tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromProject a_h in
        if add_item tbl i j b_h deriv then (
          if debug then trace_add "project" i j b_h;
          Queue.add (b_h, i, j) agenda))
      projected;

    let eps_projected = find_epsilon_projections tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromEpsilon a_h in
        if add_item tbl i j b_h deriv then (
          if debug then trace_add "eps-project" i j b_h;
          Queue.add (b_h, i, j) agenda))
      eps_projected;

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
              if add_item tbl i' j b_h deriv then (
                if debug then
                  Printf.printf "    + %-12s -> T[%d,%d]  (left-expand: %s + %s)\n%!"
                    (show_item b_h) i' j (show_hot x_h) (show_item a_h);
                Queue.add (b_h, i', j) agenda);
              (match x_h with
              | HItem x_item when is_partial x_item ->
                  block_left tbl i' i x_item r s
              | _ -> ());
              if is_partial a_h then block_right tbl i j a_h r t)
          done)
      left_exps;

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
              if add_item tbl i j' b_h deriv then (
                if debug then
                  Printf.printf "    + %-12s -> T[%d,%d]  (right-expand: %s + %s)\n%!"
                    (show_item b_h) i j' (show_item a_h) (show_hot y_h);
                Queue.add (b_h, i, j') agenda);
              if is_partial a_h then block_left tbl i j a_h r s;
              match y_h with
              | HItem y_item when is_partial y_item ->
                  block_right tbl j j' y_item r t
              | _ -> ())
          done)
      right_exps;

    let rev_right = find_right_expansions_by_right tbl.cover a_h in
    List.iter
      (fun (result, left_item) ->
        for i' = 0 to i do
          if mem_item tbl i' i left_item then
            let deriv = FromRightExpand (i, left_item, HItem a_h) in
            if add_item tbl i' j result deriv then (
              if debug then
                Printf.printf "    + %-12s -> T[%d,%d]  (rev-right: %s + %s)\n%!"
                  (show_item result) i' j (show_item left_item) (show_item a_h);
              Queue.add (result, i', j) agenda)
        done)
      rev_right;

    let rev_left = find_left_expansions_by_left tbl.cover a_h in
    List.iter
      (fun (result, right_item) ->
        for j' = j to n do
          if mem_item tbl j j' right_item then
            let deriv = FromLeftExpand (j, HItem a_h, right_item) in
            if add_item tbl i j' result deriv then (
              if debug then
                Printf.printf "    + %-12s -> T[%d,%d]  (rev-left: %s + %s)\n%!"
                  (show_item result) i j' (show_item a_h) (show_item right_item);
              Queue.add (result, i, j') agenda)
        done)
      rev_left
  done
