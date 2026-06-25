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

## L-Reduce / R-Reduce — missing left_expansion virtual cases (FIXED 2026-06-23)

`l_reduce_step` and `r_reduce_step` each apply "virtual extension" — fire a combination rule with one component missing (outside the fragment boundary). They were doing this only for `right_expansions`, ignoring `left_expansions` entirely.

**What was missed:**
- L-Reduce: `find_left_expansions(b)` — b is the known `right_item`, virtual component is `x_h`
- R-Reduce: `find_left_expansions_by_left(b)` — b is the known `x_h`, virtual component is `right_item`

**Why not caught:** Boundary seeding at T[0,1] and T[n-1,n] already uses both rule types. The gap only manifests when the item needing virtual extension first appears at T[0,k] for k > 1, after boundary seeding has run. Test grammars never exercised this.

**Reproducer grammar:** `grammar_lreduce_left_expansion` in `grammars.ml`. Fragment `["c";"d";"e"]` on `X → A D E (head=D), A → B C (head=C)`. Without fix: X not inferred. With fix: X at T[0,3].

**Fix:** added `find_left_expansions` call in `l_reduce_step` (new derivation `FromInductiveFillLeft`) and `find_left_expansions_by_left` call in `r_reduce_step` (reuses `FromInductiveFillRight`). Also added `FromInductiveFillLeft` variant to `types.ml`, `convert.ml`, `reconstruct.ml`. Test: `recognition / l_reduce left_expansion`.

## Coverage grammars added (2026-06-23)

Two new grammars in `grammars.ml` and three tests added to the "recognition" suite (50 total):

**`grammar_rreduce_left_expansion`** — exercises R-Reduce `find_left_expansions_by_left`.
`TOP → F P (head=F)`, `P → B H (head=H)`, `B → C D (head=D)`. Fragment `["f";"c";"d"]` — H missing from P. After the agenda places CompleteItem("B") at T[1,3] via C+D combination, R-Reduce k=0 fires `find_left_expansions_by_left(B)`: left_expansion (P, B, PartialItem(P→BH,1,2)) → P at T[1,3] with virtual H. Agenda then combines P with PartialItem(TOP→FP,0,1) → TOP at T[0,3]. Without the fix (only `find_right_expansions`), P→BH has no right_expansion rule (head at rightmost position), so TOP is never inferred. Test: `recognition / r_reduce left_expansion`.

**`test_arith_fragment_plus_n`** — exercises left_boundary seeding + left_expansion for terminal-head left-recursive grammar. Uses existing `grammar_arith`. Fragment `["+";"n"]`: terminal "+" seeds PartialItem(r,1,2) at T[0,1] during terminal seeding; left_boundary immediately applies `find_left_expansions(PartialItem(r,1,2))` → virtual E sibling → PartialItem(r,0,2) at T[0,1]. Agenda: PartialItem(r,0,2) + T → E at T[0,2]. Confirms boundary seeding handles the left_expansion path for left-recursive grammars.

**Known gap (not yet addressed):** items that arrive at T[0,k-1] via the agenda AFTER boundary seeding fires, but where T[0,n] is already non-empty (so the L-Reduce loop guard `items = []` prevents it from running), are not covered. Example: S → A H B (head=H, middle), fragment ["h";"b"] — PartialItem(r,1,3) reaches T[0,n]=T[0,2] via agenda (B covered), but virtual A is never added because L-Reduce doesn't run and the final pass only uses `find_right_expansions_by_right`. Similarly: the final R/L passes (after the reduce loops) only use one of the two lookup functions each — they mirror the pre-fix gap.

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
