open Practice
open Yojson.Basic.Util

let run_java_and_read_tokens () =
  let ic =
    Unix.open_process_in
      "java -cp \"./grammars:./grammars/antlr-4.13.1-complete.jar\" Main"
  in
  let rec read_all acc =
    try
      let line = input_line ic in
      let json = Yojson.Basic.from_string line in
      read_all (json :: acc)
    with End_of_file -> List.rev acc
  in
  let output = read_all [] in
  ignore (Unix.close_process_in ic);
  output

let token_of_json j = j |> member "token" |> to_string

let pretty_token = function
  | "LPAREN" -> "(" | "RPAREN" -> ")"
  | "DOT"    -> "." | "ATOM"   -> "ATOM"
  | s -> s

let rec collect_tokens tree =
  match tree with
  | Types.Leaf s -> [pretty_token s]
  | Types.Virtual (Types.HTerm t) -> [pretty_token t]
  | Types.Virtual (Types.HItem (Types.CompleteItem nt)) -> [nt]
  | Types.Virtual (Types.HItem (Types.PartialItem _)) -> []
  | Types.Node (_, []) -> []
  | Types.Node (_, children) -> List.concat_map collect_tokens children

let linearize_tree tree =
  String.concat " " (collect_tokens tree)

type display_mode = Tokens | Trees [@@warning "-37"]

let display_mode = Trees

type grammar_choice =
  | Lisp  of string list   (* tokens supplied directly *)
  | C                      (* tokens from Java/CLexer pipeline *)
[@@warning "-37"]

let active_grammar = Lisp ["RPAREN" ; "RPAREN" ; "RPAREN"]

let grammar_file = function
  | Lisp _ -> "grammars/lisp.g4"
  | C       -> "grammars/c_simple.g4"

let get_tokens = function
  | Lisp tokens -> tokens
  | C           -> run_java_and_read_tokens () |> List.map token_of_json

let print_results grammar tbl roots mode =
  List.iter (fun (rc : Types.root_candidate) ->
    let trees = Htable.reconstruct_trees_virtual tbl rc.root in
    if trees <> [] then begin
      match mode with
      | Tokens ->
        let lines = List.sort_uniq String.compare (List.map linearize_tree trees) in
        Printf.printf "  %s (%d unique):\n" rc.root (List.length lines);
        List.iter (fun line -> Printf.printf "    %s\n" line) lines
      | Trees ->
        Printf.printf "  %s (%d):\n" rc.root (List.length trees);
        List.iteri (fun i tree ->
          Printf.printf "  Tree %d:\n" (i + 1);
          Print.print_tree ~grammar tree)
          trees
    end)
    roots

let () =
  let grammar =
    Grammar_reader.extract_grammar (grammar_file active_grammar)
    |> Grammar_converter.convert_grammar
  in
  let pg = Recognize.prepare grammar in
  let tokens = get_tokens active_grammar in
  Printf.printf "Input: [%s]\n%!" (String.concat "; " tokens);
  let tbl = Recognize.recognize_with pg tokens in
  Print.print_visual_table tbl;
  let roots = Htable.infer_parse_roots tbl in
  print_results grammar tbl roots display_mode
