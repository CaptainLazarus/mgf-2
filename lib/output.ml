open Types
open Print
open Reconstruct

(* ------------------------------------------------------------------ *)
(* Linearisation                                                       *)
(* ------------------------------------------------------------------ *)

let pretty_token = function
  | "LPAREN" -> "("
  | "RPAREN" -> ")"
  | "DOT" -> "."
  | "ATOM" -> "ATOM"
  | s -> s

let rec collect_tokens ?grammar ?min_yield ~virtuals tree =
  match tree with
  | Leaf s -> [ pretty_token s ]
  | Virtual _ when not virtuals -> []
  | Virtual x -> [ label_virtual ?grammar ?min_yield x ]
  | Node (_, []) -> []
  | Node (_, children) ->
      List.concat_map (collect_tokens ?grammar ?min_yield ~virtuals) children

let linearize ?grammar ?min_yield ~virtuals tree =
  String.concat " " (collect_tokens ?grammar ?min_yield ~virtuals tree)

let count_gaps tree =
  let rec go = function
    | Virtual _ -> 1
    | Node (_, children) -> List.fold_left (fun a c -> a + go c) 0 children
    | Leaf _ -> 0
  in
  go tree

let count_virtuals tree =
  let rec go = function
    | Virtual _ -> 1
    | Leaf _ -> 0
    | Node (_, children) -> List.fold_left (fun acc c -> acc + go c) 0 children
  in
  go tree

let collect_boundary_virtuals ?grammar ?min_yield tree =
  let rec go = function
    | Virtual x -> [ `V (label_virtual ?grammar ?min_yield x) ]
    | Leaf _ -> [ `L ]
    | Node (_, children) -> List.concat_map go children
  in
  let items = go tree in
  let rec take_leading acc = function
    | `V s :: rest -> take_leading (s :: acc) rest
    | rest -> (List.rev acc, rest)
  in
  let rec take_trailing acc = function
    | `V s :: rest -> take_trailing (s :: acc) rest
    | rest -> (acc, rest)
  in
  let left_vs, rest = take_leading [] items in
  let right_vs, _ = take_trailing [] (List.rev rest) in
  (left_vs, right_vs)

(* ------------------------------------------------------------------ *)
(* Display modes                                                       *)
(* ------------------------------------------------------------------ *)

type display_mode =
  | Tokens (* real tokens only, deduplicated *)
  | Strings (* tokens + virtual markers, deduplicated *)
  | Trees (* full trees, collapsed if same string+virtuals *)

(* ------------------------------------------------------------------ *)
(* Tree printer                                                        *)
(* ------------------------------------------------------------------ *)

let print_tree_result ?grammar ?min_yield i n_unique tree =
  let gaps = count_gaps tree in
  let left_vs, right_vs = collect_boundary_virtuals ?grammar ?min_yield tree in
  let gap_parts =
    List.filter_map
      (fun (side, vs) ->
        if vs = [] then None
        else Some (Printf.sprintf "%s: [%s]" side (String.concat ", " vs)))
      [ ("L", left_vs); ("R", right_vs) ]
  in
  let gap_str =
    let g = Printf.sprintf "%d gap%s" gaps (if gaps = 1 then "" else "s") in
    if gap_parts = [] then g else g ^ "  " ^ String.concat "  " gap_parts
  in
  Printf.printf "  ── Tree %d/%d  (%s) ──\n" i n_unique gap_str;
  print_tree ?grammar ?min_yield tree;
  print_newline ()

(* ------------------------------------------------------------------ *)
(* print_results                                                       *)
(* ------------------------------------------------------------------ *)

let best_tree = function (_, trees, _) ->
  match trees with t :: _ -> Some t | [] -> None

let dominated candidate all =
  match best_tree candidate with
  | None -> false
  | Some (Node (_, children)) ->
      List.exists (fun other ->
        match best_tree other with
        | Some t -> List.mem t children
        | None -> false)
        all
  | Some _ -> false

let print_results ?grammar ?min_yield tbl roots mode =
  let with_trees =
    List.filter_map
      (fun (rc : root_candidate) ->
        let trees = reconstruct_trees_virtual_from ~limit:5 tbl rc.item in
        if trees = [] then None
        else
          let trees =
            List.sort (fun a b -> compare (count_virtuals a) (count_virtuals b)) trees
          in
          let gap_count = match trees with t :: _ -> count_virtuals t | [] -> 0 in
          Some (rc, trees, gap_count))
      roots
  in
  (* Drop roots whose best tree contains another root's best tree as a direct child *)
  let with_trees = List.filter (fun c -> not (dominated c with_trees)) with_trees in
  List.iter
    (fun (rc, trees, gap_count) ->
        Printf.printf "\n┌─ %s  [gaps: %d]\n" rc.root gap_count;
        match mode with
        | Tokens ->
            let lines =
              List.sort_uniq String.compare
                (List.map (linearize ?grammar ?min_yield ~virtuals:false) trees)
            in
            Printf.printf "│  %d unique token string%s:\n" (List.length lines)
              (if List.length lines = 1 then "" else "s");
            List.iter (fun s -> Printf.printf "│    %s\n" s) lines;
            Printf.printf "└─\n"
        | Strings ->
            let lines =
              List.sort_uniq String.compare
                (List.map (linearize ?grammar ?min_yield ~virtuals:true) trees)
            in
            Printf.printf "│  %d unique string%s (incl. gaps):\n"
              (List.length lines)
              (if List.length lines = 1 then "" else "s");
            List.iter (fun s -> Printf.printf "│    %s\n" s) lines;
            Printf.printf "└─\n"
        | Trees ->
            let by_string = Hashtbl.create 8 in
            List.iter
              (fun tree ->
                let key = linearize ?grammar ?min_yield ~virtuals:true tree in
                if not (Hashtbl.mem by_string key) then
                  Hashtbl.replace by_string key tree)
              trees;
            let unique = Hashtbl.fold (fun _ t acc -> t :: acc) by_string [] in
            let unique =
              List.sort
                (fun a b -> compare (count_gaps a) (count_gaps b))
                unique
            in
            let n = List.length unique in
            Printf.printf "│  %d unique tree%s:\n" n (if n = 1 then "" else "s");
            List.iteri
              (fun i tree -> print_tree_result ?grammar ?min_yield (i + 1) n tree)
              unique;
            Printf.printf "└─\n")
    with_trees
