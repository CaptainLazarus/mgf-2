# The Anchored Derivative: Definitions, Theorems, Proofs

Worked 2026-08-24. Everything here is proved from the definitions unless explicitly marked
CONJECTURE or UNCHECKED. Section 9 is the honesty ledger.

Companion to `docs/anchored_derivative.md`, which this document **corrects** in two places
(Remark 4.6 and Remark 8.4).

---

## 1. Preliminaries

Let `G = (N, Sigma, P, S)` be a context-free grammar, `V = N ∪ Sigma`.
For `alpha ∈ V*`, write `L(alpha) = { x ∈ Sigma* : alpha =>*_G x }`.
`eps` is the empty string; `{}` is the empty set.

A **head selection** is a map assigning to each production `r : A -> X_1 ... X_{pi_r}` with
`pi_r >= 1` an index `tau_r ∈ {1, ..., pi_r}`. Productions with `pi_r = 0` (i.e. `A -> eps`)
receive no head and are carried into the cover unchanged.

**Definition 1.1 (item).** For a production `r`, an *item* is a triple `[r,s,t]` with

    0 <= s < tau_r <= t <= pi_r.

Write `I_r` for the items of `r`, `I = ∪_r I_r`. The constraint `s < tau_r <= t` is the
*head-containment* condition. Define `span(r,s,t) = X_{s+1} X_{s+2} ... X_t ∈ V*`.

**Definition 1.2 (H-cover).** `G_H` is the grammar with nonterminals `N ∪ I`, terminals `Sigma`,
start symbol `S`, and productions:

| tag | production | side condition |
|---|---|---|
| (P) | `[r, tau_r - 1, tau_r] -> X_{tau_r}` | every `r` with `pi_r >= 1` |
| (L) | `[r, s-1, t] -> X_s [r, s, t]` | `[r,s,t] ∈ I_r`, `s >= 1` |
| (R) | `[r, s, t+1] -> [r, s, t] X_{t+1}` | `[r,s,t] ∈ I_r`, `t <= pi_r - 1` |
| (C) | `A -> [r, 0, pi_r]` | `r : A -> X_1...X_{pi_r}`, `pi_r >= 1` |
| (E) | `A -> eps` | `r : A -> eps` |

Note (L) is well-formed: `[r,s-1,t]` needs `s-1 < tau_r`, which follows from `s < tau_r`... more
precisely from `s <= tau_r - 1` we get `s - 1 <= tau_r - 2 < tau_r`, and `s-1 >= 0`. Similarly (R)
is well-formed since `t+1 > t >= tau_r`.

**Definition 1.3.** `L_H(X) = { x ∈ Sigma* : X =>*_{G_H} x }` for `X ∈ N ∪ I ∪ Sigma`.

---

## 2. Correctness of the H-cover

> **Theorem 2.1 (Span Theorem).** For all `A ∈ N`: `L_H(A) = L(A)`.
> For all `[r,s,t] ∈ I`: `L_H([r,s,t]) = L(span(r,s,t))`.

Proved as Lemmas 2.2 (soundness) and 2.3 (completeness).

### Lemma 2.2 (Soundness). For all `n >= 0`:
 (i) if `A =>^n_{G_H} x` with `A ∈ N`, `x ∈ Sigma*`, then `A =>*_G x`;
 (ii) if `[r,s,t] =>^n_{G_H} x` then `span(r,s,t) =>*_G x`.

**Proof.** Strong induction on `n`. For `n = 0` both antecedents are vacuous (a nonterminal is not a
terminal string). Let `n >= 1` and consider the first production applied.

*Case (E), `A -> eps`.* Then `x = eps` and `A ->_G eps`. ✓

*Case (C), `A -> [r,0,pi_r]`.* Then `[r,0,pi_r] =>^{n-1} x`, so by IH(ii)
`span(r,0,pi_r) = X_1...X_{pi_r} =>*_G x`. Since `A ->_G X_1...X_{pi_r}`, we get `A =>*_G x`. ✓

*Case (P), `[r,tau-1,tau] -> X_tau`.* Then `X_tau =>^{n-1}_{G_H} x`.
If `X_tau ∈ Sigma` then `n-1 = 0` and `x = X_tau`, so `X_tau =>*_G x` trivially.
If `X_tau = B ∈ N` then IH(i) gives `B =>*_G x`.
Either way `span(r,tau-1,tau) = X_tau =>*_G x`. ✓

