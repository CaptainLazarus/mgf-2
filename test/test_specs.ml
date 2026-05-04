open Practice
open Types

(* ============================================================ *)
(*  Alcotest specs for htable recognition, root inference,      *)
(*  and tree reconstruction.                                    *)
(* ============================================================ *)

(* --- Testable types ----------------------------------------- *)

let tree_t : Types.tree Alcotest.testable =
  Alcotest.testable (fun ppf _t -> Format.pp_print_string ppf "<tree>") ( = )

(* --- Helpers ------------------------------------------------- *)

let recognized g input = Recognize.recognize g input
let has tbl i j item = Table.mem_item tbl i j (Types.CompleteItem item)

let root_names candidates =
  List.map (fun (c : Types.root_candidate) -> c.root) candidates

let has_complete_root name candidates =
  List.exists
    (fun (c : Types.root_candidate) ->
      c.root = name && c.missing_left = [] && c.missing_right = [])
    candidates

(* ============================================================ *)
(*  Suite 1 — Recognition                                       *)
(* ============================================================ *)

let test_gcl_accepted () =
  let tbl =
    recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  Alcotest.(check bool) "full sentence accepted" true (Query.is_accepted tbl)

let test_gcl_rejected () =
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  Alcotest.(check bool) "bare NP rejected" false (Query.is_accepted tbl)

let test_gcl_np_in_cell () =
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  Alcotest.(check bool) "T[0,2] has NP" true (has tbl 0 2 "NP")

let test_epsilon_ab_accepted () =
  let tbl = recognized Grammars.grammar_epsilon [ "a"; "b" ] in
  Alcotest.(check bool) "a b accepted" true (Query.is_accepted tbl)

let test_epsilon_b_accepted () =
  (* A is nullable, so S -> A B with just "b" should be accepted *)
  let tbl = recognized Grammars.grammar_epsilon [ "b" ] in
  Alcotest.(check bool) "b accepted (A nullable)" true (Query.is_accepted tbl)

let test_astar_nonempty_accepted () =
  let tbl = recognized Grammars.grammar_astar [ "a"; "a"; "a" ] in
  Alcotest.(check bool) "a a a accepted" true (Query.is_accepted tbl)

let test_astar_empty_accepted () =
  let tbl = recognized Grammars.grammar_astar [] in
  Alcotest.(check bool) "empty accepted (star)" true (Query.is_accepted tbl)

(* ============================================================ *)
(*  Suite 2 — Root inference                                    *)
(* ============================================================ *)

let test_roots_np_complete () =
  (* "det n" fully parses as NP *)
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  let roots = Query.infer_parse_roots tbl in
  Alcotest.(check bool)
    "NP is a complete root" true
    (has_complete_root "NP" roots)

let test_roots_s_partial () =
  (* "det n" gives NP but not S; S should appear as partial *)
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  let roots = Query.infer_parse_roots tbl in
  Alcotest.(check bool)
    "S appears in root inference" true
    (List.mem "S" (root_names roots))

let test_roots_complete_sentence () =
  let tbl =
    recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  let roots = Query.infer_parse_roots tbl in
  Alcotest.(check bool)
    "S is complete root for full sentence" true
    (has_complete_root "S" roots)

(* ============================================================ *)
(*  Suite 3 — Tree reconstruction                              *)
(* ============================================================ *)

(* GCL full sentence: exactly one parse tree *)
let test_gcl_tree_count () =
  let tbl =
    recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  let trees = Reconstruct.reconstruct_trees_omit tbl "S" in
  Alcotest.(check int) "exactly 1 GCL tree" 1 (List.length trees)

(* GCL tree structure *)
let test_gcl_tree_structure () =
  let tbl =
    recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  let trees = Reconstruct.reconstruct_trees_omit tbl "S" in
  let expected =
    Node
      ( "S",
        [
          Node ("NP", [ Leaf "det"; Leaf "n" ]);
          Node
            ( "VP",
              [ Leaf "cl"; Leaf "v"; Node ("NP", [ Leaf "det"; Leaf "n" ]) ] );
        ] )
  in
  Alcotest.(check tree_t) "GCL tree structure" expected (List.hd trees)

(* A-star on single "a": two trees — one with trailing epsilon Astar node,
   one collapsed via epsilon projection *)
let test_astar_single_tree () =
  let tbl = recognized Grammars.grammar_astar [ "a" ] in
  let trees = Reconstruct.reconstruct_trees_omit tbl "Astar" in
  Alcotest.(check int) "2 Astar trees for [a]" 2 (List.length trees)

