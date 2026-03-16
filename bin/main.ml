open Practice

type grammar_choice =
  | Lisp of string list
  | C
[@@warning "-37"]

let active_grammar = C
  (* Lisp ["RPAREN"; "RPAREN"; "RPAREN"] *)
let display_mode = Output.Strings

let grammar_file = function Lisp _ -> "grammars/lisp.g4" | C -> "grammars/cparser.g4"
let get_tokens   = function Lisp ts -> ts | C -> Io.tokens_from_java ()

let () =
  let grammar = grammar_file active_grammar |> Grammar_reader.extract_grammar
                                            |> Grammar_converter.convert_grammar in
  let tokens  = get_tokens active_grammar in
  Printf.printf "Input: [%s]\n%!" (String.concat "; " tokens);
  let pg = Recognize.prepare grammar in
  let tbl = Recognize.recognize_with pg tokens in
  let tbl = Htable.show ~roots:true ~grammar:false ~cover:true ~table:true ~cells:false ~result:false tbl in
  let roots = Query.infer_parse_roots tbl in
  Output.print_results ~grammar tbl roots display_mode
