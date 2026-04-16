open Practice

type grammar_source =
  | File of string * string list  (* path, tokens *)
  | Inline of Types.grammar * string list  (* grammar, tokens *)
[@@warning "-37"]

let active_grammar =
  (* Inline (Grammars.grammar_astar, [ "a"; "a"; "a" ]) *)
  (* Inline (Grammars.grammar_gcl,   [ "det"; "n"; "cl"; "v"; "det"; "n" ]) *)
  (* Inline (Grammars.grammar_epsilon, [ "b" ]) *)
  (* Inline (Grammars.grammar_arith,   [ "n"; "+"; "n" ]) *)
  (* File ("grammars/simple.g4",  ["V" ; "DET" ; "N"]) *)
  (* File ("grammars/lisp.g4",    ["RPAREN"; "RPAREN"; "RPAREN"]) *)
  File ("grammars/cparser.g4", Io.tokens_from_java ())

type run_mode = Parse of Output.display_mode | DumpCover
[@@warning "-37"]

let mode = Parse Output.Strings
(* let mode = DumpCover *)

(* ------------------------------------------------------------------ *)

let show_item = function
  | Types.PartialItem (r, s, t) -> Printf.sprintf "P(%d,%d,%d)" r s t
  | Types.CompleteItem nt -> nt

let show_hot = function
  | Types.HItem i -> show_item i
  | Types.HTerm t -> Printf.sprintf "'%s'" t

let dump_cover (cover : Types.h_cover) =
  Printf.printf "=== projections (result <- source) ===\n";
  List.iter
    (fun (item, src) ->
      Printf.printf "  %-20s <-  %s\n" (show_item item) (show_hot src))
    cover.projections;
  Printf.printf "\n=== right_expansions (result <- left_head + right_sibling) ===\n";
  List.iter
    (fun (result, left_item, y_h) ->
      Printf.printf "  %-20s <-  %-20s + %s\n" (show_item result)
        (show_item left_item) (show_hot y_h))
    cover.right_expansions;
  Printf.printf "\n=== left_expansions (result <- left_sibling + right_head) ===\n";
  List.iter
    (fun (result, x_h, right_item) ->
      Printf.printf "  %-20s <-  %-20s + %s\n" (show_item result)
        (show_hot x_h) (show_item right_item))
    cover.left_expansions

(* ------------------------------------------------------------------ *)

let gen_tree_file = "grammars/gen_tree.txt"

let print_gen_tree () =
  match try Some (open_in gen_tree_file) with Sys_error _ -> None with
  | None -> ()
  | Some ic ->
      Printf.printf "┌─ gen tree ─────────────────────────\n";
      (try
         while true do
           Printf.printf "│  %s\n" (input_line ic)
         done
       with End_of_file -> ());
      close_in ic;
      Printf.printf "└────────────────────────────────────\n\n"

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
      dump_cover pg.pg_cover
  | Parse display_mode ->
      print_gen_tree ();
      let pg = Recognize.prepare grammar in
      let tbl = Recognize.recognize_with pg tokens in
      Printf.printf "Table items: %d\n%!" (Query.count_table_items tbl);
      let tbl =
        Htable.show ~roots:true ~grammar:false ~cover:true ~table:true
          ~cells:false ~result:false tbl
      in
      let roots = Query.infer_parse_roots tbl in
      Output.print_results ~grammar tbl roots display_mode
