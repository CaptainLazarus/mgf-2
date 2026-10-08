# Osorio & Navarro — prefix/suffix/infix logic, reviewed

Source: `paper/Decision_problem_of_substrings_in_Context_Free_Lan.pdf` (read 2026-08-25).
Grammar assumed in CNF, eps-free. `alpha = a_1...a_n`.

## 1. Their machinery

| theirs | meaning |
|---|---|
| `[x]` | generator set `{X : X =>* x}` |
| `pref(A) = A ∪ [AV]` | add parents whose **left** child is in `A` |
| `first(A) = pref^n(A)` | left-corner closure: `{X : X =>* B gamma, B ∈ A}` |
| `suff(A) = A ∪ [VA]`, `last(A)` | mirror: right-corner closure |
| `inf(A) = A ∪ [VA] ∪ [AV]`, `mid(A)` | both |
| `M_{i,j}` | CKY cell, generators of `a_i...a_j` |
| `P_i` | `[T* a_1..a_i]` — alpha's prefix with unknown context on the LEFT |
| `S_i` | `[a_{n-i+1}..a_n T*]` — alpha's suffix with unknown context on the RIGHT |

Equations: (1) `[alpha T*] = ∪_{i=1}^{n-1} first([[alpha_i][alpha_{i+1}T*]])`,
(2) `[T* alpha] = ∪_{i=1}^{n-1} last([[T* alpha_i][alpha_{i+1}]])`,
(3) `[T* alpha T*] = ∪_{i=0}^{n} mid([[T* alpha_i][alpha_{i+1} T*]])`, and
(4) for `|alpha| = 1`, `[alpha T*] = first([alpha])`, `[T* alpha] = last([alpha])`.

## 2. Dictionary to our terms — this is the useful part

Per nonterminal `X`, with `C_{L(X)}(alpha) = {(u,v) : u alpha v ∈ L(X)}`:

    X ∈ first([alpha])   <=>  ∃v. (eps, v) ∈ C_{L(X)}(alpha)     anchor at LEFT edge
    X ∈ last([alpha])    <=>  ∃u. (u, eps) ∈ C_{L(X)}(alpha)     anchor at RIGHT edge
    X ∈ mid([alpha])     <=>  C_{L(X)}(alpha) != {}              anchor anywhere

So `first`/`last`/`mid` are **existential projections of the context set** — they record *that* a
context exists, never *which*. `pref(A) = A ∪ [AV]` throws the right sibling away by quantifying it
as "any `V`". That is precisely where the `(u,v)` correlation is lost, and it is the mechanised form
of Prop 7.2 / Remark 7.5.

**Their `P_i` / `S_i` are our L-Reduce / R-Reduce.** `P` extends leftward (`last`), matching L-Reduce
seeding `T[0,k]`; `S` extends rightward (`first`), matching R-Reduce seeding `T[k,n]`. Note their
naming reads backwards (the "prefix vector" `P` is computed with `last`) but the logic is right: the
prefix of alpha is the part needing unknown context on its *left*.

**Eq (3) is Thm 5.3 plus the straddle family, mechanised.** Its union splits as:

- `i = 0`: `mid([V · S_n])` — alpha entirely in the RIGHT child  → Thm 5.3 case 2
- `i = n`: `mid([P_n · V])` — alpha entirely in the LEFT child   → Thm 5.3 case 1
- `1 <= i <= n-1`: `mid([P_i · S_{n-i}])` — alpha **straddles** the split → Prop 5.4

Confirms independently that the straddle family is exactly the extra cost of `|w| > 1`.

## 3. Two problems in the pseudocode — FLAGGED, both need verification

### 3.1 `S` recurrence index looks off by two

Printed:

    S_i <- S_i ∪ first([ M_{n-i-1, n-j} S_j ]);

Derivation. `S_i = [a_{n-i+1..n} T*]`. Split before the part covered by `S_j`, which spans
`a_{n-j+1..n}`; so the left factor spans `a_{n-i+1 .. n-j}`, i.e. `M_{n-i+1, n-j}`. Expected:

    S_i <- S_i ∪ first([ M_{n-i+1, n-j} S_j ]);

Check `n=3, i=2, j=1`: `S_2 = [a_2 a_3 T*]`, left factor should be `M_{2,2}`.
Expected formula gives `M_{3-2+1,3-1} = M_{2,2}` ✓. Printed gives `M_{0,2}` — **out of bounds**
(the matrix is 1-indexed). The `P` recurrence, `P_i ∪= last([P_j M_{j+1,i}])`, is correct as printed.

**CAVEAT:** the text was extracted with `pdftotext`; a `+` mis-read as `-` is entirely possible.
**Open the PDF and look at the glyph before treating this as a defect in the paper.**

### 3.2 `I` appears to omit the zero-length-context cases

Printed:

    I <- mid([P_n V]) ∪ mid([V S_n]);
    for i <- 1 to n-1 do  I <- I ∪ mid([P_i S_{n-i}]);

Every term starts from a *parent* set, and `mid(A) = A ∪ [VA] ∪ [AV]` closes **upward** only. So
`P_n` and `S_n` themselves are never inserted into `I`. But `P_n = [T* alpha]` should be in
`[T* alpha T*]` (right context `eps`), and the authors say so explicitly in the worked example:
"all suffix strings are also infix ones". Suggested fix: `I <- P_n ∪ S_n ∪ mid([P_n V]) ∪ ...`.

**CAVEAT:** in their own example this is invisible — `P_n = {E,T}` and `I = {E,T,R}` anyway, because
`E` and `T` re-enter through other terms. So this is a *latent* gap, only visible when a nonterminal
derives `gamma alpha` and is not an ancestor of anything else matching. **Construct that grammar
before asserting the bug.** Cleanest test: a grammar where some `X` derives `gamma alpha` but `X`
never appears as a child in any production reachable from the other terms.

## 4. Why this matters for us

Their output is `I ⊆ V` — a set of nonterminals, i.e. the **emptiness predicate** of `C_L(alpha)`,
one bit per nonterminal. Confirms the tier-1 placement in
`docs/literature_check_2026-08-24.md` §5. The `first`/`last`/`mid` closures are exactly where the
context pairs are discarded, which makes §3's dictionary the sharpest available way to state the
difference between their output and ours.
