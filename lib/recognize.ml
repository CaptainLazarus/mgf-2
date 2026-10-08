open Types
open Hcover
open Table

let frontier_bfs tbl agenda lookup make_deriv ti tj seed_items =
  let frontier = ref (List.map fst seed_items) in
  let visited = Hashtbl.create 16 in
  while !frontier <> [] do
    let next_frontier = ref [] in
    List.iter
      (fun b ->
        if not (Hashtbl.mem visited b) then (
          Hashtbl.replace visited b ();
          List.iter
            (fun pair ->
              let x, deriv = make_deriv b pair in
              if add_item tbl ti tj x deriv then (
                Queue.add (x, ti, tj) agenda;
                next_frontier := x :: !next_frontier))
            (lookup tbl.cover b)))
      !frontier;
    frontier := !next_frontier
  done

let l_reduce_step tbl agenda k =
  frontier_bfs tbl agenda
    find_left_expansions
    (fun right (lhs, left) -> (lhs, FromInductiveFillLeft (left, right)))
    0 (k - 1) tbl.entries.(0).(k - 1).items;
  frontier_bfs tbl agenda
    find_right_expansions_by_right
    (fun right (lhs, left) -> (lhs, FromInductiveFillLeft (HItem left, right)))
    0 (k - 1) tbl.entries.(0).(k - 1).items

let r_reduce_step tbl agenda k n =
  frontier_bfs tbl agenda
    find_right_expansions
    (fun left (lhs, right) -> (lhs, FromInductiveFillRight (left, right)))
    (k + 1) n tbl.entries.(k + 1).(n).items;
  frontier_bfs tbl agenda
    find_left_expansions_by_left
    (fun left (lhs, right) -> (lhs, FromInductiveFillRight (left, HItem right)))
    (k + 1) n tbl.entries.(k + 1).(n).items

let recognize_tbl ?(debug = false) (tbl : rec_table) : rec_table =
  let n = tbl.n in
  let agenda = Queue.create () in

  Seed.epsilons tbl n agenda;
  Seed.terminals tbl n agenda;

  (* Boundary seeding is NOT subsumed by L/R-Reduce. L-Reduce climbs from items
     already in T[0,k]; R-Reduce climbs from items already in T[k,n]. If the
     edge token is not a head terminal, those cells start empty and L/R-Reduce
     have nothing to climb from. Boundary seeding directly seeds T[0,1] and
     T[n-1,n] from the cover's expansion lists regardless of head position,
     providing the bootstrap that L/R-Reduce then propagates inward. *)
  if n > 0 then (
    Seed.left_boundary tbl tbl.input.(0) agenda;
    Seed.right_boundary tbl tbl.input.(n - 1) n agenda);

  Worklist.process_agenda ~debug tbl agenda;

  let pre_reduce_keys = List.map fst tbl.entries.(0).(n).items in

  for k = 1 to n do
    if tbl.entries.(0).(n).items = [] then (
      l_reduce_step tbl agenda k;
      Worklist.process_agenda ~debug tbl agenda)
  done;

  if tbl.entries.(0).(n).items = [] then (
    for k = n - 1 downto 0 do
      r_reduce_step tbl agenda k n;
      Worklist.process_agenda ~debug tbl agenda
    done;
    frontier_bfs tbl agenda
      find_right_expansions
      (fun b (x, y_h) -> (x, FromInductiveFillRight (b, y_h)))
      0 n tbl.entries.(0).(n).items;
    frontier_bfs tbl agenda
      find_left_expansions_by_left
      (fun b (x, right_item) -> (x, FromInductiveFillRight (b, HItem right_item)))
      0 n tbl.entries.(0).(n).items;
    Worklist.process_agenda ~debug tbl agenda);

  let new_items =
    List.filter (fun (item, _) -> not (List.mem item pre_reduce_keys))
      tbl.entries.(0).(n).items
  in
  if new_items <> [] then (
    frontier_bfs tbl agenda
      find_right_expansions_by_right
      (fun b (x, a) -> (x, FromInductiveFillLeft (HItem a, b)))
      0 n new_items;
    frontier_bfs tbl agenda
      find_left_expansions
      (fun b (x, a) -> (x, FromInductiveFillLeft (a, b)))
      0 n new_items;
    Worklist.process_agenda ~debug tbl agenda);

  tbl

let recognize (g : grammar) (input : string list) : rec_table =
  recognize_tbl (create_table g input)

let prepare (g : grammar) : prepared_grammar =
  { pg_grammar = g; pg_cover = compute_h_cover g; pg_min_yield = compute_min_yield g }

let recognize_with ?(debug = false) (pg : prepared_grammar) (input : string list) : rec_table =
  let n = List.length input in
  let entries =
    Array.init (n + 1) (fun _ ->
        Array.init (n + 1) (fun _ ->
            { items = []; blocked_left = []; blocked_right = [] }))
  in
  recognize_tbl ~debug
    {
      n;
      entries;
      input = Array.of_list input;
      grammar = pg.pg_grammar;
      cover = pg.pg_cover;
    }
