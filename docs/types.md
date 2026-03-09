# Types in `htable.ml`

Types are organised in layers from grammar input down to output.

---

## Layer 1 — Grammar representation

Shared with the rest of the lib (also in `domain_types.ml` — duplication, see notes).

```ocaml
type symbol = Terminal of string | Nonterminal of string

type production = {
  index    : int;
  lhs      : string;
  rhs      : symbol list;
  head_pos : int;        (* index into rhs of the "head" symbol *)
}

type grammar = {
  nonterminals : string list;
  terminals    : string list;
  productions  : production list;
  start        : string;
}
```

---

## Layer 2 — H-cover items

```ocaml
type h_item =
  | PartialItem of int * int * int   (* production_index, left_boundary, right_boundary *)
  | CompleteItem of string           (* nonterminal name *)

type h_item_or_terminal =
  | HItem of h_item
  | HTerm of string
```

`PartialItem(r, s, t)` means: production `r`, we've accounted for positions `s..t`
of the RHS around the head. `CompleteItem nt` means `nt` is fully recognised.

`h_item_or_terminal` exists because both H-cover items and raw terminals can appear
as siblings in an expansion.

---

## Layer 3 — Derivations

Backpointers stored in the recognition table. Used for tree reconstruction.

```ocaml
type derivation =
  | FromTerminal    of string                                    (* leaf: matched a token *)
  | FromProject     of h_item                                    (* unit projection *)
  | FromLeftExpand  of int * h_item_or_terminal * h_item         (* grew left;  k = split point *)
  | FromRightExpand of int * h_item * h_item_or_terminal         (* grew right; k = split point *)
  | FromEpsilon     of h_item                                    (* skipped nullable symbol *)
  (* NOTE : For boundry expansions, atleast one terminal is guaranteed no ? Only in the table though. Special case ? *)
  | FromBoundaryRight of h_item_or_terminal * h_item_or_terminal (* L-Reduce: left child is virtual *)
  | FromBoundaryLeft  of h_item_or_terminal * h_item_or_terminal (* R-Reduce: right child is virtual *)
  (* TODO : Why are these unequal ?  Shouldn't be. Fix *)
  | FromInductiveFill      of h_item * h_item                    (* L-Reduce inductive step *)
  | FromInductiveFillRight of h_item * h_item_or_terminal        (* R-Reduce inductive step *)
```

`FromBoundaryRight` / `FromBoundaryLeft` arise during fragment parsing (L-Reduce /
R-Reduce passes): the "virtual" child is a constituent inferred to be missing at the
input boundary.

---

## Layer 4 — H-cover structure

Computed once per grammar by `compute_h_cover`. Reused across all inputs.

```ocaml
type h_cover = {
  items               : h_item list;
  projections         : (h_item * h_item_or_terminal) list;        (* unit chains *)
  left_expansions     : (h_item * h_item_or_terminal * h_item) list;
  right_expansions    : (h_item * h_item * h_item_or_terminal) list;
  epsilon_projections : (h_item * h_item) list;
}
```

Each field is a precomputed set of rules the recogniser looks up at each table cell:

| Field | Meaning |
|---|---|
| `projections` | `result <- source` (unit / head projection) |
| `left_expansions` | `result <- left_sibling  right_item` |
| `right_expansions` | `result <- left_item  right_sibling` |
| `epsilon_projections` | `result <- source`, source spans a nullable symbol |

---

## Layer 5 — Recognition table

```ocaml
type table_entry = {
  mutable items         : (h_item * derivation list) list;
  mutable blocked_left  : (h_item * int * int) list;   (* fragment parsing artifact *)
  mutable blocked_right : (h_item * int * int) list;   (* fragment parsing artifact *)
}

type rec_table = {
  n       : int;
  entries : table_entry array array;   (* (n+1) x (n+1) grid *)
  input   : string array;
  grammar : grammar;
  cover   : h_cover;
}
```

`entries.(i).(j)` is the cell `T[i,j]`, covering input positions `i..j`.
Each cell holds a list of `(h_item, derivation list)` pairs — all items present
in that cell along with every way they were derived (for full forest reconstruction).

`blocked_left` / `blocked_right` are used by the fragment parsing passes (L-Reduce /
R-Reduce) to track items waiting for a missing boundary sibling. Their exact semantics
need clarification during the refactor.

---

## Layer 6 — Pre-compiled grammar

```ocaml
type prepared_grammar = {
  pg_grammar : grammar;
  pg_cover   : h_cover;
}
```

Separates the one-time H-cover computation from per-input recognition.
`prepare g` computes the cover; `recognize_with pg input` uses it.

---

## Layer 7 — Output types

```ocaml
type tree =
  | Node    of string * tree list      (* original-grammar nonterminal with children *)
  | Leaf    of string                  (* terminal token matched in input *)
  | Virtual of h_item_or_terminal      (* boundary-dropped constituent, kept for reference *)

type root_candidate = {
  root          : string;       (* nonterminal name *)
  missing_left  : symbol list;  (* siblings absent to the left of what was parsed *)
  missing_right : symbol list;  (* siblings absent to the right of what was parsed *)
}
```

`root_candidate` is returned by `infer_parse_roots`. When `missing_left` and
`missing_right` are both empty, the input is a complete parse of `root`.

---

## Notes / Refactor flags

- `grammar`, `symbol`, `production` are redefined in `htable.ml` but also exist in
  `domain_types.ml`. These should consolidate to one definition.
- `blocked_left` / `blocked_right` in `table_entry` are fragment-parsing state mixed
  into the core table type. Worth isolating or at least documenting clearly.