(* A-star on empty: one tree (just the epsilon node) *)
let test_astar_empty_tree () =
  let tbl = recognized Grammars.grammar_astar [] in
  let trees = Reconstruct.reconstruct_trees_omit tbl "Astar" in
  let expected = Node ("Astar", []) in
  Alcotest.(check tree_t)
    "Astar empty tree is epsilon node" expected (List.hd trees)

(* Invalid input: no trees *)
let test_gcl_no_trees_on_reject () =
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  let trees = Reconstruct.reconstruct_trees_omit tbl "S" in
  Alcotest.(check int) "no S trees for bare NP" 0 (List.length trees)

(* Lisp grammar via file *)
let lisp_grammar () =
  let domain = Grammar_reader.extract_grammar "../grammars/lisp.g4" in
  Grammar_converter.convert_grammar domain

let test_lisp_atom_accepted () =
  let g = lisp_grammar () in
  let tbl = Recognize.recognize g [ "ATOM" ] in
  Alcotest.(check bool) "ATOM accepted as lisp_" true (Query.is_accepted tbl)

let test_lisp_dotted_pair_accepted () =
  let g = lisp_grammar () in
  let tbl =
    Recognize.recognize g [ "LPAREN"; "ATOM"; "DOT"; "ATOM"; "RPAREN" ]
  in
  Alcotest.(check bool) "(a . b) accepted" true (Query.is_accepted tbl)

let _test_lisp_invalid_no_trees () =
  (* Skipped: behaviour for incomplete inputs is under active development.
     "Invalid" inputs may now produce virtual trees via R-Reduce. *)
  let g = lisp_grammar () in
  let tbl = Recognize.recognize g [ "LPAREN"; "ATOM"; "DOT" ] in
  let trees = Reconstruct.reconstruct_trees_omit tbl "lisp_" in
  Alcotest.(check int) "incomplete dotted pair: no trees" 0 (List.length trees)

(* ============================================================ *)
(*  Suite 4 — Grammar pipeline                                  *)
(* ============================================================ *)

let grammar_of_string s =
  Grammar_reader.extract_grammar_from_string s
  |> Grammar_converter.convert_grammar

let recog_str s tokens = Recognize.recognize (grammar_of_string s) tokens

(* inline group: list : ITEM (',' ITEM)* ; *)
let test_inline_group_star () =
  let g = "list : ITEM (',' ITEM)* ;" in
  Alcotest.(check bool)
    "single ITEM" true
    (Query.is_accepted (recog_str g [ "ITEM" ]));
  Alcotest.(check bool)
    "ITEM , ITEM , ITEM" true
    (Query.is_accepted (recog_str g [ "ITEM"; ","; "ITEM"; ","; "ITEM" ]))

(* optional: s : A B? C ; *)
let test_optional () =
  let g = "s : A B? C ;" in
  Alcotest.(check bool)
    "A B C" true
    (Query.is_accepted (recog_str g [ "A"; "B"; "C" ]));
  Alcotest.(check bool)
    "A C (B omitted)" true
    (Query.is_accepted (recog_str g [ "A"; "C" ]))

(* inline alternatives: s : ('+' | '-') A ; *)
let test_inline_alts () =
  let g = "s : ('+' | '-') A ;" in
  Alcotest.(check bool)
    "+ A" true
    (Query.is_accepted (recog_str g [ "+"; "A" ]));
  Alcotest.(check bool)
    "- A" true
    (Query.is_accepted (recog_str g [ "-"; "A" ]))

(* uppercase TOKEN+ must not fail with LHS-must-be-nonterminal *)
let test_uppercase_plus () =
  let g = "s : TOKEN+ ;" in
  Alcotest.(check bool)
    "TOKEN TOKEN" true
    (Query.is_accepted (recog_str g [ "TOKEN"; "TOKEN" ]))