*Case (L), `[r,s-1,t] -> X_s [r,s,t]`.* Then `X_s [r,s,t] =>^{n-1}_{G_H} x`. Since `G_H` is
context-free, the derivation splits: `x = x_1 x_2` with `X_s =>^{n_1} x_1`,
`[r,s,t] =>^{n_2} x_2`, `n_1 + n_2 = n - 1`, so `n_1, n_2 < n`.
By IH (or triviality if `X_s ∈ Sigma`), `X_s =>*_G x_1`; by IH(ii), `span(r,s,t) =>*_G x_2`.
Hence `span(r,s-1,t) = X_s · span(r,s,t) =>*_G x_1 x_2 = x`. ✓

*Case (R).* Symmetric to (L). ✓  ∎

### Lemma 2.3 (Completeness).
 (i) If `A =>*_G x` then `A =>*_{G_H} x`.
 (ii) If `span(r,s,t) =>*_G x` for `[r,s,t] ∈ I` then `[r,s,t] =>*_{G_H} x`.

**Proof.** Fix a `G`-derivation tree. Let `m` be its node count. Induct on the pair
`(m, width)` ordered lexicographically, where claim (i) is assigned `width = omega` (above every
integer) and claim (ii) is assigned `width = t - s`.

*(i).* Let `T` derive `A =>*_G x` with root production `r`.
If `r : A -> eps` then `x = eps` and (E) gives `A =>_{G_H} eps`. ✓
Otherwise `r : A -> X_1...X_{pi_r}`, `x = y_1...y_{pi_r}` with subtrees `T_i : X_i =>*_G y_i`.
Apply (C): `A ->_{G_H} [r,0,pi_r]`. It remains to show `[r,0,pi_r] =>*_{G_H} x`, which is claim (ii)
at measure `(m, pi_r) < (m, omega)`. ✓

*(ii).* Given `span(r,s,t) =>*_G x` with witness subtrees for each `X_i`, `s < i <= t`.
Note `t - s >= 1` always, since `s < tau_r <= t`.

  *Base `t - s = 1`.* Then `s < tau_r <= t = s+1` forces `tau_r = s+1 = t`, so
  `[r,s,t] = [r,tau_r-1,tau_r]` and `span = X_{tau_r}`. Apply (P):
  `[r,tau-1,tau] ->_{G_H} X_tau`. If `X_tau ∈ Sigma` then `x = X_tau` and we are done. If
  `X_tau = B ∈ N`, its subtree has `< m` nodes (it is a proper subtree of `T`, since `T`'s root is
  not part of it), so IH(i) at measure `(m', omega)` with `m' < m` gives `B =>*_{G_H} x`. ✓

  *Step `t - s >= 2`.* Two subcases; note they are exhaustive because `t - s >= 2` together with
  `s < tau_r <= t` forbids `(s = tau_r - 1 and t = tau_r)`.

  - *`t > tau_r`.* Then `[r,s,t-1] ∈ I` (as `s < tau_r <= t-1`) and (R) gives
    `[r,s,t] ->_{G_H} [r,s,t-1] X_t`. Split `x = x' x_t` per the witness trees, with
    `span(r,s,t-1) =>*_G x'` and `X_t =>*_G x_t`. IH(ii) at `(m, t-1-s) < (m, t-s)` handles `x'`;
    `X_t` is a terminal or IH(i) at strictly smaller node count. ✓
  - *`t = tau_r`.* Then `t - s >= 2` gives `s <= tau_r - 2`, so `s + 1 <= tau_r - 1 < tau_r <= t`
    and `[r,s+1,t] ∈ I`. (L) with `s' = s+1` gives `[r,s,t] ->_{G_H} X_{s+1} [r,s+1,t]`. Split and
    apply IH(ii) at `(m, t-s-1)`. ✓  ∎

**Corollary 2.4.** `L(G_H) = L(G)`. (Take `A = S` in Theorem 2.1.)

---

## 3. Every H-cover production has the same shape

> **Proposition 3.1 (Normal form).** Every production of `G_H` other than (E) has the form
> `Y -> alpha Z beta` where `Z ∈ N ∪ I ∪ Sigma` and `alpha, beta ∈ V*` with `|alpha| + |beta| <= 1`.

**Proof.** By inspection of Definition 1.2: (P) has `alpha = beta = eps`; (L) has `alpha = X_s`,
`beta = eps`; (R) has `alpha = eps`, `beta = X_{t+1}`; (C) has `alpha = beta = eps`. ∎

