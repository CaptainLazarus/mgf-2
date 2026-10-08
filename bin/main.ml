open Practice

type grammar_source =
  | File of string * string list
  | Inline of Types.grammar * string list
[@@warning "-37"]

let active_grammar =
  (* Inline (Grammars.grammar_astar, [ "a"; "a"; "a" ]) *)
  (* Inline (Grammars.grammar_gcl,   ["v" ; "det"]) *)
  (* File ("grammars/rk_example.g4", ["RPAREN"; "PLUS"; "INT"; "THEN"; "IF"]) *)
  (* Inline (Grammars.grammar_epsilon, [ "b" ]) *)
  (* Inline (Grammars.grammar_arith,   [ "n"; "+"; "n" ]) *)
  (* File ("grammars/simple.g4",  ["V" ; "DET"]) *)
  (* File ("grammars/lisp.g4", ["RPAREN" ; "RPAREN"]) *)
  (* File ("grammars/cparser.g4", Io.tokens_from_java ()) *)
  (* File ("grammars/ambig.g4", ["NUM"; "TIMES"; "NUM"; "PLUS"]) *)

type run_mode = Parse of Output.display_mode | DumpCover
[@@warning "-37"]

(* let mode = Parse Output.Trees *)
let mode = Parse Output.Trees

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
      Display.print_grammar grammar;
      Display.dump_cover grammar pg.pg_cover
  | Parse display_mode ->
      (* Io.print_gen_tree (); *)
      let pg = Recognize.prepare grammar in
      let tbl = Recognize.recognize_with pg tokens in
      Printf.printf "Table items: %d\n%!" (Query.count_table_items tbl);
      (* DEBUG: dump derivations of CompleteItem "e" at [0,n] *)
      let dbg_item = Types.CompleteItem "e" in
      let derivs = Table.get_derivations tbl 0 tbl.n dbg_item in
      Printf.printf "DEBUG e@[0,%d] has %d derivations:\n" tbl.n (List.length derivs);
      List.iter
        (fun d ->
          let s = match d with
            | Types.FromTerminal t -> "FromTerminal " ^ t
            | Types.FromProject _ -> "FromProject"
            | Types.FromLeftExpand (k,_,_) -> Printf.sprintf "FromLeftExpand k=%d" k
            | Types.FromRightExpand (k,_,_) -> Printf.sprintf "FromRightExpand k=%d" k
            | Types.FromEpsilon _ -> "FromEpsilon"
            | Types.FromBoundaryRight _ -> "FromBoundaryRight"
            | Types.FromBoundaryLeft _ -> "FromBoundaryLeft"
            | Types.FromInductiveFillLeft _ -> "FromInductiveFillLeft"
            | Types.FromInductiveFillRight _ -> "FromInductiveFillRight"
          in Printf.printf "  - %s\n" s)
        derivs;
      let trees_omit = Reconstruct.reconstruct_trees_omit tbl "e" in
      let trees_virt = Reconstruct.reconstruct_trees_virtual tbl "e" in
      Printf.printf "DEBUG reconstruct omit=%d virtual=%d\n%!"
        (List.length trees_omit) (List.length trees_virt);
      let tbl =
        Htable.show ~roots:true ~grammar:false ~cover:true ~table:true
          ~cells:false ~result:false tbl
      in
      let roots = Query.infer_parse_roots tbl in
      Output.print_results ~grammar ~min_yield:pg.pg_min_yield tbl roots display_mode
