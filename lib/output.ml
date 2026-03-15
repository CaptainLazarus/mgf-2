open Types
open Print
open Reconstruct

let pretty_token = function
  | "LPAREN" -> "(" | "RPAREN" -> ")"
  | "DOT"    -> "." | "ATOM"   -> "ATOM"
  | s -> s

let rec collect_tokens tree =
  match tree with
  | Leaf s -> [pretty_token s]
  | Virtual (HTerm t) -> [pretty_token t]
  | Virtual (HItem (CompleteItem nt)) -> [nt]
  | Virtual (HItem (PartialItem _)) -> []
  | Node (_, []) -> []
  | Node (_, children) -> List.concat_map collect_tokens children

let linearize_tree tree =
  String.concat " " (collect_tokens tree)

type display_mode = Tokens | Trees [@@warning "-37"]

let print_results ?grammar tbl roots mode =
  List.iter (fun (rc : root_candidate) ->
    let trees = reconstruct_trees_virtual tbl rc.root in
    if trees <> [] then begin
      match mode with
      | Tokens ->
        let lines = List.sort_uniq String.compare (List.map linearize_tree trees) in
        Printf.printf "  %s (%d unique):\n" rc.root (List.length lines);
        List.iter (fun line -> Printf.printf "    %s\n" line) lines
      | Trees ->
        Printf.printf "  %s (%d):\n" rc.root (List.length trees);
        List.iteri (fun i tree ->
          Printf.printf "  Tree %d:\n" (i + 1);
          print_tree ?grammar tree)
          trees
    end)
    roots
