type grammar = {
  nonterminals : string list;
  terminals : char list;
  rules : (string * string list) list;
      (* A -> [B; C] or A -> [] with terminal *)
  terminal_rules : (string * char) list; (* A -> 'a' *)
  start : string;
}

let ( >>= ) xs f = List.concat_map f xs

let print_table dp n =
  Printf.printf "CYK Table (dp.(i).(len)):\n";
  Printf.printf "%4s |" "i\\l";
  for len = 1 to n do
    Printf.printf " %10d" len
  done;
  print_newline ();
  Printf.printf "-----+";
  for _ = 1 to n do
    Printf.printf "-----------"
  done;
  print_newline ();
  for i = 0 to n - 1 do
    Printf.printf "%4d |" i;
    for len = 1 to n - i do
      let cell = dp.(i).(len) in
      let s = if cell = [] then "-" else String.concat "," cell in
      Printf.printf " %10s" s
    done;
    print_newline ()
  done

let cyk grammar input =
  let n = String.length input in

  (* dp.(i).(len) = set of nonterminals that can derive substring from i with length len *)
  (* We'll use lists as sets for simplicity *)
  let dp = Array.init (n + 1) (fun _ -> Array.make (n + 1) []) in

  for i = 0 to n - 1 do
    let xi = input.[i] in
    let initial_nts =
      List.filter_map
        (fun (lhs, rhs) -> if xi = rhs then Some lhs else None)
        grammar.terminal_rules
    in
    dp.(i).(1) <- initial_nts
  done;

  for len = 2 to n do
    for i = 0 to n - len do
      for k = 1 to len - 1 do
        let left = dp.(i).(k) in
        let right = dp.(i + k).(len - k) in
        let new_nts =
          left >>= fun l ->
          right >>= fun r ->
          grammar.rules
          |> List.filter_map (fun (a, rhs) -> if rhs = [ l; r ] then Some a else None)
        in
        dp.(i).(len) <- List.sort_uniq compare (dp.(i).(len) @ new_nts)
      done
    done
  done;
  print_table dp n;
  List.mem grammar.start dp.(0).(n)

let example_grammar =
  {
    nonterminals = [ "S"; "A"; "B" ];
    terminals = [ 'a'; 'b' ];
    rules = [ ("S", [ "A"; "B" ]); ("A", [ "B"; "A" ]) ];
    terminal_rules = [ ("A", 'a'); ("B", 'b') ];
    start = "S";
  }

(* Test *)
let cyk =
  assert (cyk example_grammar "ab" = true);
  assert (cyk example_grammar "ba" = false);
  assert (cyk example_grammar "aaa" = false);
  print_endline "Tests ready!"
