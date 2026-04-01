open Domain_types
open Symbol_table
open Grammar_reader_utils

(* FILE READING *)
let read_file path =
  let ic = open_in path in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  content

(* Also trims the final string. *)
let remove_comments (input : string) : string =
  let re_block = Str.regexp "/\\*\\(.\\|\n\\)*?\\*/" in
  let re_line = Str.regexp "//.*" in
  input
  |> Str.global_replace re_block ""
  |> Str.global_replace re_line ""
  |> String.trim

(* Scan a token list for [token], strip the brackets, and return the cleaned
   list plus the 1-based position of the head token (or None if absent). *)
let extract_head_marker (tokens : string list) : string list * int option =
  let rec go acc i = function
    | [] -> (List.rev acc, None)
    | tok :: rest ->
        let n = String.length tok in
        if n >= 2 && tok.[0] = '[' && tok.[n - 1] = ']' then
          let inner = String.sub tok 1 (n - 2) in
          (List.rev_append acc (inner :: rest), Some (i + 1))
        else go (tok :: acc) (i + 1) rest
  in
  go [] 0 tokens

(* Each x+ before the head expands to x x*, shifting the head rightward by 1. *)
let adjust_head_for_plus (tokens : string list) (raw_pos : int) : int =
  let n_plus_before =
    List.length
      (List.filteri (fun i tok -> i < raw_pos - 1 && ends_with_plus tok) tokens)
  in
  raw_pos + n_plus_before

let expand_production (production_rules : (string * string list) list) =
  let rec expand_rhs_helper lhs rhs acc =
    match rhs with
    | [] -> acc
    | x :: xs ->
        let raw_tokens =
          String.split_on_char ' ' x |> List.map String.trim
          |> List.filter (fun s -> s <> "")
        in
        let tokens, head_raw = extract_head_marker raw_tokens in
        let head_opt = Option.map (adjust_head_for_plus tokens) head_raw in
        expand_rhs_helper lhs xs ((lhs, tokens, head_opt) :: acc)
  in
  let expand_rhs (production_rule : string * string list) acc =
    match production_rule with lhs, rhs -> expand_rhs_helper lhs rhs acc
  in
  let rec expand_production_helper
      (production_rules : (string * string list) list) acc =
    match production_rules with
    | [] -> List.rev acc
    | x :: xs -> expand_production_helper xs (expand_rhs x acc)
  in
  expand_production_helper production_rules []

let convert_to_symbol (s : string) : symbol =
  let n = String.length s in
  (* Generated star-rule names like StringLiteral_star must be NonTerminal
     even when the base name starts uppercase. *)
  if n > 0 && s.[n - 1] = '*' then NonTerminal s
  else if starts_with_single_quote_or_is_uppercase s then
    if starts_with_single_quote s then
      Terminal (String.sub s 1 (String.length s - 2))
    else Terminal s
  else if s = "epsilon" then Epsilon
  else if s = "EOF" then EOF
  else NonTerminal s

let convert_to_production (prod : string) : symbol list =
  String.split_on_char ' ' prod |> List.map (fun s -> convert_to_symbol s)

let filter_content (content : string) : string list =
  content |> split_unquoted ';' |> List.filter is_parse_rule

let split_rules (parse_rules : string list) : (string * string) list =
  parse_rules
  |> List.filter_map (fun x ->
         match split_first_unquoted ':' x with
         | None -> None
         | Some (l, r) -> Some (l, r))

let split_rhs (production_rules : (string * string) list) :
    (string * string list) list =
  production_rules
  |> List.map (fun x ->
         ( String.trim (fst x),
           split_unquoted '|' (snd x) |> List.map String.trim ))

let convert_plus_to_star (q : (string * string list * int option) Queue.t)
    (s : string) : string list =
  let base = String.sub s 0 (String.length s - 1) in
  let base_star = base ^ "*" in
  if not (has_seen base_star) then (
    mark_seen base_star;
    Queue.add (base_star, [ base; base_star ], None) q;
    Queue.add (base_star, [ "epsilon" ], None) q);
  [ base; base ^ "*" ]

(* x* appears directly in input (e.g. from inline-group expansion).
   Generates: x* : x x* | epsilon  and returns [x*]. *)
let convert_star_rule (q : (string * string list * int option) Queue.t)
    (s : string) : string list =
  if not (has_seen s) then (
    mark_seen s;
    let base = String.sub s 0 (String.length s - 1) in
    Queue.add (s, [ base; s ], None) q;
    Queue.add (s, [ "epsilon" ], None) q);
  [ s ]

let desugar_rhs (q : (string * string list * int option) Queue.t)
    (rhs : string list) : symbol list =
  let rec go acc = function
    | [] -> List.rev acc
    | x :: xs ->
        let expanded =
          if ends_with_plus x then convert_plus_to_star q x
          else if ends_with_star x then convert_star_rule q x
          else [ x ]
        in
        go (List.rev_append expanded acc) xs
  in
  go [] rhs |> List.map convert_to_symbol

let rec process_queue (q : (string * string list * int option) Queue.t)
    (acc : (symbol * symbol list * int option) list) =
  if Queue.is_empty q then List.rev acc
  else
    let lhs, rhs, head_opt = Queue.take q in
    let prod = (convert_to_symbol lhs, desugar_rhs q rhs, head_opt) in
    process_queue q (prod :: acc)

let desugar_production_strings
    (production_tuples : (string * string list * int option) list) :
    (symbol * symbol list * int option) list =
  let q = Queue.create () in
  Queue.add_seq q (List.to_seq production_tuples);
  process_queue q []

let convert_to_grammar (xs : (symbol * symbol list * int option) list) : grammar
    =
  xs
  |> List.map (fun (lhs, rhs, head_opt) ->
         { lhs; rhs; head_pos = Option.value ~default:0 head_opt })

(* Currentyl reading as a string -> list. Should go from string -> graph. Is muchh safer and easier*)

let extract_grammar_from_string (content : string) =
  reset ();
  Grammar_expander.reset ();
  content
  (* Strip lexer rules before expanding so group rules from lexer bodies
     don't leak in as parser rules. *)
  |> filter_content
  |> List.map (fun r -> r ^ " ;")
  |> String.concat "\n" |> Grammar_expander.expand |> split_unquoted ';'
  |> List.filter is_parse_rule |> split_rules |> split_rhs |> expand_production
  |> desugar_production_strings |> convert_to_grammar

let extract_grammar (file : string) =
  read_file file |> remove_comments |> extract_grammar_from_string
