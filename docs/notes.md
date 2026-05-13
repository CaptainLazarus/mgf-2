# Notes

Observations and potential improvements noted during exploration.

## head position affects which nonterminals climb — not a correctness bug

Changing head position on the same grammar and input produces different items in T[0,n]. This is not a correctness bug — head position determines which nonterminal is the "spine" of each production, which changes what partial items are generated and how they combine. Different head choices cause different nonterminals to climb to T[0,n], so the root candidates differ. The language accepted is the same; what's visible at the top of the table is not.

Observed: grammar `s → np vp / vp → CL V np / np → DET N`, input `V DET N`. With head=NP on VP, VP climbs to T[0,3] as a partial item. With a different head choice, a different item reaches T[0,3].

## process_agenda — rev_right / rev_left cover agenda ordering gaps

The agenda does not process items in diagonal order (unlike CYK). A head item can be dequeued and scan for its sibling before the sibling exists in the table — finding nothing. When the sibling arrives later, the standard forward expansions don't rescan. Rev_right/rev_left close this gap: they fire when the sibling arrives and scan for a head already in the table.

Confirmed on `astar ["a";"a";"a"]` via debug trace: `P(1,0,1)` at T[0,1] scans for `Astar` at T[1,j'] when dequeued (step 8) — only epsilon `Astar` at T[1,1] present. Later, `Astar` arrives at T[1,2] (step 12) — rev_right fires and combines with `P(1,0,1)` at T[0,1] → `Astar` at T[0,2].

Blocking (Q-sets) does NOT apply to rev_right/rev_left — blocking is only valid when the head drives the combination. When the sibling drives, the head is passive and the blocking decision was already made when the head was originally processed.

## process_agenda — projection and epsilon-projection blocks could be combined

Steps 2 and 3 in `process_agenda` are identical in structure — both filter `cover.projections` and call `add_item` at the same span. Could merge into a single `find_all_projections` returning `(h_item * derivation) list`, then one `List.iter`. Derivation tags (`FromProject` vs `FromEpsilon`) would need to be carried in the result tuple.

## Boundary seeding — precompute which rules fire per terminal

Which right/left expansion rules fire at T[0,1] and T[n-1,n] is determined entirely by the grammar, not the input. Could precompute a map from terminal → matching expansion rules at `prepare` time, avoiding a full scan of `right_expansions` and `left_expansions` on every recognition call.

## block_left / block_right — blocked lists stored as list, not set

`blocked_left` and `blocked_right` in `table_entry` are lists with manual duplicate checks in `block_left`/`block_right`. Same issue as `add_item` — could be sets for O(log n) membership instead of O(n) scan.

## add_item — derivations stored as list, not set

`entry.items` stores derivations as a `list`, using `List.mem` to check for duplicates.
Could be a `Set` for O(log n) membership instead of O(n).

## L-Reduce / R-Reduce ordering — arbitrary, not principled

The current implementation runs L-Reduce first (always), then R-Reduce conditionally (only if T[0,n] is still empty after L-Reduce). This ordering has no theoretical grounding — it's a pragmatic choice that happens to work for left-leaning grammars but is wrong in general.

For a right-leaning grammar (e.g. one where the root is typically built right-to-left), R-Reduce should run first. The conditional also means R-Reduce is never attempted if L-Reduce already produced *something* in T[0,n], even if that something is incomplete or wrong.

The fix would be to always run both passes, or to determine from the grammar structure which direction to prefer. As written, the code embeds an implicit and unjustified assumption that left-context is more likely to be missing than right-context.

## L-Reduce frontier climbing — possibly redundant (open question)

**Keywords:** frontier climbing, inductive fill, agenda projection, climb-then-combine vs combine-then-climb.

The L-Reduce BFS loop climbs items in T[0,k-1] via repeated `find_right_expansions_by_right` — B → X → X' all land in the same cell. But the agenda already does upward projection after any combination fires (`find_projections_from_item` at same span). So: combine B·C → result → agenda projects result upward. The climbing the frontier does (B → X → X') may be redundant if the agenda would reach the same items after the combination anyway.

**Open question:** is there a case where climb-then-combine (frontier puts X in T[0,k-1], X·C fires) produces something that combine-then-climb (B·C fires, result projects to X-level) would miss? If not, the frontier only needs to place the direct inductive fill results (bottom level), not climb them — the agenda handles everything above.

Likely needs checking against the H-cover projection structure specifically — head grammars have constrained projection chains that might resolve this.

## recognize_tbl — pipeline structure

