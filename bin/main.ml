open Practice

type grammar_choice =
  | Lisp of string list
  | C
[@@warning "-37"]

let active_grammar = C
  (* Lisp ["RPAREN"; "RPAREN"; "RPAREN"] *)
let display_mode   = Output.Tokens

let grammar_file = function Lisp _ -> "grammars/lisp.g4" | C -> "grammars/cparser.g4"
let get_tokens   = function Lisp ts -> ts | C -> Io.tokens_from_java ()

let () =
  Printf.printf "[1] reading grammar...\n%!";
  let grammar = grammar_file active_grammar |> Grammar_reader.extract_grammar
                                            |> Grammar_converter.convert_grammar in
  Printf.printf "[2] grammar done (%d productions)\n%!" (List.length grammar.productions);
  Printf.printf "[3] fetching tokens...\n%!";
  let tokens  = get_tokens active_grammar in
  Printf.printf "[4] tokens done\n%!";
  Printf.printf "Input: [%s]\n%!" (String.concat "; " tokens);
  Printf.printf "[5] computing cover...\n%!";
  let pg = Recognize.prepare grammar in
  Printf.printf "[6] cover done\n%!";
  Printf.printf "[7] running recognition...\n%!";
  let tbl = Recognize.recognize_with pg tokens in
  Printf.printf "[8] recognition done\n%!";
  Printf.printf "[9] showing summary...\n%!";
  let tbl = Htable.show ~roots:true ~grammar:false ~cover:true ~table:true tbl in
  Printf.printf "[10] inferring roots...\n%!";
  let roots = Query.infer_parse_roots tbl in
  Printf.printf "[11] printing results...\n%!";
  Output.print_results ~grammar tbl roots display_mode;
  Printf.printf "[12] done\n%!"
