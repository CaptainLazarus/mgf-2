open Practice.Types
open Practice.Grammars

(* Grammar where the same token "x" appears as both:
   - right sibling in A -> B x  (head=B, right expansion)
   - head in     C -> x D       (head=x, left expansion -- D is right sibling... wait)
   Actually for left expansion: C -> D x  head=x means x is head on right, D is left sibling.
   So "x" as first token:
     - right expansion: A -> B x, x matches as right sibling, B is missing left boundary
     - left expansion:  C -> D x, x matches as head (already in T[0,1]), D is missing left boundary
*)
let _g : grammar =
  {
    nonterminals = [ "S"; "A"; "C" ];
    terminals = [ "x"; "y" ];
    start = "S";
    productions =
      [
        {
          index = 0;
          lhs = "S";
          rhs = [ Nonterminal "A"; Nonterminal "C" ];
          head_pos = 1;
        };
        (* A -> B x, head=B (pos 1) — right expansion, x is right sibling *)
        {
          index = 1;
          lhs = "A";
          rhs = [ Terminal "y"; Terminal "x" ];
          head_pos = 1;
        };
        (* C -> D x, head=x (pos 2) — left expansion, y is left sibling *)
        {
          index = 2;
          lhs = "C";
          rhs = [ Terminal "y"; Terminal "x" ];
          head_pos = 2;
        };
      ];
  }

let show_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "P(%d,%d,%d)" r s t
  | CompleteItem nt -> nt

let show_hot = function
  | HItem i -> show_item i
  | HTerm t -> Printf.sprintf "'%s'" t

let () =
  let cover = Practice.Hcover.compute_h_cover grammar_astar in

  Printf.printf "=== right_expansions (result, left_head, right_sibling) ===\n";
  List.iter
    (fun (result, left_item, y_h) ->
      Printf.printf "  %s  <-  %s  +  %s\n" (show_item result)
        (show_item left_item) (show_hot y_h))
    cover.right_expansions;

  Printf.printf "\n=== left_expansions (result, left_sibling, right_head) ===\n";
  List.iter
    (fun (result, x_h, right_item) ->
      Printf.printf "  %s  <-  %s  +  %s\n" (show_item result) (show_hot x_h)
        (show_item right_item))
    cover.left_expansions;

  Printf.printf "\n=== projections (item, source) ===\n";
  List.iter
    (fun (item, src) ->
      Printf.printf "  %s  <-  %s\n" (show_item item) (show_hot src))
    cover.projections;

  let first_term = "a" in
  Printf.printf "\n=== boundary seeding T[0,1] if first token = '%s' ===\n"
    first_term;
  Printf.printf
    "-- from right_expansions (x as right sibling, head is missing left) --\n";
  List.iter
    (fun (result, left_item, y_h) ->
      match y_h with
      | HTerm t when t = first_term ->
          Printf.printf
            "  seed %s  (left_head=%s missing, right_sibling='%s' matches)\n"
            (show_item result) (show_item left_item) t
      | _ -> ())
    cover.right_expansions;
  (* for left_expansions: right_item is the head; it gets into T[0,1] via projection from first_term *)
  let projects_from_term item =
    List.exists
      (fun (i, src) -> i = item && src = HTerm first_term)
      cover.projections
  in
  Printf.printf
    "-- from left_expansions (head projects from '%s', left sibling missing) --\n"
    first_term;
  List.iter
    (fun (result, x_h, right_item) ->
      if projects_from_term right_item then
        Printf.printf
          "  seed %s  (left_sibling=%s missing, right_head=%s projects from \
           '%s')\n"
          (show_item result) (show_hot x_h) (show_item right_item) first_term)
    cover.left_expansions