Every item in the table has exactly 3 fates:
1. **Project** — promotes to a larger item at the same span
2. **Combine** — merges with an existing sibling to produce a parent at a wider span
3. **Infer sideways** — assumes missing context and seeds a new item at an edge cell (frontier only)

Combination is not a reduction — it only fires when both sides already exist. Projection and inductive fill are the only true reductions (new information derived from smaller items).

The pipeline of `recognize_tbl`:

```
seed_epsilons → seed_terminals → seed_first_cell → seed_last_cell
    └──────────────────────────────────────────────────────────────→ process_agenda
                                                                            │
                               [L-Reduce k=1..n]: frontier_BFS(T[0,k-1]) → process_agenda
                                                  ↓
                [R-Reduce k=n-1..0, if T[0,n]=∅]: frontier_BFS(T[k+1,n]) → process_agenda
                                                  ↓
                              [final R, if T[0,n]=∅]: frontier_BFS(T[0,n], right) → process_agenda
                                                  ↓
                                    [final L, always]: frontier_BFS(T[0,n], left)  → process_agenda
```

Project and combine happen entirely inside `process_agenda`. Infer sideways happens only in the frontier BFS blocks. Each frontier block feeds newly inferred items into `process_agenda` so they can project and combine normally.

Projection is deferred: combine produces a new item → enqueue → dequeue later → then project.

## process_agenda — needs refactor, too long

The function is doing 6 distinct things inline: project, eps-project, left-expand, right-expand, rev-right, rev-left. Each block is structurally similar (filter cover list → scan → add_item → enqueue). Should be broken into smaller focused functions. The debug logging also adds noise. Defer until the algorithm is fully understood.

## Main.java — string literal tokens produce malformed JSON

`token.getText()` for a StringLiteral includes the surrounding C quote chars (`"hello"`). The printf then wraps it in another pair of JSON string quotes, producing `""hello""` which Yojson rejects. Currently handled in `io.ml` by catching the parse failure and substituting `<string>` as the lexeme. Real fix: in `Main.java`, strip the outer quotes from string literal text before JSON-encoding, or switch to a proper JSON library for output.

## grammar_expander — synthetic rule names should derive from parent

Anonymous repetition groups like `(a | b)*` must be given a fresh rule name since they have no name in the original G4. Currently they get counter-based names like `grp172_*`. These should instead derive from the parent rule — e.g. `declarator_star0_` — since the new pipeline in `grammar_reader` has the parent `lhs` available when `expand_alt` is called. Plain `(a | b)` groups (no suffix) are already inlined as multiple parent alternatives and need no name.

## Fragment parsing as zipper navigation (theoretical sketch)

Treating ω = α β γ, β is the *focus* of a zipper and α, γ are its left and right context. Fragment parsing then becomes: find all valid positions in the zipper hierarchy where β could sit as the focused subtree.

A zipper position corresponds to a (nonterminal, hole-location) pair — the nonterminal whose production has a hole at the position where β would slot in. The flanks α and γ are the sibling material already accounted for in the zipper context.

Claim: R(β) = the set of nonterminals reachable by climbing the zipper from β's focus position, over all valid zipper contexts consistent with the grammar. The H-cover algorithm then enumerates these zipper positions mechanically via the recognition table.

Open: formalise "zipper hierarchy" as a tree-zipper over derivation trees, and show the climbing in R(αβγ) = ∪_{A∈R(β)} R(α'Aγ') corresponds exactly to one step up the zipper spine.

## Terminology overload — "complete" / "partial" (TODO: resolve)

Two different axes both use "complete" / "partial":

1. **H-cover table items** (`Types`):
   - `CompleteItem nt` — recognized nonterminal over a span
   - `PartialItem (r, s, t)` — H-cover artifact, production r with head at positions s..t

2. **Root candidates** (output labels in `frag_test`, `infer_parse_roots`):
   - "complete" = `missing_left = [] && missing_right = []`
   - "partial" = has missing left or right context

These are related but not the same. A `CompleteItem` at T[0,n] always produces a complete root candidate. A `PartialItem` always produces a partial one. But the `inferred` section of `infer_parse_roots` can produce partial root candidates *from* `CompleteItem`s (climbing NT through productions), breaking the 1:1 mapping.

Need to decide: rename table items, rename output labels, or both. Goal is no overloaded terminology, especially for the paper.

## process_agenda — debug trace available

`process_agenda` and `recognize_with` accept an optional `~debug:true` flag. When enabled, logs each dequeue and every new item added, annotated with the rule that fired (project, eps-project, left-expand, right-expand, rev-right, rev-left). Off by default — no impact on tests or normal runs.
