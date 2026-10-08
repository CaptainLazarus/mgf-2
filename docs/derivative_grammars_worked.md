# Derivative Grammars: Worked Example (Henriksen–Bilardi–Pingali, OOPSLA 2019)

Worked derivatives for a grammar other than the paper's `E → E+E | n` running example.
Rules used: Fig. 4 inference rules (O, N, T) for first derivatives, and Definition 3.4 /
Eq. 5 for the pruned iterated construction.

## The grammar Γ

S-expression grammar. Unambiguous, 3 terminals `{ ( , ) , a }`, 2 nonterminals `{S, L}`,
and — unlike `E+E` — a **nullable** nonterminal, so the `nullable(α)` side condition in
the inference rules actually fires.

```
S → ( L )        (p1)
S → a            (p2)
L → S L          (p3)
L → ε            (p4)
```

Language: single s-expressions — `a`, `()`, `(a)`, `(a a)`, `((a) a)`, …

Nullability in Γ: `L` is nullable (via p4); `S` is not.

## Reminder: the inference rules (Fig. 4)

Given a production `A → α X β` in Γ with `nullable(α, Γ)`:

- **(N)** if `X = B` is a nonterminal: add `A_t → B_t β` to Γ_t
- **(T)** if `X = t` (the terminal we're deriving by): add `A_t → β` to Γ_t
- **(O)** every production of Γ is also in Γ_t

So for each production you scan the RHS left to right, firing the rule at every symbol
whose *prefix* is nullable, and stop at the first non-nullable symbol (inclusive).

---

## Part 1 — First derivatives with respect to each terminal

### Γ_( (derivative w.r.t. `(`)

Scan each production:

| D-parent | symbol hit | rule | D-child |
|---|---|---|---|
| `S → ( L )` | `X = (`, α = ε | T | `S_( → L )` |
| `S → a` | `X = a ≠ (` | — | (no inference; terminal mismatch) |
| `L → S L` | `X = S`, α = ε | N | `L_( → S_( L` |
| `L → ε` | no symbols | — | — |

```
Γ_( :   S_( → L )          start: S_(
        L_( → S_( L
        + all of Γ            (rule O)
```

**Sanity check**: `D_((L) = { x : (x ∈ L }`. A string starting with `(` must be
`( L-content )`, so the derivative is "a list body followed by `)`" — which is
literally what `S_( → L )` says.

### Γ_a (derivative w.r.t. `a`)

| D-parent | symbol hit | rule | D-child |
|---|---|---|---|
| `S → ( L )` | `X = ( ≠ a` | — | — |
| `S → a` | `X = a`, α = ε | T | `S_a → ε` |
| `L → S L` | `X = S`, α = ε | N | `L_a → S_a L` |

```
Γ_a :   S_a → ε            start: S_a
        L_a → S_a L
        + all of Γ
```

**Sanity check**: the only string in L beginning with `a` is `a` itself, so
`D_a(L) = {ε}` — and indeed `S_a` derives exactly ε. Note `L_a` is generated but
unreachable from `S_a`; the paper's pruning tolerates such leftovers (§3.3:
"does not eliminate all unreachable nonterminals").

### Γ_) (derivative w.r.t. `)`)

| D-parent | symbol hit | rule | D-child |
|---|---|---|---|
| `S → ( L )` | `X = ( ≠ )` | — | — (can't skip `(`: not nullable) |
| `S → a` | `X = a ≠ )` | — | — |
| `L → S L` | `X = S`, α = ε | N | `L_) → S_) L` |

```
Γ_) :   L_) → S_) L        start: S_)
        + all of Γ
```

**Sanity check**: `S_)` has **no productions** ⇒ L(Γ_)) = ∅. Correct: no string in L
starts with `)`. The derivative of a language by an impossible next symbol is the
empty language (the paper's analogue of Brzozowski's ∅).

---

## Part 2 — Pruned iterated derivatives (Def. 3.4) for w = `( a )`

Prefixes: ε, `(`, `(a`, `(a)`. Each step applies Eq. 5 to **P ∪ P_z′** (the original
productions plus only the *previous* step's new productions — that's the pruning).
Subscripts on new nonterminals are always suffixes of the prefix read so far.

### Step 1 — read `(` : grammar Γ_(

Scan P (P_ε = ∅ beyond P):

```
P_( :   S_( → L )              (T-child of p1)
        L_( → S_( L            (N-child of p3)
```

