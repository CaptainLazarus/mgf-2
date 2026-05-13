open Practice

let n_frags = ref 10
let min_len = ref 1
let max_len = ref 8
let seeded  = ref false

let () =
  Arg.parse
    [ ("--seed", Arg.Int (fun s -> Random.init s; seeded := true),
                                               "Random seed (default: self_init)")
    ; ("--n",    Arg.Set_int n_frags,          "Number of fragments (default 10)")
    ; ("--min",  Arg.Set_int min_len,          "Min fragment length (default 1)")
    ; ("--max",  Arg.Set_int max_len,          "Max fragment length (default 8)")
    ]
    (fun _ -> ())
    "Usage: rand_split [--seed N] [--n N] [--min N] [--max N]";
  if not !seeded then Random.self_init ()

let () =
  let grammar =
    Grammar_reader.extract_grammar "grammars/cparser.g4"
    |> Grammar_converter.convert_grammar
  in
  let pg = Recognize.prepare grammar in
  let tokens = Array.of_list (Io.tokens_from_java ()) in
  let n = Array.length tokens in
  if n = 0 then (print_endline "No tokens — check grammars/stdin.c"; exit 1);
  Printf.printf "Full token list (%d): [%s]\n\n%!" n
    (String.concat " " (Array.to_list tokens));
  for _ = 1 to !n_frags do
    let len = !min_len + Random.int (!max_len - !min_len + 1) in
    let len = min len n in
    let i = if n <= len then 0 else Random.int (n - len) in
    let fragment = Array.to_list (Array.sub tokens i len) in
    let tbl = Recognize.recognize_with pg fragment in
    let roots = Query.infer_parse_roots tbl in
    let unique_roots =
      List.sort_uniq (fun a b -> String.compare a.Types.root b.Types.root) roots
    in
    Printf.printf "[%s]\n" (String.concat " " fragment);
    if unique_roots = [] then
      Printf.printf "  (no parse)\n"
    else
      List.iter
        (fun (rc : Types.root_candidate) ->
          let status =
            if rc.missing_left = [] && rc.missing_right = [] then "complete"
            else "partial"
          in
          Printf.printf "  -> %s (%s)\n" rc.root status)
        unique_roots;
    print_newline ()
  done
