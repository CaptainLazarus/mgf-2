open Practice

type grammar_choice =
  | Lisp of string list
  | C
[@@warning "-37"]

let active_grammar = Lisp ["RPAREN"; "RPAREN"; "RPAREN"]
let display_mode   = Output.Trees

let grammar_file = function Lisp _ -> "grammars/lisp.g4" | C -> "grammars/c_simple.g4"
let get_tokens   = function Lisp ts -> ts | C -> Io.tokens_from_java ()

let () =
  let grammar = grammar_file active_grammar |> Grammar_reader.extract_grammar
                                            |> Grammar_converter.convert_grammar in
  let tokens  = get_tokens active_grammar in
  Printf.printf "Input: [%s]\n%!" (String.concat "; " tokens);
  grammar
  |> Recognize.prepare
  |> fun pg -> Recognize.recognize_with pg tokens
  |> fun tbl ->
       Print.print_visual_table tbl;
       Output.print_results ~grammar tbl (Query.infer_parse_roots tbl) display_mode
