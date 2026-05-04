open Types
open Convert

let print_grammar g =
  Printf.printf "+-- Grammar %s+\n" (String.make 49 '-');
  List.iter
    (fun prod ->
      let rhs_str = String.concat " " (List.map string_of_symbol prod.rhs) in
      let head_sym =
        if List.length prod.rhs > 0 then
          string_of_symbol (get_symbol prod prod.head_pos)
        else "e"
      in
      Printf.printf "| %d. %s -> %-25s [head: %s]\n" prod.index prod.lhs rhs_str
        head_sym)
    g.productions;
  Printf.printf "+%s+\n" (String.make 60 '-')

let print_cover_summary (cover : h_cover) =
  Printf.printf "+-- H-Cover Summary %s+\n" (String.make 41 '-');
  Printf.printf "| Items: %d\n" (List.length cover.items);
  Printf.printf "| Projections: %d\n" (List.length cover.projections);
  Printf.printf "| Left expansions: %d\n" (List.length cover.left_expansions);
  Printf.printf "| Right expansions: %d\n" (List.length cover.right_expansions);
  Printf.printf "| Epsilon projections: %d\n"
    (List.length cover.epsilon_projections);
  Printf.printf "+%s+\n" (String.make 60 '-')

let print_cover (cover : h_cover) =
  Printf.printf "+-- H-Cover %s+\n" (String.make 49 '-');
  Printf.printf "| Items (%d):\n" (List.length cover.items);
  List.iter
    (fun it -> Printf.printf "|   %s\n" (string_of_h_item it))
    (List.sort compare cover.items);
  Printf.printf "| Projections (%d):\n" (List.length cover.projections);
  List.iter
    (fun (lhs, rhs) ->
      Printf.printf "|   %s  <-  %s\n" (string_of_h_item lhs)
        (string_of_h_item_or_terminal rhs))
    cover.projections;
  Printf.printf "| Left expansions (%d):\n" (List.length cover.left_expansions);
  List.iter
    (fun (result, x_h, right_item) ->
      Printf.printf "|   %s  <-  %s  %s\n" (string_of_h_item result)
        (string_of_h_item_or_terminal x_h)
        (string_of_h_item right_item))
    cover.left_expansions;
  Printf.printf "| Right expansions (%d):\n"
    (List.length cover.right_expansions);
  List.iter
    (fun (result, left_item, y_h) ->
      Printf.printf "|   %s  <-  %s  %s\n" (string_of_h_item result)
        (string_of_h_item left_item)
        (string_of_h_item_or_terminal y_h))
    cover.right_expansions;
  Printf.printf "| Epsilon projections (%d):\n"
    (List.length cover.epsilon_projections);
  List.iter
    (fun (result, source) ->
      Printf.printf "|   %s  <-  %s  [ε]\n" (string_of_h_item result)
        (string_of_h_item source))
    cover.epsilon_projections;
  Printf.printf "+%s+\n" (String.make 60 '-')

let print_root_candidates candidates =
  Printf.printf "+-- Parse Root Inference %s+\n" (String.make 36 '-');
  if candidates = [] then Printf.printf "| No items found in T[0,n]\n"
  else
    List.iter
      (fun c ->
        if c.missing_left = [] && c.missing_right = [] then
          Printf.printf "| COMPLETE : %s\n" c.root
        else
          let fmt syms = String.concat " " (List.map string_of_symbol syms) in
          Printf.printf "| PARTIAL  : %s  (missing left: [%s]  right: [%s])\n"
            c.root (fmt c.missing_left) (fmt c.missing_right))
      candidates;
  Printf.printf "+%s+\n" (String.make 60 '-')

let pad_center s w =
  let len = String.length s in
  if len >= w then String.sub s 0 w
  else
    let left = (w - len) / 2 in
    let right = w - len - left in
    String.make left ' ' ^ s ^ String.make right ' '

let print_hline widths =
  print_string "+";
  Array.iter
    (fun w ->
      print_string (String.make w '-');
      print_string "+")
    widths;
  print_newline ()

let print_header_hline widths =
  print_string "+";
  Array.iter
    (fun w ->
      print_string (String.make w '=');
      print_string "+")
    widths;
  print_newline ()

let get_cell_content tbl i j =
  if j < i then ""
  else
    let items = tbl.entries.(i).(j).items in
    if items = [] then "."
    else
      String.concat ", "
        (List.map
           (fun (it, _) -> short_string_of_h_item it)
           (List.sort compare items))

let calc_widths tbl =
  let n = tbl.n in
  let widths = Array.make (n + 1) 3 in
  for j = 0 to n - 1 do
    widths.(j + 1) <- max widths.(j + 1) (String.length tbl.input.(j) + 2)
  done;
  widths.(0) <- max widths.(0) 3;
  for i = 0 to n - 1 do
    for j = i + 1 to n do
      let content = get_cell_content tbl i j in
      widths.(j) <- max widths.(j) (String.length content + 2)
    done
  done;
  widths

let print_visual_table tbl =
  let n = tbl.n in
  let widths = calc_widths tbl in

  Printf.printf "\n+-- Recognition Table %s+\n" (String.make 40 '-');
  Printf.printf "| Input: %-51s|\n"
    (String.concat " " (Array.to_list tbl.input));
  Printf.printf "+%s+\n\n" (String.make 60 '-');

  print_string "|";
  print_string (pad_center "i\\j" widths.(0));
  print_string "|";
  for j = 1 to n do
    print_string (pad_center (string_of_int j) widths.(j));
    print_string "|"
  done;
  print_newline ();

  print_string "|";
  print_string (pad_center "" widths.(0));
  print_string "|";
  for j = 0 to n - 1 do
    print_string (pad_center tbl.input.(j) widths.(j + 1));
    print_string "|"
  done;
  print_newline ();

  print_header_hline widths;

  for i = 0 to n - 1 do
    print_string "|";
    print_string (pad_center (string_of_int i) widths.(0));
    print_string "|";

    for j = 1 to n do
      let content = if j <= i then "" else get_cell_content tbl i j in
      print_string (pad_center content widths.(j));
      print_string "|"
    done;
    print_newline ();

    if i < n - 1 then print_hline widths
  done;

  print_hline widths;
  print_newline ()

let print_cell_details tbl =
  Printf.printf "+-- Cell Details %s+\n" (String.make 44 '-');

  for i = 0 to tbl.n do
    for j = i to tbl.n do
      let items = tbl.entries.(i).(j).items in
      if items <> [] then (
        let span =
          if j > i then
            String.concat " " (Array.to_list (Array.sub tbl.input i (j - i)))
          else "ε"
        in
        Printf.printf "| T[%d,%d] spans \"%s\":\n" i j span;
        List.iter
          (fun (item, derivs) ->
            Printf.printf "|   %s\n" (string_of_h_item item);
            List.iter
              (fun d -> Printf.printf "|     <- %s\n" (string_of_derivation d))
              derivs)
          (List.sort compare items))
    done
  done;

  Printf.printf "+%s+\n" (String.make 60 '-')
