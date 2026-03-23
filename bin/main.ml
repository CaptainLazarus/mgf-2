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

let gen_tree_file = "grammars/gen_tree.txt"

let print_gen_tree () =
  match (try Some (open_in gen_tree_file) with Sys_error _ -> None) with
  | None -> ()
  | Some ic ->
    Printf.printf "┌─ gen tree ─────────────────────────\n";
    (try while true do
      Printf.printf "│  %s\n" (input_line ic)
    done with End_of_file -> ());
    close_in ic;
    Printf.printf "└────────────────────────────────────\n\n"

let () =
  let grammar = grammar_file active_grammar |> Grammar_reader.extract_grammar
                                            |> Grammar_converter.convert_grammar in
  let tokens  = get_tokens active_grammar in
  Printf.printf "Input: [%s]\n\n%!" (String.concat "; " tokens);
  print_gen_tree ();
  let pg = Recognize.prepare grammar in
  let tbl = Recognize.recognize_with pg tokens in
  Printf.printf "Table items: %d\n%!" (Query.count_table_items tbl);
  let tbl = Htable.show ~roots:true ~grammar:false ~cover:true ~table:true ~cells:false ~result:false tbl in
  let roots = Query.infer_parse_roots tbl in
  Output.print_results ~grammar tbl roots display_mode