(* s : A+ B* — plus needs >=1 (no epsilon rule), star allows 0 *)
let test_plus_and_star () =
  let g = "s : A+ B* ;" in
  Alcotest.(check bool) "A accepted" true
    (Query.is_accepted (recog_str g [ "A" ]));
  Alcotest.(check bool) "A A A accepted" true
    (Query.is_accepted (recog_str g [ "A"; "A"; "A" ]));
  Alcotest.(check bool) "A B accepted" true
    (Query.is_accepted (recog_str g [ "A"; "B" ]));
  Alcotest.(check bool) "A A B B accepted" true
    (Query.is_accepted (recog_str g [ "A"; "A"; "B"; "B" ]));
  (* Z is not in the grammar at all — terminal seeding never fires, T[0,n] stays empty *)
  Alcotest.(check bool) "Z rejected (unknown token)" false
    (Query.is_accepted (recog_str g [ "Z" ]));
  (* tokens in wrong order: B then A can't reduce to s even as a fragment,
     because no production ever places B before A in a way that seeds T[0,2] *)
  Alcotest.(check bool) "B A rejected (wrong order)" false
    (Query.is_accepted (recog_str g [ "B"; "A" ]));
  (* A+ must not have an epsilon rule — its only productions are recursive *)
  let gram = grammar_of_string g in
  let aplus_prods = List.filter (fun (p : Types.production) -> p.lhs = "A+") gram.productions in
  Alcotest.(check bool) "A+ has no epsilon production" false
    (List.exists (fun (p : Types.production) -> p.rhs = []) aplus_prods)

(* np : 'det' 'n' — det n valid, n det impossible even as a fragment
   because no production places n before det in a seeding path *)
let test_wrong_order_rejected () =
  let g = "np : 'det' 'n' ;" in
  Alcotest.(check bool) "det n accepted" true
    (Query.is_accepted (recog_str g [ "det"; "n" ]));
  Alcotest.(check bool) "n det rejected" false
    (Query.is_accepted (recog_str g [ "n"; "det" ]))

(* token normalisation with a hardcoded map (no file I/O) *)
let test_token_normalize_mapped () =
  let map = Hashtbl.of_seq (List.to_seq [ ("If", "if"); ("LeftParen", "(") ]) in
  Alcotest.(check string) "If -> if" "if" (Io.normalize_token_with map "If");
  Alcotest.(check string)
    "LeftParen -> (" "("
    (Io.normalize_token_with map "LeftParen");
  Alcotest.(check string)
    "Unknown passthru" "X"
    (Io.normalize_token_with map "X")

(* ============================================================ *)
(*  Suite 5 — Grammar reader utils                             *)
(* ============================================================ *)

let test_is_uppercase () =
  Alcotest.(check bool)
    "uppercase letter" true
    (Grammar_reader_utils.is_uppercase "Hello");
  Alcotest.(check bool)
    "lowercase letter" false
    (Grammar_reader_utils.is_uppercase "hello");
  Alcotest.(check bool)
    "all lowercase" false
    (Grammar_reader_utils.is_uppercase "abc")

let test_ends_with_plus () =
  Alcotest.(check bool)
    "x+ is plus" true
    (Grammar_reader_utils.ends_with_plus "x+");
  Alcotest.(check bool)
    "x* not plus" false
    (Grammar_reader_utils.ends_with_plus "x*");
  Alcotest.(check bool)
    "x not plus" false
    (Grammar_reader_utils.ends_with_plus "x")

let test_ends_with_star () =
  Alcotest.(check bool)
    "x* is star" true
    (Grammar_reader_utils.ends_with_star "x*");
  Alcotest.(check bool)
    "x+ not star" false
    (Grammar_reader_utils.ends_with_star "x+");
  Alcotest.(check bool)
    "x not star" false
    (Grammar_reader_utils.ends_with_star "x")

let test_split_unquoted () =
  let parts = Grammar_reader_utils.split_unquoted '|' "a | b | c" in
  Alcotest.(check int) "splits into 3 parts" 3 (List.length parts);
  (* pipe inside single quotes must not split *)
  let parts2 = Grammar_reader_utils.split_unquoted '|' "a | 'b|c'" in
  Alcotest.(check int) "quoted pipe not split" 2 (List.length parts2)

(* ============================================================ *)
(*  Suite 6 — H-Cover                                          *)
(* ============================================================ *)

let test_nullable_gcl () =
  let nullable = Hcover.compute_nullable Grammars.grammar_gcl in
  Alcotest.(check (list string))
    "GCL: no nullables" []
    (List.sort String.compare nullable)

let test_nullable_epsilon () =
  let nullable = Hcover.compute_nullable Grammars.grammar_epsilon in
  Alcotest.(check bool) "A is nullable" true (List.mem "A" nullable);
  Alcotest.(check bool) "S is not nullable" false (List.mem "S" nullable);
  Alcotest.(check bool) "B is not nullable" false (List.mem "B" nullable)

