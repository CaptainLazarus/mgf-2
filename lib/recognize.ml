open Types
open Hcover
open Table

let process_agenda (tbl : rec_table) (agenda : (h_item * int * int) Queue.t) : unit =
  let n = tbl.n in
  while not (Queue.is_empty agenda) do
    let a_h, i, j = Queue.pop agenda in

    let projected = find_projections_from_item tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromProject a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
      projected;

    let eps_projected = find_epsilon_projections tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromEpsilon a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
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
              if add_item tbl i' j b_h deriv then Queue.add (b_h, i', j) agenda;
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
              if add_item tbl i j' b_h deriv then Queue.add (b_h, i, j') agenda;
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
          if mem_item tbl i' i left_item then (
            let deriv = FromRightExpand (i, left_item, HItem a_h) in
            if add_item tbl i' j result deriv then
              Queue.add (result, i', j) agenda)
        done)
      rev_right;

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

let recognize_tbl (tbl : rec_table) : rec_table =
  let n = tbl.n in
  let agenda = Queue.create () in

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

  if n > 0 then begin
    let first_term = tbl.input.(0) in
    let last_term = tbl.input.(n - 1) in
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
    List.iter
      (fun (result, x_h, right_item) ->
        if mem_item tbl 0 1 right_item then (
          let deriv = FromBoundaryRight (x_h, HItem right_item) in
          if add_item tbl 0 1 result deriv then
            Queue.add (result, 0, 1) agenda))
      tbl.cover.left_expansions;

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

    List.iter
      (fun (result, left_item, y_h) ->
        if mem_item tbl (n - 1) n left_item then (
          let deriv = FromBoundaryLeft (HItem left_item, y_h) in
          if add_item tbl (n - 1) n result deriv then
            Queue.add (result, n - 1, n) agenda))
      tbl.cover.right_expansions
  end;

  process_agenda tbl agenda;

  for k = 1 to n do
    begin
      let frontier = ref (List.map fst tbl.entries.(0).(k - 1).items) in
      let visited = Hashtbl.create 16 in
      while !frontier <> [] do
        let next_frontier = ref [] in
        List.iter (fun b ->
          if not (Hashtbl.mem visited b) then begin
            Hashtbl.replace visited b ();
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

    let projected = find_projections_from_item tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromProject a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
      projected;

    let eps_projected = find_epsilon_projections tbl.cover a_h in
    List.iter
      (fun b_h ->
        let deriv = FromEpsilon a_h in
        if add_item tbl i j b_h deriv then Queue.add (b_h, i, j) agenda)
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
              if add_item tbl i' j b_h deriv then Queue.add (b_h, i', j) agenda;
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
              if add_item tbl i j' b_h deriv then Queue.add (b_h, i, j') agenda;
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
          if mem_item tbl i' i left_item then (
            let deriv = FromRightExpand (i, left_item, HItem a_h) in
            if add_item tbl i' j result deriv then
              Queue.add (result, i', j) agenda)
        done)
      rev_right;

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
