# The Anchored (Two-Sided) Derivative and the H-Cover

Worked 2026-08-24. Status: derivation done by hand, not yet checked against code or literature.

> **SUPERSEDED IN PLACES.** See `docs/anchored_derivative_proofs.md` for the proofs. Three claims
> below are corrected there:
> - §4.1 "the fixpoint is GONE" -> only the *nullability* fixpoint is gone (Remark 6.3).
> - §4.3 "the head makes it unambiguous" -> false as stated; the head fixes the anchor, but the
>   left/right *interleaving* still gives C(pi_r-1, tau_r-1) routes. Head + canonical order gives
>   unambiguity (Theorem 4.4, Remark 4.6).
> - §4.2 conjecture "T[i,j] holds exactly I<w>" -> false by cardinality; see Remark 8.4 for the
>   repaired statements.

## 0. Symbols

| symbol | meaning |
|---|---|
| `G` | the original context-free grammar |
| `L(I)` | the language of symbol `I` — the set of strings `I` derives |
| `r` | a production of `G`, written `A -> X_1 X_2 ... X_{pi_r}` |
| `pi_r` | length of the right-hand side of production `r` |
| `tau_r` | head position in production `r` (1-based index into the RHS) |
| `X_s` | the s-th symbol on the RHS of `r` |
| `[r,s,t]` | PartialItem: the chunk of `r`'s RHS spanning `X_{s+1} ... X_t`. `s` = left boundary, `t` = right boundary. Always contains the head, i.e. `s < tau_r <= t` |
| `eps` | the empty string |
| `0` (empty set) | the empty language — derives nothing |
| `d_w L` | left (Brzozowski) derivative: `{ v : w v in L }` — chop `w` off the FRONT |
| `L d_w` | right derivative: `{ u : u w in L }` — chop `w` off the BACK |
| `nu(X)` | deferred nullability token: `eps` if `X =>* eps`, else empty set. Used only in the ONE-sided derivative |
| `I<w>` | **anchored relation**: `{ (u,v) : u w v in L(I) }`. A set of PAIRS, not a language |
| `.r` | append to the RIGHT component of a context pair |
| `.l` | prepend to the LEFT component of a context pair |
| `F(L)` | factor language `{ w : exists u,v. u w v in L }` |

## 1. The general form of an H-cover production

With `r : A -> X_1 ... X_{pi_r}` and head at `tau_r`:

| | form |
|---|---|
| projection | `[r, tau_r-1, tau_r] -> X_{tau_r}` |
| left expansion | `[r, s-1, t] -> X_s [r, s, t]` |
| right expansion | `[r, s, t+1] -> [r, s, t] X_{t+1}` |
| completion | `A -> [r, 0, pi_r]` |

Uniformly: **`I -> alpha I' beta` with `|alpha| + |beta| <= 1`.** At most one original grammar
symbol per step, on one side. The cover grammar is linear and at most binary. An arbitrary
`pi_r`-ary production becomes a chain of `pi_r` near-unit steps threaded through the head.

(Implementation note: `[r, 0, pi_r]` is excluded by `is_reachable_partial_item`, so completion is
fused into the last expansion.)

## 2. One-sided derivative (with the no-elimination caveat)

Derivative w.r.t. terminal `a`. Write `I_a` for the derived symbol, kept even when empty.

| | derived |
|---|---|
| proj | `[r,tau-1,tau]_a -> (X_tau)_a` |
| left | `[r,s-1,t]_a -> (X_s)_a [r,s,t]`  \|  `nu(X_s) [r,s,t]_a` |
| right | `[r,s,t+1]_a -> [r,s,t]_a X_{t+1}`  \|  `nu([r,s,t]) (X_{t+1})_a` |
| compl | `A_a -> [r,0,pi_r]_a` |

Observations:

- **Closed under the derivative.** Every derived production is still `I -> alpha I' beta` with
  `|alpha|+|beta| <= 1`. So `d_a G_H` is another H-cover-shaped grammar over item set `I union I_a`.
- **Linear growth.** Deriving by a word `w` gives `|I| * (|w|+1)` items. No exponential blowup,
  because nonterminals are NAMED — the derivative is memoised by construction, so Brzozowski's
  similarity-quotienting is unnecessary.
- **The caveat is what makes it a homomorphism.** Not eliminating dead subscripts, and pushing
  nullability into `nu`, makes `d_a` a purely local rewrite: no FIRST sets, no nullable sets, no
  fixpoint. Emptiness/productivity becomes a separate later pass. This is the syntactic/semantic
  split.

## 3. Two-sided: anchor at a terminal `w`

Instead of "what follows `w`" (a language), ask "what pairs can surround `w`" (a relation):

    I<w> = { (u, v) : u w v in L(I) }

