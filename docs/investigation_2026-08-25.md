# Investigation 2026-08-25: tree automata, Mezei, and the Lang prior-art hit

Triggered by "have a look at tree automata, start with the Adams & Might paper".
Outcome: **T1 refuted, repaired, and then the repaired version found to be Lang 1988.**
Read the verdict in section 5 before acting on anything here.

---

## 1. Adams & Might 2017, "Restricting Grammars with Tree Automata"

PACMPL 1(OOPSLA):82. Local copy `~/Downloads/3133906.pdf`; author copy at
`michaeldadams.org/papers/restricting-grammars-with-tree-automata/tree-automata-parsing.pdf`.

What it does: reinterpret a CFG as a **tree automaton** (same productions, labelled,
matching parse *trees* not strings), intersect with hand-written tree automata that forbid
shapes (dangling else, JS `new`, C declarators), convert back to a CFG.

Facts worth keeping:
- A tree automaton is `A = (Q, F, S, delta)` with productions `q ->f q1...q_|f|`. A CFG
  becomes one by labelling productions; the reverse by erasing labels. **CFG and tree
  automaton are the same object under two readings.**
- **Intersection and difference are undecidable on CFGs but computable on tree automata**,
  because the tree view keeps the structure the string view discards. Union, intersection,
  complement, determinisation, minimisation, equivalence: all available
  (Comon et al. 2007). Intersection is a Cartesian product of states.
- Section 2.3: a tree automaton can be read as a **string automaton over root-to-leaf
  paths**. Paths encoded as label/child-index strings, e.g. `+2*1N3$`.

**What it does NOT do.** Grepped the full text: **zero occurrences of "yield" or
"frontier".** Every restriction they express is about tree *shape* — which node may sit
under which. Nothing constrains the string the tree spells out. So their technique does not
transfer to fragment constraints, which are inherently yield constraints. Honest negative.

The paper is still worth keeping for a different reason — see section 6.

---

## 2. T1 is refuted

**Mezei's theorem** (verified): for monoids `M1...Mn`, a subset of `M1 x ... x Mn` is
*recognizable* iff it is a **finite union** of `R1 x ... x Rn` with each `Ri` recognizable.
So "finite union of rectangles" is exactly "recognizable", and T1 was a recognizability
claim. That makes it checkable. It fails.

```
s : A s C | B ;              L = { A^n B C^n : n >= 0 }
```

Anchor `w = B`:

```
Wrap(B) = { (A^n, C^n) : n >= 0 }
```

Not a finite union of rectangles. Standard argument: any rectangle containing two distinct
`n` values on the left also contains a mismatched pair, and `A B C C` is not in `L`.

**Worse, T1 was badly stated.** It said "one rectangle per derivation shape" with no
finiteness bound. An infinite union of rectangles is trivially true of *any* set of pairs
(take singletons). So T1 was **false if finite, vacuous if not**. It was never a theorem.
It survived because nobody tried to break it.

Grammar committed as `grammars/ancn.g4`.

## 3. The repair, and it holds empirically

The correlation is not merely *lost* by flattening. `Wrap(w)` **cannot be finitely factored
into string pairs at all** — `A^n <-> C^n` is unbounded correlation.

But a parse forest is a finite object, and it represents that same infinite correlated set
exactly, because the correlation is carried by *recursion in the tree*, which costs nothing.

| view | represents `Wrap(w)` exactly? |
|---|---|
| set of string pairs | **no** — not finitely, ever |
| `Left x Right` | no — strictly worse, a single rectangle |
| a forest / regular tree grammar | **yes** |

> Outputting trees is not a convenience. It is the only finite representation that exists.

**Verified against the implementation** via `bin/rect_probe.ml` (added this session;
`dune exec bin/rect_probe.exe -- grammars/ancn.g4 A A B`):

```
A B      ->  A B "C"              exactly one C
A A B    ->  A A B "C" "C"        exactly two Cs
B C C    ->  "A" "A" B C C        exactly two As
A A B C  ->  A A B C "C"          exactly one more C
```

The parser infers the *exact* number of missing symbols. A `Left x Right` method would
say "some number of Cs" and could not say "one".

**One anomaly, worth chasing.** Input `B` alone returns a single tree with `gaps=0` —
only the `n=0` completion. It does not report that `B` can also sit inside `A B C`. This is
almost certainly the suppress-projection optimization (`worklist.ml`, CompleteItems at
`T[0,n]` skip `do_project`). See open problem I7.

---

## 4. The Bar-Hillel threat, checked — and it is worse than Bar-Hillel

The threat was: `L intersect Sigma* w Sigma*` is classical (Bar-Hillel), polynomial, and
gives a CFG for exactly the strings containing `w`. If fragment parsing reduces to that,
the characterisation contributes nothing.

It does reduce to that, and someone published it. **Bernard Lang.** Both papers were
already in `paper/`.

### Lang 1988, "Parsing Incomplete Sentences" (COLING, `parsing incomplete sentences.pdf`)

- Extends the input vocabulary with `?` = one unknown word, `*` = an unknown *sequence*.
  **Our fragment case is exactly the input `* w *`.**
- Earley-based; produces the output parse grammar `G_s` in finite form,
  "all possible parses (often infinite in number) that could account for the missing parts".
