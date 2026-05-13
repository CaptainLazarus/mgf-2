open Yojson.Basic.Util

(* Tokens that cparser.g4 uses as bare uppercase names (e.g. While, Do, For).
   These already match CLexer output directly and must NOT be remapped. *)
let bare_in_grammar =
  [
    "While";
    "Do";
    "For";
    "Bool";
    "Inline";
    "Restrict";
    "Volatile";
    "ThreadLocal";
    "Typeof";
    "Typeof_unqual";
    "Alignas";
    "Alignof";
    "Countof";
    "Maxof";
    "Minof";
    "Asm";
    "Attribute";
    "Label";
    "Identifier";
    "IntegerConstant";
    "FloatingConstant";
    "CharacterConstant";
    "StringLiteral";
    "DigitSequence";
    "EOF";
  ]

(* Parse CLexer.tokens to build: CLexer-name -> grammar-literal.
   Lines 'literal'=N give the grammar form; lines Name=N give the CLexer name.
   We build Name -> literal so CLexer output can be matched against the grammar. *)
let build_clexer_map (path : string) : (string, string) Hashtbl.t =
  let by_num = Hashtbl.create 64 in
  let literals = ref [] in
  let ic = open_in path in
  (try
     while true do
       let line = String.trim (input_line ic) in
       if line <> "" then
         match String.rindex_opt line '=' with
         | None -> ()
         | Some eq ->
             let key = String.sub line 0 eq in
             let num = String.sub line (eq + 1) (String.length line - eq - 1) in
             let n = String.length key in
             if n >= 3 && key.[0] = '\'' && key.[n - 1] = '\'' then
               let lit = String.sub key 1 (n - 2) in
               literals := (num, lit) :: !literals
             else if n > 0 && key.[0] <> '\'' then
               Hashtbl.replace by_num num key
     done
   with End_of_file -> ());
  close_in ic;
  let result = Hashtbl.create 64 in
  List.iter
    (fun (num, lit) ->
      match Hashtbl.find_opt by_num num with
      | Some name when not (List.mem name bare_in_grammar) ->
          Hashtbl.replace result name lit
      | _ -> ())
    !literals;
  result

let clexer_map = lazy (build_clexer_map "grammars/CLexer.tokens")

let normalize_token_with map t =
  match Hashtbl.find_opt map t with Some lit -> lit | None -> t

let normalize_token t = normalize_token_with (Lazy.force clexer_map) t

let run_java_and_read_tokens () =
  let ic =
    Unix.open_process_in
      "java -cp \"./grammars:./grammars/antlr-4.13.1-complete.jar\" Main --nopp"
  in
  let rec read_all acc =
    match input_line ic with
    | exception End_of_file -> List.rev acc
    | line -> (
        match Yojson.Basic.from_string line with
        | json -> read_all (json :: acc)
        | exception _ ->
            (* StringLiteral tokens with embedded quotes produce malformed JSON.
               Recover by extracting just the token name and substituting a
               safe placeholder lexeme. *)
            let re = Str.regexp "{\"token\": \"\\([^\"]*\\)\"" in
            if Str.string_match re line 0 then
              let token_name = Str.matched_group 1 line in
              let safe = Printf.sprintf {|{"token": "%s", "lexeme": "<string>"}|} token_name in
              read_all (Yojson.Basic.from_string safe :: acc)
            else (
              Printf.eprintf "io: skipping malformed JSON line: %s\n%!" line;
              read_all acc))
  in
  let output = read_all [] in
  ignore (Unix.close_process_in ic);
  output

let token_of_json j = j |> member "token" |> to_string
let lexeme_of_json j = j |> member "lexeme" |> to_string

let tokens_from_java () =
  run_java_and_read_tokens ()
  |> List.map (fun j -> token_of_json j |> normalize_token)

let tokens_and_lexemes_from_java () =
  run_java_and_read_tokens ()
  |> List.map (fun j -> (token_of_json j |> normalize_token, lexeme_of_json j))

let gen_tree_file = "grammars/gen_tree.txt"

let print_gen_tree () =
  match (try Some (open_in gen_tree_file) with Sys_error _ -> None) with
  | None -> ()
  | Some ic ->
      Printf.printf "┌─ gen tree ─────────────────────────\n";
      (try
         while true do
           Printf.printf "│  %s\n" (input_line ic)
         done
       with End_of_file -> ());
      close_in ic;
      Printf.printf "└────────────────────────────────────\n\n"
