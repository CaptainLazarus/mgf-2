# Open Problems

Running list. Started 2026-08-25. Add, don't prune. Each entry: the question, why it
matters, and how it could be settled.

Status key: `OPEN` untouched | `SKETCH` argued but not proved | `TESTABLE` a concrete
experiment would settle it | `CITE` just needs a paper fetched.

---

## Theory

### T1. Is `Wrap(w)` always a union of rectangles?  `REFUTED 2026-08-25`
**Answer: no, and the question was malformed.** Mezei's theorem: finite union of rectangles
= *recognizable*. Counterexample `s : A s C | B` (`grammars/ancn.g4`), anchor `B`, gives
`Wrap(B) = {(A^n, C^n)}` -- not recognizable. And as originally written ("one rectangle per
derivation shape", no finiteness bound) it was *vacuous*, since any set of pairs is an
infinite union of singleton rectangles. **False if finite, vacuous if not.**
- Replacement claim: `Wrap(w)` has no finite string-pair representation, but the parse
  forest represents it exactly. **So trees are necessary, not convenient.**
- Verified empirically: `bin/rect_probe.ml` shows the parser infers the exact number of
  missing symbols (`A A B` -> `A A B "C" "C"`).
- **But the replacement claim is Lang 1988/1991.** See T2 and `investigation_2026-08-25.md`.

### T2. Are we exact where Rekers & Koorn prune?  `DEFLATED 2026-08-25`
**Lang 1988 is already exact**, so R&K's heuristic pruning was superseded in 1988. Beating
R&K is not a result. The whole exactness framing belongs to Lang:
- Lang 1988 "Parsing Incomplete Sentences": input alphabet extended with `*` = unknown
  sequence; our fragment case is literally the input `* w *`. Produces the output parse
  grammar in finite form. Placeholder nonterminals *with the context-freeness
  justification*, verbatim.
- Lang 1991 sec 2.3: "the complete shared forest may be interpreted as a CF grammar `G_s`
  ... precisely a grammar of the sublanguage `L_s` of all sentences that match the
  incomplete sentence `s`."
- `paper/citations.md` already noted Lang 1988 as "explicit gap markers required" --
  **that note does not distinguish us**, since our gap pattern is fixed (`* w *`).

### T2a. Is head-first search actually better than Earley on `* w *`?  `TESTABLE` **<- the live one**
The only surviving contribution shape. Lang is Earley: unidirectional, starts at position
0, i.e. begins by expanding the `*` -- the point of maximum uncertainty. Head-driven starts
*inside* `w`, where the evidence is. "Start from the evidence, not the edge" only makes
sense for fragments.
- **This replaces T2 as the Evaluation section's comparison target.** The baseline is Lang
  1988 on `* w *`, not Rekers-Koorn or Osorio.
- Needs: a Lang-style Earley reference implementation in `compare/`, then table
  size / step count / wall clock on the same fragments.

### T3. Does binarization's extra commitment cost fragment completions?  `TESTABLE`
H-cover fixes the start cell (`tau_r`) at compile time. Binarization fixes the start cell
*and* the path through the item grid. Strictly more commitment.
- Counting only shows binarization commits *more*, not that the extra commitment *hurts*.
- Asserted "don't binarize" on 2026-08-25 on the strength of counting alone. Overreach.
- Experiment: binarize a small grammar head-outward, run the same fragment through both,
  diff the completions.

### T4. Is binarization compile-time subsumption blocking?  `TESTABLE`
Both reduce the derivation count of an item to one — binarization by making alternate
routes inexpressible, blocking by pruning them at runtime. Conjecture, stated not proved.
- Experiment: binarize head-outward, disable `blocked_left`/`blocked_right`
  (`lib/table.ml:36-62`), compare derivation counts against unbinarized + blocking on.

### T5. Does fixing `tau_r` lose completions that boundary seeding doesn't recover?  `OPEN`
Fixing the head means a fragment not containing the head has nowhere to project from.
Boundary seeding (`lib/recognize.ml:52-60`) is the patch — it seeds `T[0,1]` and
`T[n-1,n]` regardless of head position. Is the patch *complete*, or only a partial repair?
- Related: Satta & Stock's published objection to Kay 1989's canonical expansion order is
  exactly a completeness objection (Prop 4.5 in the proofs doc).

---

## Literature

### L1. Kay 1989 — obtain before citing.  `CITE`
Theorem 4.4 in the proofs doc (canonical expansion order) is Kay's, cited via Satta &
Stock AAAI-91. Have not read the original. Section 4 of the proofs doc still presents it
as a theorem of ours; must be rewritten as a cited remark.

### L2. Rosenkrantz & Lewis 1970 — verify the left-corner attribution.  `CITE`
`docs/cnf_derivative.md` section 1 claims the one-sided derivative over CNF is a
left-corner transform, attributed from memory. Get the paper.

### L3. Osorio & Navarro: `S` recurrence index.  `OPEN`
Printed as `M_{n-i-1, n-j}`; the derivation gives `M_{n-i+1, n-j}`. At `n=3, i=2, j=1` the
printed form indexes out of bounds. **Read through `pdftotext` — a `+` misread as `-` is
entirely plausible. Inspect the glyph in the rendered PDF before believing this.**

### L4. Osorio & Navarro: does `I` ever contain `P_n` / `S_n`?  `OPEN`
`I <- mid([P_n V]) union mid([V S_n]) union union_i mid([P_i S_{n-i}])` never inserts
`P_n` or `S_n` themselves, though the authors state "all suffix strings are also infix
ones". Their worked example masks it (`P_n subset I` via other terms).
- Needs a constructed counterexample grammar before this is asserted as a defect.

### L5. `paper/citations.md` carries a wrong note on Lang 1988.  `NEEDS USER EDIT`
Filed as *"Same model — explicit gap markers required."* That note **does not distinguish
us**: our gap pattern is fixed at `* w *`, so the markers are free and Lang's algorithm
covers the case directly. This one line is why the Lang prior art went unnoticed for
months. Left unedited on purpose — it is the user's prose.
- Also: Lang 1988 must move to the *front* of Related Work, and Lang 1991
  (`paper/download.pdf`) is not in `citations.md` at all.
- **General lesson: re-read what is already cited before trusting the note attached to it.**

---

## Implementation / behaviour

### I1. `frontier_bfs` asymmetry.  `OPEN`
User suspects the lookup/`make_deriv` pairing in the `l_reduce_step` / `r_reduce_step`
call sites is wrong. Flagged 2026-06-25. See `bug_asymmetry_suspicion` memory.

### I2. Final passes use only one lookup each.  `OPEN`
Same structural gap that the 2026-06-23 L/R-Reduce fix repaired in the reduce loops:
`recognize.ml` final passes call one of `find_right_expansions` /
`find_left_expansions_by_left` but not the symmetric partner throughout. Items reaching
`T[0,n]` with `T[0,n]` non-empty get no virtual extension via the left_expansion path.

### I3. Should final passes run for non-language fragments?  `OPEN`
Currently gated on `T[0,n]` being empty.

### I4. L-Reduce / R-Reduce cross-feeding.  `OPEN`
Could running them against each other's output improve coverage? Currently R-Reduce only
runs if L-Reduce left `T[0,n]` empty.

### I5. Does `FromEpsilon` ever produce a tree `FromProject` doesn't?  `OPEN`
If not, `FromEpsilon` can be suppressed whenever a non-epsilon derivation exists for the
same item, killing a class of tree noise.

### I6. L-Reduce frontier climbing possibly redundant.  `OPEN`
The agenda already projects upward after combination. Needs checking.

### I7. A fragment that is itself a complete sentence reports only that.  `OPEN`
`dune exec bin/rect_probe.exe -- grammars/ancn.g4 B` returns one tree, `gaps=0`. It does
not report that `B` can also sit inside `A B C`, `A A B C C`, ... Almost certainly the
suppress-projection optimization (CompleteItems at `T[0,n]` skip `do_project` in
`worklist.ml`). For fragment parsing this is arguably wrong: "this hunk is a complete
statement" and "this hunk could also be the body of a loop" are both answers the user
wants. Found 2026-08-25 while building the Mezei counterexample.

---

## Repo state (as of 2026-08-26, uncommitted)

Nothing from the 2026-08-24/25 theory work is committed. Untracked or modified:

- untracked docs: `anchored_derivative.md`, `anchored_derivative_proofs.md`,
  `cnf_derivative.md`, `derivative_grammars_worked.md`, `investigation_2026-08-25.md`,
  `literature_check_2026-08-24.md`, `min_cover_paper.md`, `open_problems.md`,
  `osorio_navarro_review.md`, `theory_min_cover.md`, `theory_walkthrough.md`
- untracked code/data: `grammars/ancn.g4`, `bin/rect_probe.ml` (+ several other
  `grammars/*.g4` from earlier sessions)
- modified: `bin/dune` (one added stanza for `rect_probe`), plus `bin/main.ml`,
  `test/test_specs.ml`, `paper/refs.bib` and others from earlier work

`bin/rect_probe.ml` + `grammars/ancn.g4` are what make the Mezei refutation reproducible
without re-deriving it — worth keeping. The `bin/dune` stanza is the only change to a
tracked file that this session caused; reverting it only costs the probe.

`bin/main.ml` is still wired per earlier sessions, not to `cparser.g4` — check before
committing.

## Notes

- Nothing in `cnf_derivative.md` has been run against the implementation. All on paper.
- **2026-08-25: T1 refuted, T2 deflated. See `investigation_2026-08-25.md`.** The theory
  paper as conceived is gone -- Lang 1988/1991 owns the characterisation. What survives is
  **T2a** (head-first vs Earley on fragments) plus the empirical kernel-patch work.
  Related Work must now lead with Lang.
