(* Expands inline grouped alternatives in g4-style grammars to plain CFG rules.

   Handles:
     (A B C)    -> grpN_ : A B C
     (A B C)*   -> grpN_*   (star desugared later)
     (A B C)+   -> grpN_+   (plus desugared later)
     (A B C)?   -> grpN_    where grpN_ : A B C | epsilon
     (A | B | C) with any suffix

   Also normalises single-token optionals before expanding groups:
     x?         -> (x)?
     'tok'?     -> ('tok')?
*)

let counter = ref 0
let reset () = counter := 0

let fresh () =
  let n = !counter in
  incr counter;
  Printf.sprintf "grp%d_" n

(* ------------------------------------------------------------------ *)
(* Low-level string scanners that respect single-quoted strings        *)
(* ------------------------------------------------------------------ *)

(* Find the next unquoted '(' from position start. Returns Some idx or None. *)
let find_open (s : string) (start : int) : int option =
  let n = String.length s in
  let i = ref start in
  let result = ref None in
  while !i < n && !result = None do
    if s.[!i] = '\'' then (
      incr i;
      while !i < n && s.[!i] <> '\'' do
        incr i
      done;
      if !i < n then incr i)
    else if s.[!i] = '(' then result := Some !i
    else incr i
  done;
  !result

(* Find the matching unquoted ')'. [start] points just after the opening '('. *)
let find_close (s : string) (start : int) : int =
  let n = String.length s in
  let depth = ref 1 in
  let i = ref start in
  while !depth > 0 do
    if !i >= n then failwith "grammar_expander: unmatched '('";
    if s.[!i] = '\'' then (
      incr i;
      while !i < n && s.[!i] <> '\'' do
        incr i
      done;
      if !i < n then incr i)
    else
      match s.[!i] with
      | '(' ->
          incr depth;
          incr i
      | ')' ->
          decr depth;
          if !depth > 0 then incr i
      | _ -> incr i
  done;
  !i

(* Split on top-level '|', respecting paren depth and single-quoted strings. *)
let split_alts (s : string) : string list =
  let n = String.length s in
  let depth = ref 0 in
  let parts = ref [] in
  let buf = Buffer.create 32 in
  let i = ref 0 in
  while !i < n do
    if s.[!i] = '\'' then (
      Buffer.add_char buf '\'';
      incr i;
      while !i < n && s.[!i] <> '\'' do
        Buffer.add_char buf s.[!i];
        incr i
      done;
      if !i < n then (
        Buffer.add_char buf '\'';
        incr i))
    else
      match s.[!i] with
      | '(' ->
          incr depth;
          Buffer.add_char buf '(';
          incr i
      | ')' ->
          decr depth;
          Buffer.add_char buf ')';
          incr i
      | '|' when !depth = 0 ->
          parts := String.trim (Buffer.contents buf) :: !parts;
          Buffer.clear buf;
          incr i
      | c ->
          Buffer.add_char buf c;
          incr i
  done;
  let last = String.trim (Buffer.contents buf) in
  List.rev (if last = "" then !parts else last :: !parts)

(* ------------------------------------------------------------------ *)
(* Single-token ? normalisation pass                                   *)
(* ------------------------------------------------------------------ *)

let is_ident_char c =
  (c >= 'a' && c <= 'z')
  || (c >= 'A' && c <= 'Z')
  || (c >= '0' && c <= '9')
  || c = '_'

(* Convert every x? and 'tok'? into (x)? and ('tok')? so the main
   expand loop can handle them uniformly. *)
let normalize_optionals (s : string) : string =
  let n = String.length s in
  let buf = Buffer.create n in
  let i = ref 0 in
  while !i < n do
    if s.[!i] = '\'' then (
      (* Collect quoted token *)
      let start = !i in
      incr i;
      while !i < n && s.[!i] <> '\'' do
        incr i
      done;
      if !i < n then incr i;
      let tok = String.sub s start (!i - start) in
      if !i < n && s.[!i] = '?' then (
        Buffer.add_char buf '(';
        Buffer.add_string buf tok;
        Buffer.add_char buf ')';
        Buffer.add_char buf '?';
        incr i)
      else Buffer.add_string buf tok)
    else if is_ident_char s.[!i] then (
      (* Collect identifier *)
      let start = !i in
      while !i < n && is_ident_char s.[!i] do
        incr i
      done;
      let ident = String.sub s start (!i - start) in
      if !i < n && s.[!i] = '?' then (
        Buffer.add_char buf '(';
        Buffer.add_string buf ident;
        Buffer.add_char buf ')';
        Buffer.add_char buf '?';
        incr i)
      else Buffer.add_string buf ident)
    else (
      Buffer.add_char buf s.[!i];
      incr i)
  done;
  Buffer.contents buf

(* ------------------------------------------------------------------ *)
(* Main expansion loop                                                 *)
(* ------------------------------------------------------------------ *)

let make_rule (name : string) (alts : string list) : string =
  match alts with
  | [] -> Printf.sprintf "\n%s\n    : epsilon\n    ;" name
  | _ ->
      Printf.sprintf "\n%s\n    : %s\n    ;" name
        (String.concat "\n    | " alts)

let rec expand_groups (s : string) : string =
  match find_open s 0 with
  | None -> s
  | Some pos ->
      let close = find_close s (pos + 1) in
      let content = String.sub s (pos + 1) (close - pos - 1) in
      let after = close + 1 in
      let name = fresh () in
      let suffix, end_pos, new_rule =
        if after < String.length s then
          match s.[after] with
          | ('*' | '+') as c ->
              (String.make 1 c, after + 1, make_rule name (split_alts content))
          | '?' ->
              (* desugar ? by adding epsilon alternative *)
              let alts = split_alts content @ [ "epsilon" ] in
              ("", after + 1, make_rule name alts)
          | _ -> ("", after, make_rule name (split_alts content))
        else ("", after, make_rule name (split_alts content))
      in
      let before = String.sub s 0 pos in
      let rest = String.sub s end_pos (String.length s - end_pos) in
      expand_groups (before ^ name ^ suffix ^ rest ^ new_rule)

let expand (s : string) : string = s |> normalize_optionals |> expand_groups
