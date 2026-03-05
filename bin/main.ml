open Practice

(* Full flow:
   1. Load a grammar from file and compile it (H-cover computed once)
   2. Run several inputs through the compiled grammar
   3. Collect all possible parse trees for each input (list of lists)
   4. Print results *)

let () =
  (* 1. Load and compile grammar — done once *)
  let grammar =
    Grammar_reader.extract_grammar "grammars/lisp.g4"
    |> Grammar_converter.convert_grammar
  in
  let pg = Htable.prepare grammar in

  (* 2. Inputs to test *)
  let inputs =
    [ 
      (* ["ATOM"]
    ; ["LPAREN"; "ATOM"; "DOT"; "ATOM"; "RPAREN"]
    ; ["LPAREN"; "ATOM"; "RPAREN"]
    ; ["LPAREN"; "RPAREN"] ;
    ["ATOM"; "DOT"; "ATOM" ; "RPAREN" ]
    ; *)
    ["RPAREN" ; "RPAREN" ; "RPAREN" ; "RPAREN" ; "RPAREN" ; "RPAREN"] ;
        ["LPAREN" ; "LPAREN" ; "LPAREN" ; "LPAREN" ; "LPAREN" ; "LPAREN"] 
    ]
  in
  let _ = Htable.print_cover pg.pg_cover in
  (* let _ = Htable.run_and_print pg.pg_grammar ["DOT" ; "LPAREN" ; "ATOM" ; "DOT"; "ATOM" ; "RPAREN" ; "RPAREN" ; "RPAREN"] in
  let _ = Htable.run_and_print pg.pg_grammar ["DOT" ; "LPAREN" ; "ATOM" ; "DOT"; "ATOM" ; "RPAREN" ; "RPAREN"] in
  let _ = Htable.run_and_print pg.pg_grammar ["LPAREN" ; "ATOM" ; "DOT"; "ATOM" ; "RPAREN" ; "RPAREN"] in
  let _ = Htable.run_and_print pg.pg_grammar ["DOT"; "ATOM" ; "RPAREN" ; "RPAREN"  ; "RPAREN" ; "RPAREN" ; "RPAREN" ; "RPAREN"] in *)
  (* let _ = Htable.run_and_print pg.pg_grammar ["LPAREN" ; "LPAREN" ; "LPAREN" ; "LPAREN" ; "LPAREN" ; "LPAREN"]  in *)
  

  let results : (string list * Htable.tree list) list =
    List.map (fun input ->
      let tbl = Htable.recognize_with pg input in
      let trees = Htable.reconstruct_trees_virtual tbl grammar.start in
      (input, trees))
      inputs
  in


  Htable.print_grammar grammar;
  List.iter2 (fun input (_, trees) ->
    let input_str = String.concat " " input in
    Printf.printf "\n========== Input: %-30s %d tree(s) ==========\n"
      input_str (List.length trees);
    List.iteri (fun i tree ->
      Printf.printf "Tree %d:\n" (i + 1);
      Htable.print_tree ~grammar tree)
      trees)
    inputs results
