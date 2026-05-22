open Practice

let print_scan_table steps =
  let col_width = 20 in
  let sep () =
    print_string "+";
    List.iter (fun _ -> print_string (String.make col_width '-'); print_string "+") steps;
    print_newline ()
  in
  let pad s = let l = String.length s in
    if l >= col_width then String.sub s 0 col_width
    else s ^ String.make (col_width - l) ' '
  in
  (* header: token names *)
  sep ();
  print_string "|";
  List.iter (fun (tok, _) -> print_string (pad (" " ^ tok)); print_string "|") steps;
  print_newline ();
  sep ();
  (* items per step *)
  let max_items = List.fold_left (fun m (_, s) -> max m (List.length s)) 0 steps in
  let cols = List.map (fun (_, s) ->
    List.map (fun (item, _) -> Display.render_item_short item) s
  ) steps in
  for i = 0 to max_items - 1 do
    print_string "|";
    List.iter (fun col ->
      let s = if i < List.length col then List.nth col i else "" in
      print_string (pad (" " ^ s)); print_string "|") cols;
    print_newline ()
  done;
  sep ()

let () =
  let grammar = Grammars.grammar_abc in
  let tokens = [ "w1" ; "w2" ; "w3"] in
  let pg = Recognize.prepare grammar in
  Printf.printf "Input: [%s]\n\n%!" (String.concat "; " tokens);
  let steps = Linear.scan_steps pg tokens in
  print_scan_table steps
