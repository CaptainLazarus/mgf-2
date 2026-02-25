open Practice

(* ============================================================ *)
(*  Alcotest specs for htable recognition, root inference,      *)
(*  and tree reconstruction.                                    *)
(* ============================================================ *)

(* --- Testable types ----------------------------------------- *)

let tree_t : Htable.tree Alcotest.testable =
  Alcotest.testable
    (fun ppf _t -> Format.pp_print_string ppf "<tree>")
    (=)

(* --- Helpers ------------------------------------------------- *)

let recognized g input = Htable.recognize g input

let has tbl i j item =
  Htable.mem_item tbl i j (Htable.CompleteItem item)

let root_names candidates =
  List.map (fun (c : Htable.root_candidate) -> c.root) candidates

let has_complete_root name candidates =
  List.exists (fun (c : Htable.root_candidate) ->
    c.root = name && c.missing_left = [] && c.missing_right = [])
    candidates

(* ============================================================ *)
(*  Suite 1 — Recognition                                       *)
(* ============================================================ *)

let test_gcl_accepted () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"; "cl"; "v"; "det"; "n"] in
  Alcotest.(check bool) "full sentence accepted" true (Htable.is_accepted tbl)

let test_gcl_rejected () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"] in
  Alcotest.(check bool) "bare NP rejected" false (Htable.is_accepted tbl)

let test_gcl_np_in_cell () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"] in
  Alcotest.(check bool) "T[0,2] has NP" true (has tbl 0 2 "NP")

let test_epsilon_ab_accepted () =
  let tbl = recognized Htable.grammar_epsilon ["a"; "b"] in
  Alcotest.(check bool) "a b accepted" true (Htable.is_accepted tbl)

let test_epsilon_b_accepted () =
  (* A is nullable, so S -> A B with just "b" should be accepted *)
  let tbl = recognized Htable.grammar_epsilon ["b"] in
  Alcotest.(check bool) "b accepted (A nullable)" true (Htable.is_accepted tbl)

let test_astar_nonempty_accepted () =
  let tbl = recognized Htable.grammar_astar ["a"; "a"; "a"] in
  Alcotest.(check bool) "a a a accepted" true (Htable.is_accepted tbl)

let test_astar_empty_accepted () =
  let tbl = recognized Htable.grammar_astar [] in
  Alcotest.(check bool) "empty accepted (star)" true (Htable.is_accepted tbl)

(* ============================================================ *)
(*  Suite 2 — Root inference                                    *)
(* ============================================================ *)

let test_roots_np_complete () =
  (* "det n" fully parses as NP *)
  let tbl = recognized Htable.grammar_gcl ["det"; "n"] in
  let roots = Htable.infer_parse_roots tbl in
  Alcotest.(check bool) "NP is a complete root" true
    (has_complete_root "NP" roots)

let test_roots_s_partial () =
  (* "det n" gives NP but not S; S should appear as partial *)
  let tbl = recognized Htable.grammar_gcl ["det"; "n"] in
  let roots = Htable.infer_parse_roots tbl in
  Alcotest.(check bool) "S appears in root inference" true
    (List.mem "S" (root_names roots))

let test_roots_complete_sentence () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"; "cl"; "v"; "det"; "n"] in
  let roots = Htable.infer_parse_roots tbl in
  Alcotest.(check bool) "S is complete root for full sentence" true
    (has_complete_root "S" roots)

(* ============================================================ *)
(*  Suite 3 — Tree reconstruction                              *)
(* ============================================================ *)

(* GCL full sentence: exactly one parse tree *)
let test_gcl_tree_count () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"; "cl"; "v"; "det"; "n"] in
  let trees = Htable.reconstruct_trees_omit tbl "S" in
  Alcotest.(check int) "exactly 1 GCL tree" 1 (List.length trees)

(* GCL tree structure *)
let test_gcl_tree_structure () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"; "cl"; "v"; "det"; "n"] in
  let trees = Htable.reconstruct_trees_omit tbl "S" in
  let expected = Htable.(
    Node ("S", [
      Node ("NP", [Leaf "det"; Leaf "n"]);
      Node ("VP", [Leaf "cl"; Leaf "v"; Node ("NP", [Leaf "det"; Leaf "n"])])
    ])) in
  Alcotest.(check tree_t) "GCL tree structure" expected (List.hd trees)

