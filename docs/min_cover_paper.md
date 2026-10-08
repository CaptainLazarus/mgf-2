# Minimum Covering Nonterminals via Derivative Grammars

*A short note. Right-completion case only (missing right context); the
symmetric left/infix extension is future work.*

## Abstract

Given a context-free grammar Γ and a string fragment w known to be a *prefix*
of some (unknown, longer) sentence of Γ, we ask two questions: which
nonterminals can w be the beginning of, and among those, which is the
tightest fit — the one requiring the fewest additional, synthesized
terminals to close out? We answer both directly from Henriksen, Bilardi, and
Pingali's *derivative grammars* (OOPSLA 2019), with no new construction: the
derivative grammar Γ_w already contains, as one of its ordinary byproducts, a
subscripted nonterminal `A_w` for every nonterminal A of Γ, and `L(A_w)` is
exactly the set of valid completions of w under category A. We define the
*least possible completion* LPC(A, w) as the shortest such completions, use
it to define a covering set and a cost-ranked minimum covering set, prove a
zero-floor soundness property, and show by direct construction that a
plausible alternative (tree-position-based minimality) is unnecessary.

## 1. Background

Henriksen et al. show that reading a terminal `t` from a language L(Γ)
corresponds to rewriting Γ into a *derivative grammar* Γ_t generating the
derivative language `D_t(L(Γ)) = { x : tx ∈ L(Γ) }` (their Definition 3.1,
via inference rules over productions). Iterating over a string
`w = t₁…tₙ` gives Γ_w (Definition 3.3), and for *complete* input, acceptance
is nullability of the (subscripted) start symbol: `w ∈ L(Γ) ⟺ nullable(S_w)`.

We are interested in *incomplete* input: w is known to be a prefix of a
longer sentence, and we want to know what it's a prefix *of*, and what
finishing it would look like. Two observations make this immediate rather
than requiring new machinery:

**Observation 1.** For a prefix fragment, the acceptance test is not
nullability but *productivity*: `w is a prefix of some sentence ⟺
productive(S_w)`. And more than a decision procedure — `L(S_w) = D_w(L(Γ))`
is literally the set of valid completions. The derivative grammar does not
merely decide the prefix property; it generates the missing context.

**Observation 2.** Henriksen's inference rules are not S-specific. Every
production of every nonterminal A gets differentiated at every step, so a
candidate subscripted symbol `A_w` exists for *every* `A ∈ N` — not only the
one the paper happens to track for the accept/reject question. Some survive
to produce a nonempty language; some die partway (a terminal mismatch kills
the chain, and `A_w` simply never gets a production). This is the basis for
everything below: asking "what is w the beginning of" is answered by
checking, for every A, whether its (free, already-computed) derivative `A_w`
is productive.

## 2. Definitions

Fix Γ and a prefix fragment `w = t₁…tₙ`. Build the iterated derivative
grammar Γ_w exactly as in Definition 3.3.

**Least Possible Completion.**
```
LPC(A, w) = { β ∈ L(A_w) : |β| = min{ |β'| : β' ∈ L(A_w) } }
m(A)      = |β|  for any β ∈ LPC(A, w)
```
The shortest strings `A_w` derives — how w finishes under category A, at
minimum synthesized length. Ties are kept, not broken.

**Covering.**
```
A covers w  :⟺  L(A_w) ≠ ∅  ⟺  LPC(A, w) ≠ ∅
```
w is a valid prefix of something A generates. ("Exists but has zero
productions" and "never generated at all" are the same observable outcome —
there is no meaningful third state to track separately.)

**Covering set and minimum covering set.**
```
Cov(w)      = { A ∈ N : A covers w }
MinCover(w) = { A ∈ Cov(w) : m(A) = min_{B ∈ Cov(w)} m(B) }
```
`Cov(w)` is every nonterminal w could plausibly be categorized as, the
beginning of; `MinCover(w)` is the subset achieving the globally cheapest
completion — the tightest fit(s).

## 3. Zero-floor lemma

**Lemma.** If `A_w` is nullable (derives ε, `m(A) = 0`), then
`A ∈ MinCover(w)` unconditionally.

*Proof.* Completion length is non-negative; 0 is therefore a floor no other
`m(B)` can go below. ∎

Nullability of `A_w` means w is not merely a prefix of some A but is *itself*
already a complete instance of A. This is a special case of covering, not
the general phenomenon — many fragments have a nonempty `Cov(w)` in which no
member is nullable (§5, example 2).

## 4. Soundness: an alternative definition, tried and dropped

A natural alternative to §2's cost-ranked definition is a *structural* one:
build a completion tree for w, and call A minimal if it labels the lowest
node dominating all of w's leaves (its cover node / LCA). This raises an
obvious worry about the cost-ranked definition: could some nonterminal B
"beat" the structurally correct tight fit A on cost, purely by accident, via
an unrelated alternate production — i.e., could global argmin ever pick a
cover unrelated to where w actually sits?

We attempted to construct this failure mode directly, twice:

