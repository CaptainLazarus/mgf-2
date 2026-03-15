open Yojson.Basic.Util

let run_java_and_read_tokens () =
  let ic =
    Unix.open_process_in
      "java -cp \"./grammars:./grammars/antlr-4.13.1-complete.jar\" Main"
  in
  let rec read_all acc =
    try
      let line = input_line ic in
      let json = Yojson.Basic.from_string line in
      read_all (json :: acc)
    with End_of_file -> List.rev acc
  in
  let output = read_all [] in
  ignore (Unix.close_process_in ic);
  output

let token_of_json j = j |> member "token" |> to_string

let tokens_from_java () =
  run_java_and_read_tokens () |> List.map token_of_json
