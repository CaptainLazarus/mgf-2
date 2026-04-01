open Types
open Table

let tree_cap = 50

let cartesian xs ys =
  let result = ref [] and n = ref 0 in
  (try
     List.iter
       (fun x ->
         List.iter
           (fun y ->
             if !n >= tree_cap then raise Exit;
             result := (x @ y) :: !result;
             incr n)
           ys)
       xs
   with Exit -> ());
  !result

let bounded_concat_map f xs =
  let result = ref [] and n = ref 0 in
  (try
     List.iter
       (fun x ->
         List.iter
           (fun y ->
             if !n >= tree_cap then raise Exit;
             result := y :: !result;
             incr n)
           (f x))
       xs
   with Exit -> ());
  !result

let rec get_subtrees mode visited memo tbl item i j : tree list list =
  let key = (item, i, j) in
  match Hashtbl.find_opt memo key with
  | Some result -> result
  | None ->
      if Hashtbl.mem visited key then []
      else (
        Hashtbl.replace visited key ();
        let derivs = get_derivations tbl i j item in
        let result =
          List.sort_uniq compare
            (bounded_concat_map
               (subtrees_for_deriv mode visited memo tbl item i j)
               derivs)
        in
        Hashtbl.remove visited key;
        Hashtbl.replace memo key result;
        result)

and subtrees_for_deriv mode visited memo tbl item i j = function
  | FromTerminal t -> (
      match item with
      | CompleteItem nt ->
          let children = if t = "ε" then [] else [ Leaf t ] in
          [ [ Node (nt, children) ] ]
      | PartialItem _ -> if t = "ε" then [ [] ] else [ [ Leaf t ] ])
  | FromProject inner -> (
      let inner_subs = get_subtrees mode visited memo tbl inner i j in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) inner_subs
      | PartialItem _ -> inner_subs)
  | FromLeftExpand (k, x_h, right_item) -> (
      let left_subs = subs_for_x mode visited memo tbl x_h i k in
      let right_subs = get_subtrees mode visited memo tbl right_item k j in
      let combined = cartesian left_subs right_subs in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromRightExpand (k, left_item, y_h) -> (
      let left_subs = get_subtrees mode visited memo tbl left_item i k in
      let right_subs = subs_for_x mode visited memo tbl y_h k j in
      let combined = cartesian left_subs right_subs in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromEpsilon inner -> (
      let inner_subs = get_subtrees mode visited memo tbl inner i j in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) inner_subs
      | PartialItem _ -> inner_subs)
  | FromBoundaryRight (virtual_left, real_right) -> (
      let right_subs = subs_for_x mode visited memo tbl real_right i j in
      let virt =
        match mode with `Virtual -> [ Virtual virtual_left ] | `Omit -> []
      in
      let combined = List.map (fun sub -> virt @ sub) right_subs in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromBoundaryLeft (real_left, virtual_right) -> (
      let left_subs = subs_for_x mode visited memo tbl real_left i j in
      let virt =
        match mode with `Virtual -> [ Virtual virtual_right ] | `Omit -> []
      in
      let combined = List.map (fun sub -> sub @ virt) left_subs in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromInductiveFill (virtual_left, real_right) -> (
      let right_subs = get_subtrees mode visited memo tbl real_right i j in
      let virt =
        match mode with
        | `Virtual -> [ Virtual (HItem virtual_left) ]
        | `Omit -> []
      in
      let combined = List.map (fun sub -> virt @ sub) right_subs in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromInductiveFillRight (real_left, virtual_right) -> (
      let left_subs = get_subtrees mode visited memo tbl real_left i j in
      let virt =
        match mode with `Virtual -> [ Virtual virtual_right ] | `Omit -> []
      in
      let combined = List.map (fun sub -> sub @ virt) left_subs in
      match item with
      | CompleteItem nt -> List.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)

and subs_for_x mode visited memo tbl x i j =
  match x with
  | HTerm t -> [ [ Leaf t ] ]
  | HItem h_item -> get_subtrees mode visited memo tbl h_item i j

let reconstruct_trees_virtual tbl nt =
  let visited = Hashtbl.create 16 in
  let memo = Hashtbl.create 64 in
  let subs = get_subtrees `Virtual visited memo tbl (CompleteItem nt) 0 tbl.n in
  List.sort_uniq compare
    (List.filter_map (function [ t ] -> Some t | _ -> None) subs)

let reconstruct_trees_omit tbl nt =
  let visited = Hashtbl.create 16 in
  let memo = Hashtbl.create 64 in
  let subs = get_subtrees `Omit visited memo tbl (CompleteItem nt) 0 tbl.n in
  List.sort_uniq compare
    (List.filter_map (function [ t ] -> Some t | _ -> None) subs)
