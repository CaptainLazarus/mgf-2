(* Scratch probe for the T1 / Mezei investigation (2026-08-25).
   Usage: dune exec rect_probe -- grammars/ancn.g4 B
   Prints root candidates, table size, and up to N virtual trees. *)
open Practice

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  match args with
  | [] -> prerr_endline "usage: rect_probe <grammar.g4> <TOK> [TOK...]"
  | path :: tokens ->
      let grammar =
        path |> Grammar_reader.extract_grammar |> Grammar_converter.convert_grammar
      in
      Printf.printf "Grammar: %s\nInput: [%s]\n\n%!" path (String.concat "; " tokens);
      let pg = Recognize.prepare grammar in
      let tbl = Recognize.recognize_with pg tokens in
      let roots = Query.infer_parse_roots tbl in
      Printf.printf "table items: %d\nroots: %d\n%!"
        (Query.count_table_items tbl) (List.length roots);
      List.iter
        (fun (rc : Types.root_candidate) ->
          Printf.printf "\n--- root %s ---\n%!" rc.root;
          let trees = Reconstruct.reconstruct_trees_virtual_from ~limit:12 tbl rc.item in
          Printf.printf "trees returned (limit 12): %d\n%!" (List.length trees);
          List.iteri
            (fun i t ->
              Printf.printf "  [%d] gaps=%d  %s\n%!" i
                (Output.count_virtuals t)
                (Output.linearize ~grammar ~virtuals:true t))
            trees)
        roots
