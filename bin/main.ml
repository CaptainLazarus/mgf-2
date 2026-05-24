open Practice

type grammar_source =
  | File of string * string list
  | Inline of Types.grammar * string list
[@@warning "-37"]

let active_grammar =
  (* Inline (Grammars.grammar_astar, [ "a"; "a"; "a" ]) *)
  (* Inline (Grammars.grammar_gcl,   ["v" ; "det"]) *)
  (* Inline (Grammars.grammar_epsilon, [ "b" ]) *)
  (* Inline (Grammars.grammar_arith,   [ "n"; "+"; "n" ]) *)
  (* File ("grammars/simple.g4",  ["V" ; "DET"]) *)
  File ("grammars/lisp.g4", ["RPAREN" ; "RPAREN"])
  (* File ("grammars/cparser.g4", Io.tokens_from_java ()) *)

type run_mode = Parse of Output.display_mode | DumpCover
[@@warning "-37"]

let mode = Parse Output.Trees
(* let mode = DumpCover *)

(* ------------------------------------------------------------------ *)

let () =
  let grammar, tokens =
    match active_grammar with
    | File (path, ts) ->
        ( path |> Grammar_reader.extract_grammar
          |> Grammar_converter.convert_grammar,
          ts )
    | Inline (g, ts) -> (g, ts)
  in
  Printf.printf "Input: [%s]\n\n%!" (String.concat "; " tokens);
  match mode with
  | DumpCover ->
      let pg = Recognize.prepare grammar in
      Display.dump_cover grammar pg.pg_cover
  | Parse display_mode ->
      (* Io.print_gen_tree (); *)
      let pg = Recognize.prepare grammar in
      let tbl = Recognize.recognize_with pg tokens in
      Printf.printf "Table items: %d\n%!" (Query.count_table_items tbl);
      let tbl =
        Htable.show ~roots:true ~grammar:false ~cover:true ~table:true
          ~cells:false ~result:false tbl
      in
      let roots = Query.infer_parse_roots tbl in
      Output.print_results ~grammar tbl roots display_mode
