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

let rec collect_tokens ?grammar ~virtuals tree =
  match tree with
  | Leaf s -> [ pretty_token s ]
  | Virtual _ when not virtuals -> []
  | Virtual x -> [ label_virtual ?grammar x ]
  | Node (_, []) -> []
  | Node (_, children) ->
      List.concat_map (collect_tokens ?grammar ~virtuals) children

let linearize ?grammar ~virtuals tree =
  String.concat " " (collect_tokens ?grammar ~virtuals tree)

let count_gaps tree =
  let rec go = function
    | Virtual _ -> 1
    | Node (_, children) -> List.fold_left (fun a c -> a + go c) 0 children
    | Leaf _ -> 0
  in
  go tree

let collect_boundary_virtuals ?grammar tree =
  let rec go = function
    | Virtual x -> [ `V (label_virtual ?grammar x) ]
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
    | rest -> (List.rev acc, rest)
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

let print_tree_result ?grammar i n_unique gaps tree =
  Printf.printf "  ── Tree %d/%d  (%d gap%s) ──\n" i n_unique gaps
    (if gaps = 1 then "" else "s");
  print_tree ?grammar tree;
  print_newline ()

(* ------------------------------------------------------------------ *)
(* print_results                                                       *)
(* ------------------------------------------------------------------ *)

let print_results ?grammar tbl roots mode =
  List.iter
    (fun (rc : root_candidate) ->
      let trees = reconstruct_trees_virtual_from ~limit:5 tbl rc.item in
      if trees = [] then ()
      else
        let left_vs, right_vs =
          match trees with
          | t :: _ ->
              let l, r = collect_boundary_virtuals ?grammar t in
              (List.sort_uniq String.compare l, List.sort_uniq String.compare r)
          | [] -> ([], [])
        in
        let gap_label =
          if left_vs = [] && right_vs = [] then "complete"
          else
            let parts =
              List.filter_map
                (fun (side, vs) ->
                  if vs = [] then None
                  else Some (Printf.sprintf "%s: [%s]" side (String.concat ", " vs)))
                [ ("L", left_vs); ("R", right_vs) ]
            in
            "partial — " ^ String.concat "  " parts
        in
        Printf.printf "\n┌─ %s  [%s]\n" rc.root gap_label;
        match mode with
        | Tokens ->
            let lines =
              List.sort_uniq String.compare
                (List.map (linearize ?grammar ~virtuals:false) trees)
            in
            Printf.printf "│  %d unique token string%s:\n" (List.length lines)
              (if List.length lines = 1 then "" else "s");
            List.iter (fun s -> Printf.printf "│    %s\n" s) lines;
            Printf.printf "└─\n"
        | Strings ->
            let lines =
              List.sort_uniq String.compare
                (List.map (linearize ?grammar ~virtuals:true) trees)
            in
            Printf.printf "│  %d unique string%s (incl. gaps):\n"
              (List.length lines)
              (if List.length lines = 1 then "" else "s");
            List.iter (fun s -> Printf.printf "│    %s\n" s) lines;
            Printf.printf "└─\n"
        | Trees ->
            (* Collapse trees with identical full linearisation *)
            let by_string = Hashtbl.create 8 in
            List.iter
              (fun tree ->
                let key = linearize ?grammar ~virtuals:true tree in
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
              (fun i tree ->
                print_tree_result ?grammar (i + 1) n (count_gaps tree) tree)
              unique;
            Printf.printf "└─\n")
    roots
