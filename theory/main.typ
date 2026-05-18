#set document(title: "Fragment Parsing", author: "captainlazarus")
#set page(paper: "a4", margin: (x: 2.5cm, y: 3cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)
#set heading(numbering: "1.1")
#set par(justify: true)

#align(center)[
  #text(size: 18pt, weight: "bold")[Fragment Parsing]
  #v(0.4em)
  #text(size: 11pt, style: "italic")[#datetime.today().display("[month repr:long] [year]")]
]

#v(2em)

= Background

== Context-Free Grammars (copied from satta1994)

A _context-free grammar_ (CFG) is a four-tuple $G = (N, Sigma, P, S)$, where $N$ is a finite set of nonterminal symbols, $Sigma$ is a finite set of terminal symbols with $N inter Sigma = emptyset$, $P$ is a finite set of productions, and $S in N$ is the start symbol.

Productions in $P$ have the form $D_r -> Z_(r,1) Z_(r,2) dots Z_(r, pi_r)$, where $D_r in N$ and $Z_(r,j) in N union Sigma$, $pi_r >= 0$. A production is _null_ if $pi_r = 0$ and a _chain_ production if $pi_r = 1$ and $Z_(r,1) in N$.

The language derived by $G$ is $L(G) = {w | S =>^* w, w in Sigma^*}$.


== Decomposition

Let $omega$ be an input string that can be decomposed as

$ omega = alpha dot beta dot gamma $

where $alpha, gamma in Sigma^*$ and $beta in Sigma union N$.

There exists a derivation

$ alpha beta gamma arrow.double alpha A gamma $

or generally,

$ alpha beta gamma arrow.double [alpha \/ x] A [gamma \/ y] $

where $x, y in Sigma^* union N^* union {epsilon}$. The notation $[alpha\/x]$ denotes a correspondence between the input flank $alpha$ and the production symbol $x$ — specifically, $x arrow.double^* alpha$ (x derives alpha). The precise treatment of the recursive case is given in Section 3.

The possible values for the input flanks ($alpha, gamma$) and production flanks ($x, y$) are:

#table(
  columns: (1fr, 1fr),
  align: left,
  [*I — input flanks ($alpha, gamma$)*], [*II — production flanks ($x, y$)*],
  [(1) $alpha = epsilon, gamma = epsilon$],        [(1) $x = epsilon, y = epsilon$],
  [(2) $alpha = epsilon, gamma in Sigma^+$],       [(2) $x = epsilon$],
  [(3) $alpha in Sigma^+, gamma = epsilon$],       [(3) $y = epsilon$],
  [(4) $alpha, gamma in Sigma^+$],                 [(4) $x, y != epsilon$],
)

== Context Reduction Matrix

Mixing and matching cases from I and II gives all possible reduction scenarios for $beta$. Given a production $A -> x beta y$ and input fragment $alpha beta gamma$, the grammar defines what flanks are expected. A flank is a _gap_ if the production requires it but the input does not supply it.

Two notations are used in the derivations below:

