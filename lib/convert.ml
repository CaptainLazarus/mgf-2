open Types

let get_symbol prod pos = List.nth prod.rhs (pos - 1)

let string_of_symbol = function
  | Terminal t -> Printf.sprintf "\"%s\"" t
  | Nonterminal nt -> nt

let string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "I_%d^(%d,%d)" r s t
  | CompleteItem a -> Printf.sprintf "I_%s" a

let short_string_of_h_item = function
  | PartialItem (r, s, t) -> Printf.sprintf "%d^%d,%d" r s t
  | CompleteItem a -> a

let string_of_h_item_or_terminal = function
  | HItem hi -> string_of_h_item hi
  | HTerm t -> Printf.sprintf "\"%s\"" t

let string_of_derivation = function
  | FromTerminal t -> Printf.sprintf "Terminal(%s)" t
  | FromProject hi -> Printf.sprintf "Project(%s)" (string_of_h_item hi)
  | FromLeftExpand (k, x, ri) ->
      Printf.sprintf "LeftExp(k=%d, %s, %s)" k
        (string_of_h_item_or_terminal x)
        (string_of_h_item ri)
  | FromRightExpand (k, li, y) ->
      Printf.sprintf "RightExp(k=%d, %s, %s)" k (string_of_h_item li)
        (string_of_h_item_or_terminal y)
  | FromEpsilon hi -> Printf.sprintf "Epsilon(%s)" (string_of_h_item hi)
  | FromBoundaryRight (virtual_left, real_right) ->
      Printf.sprintf "BoundaryRight(virtual_left: %s, real_right: %s)"
        (string_of_h_item_or_terminal virtual_left)
        (string_of_h_item_or_terminal real_right)
  | FromBoundaryLeft (real_left, virtual_right) ->
      Printf.sprintf "BoundaryLeft(real_left: %s, virtual_right: %s)"
        (string_of_h_item_or_terminal real_left)
        (string_of_h_item_or_terminal virtual_right)
  | FromInductiveFill (virtual_left, real_right) ->
      Printf.sprintf "InductiveFill(virtual: %s, right: %s)"
        (string_of_h_item virtual_left)
        (string_of_h_item real_right)
  | FromInductiveFillRight (real_left, virtual_right) ->
      Printf.sprintf "InductiveFillRight(left: %s, virtual: %s)"
        (string_of_h_item real_left)
        (string_of_h_item_or_terminal virtual_right)
