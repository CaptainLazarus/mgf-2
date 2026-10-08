# Literature Check on the Anchored-Derivative / H-Cover Results

Run 2026-08-24. **Round 2** — supersedes the first pass. Every source marked [READ] was downloaded
as PDF, converted with `pdftotext`, and grepped/read directly. [SECONDARY] means description only.

> ## ROUND 3 CORRECTION (read this first)
>
> The user has the papers locally in `paper/`, including **`satta1994.pdf` = Satta & Stock,
> *Artificial Intelligence* 69 (1994) 123-164** — the source I had listed as unobtainable.
> Reading it changes the framing of this whole document:
>
> **The H-cover IS Satta & Stock 1994.** Their §5 uses `h-item`, `cover G_H`, `I_r^{(s,t)}`,
> `left-expand` / `right-expand`, and the recognition matrix `t_{i,j}` — the project's exact
> vocabulary and data structures. So the H-cover, the double-dotted items, and the expansion rules
> were never *claimed* as novel: they are **the algorithm this project implements**. Reporting them
> as "prior art that scoops you" was a category error on my part. Sections 1-2 below should be read
> as "here is where the implemented algorithm comes from", not "here is what you lost".
>
> **Subsumption blocking is already implemented.** Satta & Stock 1994 p.137:
> "Every time we decide to 'extend' an h-item `I_r^{(s,t)} ∈ t_{i,j}` at one side ... we record it by
> updating a set-valued symbol `Q(i,j,d)`, `d ∈ {left,right}`. In this way we are able to block
> further extensions of h-item `I_r^{(s,t)}` at the opposite side. This technique is called
> **subsumption blocking** and was originally presented in [31]." — That is `blocked_left` /
> `blocked_right` in `lib/types.ml:45`, `is_blocked_left` / `is_blocked_right` /
> `block_left` / `block_right` in `lib/table.ml:36-62`, used at `lib/worklist.ml:30,37,52,59`.
> **Action item 4 in §8 is already done. Delete it.**
>
> **Also theirs: the infix condition.** Satta & Stock 1994 §3: "This property is called the valid
> prefix property ... In bidirectional parsing this property can be replaced by a similar 'infix'
> condition", followed by their Eq. (2) over `t_{i,k}`, `t_{k,j}`.
>
> **New prior-art hit found locally: `saito1994.pdf`** — Saito, "Bi-directional LR Parsing from an
> **Anchor Word** for Speech Recognition". Bidirectional parsing "starting from an anchor symbol and
> expanding in both left and right" directions, with multiple anchors. The word "anchor" for this
> construction is taken. Use `C_L(w)` / "context set" language instead.
>
> **Osorio & Navarro confirmed as tier 1** (`Decision_problem_of_substrings_in_Context_Free_Lan.pdf`):
> "an algorithm which, given a CFG and a string `α`, decides whether a string of the form `βαγ`
> belongs to the language or not ... compute the sets of non-terminal symbols that can produce every
> substring." Decision + NT sets. No contexts, no trees. Exactly `C_L(w) != {}` per nonterminal.

**Bottom line: nearly everything mechanical is prior art, from four separate papers. The
tree-with-context-placeholder OUTPUT is Rekers & Koorn 1991. What survives is narrow but real: the
identification of that output with the context set `C_L(w)`, and the exactness claim (Thm 7.3).
Adjust the contribution claim accordingly before writing anything.**

---

## 1. Verdict table