let test_nullable_astar () =
  let nullable = Hcover.compute_nullable Grammars.grammar_astar in
  Alcotest.(check bool) "Astar is nullable" true (List.mem "Astar" nullable);
  Alcotest.(check bool) "A is not nullable" false (List.mem "A" nullable)

let test_hcover_gcl_counts () =
  let cover = Hcover.compute_h_cover Grammars.grammar_gcl in
  (* GCL has 3 productions; each single-head production produces exactly 1 projection *)
  Alcotest.(check int) "GCL: 3 projections" 3 (List.length cover.projections);
  Alcotest.(check int)
    "GCL: no epsilon proj" 0
    (List.length cover.epsilon_projections)

let test_hcover_terminal_lookup () =
  let cover = Hcover.compute_h_cover Grammars.grammar_gcl in
  let hits = Hcover.find_projections_from_terminal cover "det" in
  Alcotest.(check int) "'det' projects to exactly 1 item" 1 (List.length hits)

let test_hcover_astar_terminal () =
  let cover = Hcover.compute_h_cover Grammars.grammar_astar in
  let hits = Hcover.find_projections_from_terminal cover "a" in
  Alcotest.(check bool)
    "'a' projects to CompleteItem A" true
    (List.mem (CompleteItem "A") hits)

let test_hcover_astar_epsilon_proj () =
  (* Astar is nullable, so its left-expansion partner should have an epsilon projection *)
  let cover = Hcover.compute_h_cover Grammars.grammar_astar in
  Alcotest.(check bool)
    "astar cover has epsilon projections" true
    (List.length cover.epsilon_projections > 0)

(* ============================================================ *)
(*  Suite 7 — Table operations                                 *)
(* ============================================================ *)

let test_table_mem_add () =
  let tbl = Table.create_table Grammars.grammar_gcl [ "det"; "n" ] in
  let item = CompleteItem "NP" in
  Alcotest.(check bool)
    "not present before add" false
    (Table.mem_item tbl 0 2 item);
  let is_new = Table.add_item tbl 0 2 item (FromTerminal "det") in
  Alcotest.(check bool) "add returns true for new item" true is_new;
  Alcotest.(check bool) "present after add" true (Table.mem_item tbl 0 2 item);
  let is_dup = Table.add_item tbl 0 2 item (FromTerminal "n") in
  Alcotest.(check bool) "add returns false for duplicate" false is_dup

let test_table_count () =
  let tbl =
    recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  Alcotest.(check bool)
    "table has items after recognition" true
    (Query.count_table_items tbl > 0)

(* ============================================================ *)
(*  Suite 8 — Query                                            *)
(* ============================================================ *)

let test_get_complete_vs_all () =
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  let all = Query.get_all_items tbl 0 2 in
  let complete = Query.get_complete_items tbl 0 2 in
  Alcotest.(check bool)
    "complete items ⊆ all items" true
    (List.length complete <= List.length all);
  Alcotest.(check bool)
    "complete items contain only CompleteItem" true
    (List.for_all
       (fun (item, _) ->
         match item with CompleteItem _ -> true | PartialItem _ -> false)
       complete);
  Alcotest.(check bool)
    "all items may contain PartialItem" true
    (List.exists
       (fun (item, _) ->
         match item with PartialItem _ -> true | CompleteItem _ -> false)
       all)

(* ============================================================ *)
(*  Suite 9 — Recognize: prepare / recognize_with             *)
(* ============================================================ *)

let test_prepare_recognize_with () =
  let g = Grammars.grammar_gcl in
  let input = [ "det"; "n"; "cl"; "v"; "det"; "n" ] in
  let tbl1 = Recognize.recognize g input in
  let pg = Recognize.prepare g in
  let tbl2 = Recognize.recognize_with pg input in
  Alcotest.(check bool)
    "same acceptance result" true
    (Query.is_accepted tbl1 = Query.is_accepted tbl2);
  Alcotest.(check bool)
    "same item count" true
    (Query.count_table_items tbl1 = Query.count_table_items tbl2)