- $(x)$ — $x$ is a production symbol required by the grammar but absent from the input (a gap)
- $[alpha\/x]$ — $alpha$ is present in the input and corresponds to production symbol $x$

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    *Cases 1.x* — $alpha = epsilon$, $gamma = epsilon$:
    #table(
      columns: (auto, 1fr),
      align: left,
      [*(1.1)*], [$beta -> A$],
      [*(1.2)*], [$beta -> beta (y) -> A$],
      [*(1.3)*], [$beta -> (x) beta -> A$],
      [*(1.4)*], [$beta -> (x) beta (y) -> A$],
    )
  ],
  [
    *Cases 2.x* — $alpha = epsilon$, $gamma$ present:
    #table(
      columns: (auto, 1fr),
      align: left,
      [*(2.1)*], [$beta gamma -> A gamma$],
      [*(2.2)*], [$beta gamma -> beta [gamma\/y] -> A gamma'$],
      [*(2.3)*], [$beta gamma -> (x) beta gamma -> A gamma$],
      [*(2.4)*], [$beta gamma -> (x) beta [gamma\/y] -> A gamma'$],
    )
  ],
)

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  [
    *Cases 3.x* — $alpha$ present, $gamma = epsilon$:
    #table(
      columns: (auto, 1fr),
      align: left,
      [*(3.1)*], [$alpha beta -> alpha A$],
      [*(3.2)*], [$alpha beta -> alpha beta (y) -> alpha A$],
      [*(3.3)*], [$alpha beta -> [alpha\/x] beta -> alpha' A$],
      [*(3.4)*], [$alpha beta -> [alpha\/x] beta (y) -> alpha' A$],
    )
  ],
  [
    *Cases 4.x* — $alpha$ present, $gamma$ present:
    #table(
      columns: (auto, 1fr),
      align: left,
      [*(4.1)*], [$alpha beta gamma -> alpha A gamma$],
      [*(4.2)*], [$alpha beta gamma -> alpha beta [gamma\/y] -> alpha A gamma'$],
      [*(4.3)*], [$alpha beta gamma -> [alpha\/x] beta gamma -> alpha' A gamma$],
      [*(4.4)*], [$alpha beta gamma -> [alpha\/x] beta [gamma\/y] -> alpha' A gamma'$],
    )
  ],
)

=== Note on Null Productions

We assume $beta$ is never nullable. For nullable flanks ($x$ or $y$), an implementation may precompute the nullable set $cal(N)_G = {A in N | A =>^* epsilon}$ and add skip-rules: for any case where a flank symbol is in $cal(N)_G$, add the corresponding case with that flank dropped. For example, if $x in cal(N)_G$, case 4.3 ($[alpha\/x] beta gamma -> alpha' A gamma$) admits a skip to case 2.1 ($beta gamma -> A gamma$) directly. Epsilon productions need not fire at runtime.

== Recurrence

Let $R(omega) subset.eq N$ denote the set of nonterminals that span $omega$. The recurrence is defined as follows:

*Base case:*
$ R(beta) = {A in N | A -> x beta y in P,\ x, y in N union Sigma union {epsilon}} $

where $x$ and $y$ are either matched against input flanks or treated as gaps per the CR matrix. This is a fixed-point computation over a finite set — cycles in the grammar do not cause non-termination.

*Inductive step:* For $omega = alpha beta gamma$, apply the CR matrix to obtain $alpha' A gamma'$ for each $A in R(beta)$:
$ R(omega) = union.big_{A in R(beta)} R(alpha' A gamma') $

where $|alpha' A gamma'| < |omega|$, guaranteeing termination.

A _final_ nonterminal $F$ is any $A in R(omega)$ such that $A$ spans the entire input — i.e. no unreduced symbols remain. $F$ need not be the start symbol $S$; any nonterminal covering $omega$ constitutes a valid parse result.

= Algorithm

== Recognition Table

Let $omega = w_1 w_2 dots w_n$ be the input string. The _recognition table_ $T$ is an $(n+1) times (n+1)$ array of sets, where $T[i,j]$ contains _items_ representing partial or complete derivations over the span $[i, j]$ (i.e. over $w_{i+1} dots w_j$).

There are two kinds of items:

- A _complete item_ $I_A$ asserts that nonterminal $A$ derives $w_{i+1} dots w_j$.
- A _partial item_ $I_r^(s,t)$ asserts that production $r$ has been partially assembled: symbols $Z_{r,s+1} dots Z_{r,t}$ (the head-adjacent slice) derive $w_{i+1} dots w_j$, and the remaining symbols $Z_{r,1} dots Z_{r,s}$ and $Z_{r,t+1} dots Z_{r,pi_r}$ are yet to be combined.

== H-Cover

The _H-cover_ $cal(H)(G)$ pre-computes all valid item-to-item relationships from the grammar. It consists of:

- *Projections* $(I_A, xi)$: item $I_A$ can be projected from child $xi$, where $xi$ is either a terminal or another item.
- *Left expansions* $(I, xi, I')$: $I'$ is the trigger — the known right child already in the table. $xi$ is the left child to be found elsewhere in the table. When both are present, the result $I$ spans further left than $I'$.
- *Right expansions* $(I, I', xi)$: $I'$ is the trigger — the known left child already in the table. $xi$ is the right child to be found elsewhere in the table. When both are present, the result $I$ spans further right than $I'$.

The cover is computed once per grammar and reused across all inputs.

== Agenda Algorithm

The algorithm maintains a queue (agenda) of items to process. When item $I'$ is added to $T[i,j]$ for the first time, it is pushed onto the agenda.

Processing item $I'$ at $T[i,j]$ applies four rules:

+ *Project:* for each $(I, I') in$ projections, add $I$ to $T[i,j]$.
+ *Left-expand:* for each $(I, xi, I') in$ left-expansions, find all $i' <= i$ such that $xi in T[i',i]$, and add $I$ to $T[i',j]$.
+ *Right-expand:* for each $(I, I', xi) in$ right-expansions, find all $j' >= j$ such that $xi in T[j,j']$, and add $I$ to $T[i,j']$.
+ *Reverse lookups:* In rules 2 and 3, $I'$ is the trigger and $xi$ is what we look for. Rule 4 handles the symmetric case: $I'$ is the child that was being looked for. Scan the table for items that could serve as the trigger, and for each match add the result $I$.

#block(fill: luma(235), inset: 10pt, radius: 4pt)[
  *Example.* Take $A -> B C$ with head $C$. The cover gives left-expansion $I_A -> I_B space I_r^((1,2))$, where $I_r^((1,2))$ is the known right child and $I_B$ is $xi$.

  - *Rule 2 (left-expand):* $I_r^((1,2))$ arrives at $T[1,2]$. Scan left for $I_B$ at $T[0,1]$. If found, add $I_A$ to $T[0,2]$.

  - *Rule 4 (reverse):* Suppose $I_B$ arrives at $T[0,1]$ _after_ $I_r^((1,2))$ was already processed — rule 2 already fired and found nothing. Now $I_B$ is the trigger. It is the $xi$ for the left-expansion above, so scan _right_ for $I_r^((1,2))$ at $T[1,j]$. Found at $T[1,2]$. Add $I_A$ to $T[0,2]$.

  Rules 2 and 4 together ensure $I_A$ is found regardless of which child arrives first. The same pairing holds for right-expand (rule 3) and its reverse.
]

The algorithm terminates because $T$ is finite and each item is enqueued at most once.

== Correctness (Completeness under membership assumption)

*Theorem:* If there exists a nonterminal $A in N$ and a derivation tree rooted at $A$ whose yield (with zero or more leaves replaced by virtual gap symbols) equals $omega$, then a valid item appears in $T[0,n]$ after the algorithm completes.

*Fundamental assumption:* fix a derivation tree $cal(T)$ witnessing the theorem — i.e. $A =>^* omega'$ where $omega'$ equals $omega$ with zero or more positions replaced by gaps. The proof shows that at each step the algorithm tracks $cal(T)$: every prefix (or suffix) subtree of $cal(T)$ that spans the processed portion of the input is represented by an item in the table.

The proof proceeds in two parts, one for each fill direction.

=== Part 1 — Forward (prefix) induction

*Claim:* For every $k$, $1 <= k <= n$, $T[0,k]$ contains an item corresponding to the prefix subtree of $cal(T)$ that spans $w_1 dots w_k$.

_Base ($k = 1$):_ Terminal $w_1$ seeds its projection items via the cover. If the prefix subtree of $cal(T)$ at $w_1$ requires constituents to the left that are absent from the input, boundary stuffing injects the corresponding item into $T[0,1]$ with those constituents marked virtual. Either way, the item for the prefix subtree exists in $T[0,1]$.

_Step:_ Assume $T[0,k]$ contains an item $b$ for the prefix subtree spanning $w_1 dots w_k$. Terminal $w_{k+1}$ seeds $T[k, k+1]$. Two cases:

+ $b$ directly combines with $w_{k+1}$: right-expand fires and adds the combined item to $T[0, k+1]$.

+ $b$ cannot combine directly: the derivation tree $cal(T)$ requires more structure to the left of $b$ before the combination is possible — i.e. $b$ is the right child of some cover rule whose left child is absent from the input. The inductive fill reduces $b$ leftward by injecting that left child as a virtual gap, producing a new item $b'$ in $T[0,k]$. This repeats until an item emerges that can combine with $w_{k+1}$ via right-expand. Since $cal(T)$ guarantees such a combination exists, termination is assured. $square$

=== Part 2 — Backward (suffix) induction

Triggered only if $T[0,n]$ is empty after Part 1 — i.e. no full-span item was reached from the left alone.

*Claim:* For every $k$, $0 <= k <= n-1$, $T[k,n]$ contains an item corresponding to the suffix subtree of $cal(T)$ that spans $w_k dots w_n$.

_Base ($k = n-1$):_ Terminal $w_n$ seeds its projection items. If the suffix subtree requires constituents to the right that are absent, boundary stuffing injects the item with those constituents virtual.

_Step:_ Assume $T[k,n]$ contains an item $b$ for the suffix subtree spanning $w_k dots w_n$. Terminal $w_k$ seeds $T[k-1,k]$. Two cases:

+ $b$ directly combines with $w_k$: left-expand fires and adds the combined item to $T[k-1, n]$.

+ $b$ cannot combine directly: $cal(T)$ requires more structure to the right of $b$ before the combination is possible. The inductive fill reduces $b$ rightward by injecting the missing right child as a virtual gap, producing $b'$ in $T[k,n]$, until an item emerges that combines with $w_k$ via left-expand. $cal(T)$ guarantees such a combination exists. $square$

=== Convergence

After both passes, a final closure is run on $T[0,n]$ — applying the same fill logic to whatever the two inductions deposited there. Any item reachable by combining prefix and suffix derivations is found at this step.

Together, Parts 1 and 2 guarantee that $T[0,n]$ contains a valid item whenever there exists $A in N$ and a derivation $A =>^* omega'$ where $omega'$ equals $omega$ with zero or more symbols replaced by gaps — regardless of which direction the fragment is approached from.

#block(fill: luma(235), inset: 10pt, radius: 4pt)[
  *Remark (sequential vs. simultaneous passes).* The backward pass is an implementation choice — it fires only if $T[0,n]$ is empty after the forward pass. A simultaneous version (running both directions together, with items from each pass feeding the other) is possible and may find derivations that neither pass finds in isolation. The interaction between the two directions is currently unanalysed.
]

== Tree Pruning

Recognition populates $T[0,n]$ with items and their derivations. Tree reconstruction follows derivation pointers back through the table, producing a parse forest. For ambiguous grammars or fragment inputs this forest can be exponentially large.

*Open problem:* the forest must be pruned to be useful. Two criteria are relevant:

+ *Gap minimisation:* trees with fewer virtual (dropped) constituents are better parses of the fragment — a tree with no gaps is a complete parse. Trees should be ranked or filtered by gap count.

+ *Structural plausibility:* among trees with equal gap count, some are more plausible parses than others depending on where the gaps fall (e.g. a missing right argument is more natural than a missing head). A scoring scheme over gap positions is needed.

Neither criterion is currently enforced — the implementation returns all trees up to a fixed cap. A principled pruning strategy is future work.

