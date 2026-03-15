(* RULE READER *)
let first_word (line : string) =
  line
  |> String.trim
  |> String.split_on_char ' '
  |> List.find_opt (fun token -> token <> "")
  |> Option.value ~default:""
;;

(* This only checks if the first character is uppercase. 
  Assumption : ANTLR grammar files only have no mixed case LHS productions *)
let is_uppercase (s : string) : bool =
  String.length s > 0 && Char.uppercase_ascii s.[0] = s.[0]
;;

let starts_with_single_quote (s : string) : bool = String.length s > 0 && s.[0] = '\''

let starts_with_single_quote_or_is_uppercase (s : string) : bool =
  List.exists (fun f -> f s) [ is_uppercase; starts_with_single_quote ]
;;

(* Skip lines until a lone semicolon is found *)
let rec discard_rule (xs : string list) : string list =
  match xs with
  | [] -> []
  | x :: xs' -> if x |> String.trim <> ";" then discard_rule xs' else xs'
;;

(*
   based on g4 file semantics. grammar, fragment and lexer lines are skipped. Only parser rules matter
*)
let is_parse_rule (s : string) : bool =
  let word = first_word s in
  match word with
  | "" | " " | "grammar" | "fragment" -> false
  | _ -> not (is_uppercase word)
;;

let ends_with_plus s =
  let n = String.length s in
  n > 1 && s.[n - 1] = '+' && s.[0] <> '\''

let ends_with_star s =
  let n = String.length s in
  n > 1 && s.[n - 1] = '*' && s.[0] <> '\''

(* Split [s] on every unquoted occurrence of [c] (not inside single quotes). *)
let split_unquoted (c : char) (s : string) : string list =
  let n = String.length s in
  let parts = ref [] in
  let buf = Buffer.create 64 in
  let i = ref 0 in
  while !i < n do
    if s.[!i] = '\'' then begin
      Buffer.add_char buf '\''; incr i;
      while !i < n && s.[!i] <> '\'' do
        Buffer.add_char buf s.[!i]; incr i
      done;
      if !i < n then (Buffer.add_char buf '\''; incr i)
    end else if s.[!i] = c then begin
      parts := Buffer.contents buf :: !parts;
      Buffer.clear buf;
      incr i
    end else begin
      Buffer.add_char buf s.[!i];
      incr i
    end
  done;
  List.rev (Buffer.contents buf :: !parts)

(* Split [s] on the first unquoted occurrence of [c]. *)
let split_first_unquoted (c : char) (s : string) : (string * string) option =
  let n = String.length s in
  let i = ref 0 in
  let found = ref None in
  while !i < n && !found = None do
    if s.[!i] = '\'' then begin
      incr i;
      while !i < n && s.[!i] <> '\'' do incr i done;
      if !i < n then incr i
    end else if s.[!i] = c then
      found := Some !i
    else
      incr i
  done;
  match !found with
  | None     -> None
  | Some pos ->
    let lhs = String.sub s 0 pos in
    let rhs = String.sub s (pos + 1) (n - pos - 1) in
    Some (lhs, rhs)
