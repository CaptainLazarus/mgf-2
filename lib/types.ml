type symbol = Terminal of string | Nonterminal of string

type production = {
  index : int;
  lhs : string;
  rhs : symbol list;
  head_pos : int;
}

type grammar = {
  nonterminals : string list;
  terminals : string list;
  productions : production list;
  start : string;
}

(* H-items *)
type h_item = PartialItem of int * int * int | CompleteItem of string
type h_item_or_terminal = HItem of h_item | HTerm of string

(* How an item was derived *)
type derivation =
  | FromTerminal of string
  | FromProject of h_item
  | FromLeftExpand of int * h_item_or_terminal * h_item
  | FromRightExpand of int * h_item * h_item_or_terminal
  | FromEpsilon of h_item
  | FromBoundaryRight of h_item_or_terminal * h_item_or_terminal
  | FromBoundaryLeft of h_item_or_terminal * h_item_or_terminal
  | FromInductiveFill of h_item * h_item
  | FromInductiveFillRight of h_item * h_item_or_terminal

(* H-cover structure *)
type h_cover = {
  items : h_item list;
  projections : (h_item * h_item_or_terminal) list;
  left_expansions : (h_item * h_item_or_terminal * h_item) list;
  right_expansions : (h_item * h_item * h_item_or_terminal) list;
  epsilon_projections : (h_item * h_item) list;
}

(* Recognition table *)
type table_entry = {
  mutable items : (h_item * derivation list) list;
  mutable blocked_left : (h_item * int * int) list;
  mutable blocked_right : (h_item * int * int) list;
}

type rec_table = {
  n : int;
  entries : table_entry array array;
  input : string array;
  grammar : grammar;
  cover : h_cover;
}

(* Pre-compiled grammar *)
type prepared_grammar = { pg_grammar : grammar; pg_cover : h_cover }

(* Parse trees *)
type tree =
  | Node of string * tree list
  | Leaf of string
  | Virtual of h_item_or_terminal

(* Root inference *)
type root_candidate = {
  root : string;
  item : h_item;
  missing_left : symbol list;
  missing_right : symbol list;
}