So an arbitrary `pi_r`-ary production of `G` becomes a chain of at most `pi_r` near-unit steps
threaded outward through the head. `G_H` is a *linear* grammar in the items, with at most one
original symbol adjoined per step.

---

## 4. The canonical H-cover: routes, and a correction

Theorem 2.1 says `G_H` generates the right strings. It says nothing about how many *derivations*
`G_H` gives per `G`-derivation. This section settles that, and the answer is not what
`docs/anchored_derivative.md` claimed.

**Example 4.1.** Take `r : A -> X_1 X_2 X_3` with `tau_r = 2`. Then
`[r,1,2]` (seed), `[r,0,2]`, `[r,1,3]`, `[r,0,3]` are all items. Two distinct `G_H`-derivations
reach `[r,0,3]` from the seed:

    [r,1,2] -L-> [r,0,2] -R-> [r,0,3]
    [r,1,2] -R-> [r,1,3] -L-> [r,0,3]

Both attach `X_1` on the left and `X_3` on the right and yield the same `G`-derivation.

> **Proposition 4.2.** `G_H` is *not* in general a strict cover of `G`: the natural map from
> `G_H`-derivations to `G`-derivations is surjective (Lemma 2.3) but not injective.

**Proof.** Example 4.1 exhibits two `G_H`-derivations with the same image. ∎

The multiplicity is combinatorial: reaching `[r,0,pi_r]` from `[r,tau-1,tau]` requires `tau-1`
left steps and `pi_r - tau` right steps in any interleaving, so there are
`C(pi_r - 1, tau_r - 1)` routes per production.

**Definition 4.3 (canonical item set).** For a production `r` put

    Ic_r = { [r,s,tau_r] : 0 <= s <= tau_r - 1 }  ∪  { [r,0,t] : tau_r <= t <= pi_r }

("all left expansions first, then all right expansions"). Let `G_Hc` be `G_H` restricted to items
in `Ic = ∪_r Ic_r` (keeping only productions all of whose symbols lie in `Ic ∪ N ∪ Sigma`).

> **Theorem 4.4.** (a) `L_{G_Hc}(X) = L_{G_H}(X)` for every `X ∈ N ∪ Ic`; in particular
> `L(G_Hc) = L(G)`.
> (b) The map from `G_Hc`-derivations to `G`-derivations is a **bijection**.
> (c) `|Ic_r| = pi_r`, whereas `|I_r| = tau_r (pi_r - tau_r + 1)`, which is `Theta(pi_r^2)` for a
> centred head.

**Proof.**
*(a)* Soundness is inherited (`G_Hc ⊆ G_H`). For completeness, re-read the proof of Lemma 2.3(ii):
in the step case it uses (R) whenever `t > tau_r` and (L) only when `t = tau_r`. Starting from
`[r,0,pi_r]` this strips right down to `[r,0,tau_r]` and then strips left to `[r,tau_r-1,tau_r]` —
every item it visits lies in `Ic_r`. So the proof of Lemma 2.3 already establishes completeness for
`G_Hc` verbatim. ✓

*(b)* It suffices to show every `X ∈ Ic` has exactly one `G_Hc`-production, so that the derivation
is forced once the root production `r` is chosen. Items of `Ic_r` are of type
`A: [r,s,tau_r]` (`s <= tau_r - 1`) and type `B: [r,0,t]` (`t >= tau_r`), overlapping at `[r,0,tau_r]`.

- LHS `[r,s,tau_r]`, type A. (P) applies iff `s = tau_r - 1`. (L) with LHS `[r,s,tau_r]` requires
  RHS item `[r,s+1,tau_r] ∈ Ic_r`, which holds iff `s + 1 <= tau_r - 1`, i.e. `s < tau_r - 1`. (R)
  with LHS `[r,s,tau_r]` requires RHS item `[r,s,tau_r - 1]`, which violates head-containment.
  So exactly one production: (P) if `s = tau_r - 1`, else (L). ✓
- LHS `[r,0,t]`, type B with `t > tau_r`. (R) requires `[r,0,t-1] ∈ Ic_r` ✓, applies. (L) requires
  RHS `[r,1,t] ∈ Ic_r`, which needs `t = tau_r`, excluded. (P) requires `t = tau_r`, excluded.
  Exactly one: (R). ✓
