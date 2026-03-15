open Types

(* ============================================================ *)
(*                     STRING CONVERSION                        *)
(* ============================================================ *)

let string_of_symbol = function
  | Terminal t -> Printf.sprintf "\"%s\"" t
  | Nonterminal nt -> nt

let string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "I_%d^(%d,%d)" r s t
  | CompleteItem a -> Printf.sprintf "I_%s" a

let short_string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "%d^%d,%d" r s t
  | CompleteItem a -> a

let string_of_h_item_or_terminal = function
  | HItem hi -> string_of_h_item hi
  | HTerm t -> Printf.sprintf "\"%s\"" t

let string_of_derivation = function
  | FromTerminal t -> Printf.sprintf "Terminal(%s)" t
  | FromProject hi -> Printf.sprintf "Project(%s)" (string_of_h_item hi)
  | FromLeftExpand (k, x, ri) ->
      Printf.sprintf "LeftExp(k=%d, %s, %s)" k
        (string_of_h_item_or_terminal x)
        (string_of_h_item ri)
  | FromRightExpand (k, li, y) ->
      Printf.sprintf "RightExp(k=%d, %s, %s)" k (string_of_h_item li)
        (string_of_h_item_or_terminal y)
  | FromEpsilon hi -> Printf.sprintf "Epsilon(%s)" (string_of_h_item hi)
  | FromBoundaryRight (virtual_left, real_right) ->
      Printf.sprintf "BoundaryRight(virtual_left: %s, real_right: %s)"
        (string_of_h_item_or_terminal virtual_left)
        (string_of_h_item_or_terminal real_right)
  | FromBoundaryLeft (real_left, virtual_right) ->
      Printf.sprintf "BoundaryLeft(real_left: %s, virtual_right: %s)"
        (string_of_h_item_or_terminal real_left)
        (string_of_h_item_or_terminal virtual_right)
  | FromInductiveFill (virtual_left, real_right) ->
      Printf.sprintf "InductiveFill(virtual: %s, right: %s)"
        (string_of_h_item virtual_left)
        (string_of_h_item real_right)
  | FromInductiveFillRight (real_left, virtual_right) ->
      Printf.sprintf "InductiveFillRight(left: %s, virtual: %s)"
        (string_of_h_item real_left)
        (string_of_h_item_or_terminal virtual_right)

(* ============================================================ *)
(*                     GRAMMAR / COVER                          *)
(* ============================================================ *)

let get_symbol prod pos = List.nth prod.rhs (pos - 1)

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
  List.iter (fun it ->
    Printf.printf "|   %s\n" (string_of_h_item it))
    (List.sort compare cover.items);
  Printf.printf "| Projections (%d):\n" (List.length cover.projections);
  List.iter (fun (lhs, rhs) ->
    Printf.printf "|   %s  <-  %s\n"
      (string_of_h_item lhs) (string_of_h_item_or_terminal rhs))
    cover.projections;
  Printf.printf "| Left expansions (%d):\n" (List.length cover.left_expansions);
  List.iter (fun (result, x_h, right_item) ->
    Printf.printf "|   %s  <-  %s  %s\n"
      (string_of_h_item result)
      (string_of_h_item_or_terminal x_h)
      (string_of_h_item right_item))
    cover.left_expansions;
  Printf.printf "| Right expansions (%d):\n" (List.length cover.right_expansions);
  List.iter (fun (result, left_item, y_h) ->
    Printf.printf "|   %s  <-  %s  %s\n"
      (string_of_h_item result)
      (string_of_h_item left_item)
      (string_of_h_item_or_terminal y_h))
    cover.right_expansions;
  Printf.printf "| Epsilon projections (%d):\n" (List.length cover.epsilon_projections);
  List.iter (fun (result, source) ->
    Printf.printf "|   %s  <-  %s  [ε]\n"
      (string_of_h_item result)
      (string_of_h_item source))
    cover.epsilon_projections;
  Printf.printf "+%s+\n" (String.make 60 '-')

(* ============================================================ *)
(*                     ROOT CANDIDATES                          *)
(* ============================================================ *)

let print_root_candidates candidates =
  Printf.printf "+-- Parse Root Inference %s+\n" (String.make 36 '-');
  if candidates = [] then
    Printf.printf "| No items found in T[0,n]\n"
  else
    List.iter (fun c ->
      if c.missing_left = [] && c.missing_right = [] then
        Printf.printf "| COMPLETE : %s\n" c.root
      else
        let fmt syms = String.concat " " (List.map string_of_symbol syms) in
        Printf.printf "| PARTIAL  : %s  (missing left: [%s]  right: [%s])\n"
          c.root (fmt c.missing_left) (fmt c.missing_right))
      candidates;
  Printf.printf "+%s+\n" (String.make 60 '-')

(* ============================================================ *)
(*                     TREE PRINTING                            *)
(* ============================================================ *)

let expand_virtual g x =
  match x with
  | HTerm t -> Printf.sprintf "\"%s\"" t
  | HItem (CompleteItem nt) -> nt
  | HItem (PartialItem (r, s, t)) ->
      let prod = List.find (fun p -> p.index = r) g.productions in
      let syms = Array.of_list prod.rhs in
      Array.to_list (Array.sub syms s (t - s))
      |> List.map string_of_symbol
      |> String.concat " "

let label_virtual ?grammar x =
  match grammar with
  | Some g -> expand_virtual g x
  | None   -> string_of_h_item_or_terminal x

let rec print_tree_aux ?grammar prefix is_last tree =
  let connector    = if is_last then "└── " else "├── " in
  let child_prefix = prefix ^ (if is_last then "    " else "│   ") in
  match tree with
  | Leaf t ->
    Printf.printf "%s%s\"%s\"\n" prefix connector t
  | Virtual x ->
    Printf.printf "%s%s<virtual: %s>\n" prefix connector (label_virtual ?grammar x)
  | Node (nt, children) ->
    Printf.printf "%s%s%s\n" prefix connector nt;
    let n = List.length children in
    List.iteri (fun i child ->
      print_tree_aux ?grammar child_prefix (i = n - 1) child)
      children

let print_tree ?grammar tree =
  match tree with
  | Leaf t    -> Printf.printf "\"%s\"\n" t
  | Virtual x -> Printf.printf "<virtual: %s>\n" (label_virtual ?grammar x)
  | Node (nt, children) ->
    Printf.printf "%s\n" nt;
    let n = List.length children in
    List.iteri (fun i child ->
      print_tree_aux ?grammar "" (i = n - 1) child)
      children

(* ============================================================ *)
(*                     TABLE DISPLAY                            *)
(* ============================================================ *)

let repeat_string s n = String.concat "" (List.init n (fun _ -> s))

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

let pad_center s w =
  let len = String.length s in
  if len >= w then String.sub s 0 w
  else
    let left = (w - len) / 2 in
    let right = w - len - left in
    String.make left ' ' ^ s ^ String.make right ' '

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
