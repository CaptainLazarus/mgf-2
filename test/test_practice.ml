open Practice

let () =
  let domain_grammar = Grammar_reader.extract_grammar "../grammars/lisp.g4" in
  let converted = Grammar_converter.convert_grammar domain_grammar in
  Display.print_grammar converted;
  let run input =
    let tbl = Htable.run_and_print converted input in
    Display.print_root_candidates (Query.infer_parse_roots tbl);
    Htable.print_trees tbl "lisp_"
  in
  (* atom *)
  run [ "ATOM" ];
  (* dotted pair: (a . b) *)
  run [ "LPAREN"; "ATOM"; "DOT"; "ATOM"; "RPAREN" ];
  (* list with one element: (a) *)
  run [ "LPAREN"; "ATOM"; "RPAREN" ];
  (* empty list: () *)
  run [ "LPAREN"; "RPAREN" ];
  (* invalid: incomplete dotted pair *)
  run [ "LPAREN"; "ATOM"; "DOT" ]