- `[r,0,tau_r]` is type A with `s = 0` and is covered by the first bullet.

Hence for each `r` there is exactly one chain
`[r,tau-1,tau] -> [r,tau-2,tau] -> ... -> [r,0,tau] -> [r,0,tau+1] -> ... -> [r,0,pi_r]`,
and (C) attaches it to `A`. The `i`-th step consumes `X_i` at a determined position, so a
`G`-derivation tree determines the `G_Hc`-derivation uniquely and conversely. ✓

*(c)* `|{[r,s,tau_r]}| = tau_r`, `|{[r,0,t]}| = pi_r - tau_r + 1`, overlap `{[r,0,tau_r]}` of size 1,
total `pi_r`. For `I_r`, `s` ranges over `tau_r` values and `t` over `pi_r - tau_r + 1`. ∎

> **Proposition 4.5 (why the quadratic set is nevertheless needed).** `G_Hc` is complete for
> *whole* derivations but not for *fragments*. With `r : A -> X_1 X_2 X_3`, `tau_r = 2`, the item
> `[r,1,3]` (spanning `X_2 X_3`) is absent from `Ic_r`. Any procedure that must recognise the
> fragment `X_2 X_3` as a single constituent of `r` therefore cannot use `G_Hc`.

**Proof.** `Ic_r` contains no item with `s >= 1` and `t > tau_r`, and `span(r,1,3) = X_2 X_3`
requires `s = 1, t = 3`. ∎

**Remark 4.6 (CORRECTION).** `docs/anchored_derivative.md` §4.3 claimed the head constraint
`s < tau_r <= t` makes the anchored derivative *unambiguous*. That is **false as stated**: by
Proposition 4.2 the head fixes the *anchor point* but not the *interleaving order*, and the
interleaving alone gives `C(pi_r - 1, tau_r - 1)` routes per production. The defensible claims are:

1. The head selects one anchor per production, eliminating the `|{i : X_i can yield a}|`-fold
   choice of *where* to start (Theorem 4.4(b) needs this: without a fixed head there is no single
   seed to make the chain unique).
2. Head + canonical order together give strict unambiguity (Theorem 4.4(b)).
3. Head alone does not (Proposition 4.2), and the full quadratic item set is the price paid for
   fragment coverage (Proposition 4.5).

Theorem 4.4(c) + Proposition 4.5 give the real trade-off: **`pi_r` items and one route per
derivation for complete parsing; `Theta(pi_r^2)` items and `C(pi_r-1,tau_r-1)` routes for fragment
parsing.**

---

## 5. The anchored relation

**Definition 5.1.** For `L ⊆ Sigma*` and `w ∈ Sigma*`, the *anchored relation* is

    <w>L  =  { (u,v) ∈ Sigma* x Sigma* : u w v ∈ L } ⊆ Sigma* x Sigma*.

For a symbol `X` write `X<w> := <w>L_H(X)`. Compare the one-sided derivatives
`d_w L = { v : wv ∈ L }` and `L d_w = { u : uw ∈ L }`.

**Definition 5.2 (context products).** For `R ⊆ Sigma* x Sigma*` and `K ⊆ Sigma*`:

    R ·r K = { (u, v z) : (u,v) ∈ R, z ∈ K }        (grow the right context)
    K ·l R = { (z u, v) : (u,v) ∈ R, z ∈ K }        (grow the left context)

> **Theorem 5.3 (Anchored decomposition of concatenation).** For `K_1, K_2 ⊆ Sigma*` and
> `a ∈ Sigma` (a single letter):
>
>     <a>(K_1 K_2)  =  (<a>K_1) ·r K_2   ∪   K_1 ·l (<a>K_2).

**Proof.**
(⊇) If `(u,v_1) ∈ <a>K_1` and `z ∈ K_2` then `u a v_1 ∈ K_1`, so `u a v_1 z ∈ K_1K_2`, i.e.
`(u, v_1 z) ∈ <a>(K_1K_2)`. Symmetrically for the second term. ✓

(⊆) Let `(u,v) ∈ <a>(K_1K_2)`, so `u a v = k_1 k_2` with `k_i ∈ K_i`. Put `p = |k_1|`. The letter `a`
occupies position `|u|` (0-indexed) of `uav`. Exactly one of two cases holds, since `p` is an
integer and `|w| = |a| = 1` leaves no index strictly between `|u|` and `|u|+1`:

