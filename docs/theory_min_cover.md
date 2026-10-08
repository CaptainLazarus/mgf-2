# Minimum Covering Nonterminals via Derivative Grammars

Extends Henriksen–Bilardi–Pingali (OOPSLA 2019), "Derivative Grammars." Scope:
**right completion only** — fragment w has a complete left edge, missing right
context. Left-missing / infix is Part II (deferred; delta list at the end).

This version supersedes an earlier LCA/parse-tree draft of this file. That
draft defined minimality via "lowest common ancestor in a completion tree";
this version replaces it with a definition built directly from derivative
grammars (least possible completion, ranked). The two are compared and the
tree-based one is shown not to be needed — see §6.

Worked throughout on `grammar_gcl` (`lib/grammars.ml`):
```
S  → NP VP
VP → cl v NP
NP → det n
```
No epsilon productions anywhere in this grammar.

---

## 1. Recap: the derivative grammar is the completion generator

Henriksen's construction: reading a terminal rewrites the grammar. Reading
`w = t₁…tₙ` from Γ produces the iterated derivative grammar Γ_w (Definition
3.3), whose start symbol represents "the rest of the language" after w. For
*any* nonterminal A (not just the start symbol S), the same construction
produces `A_w`, and by Theorem 3.6 (correctness of pruned derivative
grammars):
```
L(A_w) = D_w(L(A)) = { β : A ⇒* wβ }
```
This holds uniformly — every production of every nonterminal gets
differentiated at every step, so `A_w` exists (as a candidate symbol) for
every `A ∈ N`, whether or not it turns out productive.

**Convention (Definition 3.4):** `A_ε = A`. The plain, unsubscripted
nonterminal *is* the nonterminal subscripted by the empty string — the state
"haven't read any of w yet." This matters in §7.

---

## 2. Least Possible Completion (LPC)

*In words:* build the derivative grammar Γ_w. It has a subscripted symbol
`A_w` for the nonterminal A. LPC(A, w) is the set of shortest strings `A_w`
can derive — the shortest ways to finish w under category A, keeping all ties.

*In formula:*
```
LPC(A, w) = { β ∈ L(A_w) : |β| = min{ |β'| : β' ∈ L(A_w) } }
m(A)      = |β| for any β ∈ LPC(A, w)     (well-defined: all elements tie)
```

Ties are kept deliberately (not broken by a secondary order); ranking/pruning
among ties is a later concern, not part of the definition.

---

## 3. Covering nonterminal

```
A covers w   :⟺   L(A_w) ≠ ∅   ⟺   LPC(A, w) ≠ ∅
```
"A covers w" means A can derive something that *begins with* w — w is a
valid prefix of some string A generates. (Not "substring" in general — this
document is right-completion only; general substring/infix containment is
Part II.)

`A_w` failing to exist at all (a terminal mismatch kills the inference chain
partway through) and `A_w` existing with zero productions are the same
observable outcome (`L(A_w) = ∅`) — there is no third state. "Exists" is not
a separate filter from "productive."

---

## 4. Minimum covering nonterminal(s)

```
Cov(w)      = { A ∈ N : A covers w }
MinCover(w) = { A ∈ Cov(w) : m(A) = min_{B ∈ Cov(w)} m(B) }
```
The covering nonterminal(s) whose shortest completion is *globally* cheapest
— "smallest" meaning fewest assumed/synthesized terminals, not a single
distinguished winner. Ties are kept.

---

## 5. Lemma (zero floor)

If `A_w` is nullable (`A_w ⇒* ε`, i.e. `m(A) = 0`), then `A ∈ MinCover(w)`
unconditionally — no comparison against other covers is needed, since a
completion length can never be negative and 0 is therefore an absolute floor.

Nullable is a *special case* of covering, not the general rule: many
fragments have a nonempty Cov(w) with no nullable member at all (§8, example
`cl v`).

---

## 6. Why the LCA/tree definition is not needed

*(Superseded material — kept as the record of why the switch happened.)*

An earlier draft defined "minimum covering nonterminal" as the label of the
lowest common ancestor of w's leaves in a completion tree, worrying that
global cost-ranking (§4) might not track this structural notion — e.g. that
a "wrapper" nonterminal B could out-rank the true tight fit A on cost, by
accident, via some unrelated alternate production.

Two attempts to construct this failure mode, both collapsing:

1. **B's alternate production is too short to survive reading all of w.**
   E.g. `Y → p` cannot compete for w = "p q" — differentiating by the second
   symbol kills it (`Y_p → ε` has nothing left to consume `q` with). Length
   mismatches are filtered out by construction, the same way `VP_det` never
   gets generated when `VP`'s production starts with `cl`.
2. **B's alternate production survives and ties/beats A.** E.g. adding
   `Y → p q` alongside `X → p q` (with `Y → X r` also in the grammar) makes Y
   tie with X at cost 0. This is not corruption: `Y → p q` is a real
   production, so "p q" genuinely *is* a complete Y as well as the start of
   an X — the tie is reporting real grammatical ambiguity, not noise.

**General argument:** any finite `m(B) = k` means literally `B ⇒* wβ, |β|=k`
— a real derivation, never an artifact of which production supplied it. And
per the zero-floor lemma, the true tight fit can never be *illegitimately
excluded* once it hits cost 0, since nothing beats free. So global
cost-ranking cannot produce a false answer; it can only reveal genuine
ambiguity that a single-tree LCA definition would have hidden by fixing one
witness tree. **MinCover(w) as defined in §4 is sound; the tree-based
definition is dropped as unnecessary, not merely equivalent.**

