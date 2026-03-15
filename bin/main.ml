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

let display_mode = Output.Trees

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
  let roots = Query.infer_parse_roots tbl in
  Output.print_results ~grammar tbl roots display_mode