- `p <= |u|`: then `k_1` is a prefix of `u`; write `u = k_1 u_2`. Then `k_2 = u_2 a v`, so
  `(u_2, v) ∈ <a>K_2` and `k_1 ∈ K_1`, giving `(u,v) = (k_1 u_2, v) ∈ K_1 ·l (<a>K_2)`. ✓
- `p >= |u| + 1`: then `k_1 = u a v_1` with `v = v_1 v_2`, and `k_2 = v_2`. So
  `(u,v_1) ∈ <a>K_1` and `v_2 ∈ K_2`, giving `(u,v) ∈ (<a>K_1) ·r K_2`. ✓  ∎

> **Proposition 5.4 (equality fails for `|w| >= 2`).** With `K_1 = {a}`, `K_2 = {b}`, `w = ab`:
> `<ab>(K_1K_2) = {(eps,eps)}` but `<ab>K_1 = <ab>K_2 = {}`, so the right-hand side is `{}`.

**Proof.** `ab ∈ K_1K_2` gives `(eps,eps) ∈ <ab>(K_1K_2)`. No string of `K_1` or `K_2` contains
`ab` as a factor, since each has length 1. ∎

The missing cases are exactly the split points `p` with `|u| < p < |u| + |w|`, i.e. the anchor
**straddling** the concatenation boundary. Restoring equality requires the third family

    <w>(K_1 K_2) ⊇ ∪_{w = w_1 w_2, w_1,w_2 ≠ eps} (<w_1>K_1) (x) (<w_2>K_2)

in which *both* factors are anchored — so the anchored grammar ceases to be linear.

**Remark 5.6 (`K_1 w K_2` is not a missing third case).** One might expect a case "the anchor sits
at the seam, `u ∈ K_1` and `v ∈ K_2`". It is not a case of splitting `K_1 K_2`: every letter of
`uav` must originate in `k_1` or `k_2`, and a free-floating `a` has no source. The seam situations
are already the *boundaries* of the two existing cases (`p = |u|` gives case 2 with `u_2 = eps`;
`p = |u|+1` gives case 1 with `v_1 = eps`), so a third rule would double-count.

The shape `L(K_1) x L(K_2)` does arise, but from a different rule. For `r : A -> X_1 a X_3` with
`tau_r = 2` and `X_2 = a ∈ Sigma`, Corollary 5.5 gives
`[r,1,2]<a> = {(eps,eps)}` by (A-P), then (A-L) and (A-R) yield `[r,0,3]<a> ⊇ L(X_1) x L(X_3)`.
So "anchor between two constituents" is projection-then-expand-both-ways, not a concatenation split.

> **Corollary 5.5 (Anchored H-cover equations).** Fix `a ∈ Sigma`. Using Theorem 2.1 to identify
> `L_H([r,s,t]) = L(span(r,s,t))`, the following hold for all items and nonterminals:
>
> | | equation |
> |---|---|
> | (A-P) | `[r,tau-1,tau]<a> = X_tau<a>` |
> | (A-L) | `[r,s-1,t]<a> = (X_s<a>) ·r L([r,s,t])  ∪  L(X_s) ·l ([r,s,t]<a>)` |
> | (A-R) | `[r,s,t+1]<a> = ([r,s,t]<a>) ·r L(X_{t+1})  ∪  L([r,s,t]) ·l (X_{t+1}<a>)` |
> | (A-C) | `A<a> = ∪_{r : A -> ...} [r,0,pi_r]<a>` |
> | base | `a<a> = {(eps,eps)}`;  `b<a> = {}` for `b ∈ Sigma \ {a}`;  `A<a> = {}` if `L(A) = {}` |

**Proof.** (A-P): `L_H([r,tau-1,tau]) = L(X_tau)` by Theorem 2.1, and `<a>` of equal languages is
equal. (A-L),(A-R): apply Theorem 5.3 to `L(span(r,s-1,t)) = L(X_s) · L(span(r,s,t))` and
`L(span(r,s,t+1)) = L(span(r,s,t)) · L(X_{t+1})`. (A-C): `L(A) = ∪_r L(rhs_r)` and `<a>` commutes
with unions, since `u a v ∈ ∪_r K_r` iff `u a v ∈ K_r` for some `r`. Base cases are immediate. ∎

---

## 6. What the anchor buys: no nullability predicate

