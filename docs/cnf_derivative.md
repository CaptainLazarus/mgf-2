# Derivatives over Chomsky Normal Form

Date: 2026-08-25. Companion to `anchored_derivative.md`, `anchored_derivative_proofs.md`,
`derivative_grammars_worked.md`, `osorio_navarro_review.md`.

Question asked: *what does a derivative look like if the grammar is in CNF?*

Short answer: **CNF is the degenerate case of everything in the anchored-derivative
document.** Every quantity that made the H-cover complicated (nullability token, route
interleaving, canonical item restriction, subsumption blocking) evaluates to a constant.
The straddle family survives, and is the only thing that does.

---

## 0. Setup

Chomsky Normal Form, strict:

```
A -> B C        B, C nonterminal
A -> a          a terminal
S -> eps        only if eps in L, and S occurs on no RHS
```

Write `L(X)` for the language of nonterminal `X`.
`pi_r` = RHS length (always 2 for binary rules), `tau_r` = head position.

Notation reused from the proofs doc:

- `d_a L = { v : av in L }`            left (Brzozowski) derivative
- `L d_a = { u : ua in L }`            right derivative
- `C_L(w) = { (u,v) : uwv in L }`      anchored relation (Clark & Eyraud 2010, Def 1)
- `R .r K = { (u, vy) : (u,v) in R, y in K }`   grow right context
- `K .l R = { (xu, v) : (u,v) in R, x in K }`   grow left context
- `nu(X) = eps if X nullable, else empty`

---

## 1. One-sided derivative: the nullability token disappears

General CFG rule (the `A -> alpha X beta` scan in `derivative_grammars_worked.md`):

```
d_a L(A) = union over A -> X1...Xk of
             union over i with X1..X(i-1) all nullable of
               nu(X1..X(i-1)) . d_a L(Xi) . L(X(i+1)..Xk)
```

The inner union is what forces the nullable-prefix scan.

In CNF, take `A -> B C`. `B` occurs on a RHS, so by the CNF side condition `B != S`,
hence `B` is not nullable, hence `nu(B) = empty`. **The scan stops at position 1, always.**

```
d_a L(A) = union over A->BC of  (d_a L(B)) . L(C)
         union over A->a of     { eps }
```

Two clauses, no side conditions, no fixpoint. As a grammar over derived symbols `A_a`:

```
A_a -> B_a C      for each A -> B C
A_a -> eps        for each A -> a
```

Observations:

1. **Exactly one derived symbol per RHS, always leftmost.** The derived symbols form a
   linear spine. That spine is the left-corner chain of the parse tree, so `d_a` on CNF
   *is* a left-corner transform (Rosenkrantz & Lewis 1970). This is not new; flagging it
   so we don't re-discover it a third time.
2. **Termination is free.** At most `|N|` derived symbols per terminal, `|N|.|Sigma|`
   overall. No similarity check, unlike regex derivatives.
3. `d_a L(A)` is still context-free (`C` is an ordinary nonterminal). Linear in the
   *derived* alphabet only.

Right derivative is the mirror image, `A^a -> B C^a`, giving the right-corner chain.

**Honest caveat.** Nullability did not vanish, it was *prepaid*. CNF conversion runs
eps-elimination up front; the fixpoint is in the compiler instead of the derivative.
Same for the `nu` bookkeeping in Remark 6.3 of the proofs doc.

---

## 2. Anchored derivative, |w| = 1: exactly the H-cover expansion pair

Take `A -> B C` and `uav in L(A)`. The yield splits at the B/C boundary. `a` is a single
letter, so it lands strictly inside one side. Two cases, exhaustively:

- `a` inside `B`: `u a v'` in `L(B)` and `v = v' y` with `y` in `L(C)`
- `a` inside `C`: `u = x u'` with `x` in `L(B)` and `u' a v` in `L(C)`

Hence

```
C_L(A)(a) =  union over A->BC of [ C_L(B)(a) .r L(C)  union  L(B) .l C_L(C)(a) ]
             union over A->a of { (eps, eps) }
```

This is Theorem 5.3 of the proofs doc with `pi_r = 2` substituted. As a grammar over
anchored symbols `A<a>`:

```
A<a> -> B<a> C        (left slot anchored)   <- right expansion
A<a> -> B C<a>        (right slot anchored)  <- left expansion
A<a> -> eps           for A -> a             <- projection
```

**Those three rules are the entire H-cover.** Projection seeds the anchor at a terminal;
the two expansion rules grow the context outward. The difference from our `h_cover`:

| | anchored derivative on CNF | H-cover |
|---|---|---|
| anchor position | free: both slots generate | pinned: only `tau_r` projects |
| expansion rules | `B<a> C` and `B C<a>` | `find_left_expansions` / `find_right_expansions` |
| arity | 2 | `pi_r`, arbitrary |

So the H-cover is the head-pinned, arbitrary-arity generalisation of this. Nothing here
is a new algorithm; it is a reading of the one we already have.

