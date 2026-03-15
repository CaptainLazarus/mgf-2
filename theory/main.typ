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

