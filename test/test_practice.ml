open Practice

let () =
  let g4_string = "
    grammar test;
    s : np vp EOF ;
    np : N ;
    np : np pp ;
    vp : V np ;
    pp : P np ;
  " in
  let domain_grammar = Grammar_reader.extract_grammar_from_string g4_string in
  let converted = Grammar_converter.convert_grammar domain_grammar in
  Htable.print_grammar converted;
  let tbl = Htable.recognize converted ["N"; "V"; "N"; "P"; "N"] in
  let accepted = Htable.is_accepted tbl in
  Printf.printf "Accepted: %b\n" accepted;
  assert accepted;

  (* Should reject bad input *)
  let tbl2 = Htable.recognize converted ["V"; "N"] in
  let accepted2 = Htable.is_accepted tbl2 in
  Printf.printf "Rejected bad input: %b\n" (not accepted2);
  assert (not accepted2);

  Printf.printf "All grammar reader tests passed!\n"