> **Proposition 6.1 (one-sided derivative of a concatenation).** For `K_1, K_2 ⊆ Sigma*`, `a ∈ Sigma`:
>
>     d_a(K_1 K_2) = (d_a K_1) K_2  ∪  (K_1 ∩ {eps}) · (d_a K_2).

**Proof.** (⊇) clear. (⊆) Let `av ∈ K_1K_2`, `av = k_1k_2`. If `k_1 = eps` then `av = k_2 ∈ K_2` so
`v ∈ d_a K_2` and `eps ∈ K_1`. If `k_1 ≠ eps` then `k_1 = a k_1'` and `v = k_1' k_2`, so
`k_1' ∈ d_a K_1`. ∎

The factor `(K_1 ∩ {eps})` is the nullability test `Null(K_1) ⟺ eps ∈ K_1`. For a grammar,
`Null` is the least fixpoint of a monotone operator over `2^N` and is a *global* analysis of `G`.

> **Observation 6.2.** The equations of Corollary 5.5 contain no occurrence of `Null`, and no
> occurrence of `∩`. Consequently the map "production of `G_H` ↦ its anchored equation" is a
> **local** rewrite: it inspects one production and emits one equation, with no reference to any
> other production of `G`.

**Proof.** Inspection of Corollary 5.5, whose derivation (Theorem 5.3) uses only the case split on
`p <= |u|` vs `p >= |u|+1`, which is exhaustive by integer trichotomy and does not depend on any
property of `K_1` or `K_2`. ∎

**Remark 6.3 (scope of the claim).** Observation 6.2 concerns *writing down* the equations, not
*solving* them. The system in Corollary 5.5 is recursive ((A-C) feeds back into (A-P) through
`X_tau ∈ N`), so computing `A<a>` is still a fixpoint computation — that fixpoint *is* parsing.
What disappears is the separate auxiliary `Null` analysis, not the main fixpoint.
`docs/anchored_derivative.md` §4.1's phrase "the fixpoint is gone" should read "the *nullability*
fixpoint is gone".

---

## 7. The relation is strictly stronger than its projections

**Definition 7.1.** For `R ⊆ Sigma* x Sigma*` let `piL(R) = {u : ∃v, (u,v) ∈ R}` and
`piR(R) = {v : ∃u, (u,v) ∈ R}`.

> **Proposition 7.2.** `<a>L ⊆ piL(<a>L) x piR(<a>L)`, and the inclusion is strict for some
> context-free (indeed finite) `L`.

**Proof.** The inclusion is immediate from the definition of projection. For strictness take
`Sigma = {a,b,c,d,e}` and `L = {abc, dbe}`, generated by `S -> a b c | d b e`. Anchor on `b`:

    <b>L      = { (a,c), (d,e) }
    piL(<b>L) = { a, d }
    piR(<b>L) = { c, e }
    product   = { (a,c), (a,e), (d,c), (d,e) }

and `(a,e) ∉ <b>L` because `abe ∉ L`. ∎

So the pair of one-sided objects — "what can precede the anchor" and "what can follow it" — loses
the correlation between the two sides. The relation retains it.

> **Theorem 7.3 (Rectangle decomposition).** Let `Tr(A,w)` be the set of `G_H`-derivation trees
> rooted at `A` in which the anchor occurrence `w` is distinguished, and for `T ∈ Tr(A,w)` let
> `ml(T), mr(T) ∈ V*` be the sequences of symbols left and right of the anchor path in `T`. Then
>
>     A<w> = ∪_{T ∈ Tr(A,w)} L(ml(T)) x L(mr(T)).

**Proof sketch.** (⊇) Each `T` witnesses `u ∈ L(ml(T))`, `v ∈ L(mr(T))` composing to a derivation
of `u w v` from `A`. (⊆) Given `(u,v) ∈ A<w>`, a derivation of `u w v` from `A` in `G_H` exists by
Theorem 2.1; distinguishing the occurrence of `w` in the frontier and reading off the symbols to
either side of the path from root to that occurrence yields such a `T`. ∎

