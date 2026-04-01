open Domain_types
open Types

let convert_symbol (s : Domain_types.symbol) : Types.symbol option =
  match s with
  | NonTerminal name -> Some (Nonterminal name)
  | Terminal "EOF" -> None
  | Terminal name -> Some (Terminal name)
  | Epsilon -> None
  | EOF -> None

let convert_grammar (g : Domain_types.grammar) : Types.grammar =
  let productions, _ =
    List.fold_left
      (fun (acc, idx) (rule : Domain_types.production_rule) ->
        let lhs =
          match rule.lhs with
          | NonTerminal name -> name
          | _ -> failwith "LHS must be a nonterminal"
        in
        let rhs = List.filter_map convert_symbol rule.rhs in
        let head_pos =
          if rhs = [] then 0 else if rule.head_pos > 0 then rule.head_pos else 1
        in
        let prod : Types.production = { index = idx; lhs; rhs; head_pos } in
        (prod :: acc, idx + 1))
      ([], 1) g
  in
  let productions = List.rev productions in
  let nonterminals =
    List.sort_uniq String.compare
      (List.map (fun (p : Types.production) -> p.lhs) productions)
  in
  let terminals =
    List.sort_uniq String.compare
      (List.concat_map
         (fun (p : Types.production) ->
           List.filter_map
             (fun s -> match s with Terminal t -> Some t | _ -> None)
             p.rhs)
         productions)
  in
  let start =
    match productions with p :: _ -> p.lhs | [] -> failwith "Empty grammar"
  in
  { nonterminals; terminals; productions; start }