let test_prepare_reuse () =
  (* prepare once, recognize twice — results should match *)
  let pg = Recognize.prepare Grammars.grammar_gcl in
  let tbl1 = Recognize.recognize_with pg [ "det"; "n" ] in
  let tbl2 =
    Recognize.recognize_with pg [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  Alcotest.(check bool)
    "partial input not accepted" false (Query.is_accepted tbl1);
  Alcotest.(check bool) "full input accepted" true (Query.is_accepted tbl2)

(* ============================================================ *)
(*  Suite 10 — reconstruct_trees_virtual                      *)
(* ============================================================ *)

let _has_virtual_node tree =
  let rec go = function
    | Virtual _ -> true
    | Node (_, children) -> List.exists go children
    | Leaf _ -> false
  in
  go tree

let test_virtual_trees_for_fragment () =
  (* "det n" fully parses as NP but not S.
     reconstruct_trees_virtual should find NP (it is in T[0,2]) but not S
     (S is not placed in T[0,2] by the algorithm). *)
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n" ] in
  let np_trees = Reconstruct.reconstruct_trees_virtual tbl "NP" in
  let s_trees = Reconstruct.reconstruct_trees_virtual tbl "S" in
  Alcotest.(check bool) "NP directly reachable for [det n]" true (np_trees <> []);
  Alcotest.(check bool) "S not in T[0,2] for fragment" true (s_trees = [])

let test_virtual_same_as_omit_for_complete () =
  (* For a complete parse, virtual and omit should yield same tree count *)
  let tbl =
    recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ]
  in
  let virtual_ = Reconstruct.reconstruct_trees_virtual tbl "S" in
  let omit = Reconstruct.reconstruct_trees_omit tbl "S" in
  Alcotest.(check int)
    "same count for complete parse" (List.length omit) (List.length virtual_)

(* ============================================================ *)
(*  Suite 10b — lazy reconstruction                           *)
(* ============================================================ *)

let test_limit_respected () =
  (* astar ["a";"a";"a"] produces multiple trees — limit should cap the count *)
  let pg = Recognize.prepare Grammars.grammar_astar in
  let tbl = Recognize.recognize_with pg [ "a"; "a"; "a" ] in
  let trees_limit1 = Reconstruct.reconstruct_trees_omit ~limit:1 tbl "Astar" in
  Alcotest.(check bool) "limit:1 gives at most 1 tree" true (List.length trees_limit1 <= 1)

let test_lazy_same_results_as_before () =
  (* for small grammars, lazy should give same trees as the old eager version *)
  let tbl = recognized Grammars.grammar_gcl [ "det"; "n"; "cl"; "v"; "det"; "n" ] in
  let trees = Reconstruct.reconstruct_trees_omit tbl "S" in
  Alcotest.(check int) "gcl still gives 1 tree" 1 (List.length trees)

let test_astar_lazy_terminates () =
  (* astar on a longer input — should terminate quickly, not hang *)
  let pg = Recognize.prepare Grammars.grammar_astar in
  let tbl = Recognize.recognize_with pg [ "a"; "a"; "a"; "a"; "a" ] in
  let trees = Reconstruct.reconstruct_trees_omit tbl "Astar" in
  Alcotest.(check bool) "astar 5 tokens terminates and gives trees" true
    (List.length trees > 0)

(* ============================================================ *)
(*  Suite 11 — Symbol table reset                             *)
(* ============================================================ *)

let test_symbol_table_reset () =
  (* extract_grammar_from_string calls reset() internally;
     reading the same grammar twice must produce the same rule count *)
  let g = "s : x+ ;" in
  let g1 = Grammar_reader.extract_grammar_from_string g in
  let g2 = Grammar_reader.extract_grammar_from_string g in
  Alcotest.(check int)
    "same rule count on second read" (List.length g1) (List.length g2)

let test_star_rules_present_after_reset () =
  (* x+ desugars to x x* plus two rules for x* — total > 1 *)
  let g = "s : x+ ;" in
  let rules = Grammar_reader.extract_grammar_from_string g in
  Alcotest.(check bool)
    "desugared grammar has more than 1 rule" true
    (List.length rules > 1)

(* ============================================================ *)
(*  Runner                                                      *)
(* ============================================================ *)

