# Code Review Progress

Last reviewed: 2026-09-16

## Project summary

Experimental OCaml parser for incomplete token sequences. It reads ANTLR-style
or built-in grammars, constructs a head-driven H-cover, recognizes fragments,
infers possible parse roots, and reconstructs parse trees with optional virtual
missing structure.

## Confirmed algorithm intent

- The main result is not membership in the grammar start language. Each
  nonterminal is treated as a candidate sublanguage that may cover the observed
  fragment.
- In the full-span cell `T[0,n]`, every partial path should climb only until its
  first `CompleteItem`. That item is the smallest complete cover on that path.
- A complete item in `T[0,n]` is terminal: it must not project, expand, undergo
  epsilon closure, or be traversed by a frontier BFS. For example, `DET N`
  completes as `NP` and must not subsequently climb to `S` or `Top`.
- This stopping rule is specific to `T[0,n]`; complete items in internal chart
  cells still participate in building structures that cover more input.

## Files covered

1. `bin/main.ml`
   - Selects a grammar and tokens.
   - Loads and normalizes file-based grammars.
   - Prepares the H-cover, performs recognition, infers roots, and prints trees.
2. `lib/grammar_reader.ml` and `lib/grammar_reader_utils.ml`
   - Implement a lightweight reader for the supported subset of ANTLR grammar
     syntax, including custom head markers and EBNF desugaring.
3. `lib/grammar_converter.ml`
   - Converts `Domain_types.grammar` into the normalized parser grammar.
4. `lib/types.ml`
   - Defines normalized grammars, H-items, H-covers, derivations, chart tables,
     prepared grammars, reconstructed trees, and root candidates.
5. `lib/hcover.ml`
   - Computes nullable nonterminals and representative minimum yields.
   - Compiles productions into projections plus left, right, and epsilon
     expansion relations used by recognition.
   - Provides lookup helpers over those relations.
6. `lib/table.ml`
   - Allocates the recognition chart and owns item membership, derivation
     storage, and left/right blocking records for each chart cell.
7. `lib/seed.ml`
   - Seeds explicit epsilon productions at every zero-width input position.
   - Projects each input token into initial H-items.
   - Adds one-sided virtual expansions at the left and right input boundaries.
8. `lib/worklist.ml`
   - Processes newly discovered chart items to a fixed point through ordinary
     projection, nullable projection, and bidirectional left/right expansion.
   - Uses reverse expansion passes so combinations are found regardless of
     which partner reaches the chart first.
9. `lib/recognize.ml`
   - Coordinates seeding and worklist closure, then conditionally applies
     left- and right-boundary reductions for incomplete input.
   - Exposes one-shot recognition plus a prepared-grammar API that reuses the
     H-cover and minimum-yield computation across inputs.
10. `lib/query.ml`
    - Tests strict start-symbol acceptance, exposes chart-cell items and chart
      size, and turns full-span complete or partial items into root candidates.
11. `lib/reconstruct.ml`
    - Walks derivation backpointers lazily, combines child alternatives, breaks
      cycles, memoizes subtree results, and emits trees with virtual nodes kept
      or omitted.
    - Wraps full-span partial items in their production LHS and inserts virtual
      symbols for uncovered RHS prefixes and suffixes.
12. `lib/linear.ml`
    - Implements a separate experimental left-to-right H-cover scanner, not the
      chart algorithm used by the main executables.
    - Carries forest nodes directly in each state, fills virtual material at
      the outer boundaries, and exposes whole-scan and step-by-step APIs.

## Review tally

1. `bin/main.ml` does not compile because `active_grammar` has no value; all
   candidates are commented out.
2. `bin/main.ml` contains hard-coded debugging for nonterminal `"e"`.
3. Grammar comment removal is not quote-aware, so comment-like text inside a
   quoted literal can be corrupted.
4. `Grammar_converter.convert_grammar` removes `EOF` and epsilon symbols without
   adjusting an explicitly marked `head_pos`, potentially leaving an invalid
   position.
5. Grammar rules without an unquoted colon are silently ignored instead of
   producing a parse error.
6. `PartialItem` and related structures use unlabelled integer tuples whose
   invariants are implicit and unchecked.
7. All H-cover lookup helpers linearly scan relation lists. They are called in
   recognition loops, so large grammars may pay repeated O(cover-size) costs
   where indexed lookup tables could be used.
8. The nullable `compute_min_yield` correction is only one pass. For a chain
   such as `A -> B`, `B -> epsilon | 'b'`, it can update `B` to `["b"]` while
   leaving `A` at `[]`, producing a misleading virtual expansion for `A`.
9. Chart-cell items, derivations, and blocking records are all association
   lists. Membership and insertion repeatedly scan (and, for a new derivation,
   rebuild) those lists, which may become a recognition bottleneck.
10. Boundary seeding scans each expansion list only once while also mutating the
    cell being queried. Multi-level virtual boundary expansions can therefore
    depend on relation iteration order unless a later reduction phase happens
    to close the chain; the expansion lists themselves come from hash-table
    folds with unspecified order.
11. The intended full-span stopping rule is only partially implemented.
    `Worklist.process_agenda` suppresses ordinary projection from complete items
    in `T[0,n]`, but still runs epsilon and expansion operations; `frontier_bfs`
    has no complete-item guard. These paths can climb beyond the first complete
    cover.
12. Boundary reduction is guarded by `T[0,n].items = []`. Under the confirmed
    intent, each full-span partial path must close to its first complete cover;
    the presence of any incidental item (especially another partial) must not
    suppress that closure.
13. Root inference retains only one `h_item` per root name. If several partial
    items for the same nonterminal represent different productions or covered
    regions, all but the structurally first are discarded before tree
    reconstruction, potentially losing incomplete interpretations.
14. Reconstruction memoizes at most 10 subtree results per chart item even when
    the public `limit` is larger (default 50). It truncates before deduplication,
    so requested limits are not reliable and later unique trees may be lost.
15. `FromEpsilon` records only the surviving item, not the nullable grammar
    symbol that was skipped. Reconstruction therefore cannot emit that symbol's
    empty node, which can make reconstructed trees structurally incomplete.
16. `Linear.merge_into` treats every forest node as new even when the item and
    node were already seen. Projection cycles can therefore fail to terminate,
    and ambiguous inputs can accumulate duplicate forests explosively.
17. The linear scanner ignores epsilon productions and H-cover epsilon
    projections; `scan` also returns no state for empty input. It is therefore
    not semantically equivalent to the main recognizer for nullable grammars.

## Verification

- `dune build @all`: fails at `bin/main.ml` because `active_grammar` is missing.
- `dune runtest`: passes all 49 tests.

## Next file

`lib/grammar_expander.ml` (or the deferred output/display layer)
