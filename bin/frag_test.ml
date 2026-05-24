open Practice

type lang = Lisp | C

let lang      = ref C
let slices    : (int * int) list ref = ref []
let pending_i : int option ref = ref None

let add_slice s =
  match !pending_i with
  | None   -> pending_i := Some (int_of_string s)
  | Some i -> slices := (i, int_of_string s) :: !slices; pending_i := None

let () =
  Arg.parse
    [ ("--c",     Arg.Unit (fun () -> lang := C),    "Use C grammar + stdin.c tokens")
    ; ("--lisp",  Arg.Unit (fun () -> lang := Lisp), "Use Lisp grammar")
    ; ("--slice", Arg.String add_slice,
                  "Extract slice I J from token list (repeat for multiple)")
    ]
    (fun _ -> ())
    "Usage: frag_test [--c | --lisp] [--slice I J] ..."

(* ------------------------------------------------------------------ *)

let sep = String.make 72 '='

type frag_stats = {
  code     : string;
  tokens   : string list;
  roots    : Types.root_candidate list;
  tbl      : Types.rec_table;
  items    : int;
} [@@warning "-69"]

let compute_stats grammar pg tok_lex_arr (i, j) =
  let slice  = Array.to_list (Array.sub tok_lex_arr i (j - i)) in
  let tokens = List.map fst slice in
  let code   = String.concat " " (List.map snd slice) in
  let tbl    = Recognize.recognize_with pg tokens in
  let roots  = Query.infer_parse_roots tbl in
  let items = Query.count_table_items tbl in
  ignore grammar;
  { code; tokens; roots; tbl; items }

let print_stats_table results =
  Printf.printf "\n%-45s  %4s  %6s  %5s\n" "Fragment" "Toks" "Roots" "Items";
  Printf.printf "%s\n" (String.make 65 '-');
  List.iter (fun r ->
    let display =
      if String.length r.code > 44
      then String.sub r.code 0 41 ^ "..."
      else r.code
    in
    Printf.printf "%-45s  %4d  %6d  %5d\n"
      display (List.length r.tokens) (List.length r.roots) r.items)
    results

let print_detail r =
  Printf.printf "\n%s\n" sep;
  Printf.printf "  code  : %s\n" r.code;
  Printf.printf "  tokens: [%s]\n%!" (String.concat " " r.tokens);
  Printf.printf "%s\n\n" sep;
  Display.print_root_candidates r.roots;
  let seen = Hashtbl.create 8 in
  let _distinct_roots =
    List.filter (fun (rc : Types.root_candidate) ->
      if Hashtbl.mem seen rc.root then false
      else (Hashtbl.replace seen rc.root (); true))
      r.roots
    |> fun rs -> List.filteri (fun i _ -> i < 5) rs
  in
  ()
  (* if distinct_roots <> [] then begin
    Printf.printf "\nTrees (first %d distinct root%s):\n"
      (List.length distinct_roots)
      (if List.length distinct_roots = 1 then "" else "s");
    Output.print_results r.tbl distinct_roots Output.Trees
  end *)

(* ------------------------------------------------------------------ *)

let () =
  match !lang with
  | Lisp ->
      let grammar =
        Grammar_reader.extract_grammar "grammars/lisp.g4"
        |> Grammar_converter.convert_grammar
      in
      let pg = Recognize.prepare grammar in
      let inputs =
        [ [ "RPAREN"; "RPAREN"; "RPAREN" ]
        ; [ "LPAREN"; "ATOM"; "DOT"; "ATOM"; "RPAREN"; "RPAREN" ]
        ]
      in
      List.iter
        (fun input ->
          Printf.printf "\n%s\n  [%s]\n%s\n\n" sep
            (String.concat " " input) sep;
          let tbl = Recognize.recognize_with pg input in
          Display.print_root_candidates (Query.infer_parse_roots tbl))
        inputs

  | C ->
      let grammar =
        Grammar_reader.extract_grammar "grammars/cparser.g4"
        |> Grammar_converter.convert_grammar
      in
      let pg      = Recognize.prepare grammar in
      let tok_lex = Io.tokens_and_lexemes_from_java () in
      let n       = List.length tok_lex in
      let arr     = Array.of_list tok_lex in
      Printf.printf "Tokens (%d): [%s]\n%!" n
        (String.concat " " (List.map fst tok_lex));
      let spans =
        match List.rev !slices with
        | [] ->
            Random.self_init ();
            List.init 10 (fun _ ->
              let len = 1 + Random.int n in
              let i   = if n <= len then 0 else Random.int (n - len) in
              (i, i + len))
        | ss -> List.map (fun (i, j) -> (max 0 i, min n j)) ss
      in
      let results = List.map (compute_stats grammar pg arr) spans in
      print_stats_table results;
      List.iter print_detail results
