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

let () =
  let grammar =
    Grammar_reader.extract_grammar "grammars/c_simple.g4"
    |> Grammar_converter.convert_grammar
  in
  let pg = Htable.prepare grammar in
  let tokens = run_java_and_read_tokens () |> List.map token_of_json in
  Printf.printf "Tokens: [%s]\n%!" (String.concat "; " tokens);

  let tbl_full    = Htable.recognize_with          pg tokens in
  let tbl_bounded = Htable.recognize_bounded_with  pg tokens in

  Printf.printf "\n%-6s  %s\n" "Cell" "full | bounded";
  Printf.printf "%s\n" (String.make 60 '-');
  let n = List.length tokens in
  for i = 0 to n do
    for j = i to n do
      let full    = List.length (Htable.get_all_items tbl_full    i j) in
      let bounded = List.length (Htable.get_all_items tbl_bounded i j) in
      if full > 0 || bounded > 0 then
        Printf.printf "T[%d,%d]  %d | %d\n" i j full bounded
    done
  done;

  Printf.printf "\n--- Full table ---\n";
  Htable.print_visual_table tbl_full;
  let roots = Htable.infer_parse_roots tbl_full in
  List.iter (fun (rc : Htable.root_candidate) ->
    let trees = Htable.reconstruct_trees_omit tbl_full rc.root in
    if trees <> [] then begin
      Printf.printf "\n=== %s (%d tree(s)) ===\n" rc.root (List.length trees);
      List.iteri (fun i tree ->
        Printf.printf "Tree %d:\n" (i + 1);
        Htable.print_tree ~grammar tree)
        trees
    end)
    roots
