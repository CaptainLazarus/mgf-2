#set document(title: "Prefix Completion Using Derivatives", author: "Aditya Gudimetla")
#set page(paper: "us-letter", margin: (x: 2.5cm, y: 3cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)
#set heading(numbering: "1.1")
#set par(justify: true)

#align(center)[
  #text(size: 18pt, weight: "bold")[Prefix Completion Using Derivatives]
  #v(0.5em)
  #text(size: 12pt)[Aditya Gudimetla]
  #v(0.3em)
  #text(size: 11pt, style: "italic")[#datetime.today().display("[month repr:long] [year]")]
]

#v(2em)

#columns(2)[
  *Abstract* #h(0.5em) Given a context-free grammar $Gamma$ and a fragment $w$ that is a prefix of some unknown sentence of $Gamma$, what are the possible completions of $w$ ? Henriksen et al.'s derivative grammars #cite(<henriksen2019>) already builds, for every non-terminal $A$, a derivative $A_w$ whose language is exactly the set of completions of $w$ under $A$. Checking every non-terminal rather than only the start symbol for shortest completion length rather than nullability yields the non-terminals that can derive $w$ together with the least completion for each, at no cost beyond their construction.

  #v(1em)

  = Introduction
  
  Derivative grammars are constructed by iteratively differentiating a grammar $Gamma$ by an input string $w$, transforming it into the derivative grammar $Gamma_w$. Nullability of $Gamma_w$'s start symbol is taken as the test for whether $w in L(Gamma)$.
  
  The same differentiation defines an $A_w$ for _every_ non-terminal $A$, not just the start symbol, and $L(A_w)$ is exactly the set of completions of $w$ under $A$. Thus $A$ covers $w$ iff $A_w$ generates any string.
  
  From the obtained non-terminals, we focus on the minimal covering non-terminals i.e. those whose shortest completion of $w$ is smallest. We find these with a single fixpoint over $Gamma_w$ that measures each $A_w$'s shortest completion length. Henriksen et al.'s nullability check can be seen as a special case where that length is zero.

  // DRAFT: revised intro, addressing Julia's 2026-05-26 comments (problem/why/what/why-interesting/
  // challenges/approach structure, honest "no real challenge" framing, explicit prefix-only scope).
  // Not yet swapped in for the paragraphs above -- for review first.
  //
  // *Derivative grammars* #cite(<henriksen2019>) rewrite a context-free grammar $Gamma$ with respect
  // to a string $w$, producing $Gamma_w$, and were introduced for a single test: is $w$ a sentence of
  // $Gamma$? That test looks only at nullability of the start symbol's derivative -- but the
  // construction itself is not start-symbol-specific: differentiating $Gamma$ by $w$ produces a
  // derivative $A_w$ for *every* non-terminal $A$, discarded once the start symbol's answer is read
  // off. It's natural to ask what those discarded derivatives are good for.
  //
  // We show they already answer a harder question. Given $Gamma$ and a prefix fragment $w$, we ask
  // not just whether $w$ can be completed, but which non-terminals can complete it, and the shortest
  // completion under each. Answering this needs no new construction: only checking *generating*
  // rather than *nullable*, doing so for every $A_w$ rather than only $S_w$, and a length rather than
  // a yes/no. There is no technical obstacle here -- the machinery to answer both questions was
  // already sitting in Henriksen et al.'s definitions. The only thing missing was asking.
  //
  // We treat only the prefix case, where $w$ has no missing context to its left; the infix case,
  // where $w$ can also sit in the middle of a sentence, needs a two-sided construction and is left
  // for future work. §2 recalls the construction; §3--4 define covering and a completion-length
  // fixpoint over $Gamma_w$; §5 works both by hand on small grammars.

  #v(1em)

  = Background: derivative grammars

  Henriksen et al. #cite(<henriksen2019>) show that reading a terminal $t$ from a language $L(Gamma)$ corresponds to rewriting the grammar $Gamma$ into a derivative grammar $Gamma_t$ generating the derivative language $D_t (L(Gamma)) = {x : t x in L(Gamma)}$, via a small set of inference rules over productions. Iterating over a string $w = t_1 dots t_n$ produces the iterated derivative grammar $Gamma_w$, whose (subscripted) start symbol represents "the rest of the language" after $w$ has been read. For complete input, acceptance is nullability of that symbol, $w in L(Gamma) <=> "nullable"(S_w)$.

  We consider the case where $w$ is a genuine prefix, not malformed input. Two observations, both immediate from this construction, answer the fragment question without further machinery.

  *Observation 1.* For a prefix fragment, the relevant test is not nullability but whether $S_w$ is generating. $w$ is a prefix of some sentence of $Gamma$ iff $S_w$ generates some terminal string. More than a decision procedure, $L(S_w) = D_w (L(Gamma))$ is the set of valid completions of $w$.

  *Observation 2.* Henriksen et al.'s inference rules are not specific to the start symbol. Every production of every non-terminal is differentiated at every step, so a candidate subscripted non-terminal $A_w$ exists for every $A in N$. Some of these survive to produce a non-empty language, while others die partway when a terminal of $w$ mismatches every alternative available at that point, and the corresponding subscripted non-terminal simply never receives a production. Asking "what is $w$ the beginning of" is answered by checking, for every $A$, whether its already-computed derivative $A_w$ is generating.

  = Definitions

  Let $Gamma = (N, Sigma, P, S)$ be a CFG and a prefix fragment $w = t_1 dots t_n$. Build the iterated derivative grammar $Gamma_w$ as in Henriksen et al.'s Definition 3.3.

  *Least possible completion.* For a non-terminal $A$, let
  $ "LPC"(A, w) = { beta in L(A_w) : |beta| = min_(beta' in L(A_w)) |beta'| }. $

  $"LPC"(A, w)$ is the set of shortest completions of $w$ under $A$. We define the shortest completion as a string in $L(A_w)$ of minimum length. Since several completions can share that minimum length, $"LPC"(A, w)$ is in general a set, and all of its members have the same length. We call that shared length $m(A_w)$, the number of terminals needed to complete $w$ as an $A$. The subscript matters: $m(A_w)$ is a property of the derivative $A_w$, not of $A$ in the original grammar.

  *Covering.* $A$ covers $w$ if $A ==>^* alpha w beta$ for some $alpha, beta$, that is if $w$ appears in some string $A$ derives. This paper treats the prefix case $alpha = epsilon$, where $A$ covers $w$ exactly when either equivalent condition holds:
  1. $L(A_w) eq.not emptyset$
  2. $"LPC"(A, w) eq.not emptyset$
  In either case $w$ is a valid prefix of something $A$ generates. When $A$ does not cover $w$, this shows up in one of two observationally identical ways:
  1. $A_w$ never receives a production, or
  2. $A_w$ receives productions but generates nothing.

  *Covering set and minimum covering set.* 
  Let us define the covering set as
  $ "Cov"(w) = { A in N | A ==>^* alpha w beta } $

  where $alpha, beta in (N union Sigma)^*$

  Taking $alpha = epsilon$ (nothing to the left of $w$), we get the prefix covers for $w$, where

  $ "PrefixCov"(w) = { A in N | A ==>^* w beta } $

  is the set of non-terminals for which $w$ is a prefix of some string $A$ derives.
  
  We can now define a $"MinPrefixCover"(w)$ as
  $ {A in "PrefixCov"(w) : m(A_w) = m_min} $

  where $m_min = min_(B in "PrefixCov"(w)) m(B_w)$ is the smallest completion length among all prefix covers. $"MinPrefixCover"(w)$ keeps every cover that can generate $w$ and has length $m_min$, since they are all valid completions.

  Consequently, if $A_w$ is nullable then $m(A_w) = 0$, and since a completion length is never negative, such an $A$ is always in $"MinPrefixCover"(w)$, as $w$ can be automatically reduced to a complete $A$. Because every $m(A_w)$ is the length of an actual derivation $A ==>^* w beta$, $"MinPrefixCover"(w)$ never contains an invalid cover.

  = Computing m(A_w)

  We compute every $m(A_w)$ by a shortest-length fixpoint over $Gamma_w$'s productions, assigning each non-terminal the length of the shortest string it derives. A production costs the sum of its children, a terminal counting one and a non-terminal its own $m$. $m(A_w)$ is the smallest such cost over $A$'s productions, and we iterate until no length changes.

  *Example.* The fixpoint itself doesn't depend on the productions coming from a derivative grammar rather than an ordinary one — the mechanics are the same either way, so we illustrate them on a plain grammar and drop the subscript. Take the recursive, ambiguous grammar
  $ E arrow.r E "+" E | E "*" E | "(" E ")" | C | "num" | "id" $
  $ C arrow.r "id" "(" L ")" $
  $ L arrow.r E | L "," E $
  where $C$ is a call and $L$ an argument list. $E$ is ambiguous (two ways to combine) and recursive (it reaches itself through $C$ and $L$), yet the fixpoint still converges. Each non-terminal resolves once some production has all its children, giving
  $ m(E) = 1 quad (E arrow.r "num" "or" E arrow.r "id") $
  $ m(L) = m(E) = 1 $
  $ m(C) = 1 + 1 + m(L) + 1 = 4 $

  The recursive alternatives $E "+" E$, $E "*" E$ and $"(" E ")"$ all cost $3$, so the minimum never climbs and the iteration halts. Recursion and ambiguity do not affect the shortest length, only the parse forest.  

  Henriksen et al. consider nullability for the decision problem of strings in the language, which can be considered as the special case where $m(A_w) = 0$. A non-terminal is nullable exactly when the shortest string it derives is empty.

  A non-terminal gets a finite $m$ precisely when it derives some terminal string. The fixpoint terminates because $Gamma_w$ has only finitely many subscripted non-terminals and the lengths are strictly decreasing. The subscripts range over the suffixes of $w$, out of which we only consider those with subscript $w$ as part of the covering set.

  = Worked example

  == Grammar 1

  Take the toy grammar.
  $ S arrow.r "NP" "VP" $
  $ "VP" arrow.r "cl" thin "v" thin "NP" $
  $ "NP" arrow.r "det" thin "n" $

  === Input 1 ($w = $ "det n")
  $ S_"det" arrow.r "NP"_"det" "VP" $
  $ "NP"_"det" arrow.r n $
  $ S_"det n" arrow.r "NP"_"det n" "VP" quad ==> quad m(S_"det n") = 4 $
  $ "NP"_"det n" arrow.r epsilon quad ==> quad m("NP"_"det n") = 0 $

  $"VP"$'s own production starts with "cl", which does not match "det", so $"VP"_"det"$ is never generated and $"VP" in.not "PrefixCov"("det n")$.
  
  $ "PrefixCov"("det n") = {"NP", S} $
  $ "MinPrefixCover"("det n") = {"NP"} $
  "det n" is exactly a complete NP, while S also covers it, at four extra synthesised terminals.

  === Input 2 ($w = $ "cl v")
  A covering set with no nullable member at all.
  $ "VP"_"cl" arrow.r v thin "NP" $
  $ "VP"_"cl v" arrow.r "NP" quad ==> quad m("VP"_"cl v") = 2 $
  ($"NP"$ has no epsilon production). $S_"cl" arrow.r "NP"_"cl" "VP"$, but $"NP"$ has no production starting with "cl", so $"NP"_"cl"$ receives zero productions, $S_"cl"$ can never bottom out, and $S in.not "PrefixCov"("cl v")$.
  $ "PrefixCov"("cl v") = {"VP"} $
  $ "MinPrefixCover"("cl v") = {"VP"} $
  Here $m("VP"_"cl v") = 2$, and no non-terminal in this covering set is nullable at all.

  == Grammar 2

  Now take a small expression grammar.
  $ "Stmt" arrow.r "Expr" ";" | "Lvalue" "=" "Expr" ";" $
  $ "Expr" arrow.r "id" | "num" | "Expr" "+" "Expr" $
  $ "Lvalue" arrow.r "id" | "id" "[" "Expr" "]" $

  === Input 1 ($w = $ "id")
  A tie, with two non-terminals already complete.
  $ "Expr"_"id" arrow.r epsilon quad ==> quad m("Expr"_"id") = 0 $
  $ "Lvalue"_"id" arrow.r epsilon quad ==> quad m("Lvalue"_"id") = 0 $
  $ "Stmt"_"id" arrow.r ";" quad ==> quad m("Stmt"_"id") = 1 $
  $ "PrefixCov"("id") = {"Expr", "Lvalue", "Stmt"} $
  $ "MinPrefixCover"("id") = {"Expr", "Lvalue"} $
  A lone "id" is both a complete expression and a complete lvalue, so both tie at $m = 0$. "Stmt" also covers "id" but needs one more terminal, so it isn't included in the minimum prefix cover.

  = Conclusions

  Given a context-free grammar and a prefix fragment $w$, the derivative-grammar construction already builds a derivative $A_w$ for every non-terminal $A$, while only the nullability test for language membership is restricted to the start symbol. Applying instead
  
  1. that test to every $A_w$, not only the start symbol's, and
  2. a shortest-completion length in place of plain nullability,
  
  yields the non-terminals that can cover $w$, together with the least possible completion for each, at no cost beyond Henriksen et al.'s existing machinery. 
  
  So enumerating the non-terminals that can cover a prefix fragment, ranked by how little each is missing, is a simple process due to the construction of derivative grammars.

  The natural next step is the infix case, where $w$ is missing context on both sides rather than only the right. This requires a two-sided construction and is left for a follow-up.

  #bibliography("refs.bib")

]
// #columns(1)[
// ]