**Status: this one is a sketch, not a proof.** Making it a proof requires (a) a precise definition
of "the anchor path" when `|w| > 1` (the anchor's frontier positions need not share a single path),
and (b) an argument that `ml(T)`, `mr(T)` are well defined. For `|w| = 1` the path is unique and
the argument goes through; for `|w| > 1` it is CONJECTURE.

**Corollary 7.4 (the shape of the gap to Osorio–Navarro).** Write `F(L) = {w : ∃u,v. uwv ∈ L}`
for the factor language. Then

    A<w> ≠ {}   ⟺   w ∈ F(L(A)).

So the infix-nonterminal set `{A : w ∈ F(L(A))}` computed by an infix/substring recogniser is
exactly the **emptiness predicate** of `A<w>`. By Theorem 7.3 the anchored relation is a finite
union of rectangles indexed by parse trees; the recogniser retains only whether that union is
nonempty, and `piL x piR` retains only its bounding rectangle, which by Proposition 7.2 is strictly
coarser than the union whenever two rectangles are incomparable.

**Proof of the equivalence.** `A<w> ≠ {}` iff `∃(u,v). uwv ∈ L(A)` iff `w ∈ F(L(A))`. ∎

**Remark 7.5 (where the correlation actually lives — intra- vs inter-rectangle).** Prop 7.2 is
easy to misread as "left and right context are never independent". They are: *within a single
rectangle* `L(ml(T)) x L(mr(T))` the two sides are by construction a product, and for a fixed item
`[r,s,t]` the missing left `X_1...X_s` and missing right `X_{t+1}...X_{pi_r}` are each determined by
`(r,s)` and `(r,t)` alone. The correlation is **between** rectangles: it is destroyed only by
collapsing the union into a single product of the unions. With `L = {abc, dbe}` anchored at `b`,

    {a}x{c} ∪ {d}x{e}            = 2 pairs   (correct)
    ({a}∪{d}) x ({c}∪{e})        = 4 pairs   (invents abe, dbc)

Design rule: never merge context sets across derivations. Per-tree `missing_left`/`missing_right`
respects this; a single flat pair of context sets (or a flat infix-NT set) does not.

---

## 8. The algorithm

**Remark 8.1.** Corollary 5.5 is a statement about *languages and relations*. Turning it into the
claim "the implementation computes this" needs a separate argument relating the equations to the
chart. That argument is not in this document.

**Remark 8.2 (what a chart can and cannot hold).** `A<w>` is in general infinite (e.g.
`A -> a A b | w` gives `A<w> = {(a^n, b^n) : n >= 0}`). No finite table stores it directly. Theorem
7.3 says the finite object is the *set of rectangles*, i.e. the set of `(ml(T), mr(T))` pairs of
symbol sequences — which is what `missing_left` / `missing_right` record.

**Remark 8.3 (correct form of the chart statement).** For a complete input `x = a_1...a_n`, the
standard chart claim is
`T[i,j] = { X ∈ N ∪ I : a_{i+1}...a_j ∈ L_H(X) }`,
which follows from Theorem 2.1 by ordinary CYK-style induction on span width. This is *not* the
anchored statement; it is the `u = v = eps` case.

**Remark 8.4 (CORRECTION).** `docs/anchored_derivative.md` §4.2 stated the conjecture
"`T[i,j]` holds exactly `I<w>` for `w = input[i..j]`". As written this is **false by cardinality**
(Remark 8.2): `T[i,j]` is finite, `I<w>` need not be. The repairable statements are:

- (i) `T[i,j] = { X : a_{i+1}...a_j ∈ L_H(X) }` — Remark 8.3, true, but the non-fragment case.
- (ii) *Fragment version, CONJECTURE:* after boundary seeding and the reduce passes, the set of
  root candidates at `T[0,n]` equals `{ A ∈ N : A<w> ≠ {} }` for `w = a_1...a_n`, i.e. exactly the
  factor-membership set of Corollary 7.4.
- (iii) *CONJECTURE:* the reconstructed trees with their virtual nodes enumerate the rectangles of
  Theorem 7.3, i.e. `A<w> = ∪_T L(ml(T)) x L(mr(T))` over reconstructed `T`.

(ii) and (iii) are the theorems worth proving; neither is proved here, and both are claims about
the *implementation*, which requires reading `worklist.ml`, `seed.ml`, `recognize.ml`.

---

## 9. Honesty ledger

**Proved here, from the definitions, no gaps I am aware of:**
- Theorem 2.1 / Lemmas 2.2, 2.3 — the H-cover generates the right languages (Span Theorem).
- Proposition 3.1 — the normal form `Y -> alpha Z beta`, `|alpha|+|beta| <= 1`.
- Proposition 4.2 + Example 4.1 — `G_H` is not a strict cover; routes multiply.
- Theorem 4.4 — the canonical restriction `G_Hc` is language-equivalent, derivation-bijective, and
  has `pi_r` items per production instead of `Theta(pi_r^2)`.
- Proposition 4.5 — `G_Hc` is nevertheless incomplete for fragments.
- Theorem 5.3 — anchored decomposition of concatenation, with equality, for `|w| = 1`.
- Proposition 5.4 — equality fails for `|w| >= 2` (straddle).
- Corollary 5.5 — the anchored equations.
- Proposition 6.1 + Observation 6.2 — the one-sided equation needs `Null`, the anchored one does not.
- Proposition 7.2 — the relation is strictly finer than the product of its projections.
- Corollary 7.4 — infix-NT-set = emptiness predicate of the anchored relation.

**Sketched, not proved:**
- Theorem 7.3 (rectangle decomposition). Solid for `|w| = 1`; the `|w| > 1` anchor-path definition
  is not pinned down.

**Conjecture, unproved:**
- Remark 8.4(ii), (iii) — that the implementation's root candidates and reconstructed trees compute
  the factor-membership set and the rectangles respectively.

**LITERATURE CHECK ROUND 2 DONE 2026-08-24 — full report `docs/literature_check_2026-08-24.md`.
Primary sources downloaded and read, not summarised. Results are worse than round 1:**
- Def 5.1 `C_L(w)` = Clark & Eyraud JMLR 2010 **Def 1 verbatim**. Classical. Rename and cite.
- Prop 3.1 (double-dotted item) = Satta & Stock 1989 `[p,ldot,rdot,m]` / Sikkel 1993.
- Prop 4.2 (routes multiply) = Satta & Stock 1989 §4.
- **Thm 4.4 = KAY 1989.** Satta & Stock 1991 attribute it: "fixing a privileged order of expansion
  in each production, which amounts to reducing the size of set I'".
- **Prop 4.5 = the published objection to Kay 1989**, same paragraph of Satta & Stock 1991.
  Their fix — *subsumption blocking*, generalising the 1989 `m` lock — beats both and preserves
  fragment coverage. §4 must be rewritten as a cited remark, not a theorem.
- Thm 4.4(c) = Sikkel 1993's `r` factor for double-dotted items.
- Cor 7.4 = Rekers & Koorn 1991 abstract, `∃v,w : vsw ∈ L`.
- **Thm 7.3's OUTPUT FORM = Rekers & Koorn 1991 §5**: trees for "possible contextual completions"
  with nonterminal placeholders `σ_1 s σ_2`, plus the rule not to generate subtrees whose frontier
  lies entirely inside `σ_1`/`σ_2`. That is our `Virtual` nodes and our don't-descend rule.
  **What is NOT theirs: exactness.** Their §5.2 prunes heuristically (forbid `A =>+ αA` etc.,
  remove-cycles, "prefer the simplest completion") and openly discards completions. Thm 7.3 claims
  an *equality*. That equality, and the identification with `C_L(w)`, is all that is left.
- Thm 5.3: not found stated; elementary; operationally the scan/complete rules. Do not claim.

**Scope point that keeps a contribution alive:** Satta & Stock's island parser ends with
`if I_S ∈ t_{0,n} then accept else reject` — the input is a COMPLETE candidate sentence and islands
are a search strategy. The "valid infix property" is likewise a search-discipline property. Neither
computes anything about `w` as a fragment of an unseen larger sentence.

**Still not obtained:**
- Satta & Stock, *Artif. Intell.* 69 (1994) — paywalled; the one remaining source that could preempt.
- Kay 1989 — cited only via Satta & Stock 1991; get it before citing.
- Bojar et al. CICLing 2006; Conway ch. 6; Ginsburg-Spanier 1963.
  Conway's factor theory; Ginsburg–Spanier on quotients; the substring-parsing line
  (Rekers–Koorn, Osorio–Navarro); Mignot on two-sided derivatives for regular languages;
  Henriksen–Bilardi–Pingali (OOPSLA 2019). **This is the single biggest risk to the contribution
  claim** — Theorem 5.3 is elementary enough that someone has very likely written it down.
- Whether Theorem 4.4's canonical restriction matches what the code actually builds in `hcover.ml`.
- Corrections to `docs/anchored_derivative.md` (Remarks 4.6, 6.3, 8.4) have not been folded back
  into that file; it should be read as superseded where they conflict.