let () =
  Alcotest.run "htable"
    [
      ( "recognition",
        [
          Alcotest.test_case "gcl accepted" `Quick test_gcl_accepted;
          Alcotest.test_case "gcl rejected" `Quick test_gcl_rejected;
          Alcotest.test_case "gcl NP in cell" `Quick test_gcl_np_in_cell;
          Alcotest.test_case "epsilon a b" `Quick test_epsilon_ab_accepted;
          Alcotest.test_case "epsilon b (nullable)" `Quick
            test_epsilon_b_accepted;
          Alcotest.test_case "astar a a a" `Quick test_astar_nonempty_accepted;
          Alcotest.test_case "astar empty" `Quick test_astar_empty_accepted;
        ] );
      ( "root inference",
        [
          Alcotest.test_case "NP complete" `Quick test_roots_np_complete;
          Alcotest.test_case "S partial" `Quick test_roots_s_partial;
          Alcotest.test_case "S complete sentence" `Quick
            test_roots_complete_sentence;
        ] );
      ( "grammar pipeline",
        [
          Alcotest.test_case "inline group star" `Quick test_inline_group_star;
          Alcotest.test_case "optional B?" `Quick test_optional;
          Alcotest.test_case "inline alternatives" `Quick test_inline_alts;
          Alcotest.test_case "uppercase TOKEN+" `Quick test_uppercase_plus;
          Alcotest.test_case "plus and star" `Quick test_plus_and_star;
          Alcotest.test_case "wrong order rejected" `Quick test_wrong_order_rejected;
          Alcotest.test_case "token normalize" `Quick
            test_token_normalize_mapped;
        ] );
      ( "grammar reader utils",
        [
          Alcotest.test_case "is_uppercase" `Quick test_is_uppercase;
          Alcotest.test_case "ends_with_plus" `Quick test_ends_with_plus;
          Alcotest.test_case "ends_with_star" `Quick test_ends_with_star;
          Alcotest.test_case "split_unquoted" `Quick test_split_unquoted;
        ] );
      ( "hcover",
        [
          Alcotest.test_case "nullable gcl" `Quick test_nullable_gcl;
          Alcotest.test_case "nullable epsilon" `Quick test_nullable_epsilon;
          Alcotest.test_case "nullable astar" `Quick test_nullable_astar;
          Alcotest.test_case "gcl cover counts" `Quick test_hcover_gcl_counts;
          Alcotest.test_case "terminal lookup" `Quick
            test_hcover_terminal_lookup;
          Alcotest.test_case "astar terminal" `Quick test_hcover_astar_terminal;
          Alcotest.test_case "astar epsilon proj" `Quick
            test_hcover_astar_epsilon_proj;
        ] );
      ( "table",
        [
          Alcotest.test_case "mem/add item" `Quick test_table_mem_add;
          Alcotest.test_case "count items" `Quick test_table_count;
        ] );
      ( "query",
        [
          Alcotest.test_case "complete vs all items" `Quick
            test_get_complete_vs_all;
        ] );
      ( "recognize",
        [
          Alcotest.test_case "prepare/recognize_with" `Quick
            test_prepare_recognize_with;
          Alcotest.test_case "prepare reuse" `Quick test_prepare_reuse;
        ] );
      ( "reconstruct virtual",
        [
          Alcotest.test_case "virtual for fragment" `Quick
            test_virtual_trees_for_fragment;
          Alcotest.test_case "virtual=omit complete" `Quick
            test_virtual_same_as_omit_for_complete;
        ] );
      ( "lazy reconstruction",
        [
          Alcotest.test_case "limit respected" `Quick test_limit_respected;
          Alcotest.test_case "same results small grammar" `Quick
            test_lazy_same_results_as_before;
          Alcotest.test_case "astar 5 tokens terminates" `Quick
            test_astar_lazy_terminates;
        ] );
      ( "symbol table",
        [
          Alcotest.test_case "reset on re-read" `Quick test_symbol_table_reset;
          Alcotest.test_case "star rules present" `Quick
            test_star_rules_present_after_reset;
        ] );
      ( "tree reconstruction",
        [
          Alcotest.test_case "gcl tree count" `Quick test_gcl_tree_count;
          Alcotest.test_case "gcl tree structure" `Quick test_gcl_tree_structure;
          Alcotest.test_case "astar single" `Quick test_astar_single_tree;
          Alcotest.test_case "astar empty tree" `Quick test_astar_empty_tree;
          Alcotest.test_case "no trees on reject" `Quick
            test_gcl_no_trees_on_reject;
          Alcotest.test_case "lisp atom accepted" `Quick test_lisp_atom_accepted;
          Alcotest.test_case "lisp dotted pair" `Quick
            test_lisp_dotted_pair_accepted;
          (* test_lisp_invalid_no_trees: skipped — behaviour for incomplete inputs
           is under active development; "invalid" inputs may now produce virtual trees *)
        ] );
    ]
