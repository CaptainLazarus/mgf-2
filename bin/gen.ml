open Practice
open Domain_types

let () = Random.self_init ()

let identifiers = [| "x"; "y"; "z"; "n"; "ptr"; "val"; "buf"; "len"; "i"; "count" |]
let integers    = [| "0"; "1"; "2"; "42"; "100"; "255" |]

let terminal_value = function
  | "Identifier"        -> identifiers.(Random.int (Array.length identifiers))
  | "IntegerConstant"   -> integers.(Random.int (Array.length integers))
  | "FloatingConstant"  -> "3.14"
  | "CharacterConstant" -> "'a'"
  | "StringLiteral"     -> "hello_str"
  | "DigitSequence"     -> "0"
  | t                   -> t

let build_index (g : grammar) : (string, production_rule list) Hashtbl.t =
  let tbl = Hashtbl.create 128 in
  List.iter (fun r ->
    match r.lhs with
    | NonTerminal nt ->
      let prev = try Hashtbl.find tbl nt with Not_found -> [] in
      Hashtbl.replace tbl nt (r :: prev)
    | _ -> ()
  ) g;
  tbl

(* Productions where every RHS symbol is a terminal/epsilon — one-level lookahead *)
let terminal_only prods =
  List.filter (fun r ->
    List.for_all (fun s -> match s with
      | Terminal _ | Epsilon | EOF -> true
      | NonTerminal _ -> false
    ) r.rhs
  ) prods

type tree =
  | Node of string * tree list
  | Leaf of string

let rec print_tree indent t =
  match t with
  | Leaf s -> Printf.printf "%s%s\n" indent s
  | Node (name, children) ->
    Printf.printf "%s%s\n" indent name;
    List.iter (print_tree (indent ^ "  ")) children

let generate index start_nt max_depth =
  let tokens = Buffer.create 256 in
  let rec expand nt depth =
    match Hashtbl.find_opt index nt with
    | None -> Node (nt, [])
    | Some prods ->
      let candidates =
        if depth >= max_depth then
          (* at depth limit: prefer productions with only terminals *)
          let fin = terminal_only prods in
          if fin = [] then prods else fin
        else prods
      in
      let rule = List.nth candidates (Random.int (List.length candidates)) in
      let children = List.filter_map (expand_sym (depth + 1)) rule.rhs in
      Node (nt, children)
  and expand_sym depth s = match s with
    | Terminal t ->
      let v = terminal_value t in
      Buffer.add_string tokens v;
      Buffer.add_char tokens ' ';
      Some (Leaf v)
    | NonTerminal nt -> Some (expand nt depth)
    | Epsilon | EOF  -> None
  in
  let tree = expand start_nt 0 in
  (Buffer.contents tokens, tree)

let usage () =
  Printf.eprintf "Usage: gen [<start_nt> [<max_depth>]]\n";
  exit 1

let () =
  let grammar  = "grammars/cparser.g4" |> Grammar_reader.extract_grammar in
  let index    = build_index grammar in
  let all_nts  = Hashtbl.fold (fun nt _ acc -> nt :: acc) index []
                 |> List.sort_uniq String.compare in
  let start_nt, max_depth =
    match Array.length Sys.argv with
    | 1 -> List.nth all_nts (Random.int (List.length all_nts)), 5
    | 2 -> Sys.argv.(1), 5
    | 3 -> Sys.argv.(1), (try int_of_string Sys.argv.(2) with _ -> usage ())
    | _ -> usage ()
  in
  if not (Hashtbl.mem index start_nt) then begin
    Printf.eprintf "Unknown nonterminal: %s\n" start_nt;
    exit 1
  end;
  let code, tree = generate index start_nt max_depth in
  Printf.printf "// gen: %s depth=%d\n%s\n" start_nt max_depth code;
  Printf.printf "-- derivation tree --\n";
  print_tree "" tree;
  (* Write tokens to stdin.c *)
  let oc = open_out "grammars/stdin.c" in
  Printf.fprintf oc "// gen: %s depth=%d\n%s\n" start_nt max_depth code;
  close_out oc;
  (* Write tree to gen_tree.txt *)
  let ot = open_out "grammars/gen_tree.txt" in
  let rec write_tree indent = function
    | Leaf s -> Printf.fprintf ot "%s%s\n" indent s
    | Node (name, children) ->
      Printf.fprintf ot "%s%s\n" indent name;
      List.iter (write_tree (indent ^ "  ")) children
  in
  write_tree "" tree;
  close_out ot;
  Printf.printf "-> written to grammars/stdin.c and grammars/gen_tree.txt\n"