---

## 3. What CNF kills (the counting)

All four are corollaries of `pi_r = 2`. Formulas from the proofs doc, sections 4 and 8.

| quantity | general | CNF (`pi_r = 2`) |
|---|---|---|
| items per production, `|I_r| = tau_r (pi_r - tau_r + 1)` | up to `~pi_r^2/4` | **2** (`tau=1`: 1x2; `tau=2`: 2x1) |
| reachable *partial* items (excluding `s=0,t=pi_r`, `hcover.ml:8`) | `|I_r| - 1` | **1** |
| expansion routes, `C(pi_r - 1, tau_r - 1)` | exponential in `pi_r` | **1** (`C(1,0)=C(1,1)=1`) |
| canonical set `|Ic_r| = pi_r` vs `|I_r|` | proper restriction | **equal — restriction is vacuous** |

Consequences worth stating plainly:

- **Route duplication cannot occur in CNF.** With one left step or one right step per
  production there is nothing to interleave. This is the retracted claim #1 from
  2026-08-24 (`head does not make it unambiguous`) evaluated at `pi_r = 2`, where it
  happens to be true for a reason that has nothing to do with the head.
- **Subsumption blocking is vacuous in CNF.** `blocked_left` / `blocked_right`
  (`table.ml:36-62`) exist to suppress the interleaving above. With one route there is
  nothing to block. Conjecture, stated as mine, not proved: *binarization is
  compile-time subsumption blocking* — both reduce the derivation count of an item to
  one, one by making the alternate routes inexpressible, the other by pruning them at
  runtime.
- **Kay 1989's canonical expansion order is vacuous in CNF.** `Ic_r = I_r`. Satta &
  Stock's objection to it (Prop 4.5) is about fragment completeness, and is unaffected.

**Honest caveat.** Binarization does not delete the routes, it *picks one at
grammar-compile time*. Head-outward binarization of `A -> X1 X2 X3 X4` with head `X2`
commits to a bracketing; the other `C(pi-1, tau-1) - 1` interleavings are gone because
the grammar no longer expresses them, not because they were shown redundant. The cost
moved, it did not evaporate. Whether the chosen bracketing is the right one for fragment
parsing is exactly the open question — a bad bracketing hides completions.

---

## 4. |w| >= 2: straddle is the only survivor

Everything above used "a single letter lands in one child". For `|w| >= 2` that fails:
`w` can span the B/C boundary. Third family:

```
straddle(A, w) = union over A->BC, over w = w1 w2 with w1,w2 nonempty, of
                   { (u,v) : (u,eps) in C_L(B)(w1) and (eps,v) in C_L(C)(w2) }
```

`w1` must be a *suffix* of some B-yield, `w2` a *prefix* of some C-yield. In Osorio &
Navarro's vocabulary that is exactly `last` on the left child and `first` on the right
child (see `osorio_navarro_review.md` section 2), and the three-way split

```
i = 0            anchor entirely in the right child
i = n            anchor entirely in the left child
1 <= i <= n-1    straddle
```

**is their Eq (3).** Independent confirmation of last night's reading: the whole content
of `|w| > 1` is the straddle family, and CNF does not help with it. It is also why
Proposition 5.4 (Theorem 5.3 fails as an equality for `|w| >= 2`) is not an artifact of
arbitrary arity — it survives binarization.

Note the anchored grammar stops being linear here: the straddle rule has `B` and `C`
*both* carrying anchor material. That is the real reason `|w| >= 2` is harder, and it is
independent of arity.

Degenerate case for completeness: `C_L(eps) = { (u,v) : uv in L }`, all splits of all
words of `L`. No anchor, no information.

---

## 5. Verdict

- CNF makes the *machinery* of the anchored derivative trivial (sections 1-3) and leaves
  the *hard part* (section 4) untouched.
- Therefore: binarizing is not a route to a better fragment parser. It buys constant
  factors in the item/route counting and costs a fixed bracketing.
- The genuinely useful output is section 2's table: it says in three lines what the
  relationship between `C_L(w)` and the H-cover expansion rules is, with no `pi_r`
  bookkeeping in the way. Good candidate for the paper's Terminology or Overview section
  as an expository warm-up before the general `pi_r` case.
- It also explains cleanly why Osorio & Navarro can work in CKY/CNF and still lose the
  `(u,v)` correlation: **the loss is not from binarization.** It is from
  `pref(A) = A union [AV]` existentially quantifying the sibling. Two independent things;
  do not conflate them in Related Work.

## 6. Unverified / to do

- The "binarization = compile-time subsumption blocking" conjecture in section 3 is
  stated, not proved. Cheap to check: binarize a small grammar head-outward, run with
  `blocked_left`/`blocked_right` disabled, compare derivation counts against the
  unbinarized run with blocking enabled.
- Left-corner-transform identification in section 1 is from memory of Rosenkrantz &
  Lewis 1970; get the paper before citing.
- Nothing here has been run against the implementation. It is all on paper.