| result | verdict | prior art |
|---|---|---|
| Def 5.1 `C_L(w) = {(u,v) : uwv ∈ L}` | **CLASSICAL** | Clark & Eyraud JMLR 2010 **Def 1**, verbatim. Underlies the syntactic congruence (Def 2) [READ] |
| Prop 3.1 normal form (double-dotted item) | **NOT NOVEL** | Satta & Stock 1989 `[p, ldot, rdot, m]`; Sikkel & op den Akker 1993 `[B -> a.b.c, i, j]` "double dotted (DD) items" [READ] |
| Prop 4.2 routes multiply | **NOT NOVEL** | Satta & Stock 1989 §4 verbatim; restated Satta & Stock 1991 as "the main frailty of bidirectional parsing is (partial) analysis redundancy" [READ] |
| Thm 4.4 canonical order fixes it | **NOT NOVEL — this is KAY 1989** | Satta & Stock 1991 attribute it: "A solution proposed in [Kay, 1989] for head-driven parsing consists of **fixing a privileged order of expansion in each production, which amounts to reducing the size of set I'**" [READ] |
| Prop 4.5 (canonical order breaks fragments) | **NOT NOVEL — it is the published objection to Kay** | Satta & Stock 1991, immediately after: "causes obvious problems for parsing applications that need **dynamic control strategies**... given that words to be chosen as starting islands can fall more than one in the same constituent in an unpredictable way, it is not clear how to accomplish island-driven strategies through static order expansion" [READ] |
| Thm 4.4(c) `Theta(pi^2)` item count | **NOT NOVEL** | Sikkel 1993: `O(\|G\| r n^3)`, "This extra factor r is because we use double dotted, rather than single dotted items" [READ] |
| Thm 5.3 anchored decomposition | **not found stated**, but elementary | Clark & Eyraud Lemma 4/5/Cor 6 are a *different* split (see §3). Operationally it is the scan/complete rule pair of any bidirectional chart parser. **Do not claim it.** |
| Cor 7.4 `C_L(w) != {}` | **NOT NOVEL** | Rekers & Koorn 1991 abstract: "substring-recognize(s) succeeds if and only if `∃v,w : v s w ∈ L`" [READ]. Also the "valid infix property", Sikkel 1993 citing Satta & Stock |
| **Thm 7.3 rectangle decomposition / trees with context placeholders** | **OUTPUT FORM NOT NOVEL; exactness claim not found** | Rekers & Koorn 1991 §5 — see §4. **This is the sharpest hit of the whole search.** |
| Obs 6.2 (anchored equations need no `Null`) | not found | small, but appears to be ours |
| Remark 7.5 (inter-rectangle correlation) | not found | appears to be ours |

---

## 2. Satta & Stock — three papers, not two, and no 1992

Sikkel & op den Akker 1993 cite "(Satta and Stock, 1992)" for the **valid infix property**. There is
no 1992 Satta–Stock paper. Per dblp the Satta–Stock corpus is:

| year | paper | venue |
|---|---|---|
| 1989 | Head-Driven Bidirectional Parsing: A Tabular Method | IWPT [READ] |
| 1989 | Formal Properties and Implementation of Bidirectional Charts | IJCAI [downloaded] |
| **1991** | **A Tabular Method for Island-Driven Context-Free Grammar Parsing** | **AAAI-91, paper AAAI91-023** [READ] |
| 1994 | Bidirectional Context-Free Grammar Parsing for NLP | Artif. Intell. 69 [paywalled] |

Sikkel's "1992" is almost certainly the submitted/preprint version of the 1994 *Artificial
Intelligence* paper. **The 1994 AI paper is the one remaining unread primary source that could
still matter.**

### 2.1 The 1989 duplication control (`m` index)

> "The component `m` is a simple indicator. `m = lm` indicates that the value of `ldot` cannot be
> further diminished... `m = rm` indicates that `rdot` cannot be increased further... **one
> limitation excludes the other**. [...] The use of the index `m` ... **prevents the duplication of
> 'partial analyses' for substrings of w**."

> "Algorithm 3.1 allows the extension of a state to both the left and right sides. This possibility,
> if not carefully controlled, **can lead to the duplication of an analysis** ... two partially
> overlapping states, `s'` and `s''`, for the same analysis."

Their Definition 4.1 is the **Partial Overlapping Relation**.

### 2.2 The 1991 island paper — reads like a description of your parser

> "Island-driven strategies start the analysis of the input sentence from several (dynamically
> determined) positions within it, and **then proceed outward from them in both directions**."

> "a mixed bottom-to-top and top-down approach is followed, **without leading to redundant partial
> analyses**."

And the Discussion section, which is simultaneously our Thm 4.4 *and* our Prop 4.5, with
attribution and a counter-proposal:

> "the main frailty of bidirectional parsing is (partial) analysis redundancy. A solution proposed
> in **[Kay, 1989]** for head-driven parsing consists of **fixing a privileged order of expansion in
> each production, which amounts to reducing the size of set I'**. The use of a strategy specified
> by the grammar writer causes obvious problems for parsing applications that need dynamic control
> strategies... Algorithm 1 allows the use of dynamic strategies, while **subsumption blocking**
> prevents (redundant) analysis proliferation."

> **So: Thm 4.4 = Kay 1989. Prop 4.5 = the published objection to Kay 1989. Their fix
> (subsumption blocking, generalising the `m` index) is better than both and is what to implement.**

### 2.3 Crucial scope limit — island parsing is NOT fragment parsing

The island parser terminates with

    if I_S ∈ t_{0,n} then accept else reject

and the text says "clearly no complete tree can eventually derive the **input string**". The input
`w` is a **complete candidate sentence**; islands are a *search strategy* for parsing all of `w`,
motivated by speech (start from acoustically confident words). It does **not** compute anything
about `w` as a fragment of a larger unseen sentence.

