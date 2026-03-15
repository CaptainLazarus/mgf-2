open Types
open Print
open Recognize
open Query
open Reconstruct

let print_trees ?grammar ?(mode="omit") tbl nt =
  let trees =
    if mode = "virtual" then reconstruct_trees_virtual tbl nt
    else reconstruct_trees_omit tbl nt
  in
  let n = List.length trees in
  Printf.printf "+-- Parse Trees for %s (%s mode) %s+\n" nt mode
    (String.make (max 0 (27 - String.length nt - String.length mode)) '-');
  if n = 0 then
    Printf.printf "| No trees (input not accepted as %s)\n" nt
  else if n = 1 then (
    Printf.printf "| 1 parse tree:\n|\n";
    print_tree ?grammar (List.hd trees))
  else (
    Printf.printf "| AMBIGUOUS: %d parse trees:\n" n;
    List.iteri (fun i tree ->
      Printf.printf "|\n| Tree %d:\n" (i + 1);
      print_tree ?grammar tree)
      trees);
  Printf.printf "+%s+\n" (String.make 60 '-')

let print_result tbl =
  let accepted = is_accepted tbl in
  Printf.printf "+-- Result %s+\n" (String.make 50 '-');
  if accepted then
    Printf.printf "| ACCEPTED: I_%s found in T[0,%d]\n" tbl.grammar.start tbl.n
  else (
    Printf.printf "| REJECTED: I_%s not in T[0,%d]\n" tbl.grammar.start tbl.n;
    let complete = get_complete_items tbl 0 tbl.n in
    if complete <> [] then (
      Printf.printf "| But found these complete items at T[0,%d]:\n" tbl.n;
      List.iter
        (fun (it, _) -> Printf.printf "|   %s\n" (string_of_h_item it))
        complete));
  Printf.printf "+%s+\n" (String.make 60 '-')

let run_and_print g input =
  Printf.printf "\n";
  Printf.printf "============================================================\n";
  Printf.printf
    "                    RECOGNITION TEST                         \n";
  Printf.printf
    "============================================================\n\n";

  (* print_grammar g;
  print_newline (); *)

  let tbl = recognize g input in

  (* print_cover_summary tbl.cover;
  print_newline (); *)

  print_visual_table tbl;

  (* print_cell_details tbl;
  print_newline ();

  print_result tbl;
  print_newline (); *)

  tbl

