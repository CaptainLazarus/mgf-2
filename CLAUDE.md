# Project: Head-Driven Parser (OCaml)

## What this is
An OCaml implementation of head-driven parsing using the H-cover algorithm. Given a context-free grammar, it:
1. Pre-computes an H-cover (done once per grammar)
2. Recognises input strings against that cover
3. Reconstructs all possible parse trees (full parse forest)

## Build & Run

```sh
dune build
dune exec practice            # runs bin/main.ml end-to-end
dune test                     # runs all tests
dune runtest test/            # runs Alcotest specs only
```

## Key Files

| File | Role |
|---|---|
| `lib/htable.ml` | Core algorithm: H-cover, recognition, tree reconstruction, printing |
| `lib/grammar_reader.ml` | Reads `.g4` files into internal `grammar` type |
| `lib/grammar_converter.ml` | Converts domain grammar to `Htable.grammar` |
| `lib/domain_types.ml` | Shared types: `symbol`, `production`, `grammar` |
| `lib/symbol_table.ml` | Global mutable table tracking desugared rule names (call `reset()` before each grammar read) |
| `bin/main.ml` | Example end-to-end program |
| `test/test_specs.ml` | Alcotest specs (18 tests, 3 suites) |
| `test/test_practice.ml` | Interactive demo test |
| `grammars/lisp.g4` | Lisp S-expression grammar used in tests |

## Architecture

### H-Cover (`htable.ml`)

**Items:**
- `CompleteItem of string` — a completed original-grammar nonterminal
- `PartialItem of int * int * int` — H-cover artifact, indexed by (production r, left-boundary s, right-boundary t)

**Recognition table:** `T[i,j]` cells contain `(h_item * derivation list) list` — all derivations stored for every item to enable full forest reconstruction.

**Derivation variants:**
- `FromTerminal of string` — projected from a terminal
- `FromProject of h_item` — epsilon projection of inner item
- `FromLeftExpand of h_item * h_item` — left expansion
- `FromRightExpand of h_item * h_item` — right expansion
- `FromEpsilon of h_item` — epsilon rule handling
- `FromBoundary of string * h_item_or_terminal` — boundary-seeded item (tags the dropped constituent)

**Grammar/input separation:**
```ocaml
(* Compile once *)
let pg : prepared_grammar = Htable.prepare grammar

(* Recognise many inputs *)
let tbl = Htable.recognize_with pg input
```

**Tree types:**
```ocaml
type tree =
  | Node of string * tree list   (* original grammar nonterminal *)
  | Leaf of string               (* terminal *)
  | Virtual of h_item_or_terminal (* boundary-dropped constituent, kept for reference *)
```

**Key reconstruction functions:**
- `reconstruct_trees_omit tbl root` — omits virtual/boundary constituents, returns `tree list`
- `reconstruct_trees_virtual tbl root` — includes virtual constituents as `Virtual` nodes

**Root inference:**
- `infer_parse_roots tbl` — climbs from `T[0,n]` items to original grammar nonterminals, returns `root_candidate list` with `missing_left`/`missing_right` siblings (empty = fully parsed)

### Grammar Reading Pipeline

`.g4 file` → `remove_comments` → `filter_content` → `split_rules` → `split_rhs` → `expand_production` → `desugar_production_strings` → `convert_to_grammar`

Desugaring handles:
- `x+` → rewrites as `x x*` and adds `x* -> x x* | epsilon` rules
- `x*` → adds `x* -> x x* | epsilon` rules
- `epsilon` keyword → `Epsilon` symbol
- Single-quoted strings `'tok'` → `Terminal "tok"`
- UPPERCASE → `Terminal`
- lowercase → `NonTerminal`

**Important:** `Symbol_table` uses global mutable state. Call `reset()` before reading a grammar (already wired into `extract_grammar_from_string`). Without this, reading the same grammar twice in one process drops desugared `*` rules on the second read.

## Tests (Alcotest — `test/test_specs.ml`)

18 tests across 3 suites, all passing:

- **recognition**: GCL accept/reject, epsilon grammars, A-star grammar
- **root inference**: complete/partial roots for various inputs
- **tree reconstruction**: tree count, exact structure, epsilon trees, lisp grammar via file

### Known subtlety: `astar ["a"]` produces 2 trees
Grammar `Astar -> a Astar | ε` legitimately gives two parse forests for `["a"]`:
1. `Node("Astar", [Leaf "a"; Node("Astar", [])])` — explicit epsilon tail
2. Collapsed version via epsilon projection in omit mode

## Completed Work

- [x] Task 1: Infer parse root from T[0,n] (`infer_parse_roots`, `root_candidate`)
- [x] Task 2: Reconstruct all parse trees (`reconstruct_trees_omit`, `reconstruct_trees_virtual`)
- [x] Task 3: Tag boundary-seeded derivations (`FromBoundary` variant)
- [x] Task 4: Define parse tree type (`tree = Node | Leaf | Virtual`)
- [x] Task 5: Pretty-print trees (`print_tree`, `print_trees` with box-drawing connectors)
- [x] Task 7: Alcotest specs (18 tests)
- [x] Grammar/input separation (`prepared_grammar`, `prepare`, `recognize_with`)
- [x] Example end-to-end program (`bin/main.ml`)

## Optional / Future Work

- [ ] **Task 6 (optional):** Investigate head position effect on efficiency. Head position doesn't affect correctness but may affect table size and step count. Approach: randomise head positions across runs on the same grammar/input, measure table size/steps, compare.