Start symbol: `S_(`. Nullable new NTs: none (`S_(` ends in `)`) — so `(` ∉ L. ✓

### Step 2 — read `a` : grammar Γ_(a

Scan P ∪ P_( with t = `a`:

| D-parent | from | rule | D-child |
|---|---|---|---|
| `S → a` | P | T | `S_a → ε` |
| `L → S L` | P | N | `L_a → S_a L` |
| `S_( → L )` | P_( | N | `S_(a → L_a )` |
| `L_( → S_( L` | P_( | N | `L_(a → S_(a L` |

In row 3, after emitting `S_(a → L_a )` the scan reaches `)` with α = `L` nullable —
but `)` ≠ `a`, so nothing more fires there.

```
P_(a :  S_a  → ε
        L_a  → S_a L
        S_(a → L_a )
        L_(a → S_(a L
```

Start symbol: `S_(a`. Nullability: `S_a` nullable, hence `L_a` nullable
(`S_a L`, both nullable); `S_(a` still not (trailing `)`). So `(a` ∉ L. ✓
Note the P_( productions themselves are now dead weight and are **not** carried
into the next scan — that's exactly what pruning discards.

### Step 3 — read `)` : grammar Γ_(a)

Scan P ∪ P_(a with t = `)`:

| D-parent | from | rule | D-child |
|---|---|---|---|
| `L → S L` | P | N | `L_) → S_) L` |
| `L_a → S_a L` | P_(a | N | `L_a) → S_a) L` |
| `L_a → S_a L` (α = `S_a` nullable, X = `L`) | P_(a | N | `L_a) → L_)` |
| `S_(a → L_a )` | P_(a | N | `S_(a) → L_a) )` |
| `S_(a → L_a )` (α = `L_a` nullable, X = `)` = t) | P_(a | **T** | `S_(a) → ε` |
| `L_(a → S_(a L` | P_(a | N | `L_(a) → S_(a) L` |

Rows 3 and 5 are the payoff of nullability: because `S_a` and `L_a` are nullable,
the scan *skips past them* and fires again on the next symbol. Row 5 is the one
that accepts the string.

```
P_(a) : L_)   → S_) L
        L_a)  → S_a) L
        L_a)  → L_)
        S_(a) → L_a) )
        S_(a) → ε
        L_(a) → S_(a) L
```

Start symbol: `S_(a)`. **`S_(a) → ε` makes the start symbol nullable ⇒ `( a )` ∈ L(Γ).** ✓

(`S_)` and `S_a)` end up with no productions — more of the tolerated useless residue.)

### The whole sequence at a glance

```
Γ ──(──▶ Γ_(          ──a──▶ Γ_(a          ──)──▶ Γ_(a)
         S_( → L )           S_a  → ε             S_(a) → ε        ← accept
         L_( → S_( L         L_a  → S_a L         S_(a) → L_a) )
                             S_(a → L_a )         L_a)  → S_a) L
                             L_(a → S_(a L        L_a)  → L_)
                                                  L_)   → S_) L
                                                  L_(a) → S_(a) L
```

Recognition = `nullable(S_w, Γ_w)`, exactly Brzozowski lifted from regexes to CFGs,
with the grammar-as-symbol encoding replacing the operational knot-tying of PWD.

---

## Observations

1. **Everything is driven by one rule (Eq. 5).** N-inference, T-inference, and the
   nullable-skip are one scan over each RHS; rule O is just "keep Γ around".
2. **The `nullable(α)` condition is where CFG-ness lives.** For the `E+E` grammar it
   barely matters; here it produces both the double-child `L_a) → S_a) L | L_)` and
   the accepting `S_(a) → ε`. Skipping a nullable prefix to act on the next symbol is
   the same move as an epsilon-closure / LR-closure step.
3. **Dead nonterminals are tolerated, not prevented.** `S_)`, `S_a)` get no productions;
   pruning only guarantees subscripts stay suffixes of the input read so far.
4. **Connection to our parser**: the D-child relation `(A_v → αXβ) ⇒ (A_vt → X_t β)`
   is a *left-to-right, prefix-quotient* step. Our `find_left_expansions` /
   `find_right_expansions` walk the same production structure but from the head
   outward in both directions — which is why the live theory framing is "split
   their Eq. 2 into a syntactic half we already have, and a semantic half where
   the real terminal is replaced by quotient-by-Σ*" (see memory note 2026-07-11).
