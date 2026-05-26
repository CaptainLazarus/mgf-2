open Types
open Convert

let expand_virtual ?min_yield g x =
  match x with
  | HTerm t -> Printf.sprintf "\"%s\"" t
  | HItem (CompleteItem nt) ->
      (match min_yield with
       | Some tbl ->
           (match Hashtbl.find_opt tbl nt with
            | Some [] -> Printf.sprintf "ε(%s)" nt
            | Some terms -> String.concat " " terms
            | None -> nt)
       | None -> nt)
  | HItem (PartialItem (r, s, t)) ->
      let prod = List.find (fun p -> p.index = r) g.productions in
      let syms = Array.of_list prod.rhs in
      Array.to_list (Array.sub syms s (t - s))
      |> List.map string_of_symbol |> String.concat " "

let label_virtual ?grammar ?min_yield x =
  match grammar with
  | Some g -> expand_virtual ?min_yield g x
  | None -> string_of_h_item_or_terminal x

let rec print_tree_aux ?grammar ?min_yield prefix is_last tree =
  let connector = if is_last then "└── " else "├── " in
  let child_prefix = prefix ^ if is_last then "    " else "│   " in
  match tree with
  | Leaf t -> Printf.printf "%s%s\"%s\"\n" prefix connector t
  | Virtual x ->
      Printf.printf "%s%s<virtual: %s>\n" prefix connector
        (label_virtual ?grammar ?min_yield x)
  | Node (nt, children) ->
      Printf.printf "%s%s%s\n" prefix connector nt;
      let n = List.length children in
      List.iteri
        (fun i child -> print_tree_aux ?grammar ?min_yield child_prefix (i = n - 1) child)
        children

let print_tree ?grammar ?min_yield tree =
  match tree with
  | Leaf t -> Printf.printf "\"%s\"\n" t
  | Virtual x -> Printf.printf "<virtual: %s>\n" (label_virtual ?grammar ?min_yield x)
  | Node (nt, children) ->
      Printf.printf "%s\n" nt;
      let n = List.length children in
      List.iteri
        (fun i child -> print_tree_aux ?grammar ?min_yield "" (i = n - 1) child)
        children
