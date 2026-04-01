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
  | Virtual x -> [ Printf.sprintf "<%s>" (Print.label_virtual ?grammar x) ]
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
      let trees = reconstruct_trees_virtual tbl rc.root in
      if trees = [] then ()
      else
        let fmt_syms syms =
          String.concat " "
            (List.map
               (function
                 | Terminal t -> Printf.sprintf "\"%s\"" t | Nonterminal n -> n)
               syms)
        in
        let gap_label =
          if rc.missing_left = [] && rc.missing_right = [] then "complete"
          else
            let parts =
              List.filter_map
                (fun (side, syms) ->
                  if syms = [] then None
                  else Some (Printf.sprintf "%s: [%s]" side (fmt_syms syms)))
                [ ("L", rc.missing_left); ("R", rc.missing_right) ]
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
