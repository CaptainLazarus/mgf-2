open Types
open Table

let is_accepted tbl =
  let start_item = CompleteItem tbl.grammar.start in
  mem_item tbl 0 tbl.n start_item

let get_complete_items tbl i j =
  List.filter_map
    (fun (item, derivs) ->
      match item with
      | CompleteItem _ -> Some (item, derivs)
      | PartialItem _ -> None)
    tbl.entries.(i).(j).items

let get_all_items tbl i j = tbl.entries.(i).(j).items

let count_table_items tbl =
  let total = ref 0 in
  for i = 0 to tbl.n do
    for j = i to tbl.n do
      total := !total + List.length tbl.entries.(i).(j).items
    done
  done;
  !total

let find_production tbl r =
  List.find (fun p -> p.index = r) tbl.grammar.productions

let infer_parse_roots tbl =
  let n = tbl.n in
  let items = get_all_items tbl 0 n in
  let rhs_arr prod = Array.of_list prod.rhs in
  let direct =
    List.filter_map (fun (item, _) ->
      match item with
      | CompleteItem nt ->
        Some { root = nt; missing_left = []; missing_right = [] }
      | PartialItem (r, s, t) ->
        let prod = find_production tbl r in
        let rhs = rhs_arr prod in
        let len = Array.length rhs in
        Some {
          root = prod.lhs;
          missing_left  = Array.to_list (Array.sub rhs 0 s);
          missing_right = Array.to_list (Array.sub rhs t (len - t));
        })
      items
  in
  let complete_nts =
    List.filter_map (fun (item, _) ->
      match item with CompleteItem nt -> Some nt | _ -> None)
      items
  in
  let inferred =
    List.concat_map (fun nt ->
      List.filter_map (fun prod ->
        let rhs = prod.rhs in
        let positions =
          List.filteri (fun i sym ->
            match sym with Nonterminal s -> s = nt && i >= 0 | _ -> false)
            rhs
          |> List.mapi (fun _ sym -> sym)
        in
        if positions = [] then None
        else
          let missing =
            List.filter (fun sym ->
              match sym with Nonterminal s -> s <> nt | Terminal _ -> true)
              rhs
          in
          if missing = [] then None
          else Some { root = prod.lhs; missing_left = missing; missing_right = [] })
        tbl.grammar.productions)
      complete_nts
  in
  let all = direct @ inferred in
  List.sort_uniq compare all