Likewise the "valid infix property" is a **search-discipline** property (the parser never builds an
item unless the covered infix is valid), analogous to the valid prefix property — not an output.

**This is the distinction that keeps a contribution alive. State it explicitly in Related Work.**

---

## 3. Clark & Eyraud — same object, different lemma

> **Definition 1** "The set of contexts, or context distribution, of a string `u` in a language `L`
> is, `C_L(u) = {(l, r) ∈ Σ* × Σ* | l u r ∈ L}`."
> **Definition 2** `u ≡_L v` iff `C_L(u) = C_L(v)`.
> **Lemma 4** if `C(u) = C(u')` and `C(v) = C(v')` then `C(uv) = C(u'v')`.
> *Proof:* "If `(l,r) ∈ C(uv)`, then `(l, vr) ∈ C(u)`..."

Clark splits **the anchor** (`w = uv`) — a deterministic reassociation, one case. Thm 5.3 splits
**the language** (`K_1 K_2`) — two cases, because the seam is a free variable. Adjoint, neither
implying the other. Their Cor 6 also unions over splits of the anchor, not of the language.

---

## 4. Rekers & Koorn 1991 — the sharpest hit [READ]

Abstract:

> "A substring recognizer for a language L determines whether a string `s` is a substring of a
> sentence in L, i.e. `substring-recognize(s)` succeeds iff `∃v, w : v s w ∈ L`. [...] By extending
> the substring recognizer with the ability to **generate trees for the possible contextual
> completions of the substring**, we obtain a **substring parser**, which can be used in a
> syntax-directed editor to **complete fragments of sentences**."

§5, on the trees they generate for `σ_1 s σ_2`:

> "only when the frontier of each of its subtrees contains at least one symbol of `s`; i.e., **we do
> not generate subtrees whose frontier lies entirely within `σ_1` or `σ_2`**. The trees that we
> generate are the **most general trees**, as it is not possible to replace any of their subtrees by
> a non-terminal such that the frontier still contains `s` as a substring."

> "As the total number of possible completions will often be **infinite**, only **generic
> completions** are generated."

**Therefore:** trees whose unparsed left/right context is represented by *nonterminal placeholders*,
with a rule against descending into those placeholders, is **Rekers & Koorn 1991**. That is our
`Virtual` node / `missing_left` / `missing_right` output, and our
"don't descend into virtual NTs" rule. **Not novel.**

### What is still not theirs

§5.2 is openly heuristic. They say the most-general set is "often still too large and not even
always finite" and add three *ad hoc* pruning rules — forbid `A ⇒⁺ αA`, `A ⇒⁺ αAβ`, `A ⇒⁺ Aβ`;
`remove-cycles`; and "prefer the simplest completion", i.e. prefer `A ::= αβ` over `A ::= αγ` when
`|β| < |γ|`. Those rules **discard** completions. There is no claim, and given rules 1 and 3 no
possibility, that the output is a *complete and exact* representation of the completion set.

Theorem 7.3 claims exactly that: `C_L(w) = ∪_T L(ml(T)) × L(mr(T))`, an equality. **The
contribution, if there is one, is the exactness and the identification with `C_L(w)` — not the
output format.** And Thm 7.3 is still only a sketch.

---

## 5. Nederhof & Satta 2011 — infix probabilities [READ]

> "we are given a PCFG `G` and a string `w`, and we are asked to compute the probability that a
> sentence generated by `G` has `w` as an **infix**. This probability is defined as the possibly
> infinite sum of the probabilities of **all strings of the form `xwy`, for any pair of strings `x`
> and `y`**."

That sum is over exactly `C_L(w)`. So they compute a **measure** of the context set. This gives a
clean three-tier framing for Related Work:

| tier | object | who |
|---|---|---|
| decide | `C_L(w) != {}` | Rekers & Koorn 1991; Osorio–Navarro |
| measure | `P(C_L(w))` | Nederhof & Satta, EMNLP 2011 |
| **represent** | `C_L(w)` **structurally, exactly** | claimed here (Thm 7.3) — R&K get the format but not exactness |

