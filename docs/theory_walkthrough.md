# Theory Walkthrough — the six ideas, in plain terms

Written 2026-08-25, as a teaching pass. The other theory docs
(`anchored_derivative.md`, `anchored_derivative_proofs.md`, `cnf_derivative.md`) are dense
and notation-heavy. This one is the version you can actually read.

`Wrap(w)` here = the literature's `C_L(w)` (Clark & Eyraud 2010, Def 1). Local name only,
to avoid confusing it with anything in the papers. Use `C_L(w)` when writing.

> **CORRECTION 2026-08-25 (later the same day).** Everywhere below that says T1 ("union of
> rectangles") is an open sketch: **T1 was refuted.** Counterexample `s : A s C | B`, anchor
> `B`, gives `Wrap(B) = {(A^n, C^n)}`, which is not a finite union of rectangles (Mezei).
> The repaired claim -- no finite string-pair representation exists, but a forest represents
> it exactly, so trees are *necessary* -- is **Lang 1988/1991**, not ours. Ideas 1-6 below
> are still correct as *explanation*; the novelty claims attached to them are not.
> See `investigation_2026-08-25.md`.

---

## 1. Derivative — chop a known end off

`d_a L = { v : av in L }`. Take every string in `L` starting with `a`, delete the `a`,
keep the rest. Anything not starting with `a` is discarded.

`L = {cat, car, cow}`: `d_c L = {at, ar, ow}`, `d_a L = empty`, `d_ca L = {t, r}`.

Turns membership into a stopping test: is `cat` in `L`? chop c, chop a, chop t, then ask
"is eps in what's left?"

**The real assumption is one-sidedness, not prefix-ness.** Chopping from the back is the
same structure mirrored. One end known, the other open. Everything downstream follows:
strict left-to-right consumption, non-matching branches dying to empty, and the
"could this part have been empty?" nullability side-condition.

**Which is exactly why fragments are hard: a fragment has both ends open.**

## 2. Anchored derivative — fix a middle, ask what wraps it

```
Wrap(w) = { (u, v) : u w v in L }
```

`L = {cat, car, cow}`, anchor `a`: `Wrap(a) = {(c,t), (c,r)}`.

Two distinct kinds of nothing, and the difference is load-bearing:
- `(ca, eps)` — nothing goes on the right **and that's legal**; the anchor sits at the end
  of a valid string. (This is what `last` names, later.)
- `empty` — no wrapping works at all; the anchor is not in the language anywhere.

`Wrap(w) != empty` is exactly "is this fragment a fragment of anything legal?". The pairs
themselves are "here is what it could have been" — the parser's actual output.

## 3 + 4. It is a set of PAIRS, and projecting loses the pairing  [THE CRUX]

`L = {abc, dbe}`, anchor `b`:

```
Wrap(b)      = { (a,c), (d,e) }              2 pairs -- the truth
Left(b)      = { a, d }                      squash, keep left halves
Right(b)     = { c, e }                      squash, keep right halves
Left x Right = { (a,c),(a,e),(d,c),(d,e) }   4 pairs
```

`(a,e)` claims `abe` in `L`. False. So `Wrap(w) SUBSET Left(w) x Right(w)`, and the
inclusion can be strict.

**As a grid.** Rows = left contexts, columns = right contexts, tick if `u w v in L`:

```
        c     e                    c     e
  a     v     .              a     v     v
  d     .     v              d     v     v
  {abc, dbe}                 {abc,abe,dbc,dbe}
  diagonal -- leaks          solid -- safe
```

Projection only sees the shadow on each axis, and **both shapes cast the same shadow**.
Flattening fills in the whole grid on every row and column that has a tick.

**Rectangle** = when `Wrap(w)` equals `Left(w) x Right(w)` exactly. Nothing to lose.

**Where rectangles come from.** Take `S -> A b C`, `A -> a | d`, `C -> c | e`. The anchor
sits in that production with `A` on its left and `C` on its right. `A` and `C` are
siblings, and **in a context-free grammar siblings are generated independently** -- neither
constrains the other. So every `A`-string pairs with every `C`-string.

> A rectangle is one production, seen from the anchor: `L(A) x L(C)`.
> It is solid *because* the grammar is context-free.

Add `S -> G b F`, `G -> g`, `F -> f` and you get a second block. Union of rectangles.
**The correlation you lose by flattening is exactly: which production you were in.**
Inside a block there is nothing to remember. Across blocks there is.

### Who this critique does and does not hit

- **Osorio & Navarro** output an infix nonterminal set, no trees. The critique lands.
- **Rekers & Koorn (1991, sec 5)** build trees with nonterminal placeholders. They keep
  the pairing. **The critique does NOT land on them.** Their weakness is different: they
  *prune* (forbid `A =>+ alpha A`, remove-cycles, prefer the "simplest" completion). The
  live question against R&K is exactness vs heuristic pruning -- see `open_problems.md` T2.
- For a pure **decision** problem, flattening is harmless:
  `Wrap(w) != empty  <=>  Left(w) != empty`. Existential quantification commutes with
  yes/no. It does not commute with enumerating pairs.

## 5. The item is the pair

Notation, from the code: `r` a production, `pi_r` its arity, `tau_r` the head position,
`[r,s,t]` an item meaning "inside production `r`, I have covered RHS positions `s+1..t`".

`s` and `t` are **two frontiers** — how far left, how far right.

For `S -> A b C` with the head on `b` (`pi_r = 3`, `tau_r = 2`):

```
            t=2        t=3
   s=1      [b]   ->  [b C]
             |           |
             v           v
   s=0     [A b]  ->  [A b C]  =>  S
```

| operation | move | meaning |
|---|---|---|
| projection | land on `[r,1,2]` | plant the anchor at the head |
| left expansion | `s` decreases | swallow one more symbol on the left |
| right expansion | `t` increases | swallow one more symbol on the right |
| completion | far corner | production covered, hand up `S` |

**That grid IS the rectangle from idea 4, one level down.** And the point:

> `s` and `t` live in the **same object**. One item carries both frontiers. So when a
> production completes, the parser knows which left growth went with which right growth.
> **You never flatten because you never had two separate things to flatten.**

Mechanical contrast (my reading, not their claim): Osorio & Navarro keep `P` and `S` as
two *separate* vectors, closed independently, combined at the end. Two arrays instead of
one item — structurally where a product sneaks in.

### Route duplication falls straight out of the grid

Two paths from `[b]` to `[A b C]`: down-then-right, or right-then-down. Same cell. That is
**spurious** ambiguity — same tree, derived twice. (Genuine ambiguity must survive;
blocking must not touch it.)

```
routes = C(pi_r - 1, tau_r - 1)
```

`pi=3,tau=2` -> 2. `pi=6,tau=3` -> 10. `pi=8,tau=4` -> 35. Hence subsumption blocking
(`lib/table.ml:36-62`) — Satta & Stock's lock, already implemented.

**In CNF `pi_r = 2`, so `C(1,0) = C(1,1) = 1`.** One route always; the grid is a single
line. Subsumption blocking is dead code in CNF. That is the whole content of
"CNF is the degenerate case".

**But** binarization does not *solve* route duplication — it picks the route at
grammar-compile time. And the H-cover already commits at compile time too, by fixing
`tau_r`. The difference:

| | fixes start cell (`tau_r`) | fixes the path |
|---|---|---|
| H-cover | yes | **no** — free at runtime, hence blocking |
| binarization | yes | **yes** — the bracketing *is* the path |

Binarization commits strictly more. Whether the extra commitment *hurts* is `open_problems.md` T3 — not settled, and was overclaimed once already.

Fixing `tau_r` already costs something, and the code has the receipt
(`lib/recognize.ml:52-60`): a fragment that does not contain the head has nowhere to
project from. **Boundary seeding exists to get in without the head.**

## 6. Straddle — when the anchor is longer than one token

`S -> A C`, `A -> a b`, `C -> c d`, so `L = {abcd}`. Anchor `bc`.

`bc` is not inside `A` (`ab`) nor inside `C` (`cd`). It **straddles**:

```
        A         C
      +----+   +----+
        a  b     c  d
        |  +--+--+  |
        u   anchor  v
```

Both children now have a job:
- `A` must produce something **ending in** `b` -> produces `ab`, leftover `a` = `u`
- `C` must produce something **starting with** `c` -> produces `cd`, leftover `d` = `v`

`Wrap(bc) = {(a,d)}`. Those two operations are the plain one-sided derivatives from idea 1,
one from each end. **Straddle is where they come back.**

You are not told where the `A`/`C` boundary is, so you try every position:

```
i = 0          anchor entirely in the right child
i = n          anchor entirely in the left child
1 <= i <= n-1  straddle  (n-1 of these)
```

**That list is Osorio & Navarro's Eq (3)**, and it is why they need three closures
(`first`, `last`, `mid`) instead of one. See `osorio_navarro_review.md` for the dictionary.

### Straddle is a proof bill, not a performance bill

- **At runtime it is free.** The chart is indexed `T[i,j]` — trying every split is what a
  chart parser already does. It is the `O(n^3)` you were already paying.
- **In the proof it is the blocker.** In the easy cases one sibling carries the anchor and
  the other is **free**, which is what makes the rectangle solid for nothing. Under
  straddle both siblings are pinned. No free factor, so the clean "follow the anchor down
  one path" induction has nowhere to go. **That is why T1 is still a sketch.**

Note straddle is still *rectangular*: the contribution is `(L(A) d_w1) x (d_w2 L(C))`, a
clean product of two one-sided derivatives. Straddle adds more rectangles, it does not
break rectangularity. **This was the argument for T1 and it is wrong** -- rectangularity of
each *contribution* says nothing about the *union* being finite, and it is not.

---

## How the parser actually enumerates splits

Not like CYK. `lib/worklist.ml:26-45`, `do_left_expand`: holding `a_h` at `T[i,j]`,

```ocaml
for i' = 0 to i do ... mem_item tbl i' i x_item ...
```

**The split point is `i`, and it is already pinned** — it is the edge of the item you hold.
The loop searches for the *far* end of the neighbour, and only combines if something
actually lives at `T[i',i]`.

| | free variable in the inner loop |
|---|---|
| CYK | the **split** `k` — guess where the cut is |
| H-cover | the **far edge** `i'` — the cut is wherever the current item ends |

> CYK guesses the whole split structure up front, per cell.
> The H-cover grows outward one boundary at a time; **each expansion step commits to
> exactly one cut.**

Same space of possibilities, different order of commitment. Which is why straddle is free
at runtime — every expansion step already *is* a straddle decision — and also why the
proof is hard: there is no single "the anchor was cut here" moment to induct on. It is
spread across the whole derivation.

---

## Two follow-ups: climbing, and where derivatives actually sit

### Climbing

Two orthogonal motions, and it is worth keeping them apart:

- **Expansion** moves you *sideways* — grow the span within one production's grid.
- **Climbing** moves you *up* — no input consumed, you change which production you are in.

The grid in idea 5 is **per production**. When you reach its far corner you get a
`CompleteItem A`, and `A` can be the head of some *other* production `r'`. Projecting into
`r'` drops you at `r'`'s anchor cell, in a fresh grid stacked above.

```
   grid for r'      <- climb (projection): new production, no input eaten
        ^
   grid for r       <- expand: same production, span grows
```

So: **the union of rectangles from idea 4 is really a *tree* of rectangles**, and climbing
is the nesting. `do_project` / `do_eps_project` (`worklist.ml:17-24`) are the climb;
`frontier_bfs` in the L/R-Reduce steps and `infer_parse_roots` are also climbs.

### Where derivatives sit — the intuition holds, with two corrections

"I am going one at a time, so the derivative idea holds" — yes, but sharpen it twice:

**(1) It is two-sided.** Brzozowski eats from one end only. Expansion eats from either
end. That is idea 2, not idea 1.

**(2) Each step eats a whole constituent, not a letter.** In `do_left_expand`, `x_h` is
either `HTerm term` (one input token) or `HItem x_item` (a nonterminal spanning any width).
Chopping a single string off is a **derivative**. Chopping a whole *language* off is a
**quotient**:

```
L / K = { u : exists k in K, uk in L }        right quotient
K \ L = { v : exists k in K, kv in L }        left quotient
```

**Expansion by a nonterminal `X` is a quotient by `L(X)`.** The derivative is the special
case where `X` is a single terminal, i.e. `K = {a}`.

So the framing is legitimate, not a fudge — quotient is the general form and derivative is
the one-letter case. But **in the paper, say "quotient" for the nonterminal steps**;
"derivative" is only correct for the terminal ones. Both are textbook, neither is invented.
