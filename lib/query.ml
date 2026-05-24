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
  let items = get_all_items tbl 0 tbl.n in
  let direct =
    List.filter_map
      (fun (item, _) ->
        match item with
        | CompleteItem nt -> Some { root = nt; item = CompleteItem nt }
        | PartialItem (r, _, _) ->
            let prod = find_production tbl r in
            Some { root = prod.lhs; item })
      items
  in
  (* Deduplicate by root name: prefer CompleteItem over PartialItem *)
  let by_root = List.sort_uniq compare direct in
  let roots = List.map (fun c -> c.root) by_root |> List.sort_uniq String.compare in
  List.map
    (fun root ->
      let candidates = List.filter (fun c -> c.root = root) by_root in
      match List.find_opt (fun c -> match c.item with CompleteItem _ -> true | _ -> false) candidates with
      | Some c -> c
      | None   -> List.hd candidates)
    roots