(Careful: Nederhof & Satta 1994 "An Extended Theory of Head-Driven Parsing" [READ] uses "common
infix" for a *shared infix of two right-hand sides* — an unrelated technical sense. Don't conflate.)

---

## 6. Adjacent, do not confuse

- **Two-sided quotient** `u^{-1} L v^{-1} = {x : uxv ∈ L}` — the **dual**: fixes contexts, returns
  middles. Basis of **biautomata** (Klíma & Polák) [downloaded]. `C_L(w)` fixes the middle.
- **Mignot, arXiv 1301.3316** [downloaded] — two-sided derivatives for regular and hairpin
  expressions; the payoff is that hairpin completions are **linear context-free**. Regular-language
  setting, not CFG parsing.
- **Ginsburg & Spanier, JACM 10 (1963) 487–492** [SECONDARY] — quotient of a CFL by a *regular*
  language is context-free; undecidable in general for two CFLs.
- **Might, Darais & Spiewak, ICFP 2011** [downloaded] — left derivative only, left-to-right.
- **van Noord, CL 23(3) 1997** [downloaded] — "parser is bidirectional, starting from a head outward
  (**island-driven**)". Confirms head-corner ≡ island-driven in this literature.
- **Kay 1989** — the privileged-expansion-order idea. **Not yet obtained; cited only via Satta &
  Stock 1991.** Get it before citing.

---

## 7. Revised position

Gone: the normal form, the route-duplication finding, the canonical-order fix, its fragment
objection, the item-count bound, the substring decision, the tree-with-placeholder output format.

Possibly remaining:

1. **The identification.** That the object a head-corner fragment parser computes *is* `C_L(w)`, the
   context set of the syntactic congruence. The parsing literature never names it; the
   distributional-learning literature never parses. Not found joined anywhere.
2. **Theorem 7.3, exactness.** `C_L(w) = ∪_T L(ml(T)) × L(mr(T))` as an equality, versus Rekers &
   Koorn's heuristically pruned "most general completions". **Still a sketch — prove it or drop it.**
3. **Remark 7.5** — the correlation is inter-rectangle, so a flat context set loses it.
4. **Obs 6.2** — the anchored equations carry no nullability predicate.

Items 3 and 4 are remarks, not a paper. **Item 2 is the paper, and it is unproved.**

---

## 8. Next actions

1. **Prove Theorem 7.3.** Everything rests on it now. Define the anchor path for `|w| > 1`.
2. **Get Satta & Stock 1994** (Artif. Intell. 69) — the one unread primary source that could still
   preempt something. Paywalled; try the library.
3. **Get Kay 1989** before citing it for Thm 4.4.
4. **Implement subsumption blocking / the `m` lock** in `worklist.ml` (Satta & Stock 1989 §4, 1991).
   Published, better than the canonical-order fix, and preserves fragment coverage.
5. Rewrite §4 of `anchored_derivative_proofs.md` as a cited remark, not a theorem.
6. Rename `<w>L` to `C_L(w)`, citing Clark & Eyraud Def 1.
7. Related Work must explicitly distinguish **island-driven parsing** (complete sentence, islands as
   search strategy) from **fragment parsing** (input IS the fragment, context existentially
   quantified). That distinction is what is left of the novelty.

---

## Sources

**[READ] — PDF obtained, text extracted, read:**
- Clark & Eyraud, JMLR 11 (2010) 2707–2744. https://jmlr.csail.mit.edu/papers/volume11/clark10a/clark10a.pdf
- Satta & Stock, IWPT 1989. https://aclanthology.org/W89-0205.pdf
- **Satta & Stock, AAAI-91, paper AAAI91-023.** https://cdn.aaai.org/AAAI/1991/AAAI91-023.pdf
- Sikkel & op den Akker, IWPT 1993. https://aclanthology.org/1993.iwpt-1.21.pdf
- **Rekers & Koorn, IWPT 1991.** https://aclanthology.org/1991.iwpt-1.25.pdf
- Nederhof & Satta, EMNLP 2011. https://aclanthology.org/D11-1112.pdf
- Nederhof & Satta, ACL 1994. https://aclanthology.org/P94-1029.pdf

**Downloaded, skimmed:** Satta & Stock IJCAI 1989 (https://www.ijcai.org/Proceedings/89-2/Papers/100.pdf);
van Noord CL 1997 (https://aclanthology.org/J97-3004.pdf); Mignot (https://arxiv.org/pdf/1301.3316);
Klíma & Polák (https://www.math.muni.cz/~klima/Math/biautomata-for-DLT.pdf);
Might et al. (http://david.darais.com/assets/papers/parsing-with-derivatives/pwd.pdf)

**Not obtained:** Satta & Stock, Artif. Intell. 69 (1994) — paywalled, https://doi.org/10.1016/0004-3702(94)90080-9 ·
Kay 1989 · Bojar et al., CICLing 2006 · Conway ch. 6 · Ginsburg & Spanier 1963

Local copies: `/tmp/claude-1000/.../scratchpad/lit/` (session-scoped — re-download if needed).
