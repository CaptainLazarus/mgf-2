open Practice

let () =
  let grammar =
    Grammar_reader.extract_grammar "grammars/lisp.g4"
    |> Grammar_converter.convert_grammar
  in
  let pg = Recognize.prepare grammar in
  let inputs =
    [
      [ "RPAREN"; "RPAREN"; "RPAREN" ];
      [ "LPAREN"; "ATOM"; "DOT"; "ATOM"; "RPAREN"; "RPAREN" ];
    ]
  in
  List.iter
    (fun input ->
      Printf.printf "\n=== Input: %s ===\n" (String.concat " " input);
      let tbl = Recognize.recognize_with pg input in
      Display.print_root_candidates (Query.infer_parse_roots tbl);
      Htable.print_trees ~grammar ~mode:"virtual" tbl grammar.start)
    inputs