1. *B's alternate is too short.* Giving B an unrelated one-symbol production
   that only matches the first token of w fails immediately: differentiating
   further by w's remaining tokens kills that branch (nothing left on the
   right-hand side to consume them with), the same way a production whose
   first symbol doesn't match w's first terminal never even generates a
   candidate. Length mismatches are filtered out by the construction itself.
2. *B's alternate survives and ties/beats A.* Giving B a full-length
   alternate production identical in shape to A's own tight production makes
   B tie with A at the same minimal cost — but this is not corruption: the
   alternate production is real, so w genuinely *is* (via that production) a
   complete B as well as the start of an A. The tie reports real grammatical
   ambiguity; it does not hide or misrepresent anything.

**General argument.** Any finite `m(B) = k` asserts `B ⇒* wβ` for a real
string β of length k — never an artifact of which production supplied it.
Combined with the zero-floor lemma (the true tight fit, once it hits cost 0,
cannot be beaten), global cost-ranking cannot produce a false or misleading
answer. We therefore drop the tree-position definition as unnecessary rather
than merely equivalent: it can only *hide* genuine ambiguity (by committing
to one witness tree) that the cost-ranked definition correctly reports as a
tie.

## 5. Worked example

Grammar (`lib/grammars.ml`, `grammar_gcl` — a minimal toy grammar with no
epsilon productions, used in this project's test suite):
```
S  → NP VP
VP → cl v NP
NP → det n
```

**Example 1 — w = `det n`.**
```
NP_det → n                NP_(det n) → ε              m(NP) = 0
S_det  → NP_det VP         S_(det n) → NP_(det n) VP    m(S)  = 4
   (reduces to VP; VP → cl v NP → cl v det n is the shortest VP string)
VP → cl v NP: first symbol cl ≠ det ⟹ VP_det never generated ⟹ VP ∉ Cov(det n)

Cov(det n)      = {NP, S}
MinCover(det n) = {NP}        (LPC(NP, det n) = {ε})
```
`det n` is exactly a complete NP; S also covers it (as the start of an NP
inside a full sentence), but at four extra synthesized terminals.

**Example 2 — w = `cl v`** (Cov(w) nonempty, no nullable member — §3's
non-triviality claim, exhibited):
```
VP_cl     → v NP
VP_(cl v) → NP             NP has no epsilon production        m(VP) = 2  (LPC = {det n})

S_cl → NP_cl VP: NP has no production starting with cl
     ⟹ NP_cl gets zero productions ⟹ S_cl can never bottom out ⟹ S ∉ Cov(cl v)

Cov(cl v)      = {VP}
MinCover(cl v) = {VP}, m(VP) = 2, no epsilon anywhere
```

## 6. A scoping hygiene rule

Differentiating Γ_w's full production set in one pass computes costs for
both the subscripted symbols `N_w` and the plain, unsubscripted symbols `N`
(carried forward unchanged by Henriksen's rule (O)). These must not be
conflated. By convention, `A_ε = A` — the plain nonterminal *is* the
nonterminal subscripted by the empty string, representing "haven't read any
of w." Its cost is the grammar's own shortest-sentence length for A, a
constant independent of w (`cost(VP) = 4` regardless of which fragment is
under consideration). `Cov(w)` and `MinCover(w)` range exclusively over
`N_w`; plain-nonterminal costs are necessary *inputs* to the fixpoint (a
production like `S_det → NP_det VP` needs `VP`'s ordinary cost, since
nothing after the differentiation point has been touched by w) but are never
themselves members of the covering set.

## 7. Computation

`m(A)` for every nonterminal is obtained by a single shortest-string fixpoint
over Γ_w — the natural numeric generalization of a boolean nullability
fixpoint (each production's cost is 1 + sum of its children's costs,
terminals cost 1, take the min over alternative productions, iterate to a
fixed point). This is not new infrastructure: it is a direct numeric
generalization of the nullability fixpoint Henriksen et al.'s own Appendix
A.5 already builds (a bipartite dependency graph relaxed to a boolean
fixpoint; nullable is exactly the special case "shortest length = 0").
Recursive nonterminals with no terminal-only escape simply never reach a
finite cost — a normal outcome (`L(A) = ∅`), not a grammar defect. Because
Γ_w is the *pruned* derivative grammar (subscripts restricted to suffixes of
w), `N_w` is finite for any finite w, so the fixpoint terminates. (A citable
reference for the general shortest-string-per-nonterminal algorithm is still
to be confirmed by reading rather than asserted here.)

## 8. Related work

Not written up yet, pending an actual read of candidate papers rather than
search-result summaries. `paper/citations.md` has the vetted lineage this
project already draws on (Osorio & Navarro 2001 state the per-nonterminal
enumeration problem explicitly via CYK, without characterizing missing
context or ranking by completion cost; Pasti, Opedal et al. 2026, "Prefix
Parsing is Just Parsing," is closest in spirit to Observation 1 and worth a
direct comparison once read). A programming-languages-side sweep was drafted
this session and discarded unread.

## 9. Future work

The symmetric case (left context also missing, i.e. general infix/fragment
parsing) requires a prefix-closure construction dual to the one used here,
a two-sided straddle test, and re-examination of §4's soundness argument
under the additional freedom of a doubly-relative predicate. This is Part II,
tracked in `docs/theory_min_cover.md` §11.
