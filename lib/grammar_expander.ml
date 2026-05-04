(* Expands inline grouped alternatives in g4-style grammars to plain CFG rules.

   Handles:
     (A B C)*   -> grpN_*   (star desugared later)
     (A B C)+   -> grpN_+   (plus desugared later)
     (A B C)?   -> grpN_    where grpN_ -> A B C | epsilon
     (A | B | C) with no suffix -> inlined as multiple parent alternatives
       e.g. x (A | B) y -> x A y  and  x B y

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

let normalize_optionals (s : string) : string =
  let n = String.length s in
  let buf = Buffer.create n in
  let i = ref 0 in
  while !i < n do
    if s.[!i] = '\'' then (
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
(* Group expansion                                                     *)
(* ------------------------------------------------------------------ *)

(* Expand groups within a single RHS alternative string.
   Returns:
     - list of expanded alternative strings (multiple when inline alts are inlined)
     - list of (name, alternatives) pairs for new synthetic rules needed *)
let rec expand_alt (s : string) : string list * (string * string list) list =
  let s = normalize_optionals s in
  match find_open s 0 with
  | None -> ([ String.trim s ], [])
  | Some pos ->
      let close = find_close s (pos + 1) in
      let content = String.sub s (pos + 1) (close - pos - 1) in
      let after_pos = close + 1 in
      let before = String.sub s 0 pos in
      let len = String.length s in
      let suffix = if after_pos < len then Some s.[after_pos] else None in
      (match suffix with
      | Some ('*' | '+' as c) ->
          let name = fresh () in
          let rest = String.sub s (after_pos + 1) (len - after_pos - 1) in
          let alts = List.map String.trim (split_alts content) in
          let main_exp, main_new =
            expand_alt (before ^ name ^ String.make 1 c ^ rest)
          in
          (main_exp, (name, alts) :: main_new)
      | Some '?' ->
          let name = fresh () in
          let rest = String.sub s (after_pos + 1) (len - after_pos - 1) in
          let alts = List.map String.trim (split_alts content) @ [ "epsilon" ] in
          let main_exp, main_new = expand_alt (before ^ name ^ rest) in
          (main_exp, (name, alts) :: main_new)
      | _ ->
          (* No suffix: inline-expand, duplicating the parent alternative *)
          let alts = List.map String.trim (split_alts content) in
          let rest = String.sub s after_pos (len - after_pos) in
          List.fold_left
            (fun (acc_exp, acc_new) alt ->
              let exp, new_r = expand_alt (before ^ alt ^ rest) in
              (acc_exp @ exp, acc_new @ new_r))
            ([], []) alts)
