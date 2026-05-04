open Types
open Table

let memo_cap = 20

let drain_seq n seq =
  let result = ref [] and count = ref 0 in
  let rec go s =
    if !count >= n then ()
    else
      match s () with
      | Seq.Nil -> ()
      | Seq.Cons (x, rest) ->
          result := x :: !result;
          incr count;
          go rest
  in
  go seq;
  List.rev !result

let cartesian_lazy xs ys =
  Seq.flat_map (fun x -> Seq.map (fun y -> x @ y) ys) xs

let rec get_subtrees mode visited memo tbl item i j : tree list Seq.t =
  let key = (item, i, j) in
  match Hashtbl.find_opt memo key with
  | Some result -> List.to_seq result
  | None ->
      if Hashtbl.mem visited key then Seq.empty
      else begin
        Hashtbl.replace visited key ();
        let derivs = get_derivations tbl i j item in
        let seq =
          Seq.flat_map
            (subtrees_for_deriv mode visited memo tbl item i j)
            (List.to_seq derivs)
        in
        let result = List.sort_uniq compare (drain_seq memo_cap seq) in
        Hashtbl.remove visited key;
        Hashtbl.replace memo key result;
        List.to_seq result
      end

and subtrees_for_deriv mode visited memo tbl item i j deriv : tree list Seq.t =
  match deriv with
  | FromTerminal t -> (
      match item with
      | CompleteItem nt ->
          let children = if t = "ε" then [] else [ Leaf t ] in
          Seq.return [ Node (nt, children) ]
      | PartialItem _ -> if t = "ε" then Seq.return [] else Seq.return [ Leaf t ])
  | FromProject inner -> (
      let inner_seq = get_subtrees mode visited memo tbl inner i j in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) inner_seq
      | PartialItem _ -> inner_seq)
  | FromLeftExpand (k, x_h, right_item) -> (
      let left_seq = subs_for_x mode visited memo tbl x_h i k in
      let right_seq = get_subtrees mode visited memo tbl right_item k j in
      let combined = cartesian_lazy left_seq right_seq in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromRightExpand (k, left_item, y_h) -> (
      let left_seq = get_subtrees mode visited memo tbl left_item i k in
      let right_seq = subs_for_x mode visited memo tbl y_h k j in
      let combined = cartesian_lazy left_seq right_seq in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromEpsilon inner -> (
      let inner_seq = get_subtrees mode visited memo tbl inner i j in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) inner_seq
      | PartialItem _ -> inner_seq)
  | FromBoundaryRight (virtual_left, real_right) -> (
      let right_seq = subs_for_x mode visited memo tbl real_right i j in
      let virt =
        match mode with `Virtual -> [ Virtual virtual_left ] | `Omit -> []
      in
      let combined = Seq.map (fun sub -> virt @ sub) right_seq in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromBoundaryLeft (real_left, virtual_right) -> (
      let left_seq = subs_for_x mode visited memo tbl real_left i j in
      let virt =
        match mode with `Virtual -> [ Virtual virtual_right ] | `Omit -> []
      in
      let combined = Seq.map (fun sub -> sub @ virt) left_seq in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromInductiveFill (virtual_left, real_right) -> (
      let right_seq = get_subtrees mode visited memo tbl real_right i j in
      let virt =
        match mode with
        | `Virtual -> [ Virtual (HItem virtual_left) ]
        | `Omit -> []
      in
      let combined = Seq.map (fun sub -> virt @ sub) right_seq in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)
  | FromInductiveFillRight (real_left, virtual_right) -> (
      let left_seq = get_subtrees mode visited memo tbl real_left i j in
      let virt =
        match mode with `Virtual -> [ Virtual virtual_right ] | `Omit -> []
      in
      let combined = Seq.map (fun sub -> sub @ virt) left_seq in
      match item with
      | CompleteItem nt -> Seq.map (fun sub -> [ Node (nt, sub) ]) combined
      | PartialItem _ -> combined)

and subs_for_x mode visited memo tbl x i j : tree list Seq.t =
  match x with
  | HTerm t -> Seq.return [ Leaf t ]
  | HItem h_item -> get_subtrees mode visited memo tbl h_item i j

let reconstruct_trees ?(limit = 50) mode tbl nt =
  let visited = Hashtbl.create 16 in
  let memo = Hashtbl.create 64 in
  let seq = get_subtrees mode visited memo tbl (CompleteItem nt) 0 tbl.n in
  let raw = drain_seq limit seq in
  List.sort_uniq compare
    (List.filter_map (function [ t ] -> Some t | _ -> None) raw)

let reconstruct_trees_virtual ?(limit = 50) tbl nt =
  reconstruct_trees ~limit `Virtual tbl nt

let reconstruct_trees_omit ?(limit = 50) tbl nt =
  reconstruct_trees ~limit `Omit tbl nt