Base cases: `w<w> = {(eps, eps)}`, and `a<w> = empty` for `a != w` (kept, not eliminated).

Push through `L(I) = L(X_s) . L([r,s,t])`. If `u w v` is in that concatenation, the split point
falls either to the RIGHT of `w` (so `w` sat in the left child) or to the LEFT of `w` (so `w` sat in
the right child). Two cases, exhaustive:

| | anchored form |
|---|---|
| proj | `[r,tau-1,tau]<w> -> X_tau<w>` |
| left | `[r,s-1,t]<w> -> X_s<w> .r [r,s,t]`  \|  `X_s .l [r,s,t]<w>` |
| right | `[r,s,t+1]<w> -> [r,s,t]<w> .r X_{t+1}`  \|  `[r,s,t] .l X_{t+1}<w>` |
| compl | `A<w> -> [r,0,pi_r]<w>` |

## 4. What falls out

### 4.1 Nullability disappears

No `nu` anywhere. The one-sided derivative needed it to ask "did the left part vanish, so does the
derivative pass through to the right part?" The anchor is a POSITIVE WITNESS — `w` is a real token
that is definitely present, so it is either in the left child or the right child, and the two
alternatives are exhaustive by construction. The wrong branch simply derives nothing.

Consequence: the fixpoint isn't deferred, it is GONE. The anchored derivative is a purely local
production-to-production rewrite.

### 4.2 The anchored rules ARE the H-cover recognition procedure

- anchored projection  = `do_project`
- anchored left expansion (two alternatives) = left expansion
- anchored right expansion (two alternatives) = right expansion
- anchored completion = `infer_parse_roots`
- the accumulated `(u, v)` = `missing_left` / `missing_right`

So the H-cover is not merely ANALOGOUS to a derivative. H-cover recognition IS the two-sided
derivative of `G` at a point, evaluated bottom-up.

Conjecture to prove (induction on expansion steps):
**`T[i,j]` holds exactly `I<w>` for `w = input[i..j]`.**

### 4.3 The head makes the anchored derivative unambiguous

The constraint `s < tau_r <= t` is not bookkeeping. Any production could be anchored at ANY RHS
position able to yield `w`. Allowing all of them recomputes the same `(u,v)` pairs by many different
routes — ambiguity in the SEARCH, not in the grammar. The head selection assigns each production
exactly one anchor point.

**Head-driven parsing = a canonical choice of anchor that makes the two-sided derivative
unambiguous.**

Corollary, and it settles Task 6's shape: head position does not change the relation `I<w>`, only
the ROUTE taken to compute it. Hence correctness is unaffected by head choice, but table size and
step count are not.

### 4.4 The relation is strictly stronger than the pair of languages

Tempting shortcut: compute `d_w L` (what can follow) and `L d_w` (what can precede) separately, then
pair them. **This is wrong**, and it is the crux.

Counterexample: `L = { a x b , c x d }`, anchor `x`.
- left contexts `{a, c}`, right contexts `{b, d}` -> pairing gives 4 combinations
- but only 2 are real; `a x d` is not in `L`

The relation keeps left and right CORRELATED. The pair of languages loses the correlation.

Consequences:
1. This is why `PartialItem` carries BOTH boundaries `(s,t)` in one symbol. The correlation lives
   inside the item. Two separate one-sided indices could not express it.
2. This is exactly the gap between this work and Osorio-Navarro. `F(L)` — "which nonterminals can
   appear infixed" — is `I<w>` with the contexts PROJECTED AWAY. Keeping the pairs is what yields
   trees. That is a precise, citable statement of the contribution over the substring-parsing line.

## 5. Open: anchor of length > 1

For `w` a single terminal the anchored grammar stayed LINEAR — exactly one anchored child per
production. For `w` a multi-token fragment, `w` can STRADDLE the split point: part of it in the left
child, part in the right child. That adds a third family of rules,

    [r,s-1,t]<w> -> X_s<w_1> (x) [r,s,t]<w_2>   for every split w = w_1 w_2

in which BOTH children are anchored. The anchored grammar is then no longer linear but branching,
and the choice of split point is the CYK-like O(n) factor.

Hypothesis: the single-terminal case is the cheap linear core; the straddle family is where the real
fragment-parsing cost lives, and where L-Reduce/R-Reduce asymmetry should be re-examined.

## 6. Not yet done

- Check 4.2 against the actual code (`worklist.ml`, `hcover.ml`) rather than against the general form.
- Prove the `T[i,j] = I<w>` conjecture properly.
- Check whether the anchored relation is the same object as Conway's factor theory / the
  `docs/theory_min_cover.md` MinCover.
- Literature check: does the anchored bi-derivative already exist under another name?
