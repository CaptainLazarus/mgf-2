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
    find_right_expansions_by_right
    (fun b (x, a) -> (x, FromInductiveFill (a, b)))
    0 (k - 1) tbl.entries.(0).(k - 1).items

let r_reduce_step tbl agenda k n =
  frontier_bfs tbl agenda
    find_right_expansions
    (fun b (x, y_h) -> (x, FromInductiveFillRight (b, y_h)))
    (k + 1) n tbl.entries.(k + 1).(n).items

let recognize_tbl ?(debug = false) (tbl : rec_table) : rec_table =
  let n = tbl.n in
  let agenda = Queue.create () in

  Seed.epsilons tbl n agenda;
  Seed.terminals tbl n agenda;

  if n > 0 then (
    Seed.left_boundary tbl tbl.input.(0) agenda;
    Seed.right_boundary tbl tbl.input.(n - 1) n agenda);

  Worklist.process_agenda ~debug tbl agenda;

  for k = 1 to n do
    l_reduce_step tbl agenda k;
    Worklist.process_agenda ~debug tbl agenda
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
    Worklist.process_agenda ~debug tbl agenda);

  frontier_bfs tbl agenda
    find_right_expansions_by_right
    (fun b (x, a) -> (x, FromInductiveFill (a, b)))
    0 n tbl.entries.(0).(n).items;
  Worklist.process_agenda ~debug tbl agenda;

  tbl

let recognize (g : grammar) (input : string list) : rec_table =
  recognize_tbl (create_table g input)

let prepare (g : grammar) : prepared_grammar =
  { pg_grammar = g; pg_cover = compute_h_cover g }

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