(* A-star on single "a": two trees — one with trailing epsilon Astar node,
   one collapsed via epsilon projection *)
let test_astar_single_tree () =
  let tbl = recognized Htable.grammar_astar ["a"] in
  let trees = Htable.reconstruct_trees_omit tbl "Astar" in
  Alcotest.(check int) "2 Astar trees for [a]" 2 (List.length trees)

(* A-star on empty: one tree (just the epsilon node) *)
let test_astar_empty_tree () =
  let tbl = recognized Htable.grammar_astar [] in
  let trees = Htable.reconstruct_trees_omit tbl "Astar" in
  let expected = Htable.(Node ("Astar", [])) in
  Alcotest.(check tree_t) "Astar empty tree is epsilon node" expected
    (List.hd trees)

(* Invalid input: no trees *)
let test_gcl_no_trees_on_reject () =
  let tbl = recognized Htable.grammar_gcl ["det"; "n"] in
  let trees = Htable.reconstruct_trees_omit tbl "S" in
  Alcotest.(check int) "no S trees for bare NP" 0 (List.length trees)

(* Lisp grammar via file *)
let lisp_grammar () =
  let domain = Grammar_reader.extract_grammar "../grammars/lisp.g4" in
  Grammar_converter.convert_grammar domain

let test_lisp_atom_accepted () =
  let g = lisp_grammar () in
  let tbl = Htable.recognize g ["ATOM"] in
  Alcotest.(check bool) "ATOM accepted as lisp_" true (Htable.is_accepted tbl)

let test_lisp_dotted_pair_accepted () =
  let g = lisp_grammar () in
  let tbl = Htable.recognize g ["LPAREN"; "ATOM"; "DOT"; "ATOM"; "RPAREN"] in
  Alcotest.(check bool) "(a . b) accepted" true (Htable.is_accepted tbl)

let test_lisp_invalid_no_trees () =
  let g = lisp_grammar () in
  let tbl = Htable.recognize g ["LPAREN"; "ATOM"; "DOT"] in
  let trees = Htable.reconstruct_trees_omit tbl "lisp_" in
  Alcotest.(check int) "incomplete dotted pair: no trees" 0 (List.length trees)

(* ============================================================ *)
(*  Runner                                                      *)
(* ============================================================ *)

let () =
  Alcotest.run "htable"
    [ "recognition", [
        Alcotest.test_case "gcl accepted"         `Quick test_gcl_accepted;
        Alcotest.test_case "gcl rejected"         `Quick test_gcl_rejected;
        Alcotest.test_case "gcl NP in cell"       `Quick test_gcl_np_in_cell;
        Alcotest.test_case "epsilon a b"          `Quick test_epsilon_ab_accepted;
        Alcotest.test_case "epsilon b (nullable)" `Quick test_epsilon_b_accepted;
        Alcotest.test_case "astar a a a"          `Quick test_astar_nonempty_accepted;
        Alcotest.test_case "astar empty"          `Quick test_astar_empty_accepted;
      ]
    ; "root inference", [
        Alcotest.test_case "NP complete"          `Quick test_roots_np_complete;
        Alcotest.test_case "S partial"            `Quick test_roots_s_partial;
        Alcotest.test_case "S complete sentence"  `Quick test_roots_complete_sentence;
      ]
    ; "tree reconstruction", [
        Alcotest.test_case "gcl tree count"       `Quick test_gcl_tree_count;
        Alcotest.test_case "gcl tree structure"   `Quick test_gcl_tree_structure;
        Alcotest.test_case "astar single"         `Quick test_astar_single_tree;
        Alcotest.test_case "astar empty tree"     `Quick test_astar_empty_tree;
        Alcotest.test_case "no trees on reject"   `Quick test_gcl_no_trees_on_reject;
        Alcotest.test_case "lisp atom accepted"   `Quick test_lisp_atom_accepted;
        Alcotest.test_case "lisp dotted pair"     `Quick test_lisp_dotted_pair_accepted;
        Alcotest.test_case "lisp invalid"         `Quick test_lisp_invalid_no_trees;
      ]
    ]