---

## 7. Scoping rule: N vs N_w

`Cov(w)` and `MinCover(w)` range **exclusively** over the subscripted symbols
`N_w`, never over the plain nonterminals `N`, even though a single fixpoint
pass over Γ_w's full production set computes costs for both simultaneously.

Reason (§1's convention): plain `A` is `A_ε` — "haven't read any of w." Its
cost is the grammar's own shortest-sentence length for A, a constant,
completely independent of w. Example: `cost(VP)` (unsubscripted) = 4 (`cl v
det n`) — true for *every* fragment you will ever ask about, because it
doesn't reference w. Compare `cost(NP_(det n)) = 0` — specific to having just
read `det n`.

The two numbers must still be computed together: a production like
`S_det → NP_det VP` mixes a subscripted symbol (w-relative) with a plain one
(w-independent, "derive a fresh, untouched VP from here") in the same RHS,
so the fixpoint needs both. But only the subscripted half is ever a candidate
for `Cov(w)`/`MinCover(w)`.

```
Cov(w)      only ever tests   A_w
MinCover(w) only ever ranks   A_w
plain-A costs (≡ A_ε costs)   are inputs, never members
```

---

## 8. Computing it: reuse of the paper's own nullability machinery

`m(A)` for every surviving `A_w` is computed by a single shortest-string
fixpoint over Γ_w's full production set — the natural numeric generalization
of a boolean nullability fixpoint (relax each production's cost as
1+sum-of-children, terminals cost 1, take the min over alternative
productions, iterate to a fixed point). This is not new infrastructure:
Appendix A.5 of the paper (Henriksen et al., read directly from the PDF)
already builds a bipartite dependency graph (`Bnull`) to fixpoint-compute
**nullability** per nonterminal — nullability is exactly the boolean
specialization "shortest length = 0" of the same computation. Generalizing
that graph from boolean to numeric cost reuses the existing machinery; it
does not require a second algorithm. (This also lines up with the project's
own pending task, "grammar precomputation — nullable sets, FIRST/LAST sets,"
which is the same computation under a different name. A citable reference
for the general shortest-string-per-nonterminal algorithm — plausibly Knuth
1977 — is still to be confirmed by actually reading it, not asserted here.)

Recursion does not threaten termination of this fixpoint: a nonterminal with
only self-recursive productions and no terminal-only escape simply never
reaches a finite cost (stays at ∞) — that is a normal, correct outcome
(`L(A) = ∅`, an unproductive nonterminal), not a grammar defect. E.g.
`A → aA | a` converges to cost 1 via the escape production; the recursive
branch only ever produces strictly longer candidates and can never win a
minimum.

Since Γ_w is the *pruned* derivative grammar (Definition 3.4 — subscripts
restricted to suffixes of the prefix read so far), `N_w` is finite for any
finite w, so this fixpoint is a finite computation regardless of how long w
gets.

---

## 9. Worked example on `grammar_gcl`

**w = `det n`:**
```
NP_det     → n                       NP_(det n) → ε              m(NP) = 0
S_det      → NP_det VP               S_(det n)  → NP_(det n) VP  m(S)  = 4
                                        (reduces to VP; VP → cl v NP → cl v det n)
VP → cl v NP: first symbol cl ≠ det. VP_det never generated.     VP ∉ Cov(det n)

Cov(det n)      = {NP, S}
MinCover(det n) = {NP}     (LPC = {ε})
```

**w = `cl v`** (illustrates §5's point — Cov(w) can be nonempty with no
nullable member at all):
```
VP_cl      → v NP
VP_(cl v)  → NP                      NP has no epsilon production   m(VP) = 2  (LPC = {det n})

S_cl → NP_cl VP: NP has no production starting with cl → NP_cl has zero
productions → S_cl can never bottom out → S ∉ Cov(cl v)

Cov(cl v)      = {VP}
MinCover(cl v) = {VP},  m(VP) = 2,  no epsilon anywhere
```

---

## 10. Related work

Not written up yet — pending an actual read of the candidate papers rather
than search-result summaries. `paper/citations.md` already has the vetted
NLP-side lineage (bidirectional/island parsing, substring recognition,
gapped-input parsing) plus, from a prior session, Pasti/Opedal et al. 2026
("Prefix Parsing is Just Parsing"), which is worth a direct comparison pass
against §1 once read. A programming-languages-side sweep (LR-based
incomplete-input handling, error-correcting parsers) was drafted this session
and discarded unread — redo properly later, citing only what's actually been
read.

---

## 11. Deferred to Part II (left context also missing)

1. Symmetric prefix-closure construction (A^▷, right quotients) for the case
   where w's left edge is also unknown.
2. Acceptance/covering predicate becomes doubly-relative; straddle test
   needs both a Suff-closed and a Pref-closed half.
3. Re-run §6's soundness argument in the two-sided setting — the zero-floor
   lemma should still hold, but the "attempted counterexample" construction
   should be redone once both sides are open, since the additional freedom
   might change which failure modes are constructible.
4. Straddle test as an oracle for the suspected `l_reduce_step`/`r_reduce_step`
   asymmetry (flagged 2026-06-25) — needs the Part II construction to state.