- On placeholders, verbatim: *"Since the subsequence is unknown anyway, its hypothetical
  structures can be summarized by the nonterminal symbols that dominate it (thanks to
  context-freeness)."* — that is our `Virtual` node, **including the context-freeness
  justification I gave for rectangles.**
- *"to keep the output readable, we usually qualify these `*` symbols with the appropriate
  nonterminal"* — that is `Virtual of h_item_or_terminal`.
- Footnote 8 handles the cyclic-rule blowup (`X -> aX` behaves as `X -> X`); finiteness
  from a bounded item count.
- Footnote 10: if the input is `*` alone, the output grammar is the original grammar.

### Lang 1991, "Towards a Uniform Formal Framework for Parsing" (`paper/download.pdf`)

Section 2.3, "Parse forests for incomplete sentences":
- *"Such an incomplete sentence s may be understood as defining a sublanguage L_s which
  contains all the correct sentences matching s."* — that is `Wrap(w)`.
- *"The complete shared forest may be interpreted as a CF grammar G_s. This grammar is
  precisely a grammar of the sublanguage L_s of all sentences that match the incomplete
  sentence s."* — **that is the exact-representation claim, stated and attributed in 1991.**
- *"the forest could be simplified by ... labelling the end node with PP* (resp. NP*),
  meaning an arbitrary PP (resp. NP) constituent."*
- *"given a set of parse trees, they form the set of parses of a CF language iff they can
  be merged into a shared forest that is finite."*
- *"the construction of a shared forest for a (possibly incomplete) sentence may be seen as
  a specialization of the original grammar to the sublanguage defined by that sentence."*
  — the intersection/Bar-Hillel framing, explicit.

`paper/citations.md` already lists Lang 1988 with the note *"Same model — explicit gap
markers required."* **That note does not distinguish us.** Our gap pattern is fixed and
known — every fragment is `* w *` — so the markers are free. The objection does not hold
for this use case.

---

## 5. Verdict

**The theory contribution, as it stood this morning, is gone.**

| piece | whose |
|---|---|
| completion sublanguage `L_s` = `Wrap(w)` | Lang 1988/1991 |
| forest is a finite grammar for it, exactly | Lang 1988/1991; Billot & Lang 1989 |
| placeholder nonterminals for unknown constituents | Lang 1988, explicitly |
| the context-freeness justification for placeholders | Lang 1988, verbatim |
| correctness proof of the constructed forest | Lang 1988 (he flags it as the only such) |
| bidirectional / head-driven machinery | Satta & Stock 1989/91/94 |
| `C_L(w)` as an object | Clark & Eyraud 2010; classical |

T2 (exactness vs Rekers & Koorn's pruning) is deflated too: **Lang is already exact**, so
R&K's heuristic pruning was already superseded in 1988. Beating R&K is not a result.

### What actually survives

1. **The combination.** Lang is Earley — unidirectional, starts at position 0.
   Satta & Stock are bidirectional but for *complete* sentences. Head-driven *fragment*
   parsing appears to be uncombined in the literature. That is what this code is.
2. **A real motivation for it.** For a fragment, the edges are exactly where you have no
   information. Earley on `* w *` starts by expanding `*` — the position of maximum
   uncertainty. Head-driven starts *inside* `w`, where the evidence is. **"Start from the
   evidence, not the edge"** is an argument that only makes sense for fragments, and it is
   testable.
3. **The empirical work.** Characterising syntactic change patterns in kernel patches is
   untouched by any of this.

### What this changes about the paper

- The framing moves from **theory** to **algorithm + evaluation**. Not "we can represent
  `Wrap(w)`" (Lang, 1988) but "we compute it head-first, and for fragments that is the
  right direction".
- **The Evaluation stub's comparison target is wrong.** It was Rekers-Koorn and Osorio.
  The real baseline is **Lang 1988 on `* w *`** — same output, different search order.
  That is the experiment the paper needs.
- Related Work must lead with Lang, not with Osorio.
- The Mezei counterexample stays, but demoted: it is a good *explanation* of why the output
  type must be trees, not a novel result. One paragraph, cited to Mezei.

### Process note

The Bar-Hillel threat was flagged as "worth an hour" and it cost about that. It was the
right thing to check first. Two of the three deciding papers were already in `paper/` and
one was already in `citations.md` with a note that turned out not to hold. **Re-read what
is already cited before trusting the note attached to it.**

---

## 6. Leads not yet pulled

- **Tree automaton equivalence is decidable.** Even with Lang owning the characterisation,
  this gives a way to *test* whether two fragment parsers produce the same forest —
  useful for validating our output against a Lang-style reference implementation.
- **Adams & Might's actual technique** (restrict a grammar by intersecting with a tree
  automaton) is directly usable for the kernel-patch work: "find fragments whose shape
  matches this pattern" is a tree automaton. Applied, unblocked, nothing to do with T1.
- **Path automata** (their section 2.3): a tree automaton as a string automaton over
  root-to-leaf paths. The H-cover climbs the head spine, which *is* a root-to-leaf path.
  Possible reframing: head-driven parsing = a path automaton on the head spine plus lateral
  expansion. Speculative, unexplored.
