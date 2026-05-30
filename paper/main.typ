#import "@preview/cetz:0.3.4": canvas, draw
#set document(title: "Fragment Parsing", author: "captainlazarus")
#set page(paper: "us-letter", margin: (x: 2.5cm, y: 3cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)
#set heading(numbering: "1.1")
#set par(justify: true)

#let ctx-line(s) = block(width: 100%, above: 0pt, below: 0pt, inset: (x: 6pt, y: 2pt))[#text(size: 9pt)[#raw(s)]]
#let del-line(s) = block(width: 100%, fill: rgb("#ffd7d5"), above: 0pt, below: 0pt, inset: (x: 6pt, y: 2pt))[#text(size: 9pt)[#raw(s)]]
#let add-line(s) = block(width: 100%, fill: rgb("#d4f4c7"), above: 0pt, below: 0pt, inset: (x: 6pt, y: 2pt))[#text(size: 9pt)[#raw(s)]]

#align(center)[
  #text(size: 18pt, weight: "bold")[Anchor Parsing]
  #v(0.4em)
  #text(size: 11pt, style: "italic")[#datetime.today().display("[month repr:long] [year]")]
]

#v(2em)

#columns(2)[
  *Abstract* #h(0.5em) We present a parser that given a context free grammar $G = (N, Sigma, P, S)$ and a string $beta$ such that $exists x,y in Sigma^*: x beta y in L(G)$, enumerates all possible parse trees that can cover $beta$ with the missing left and right context, if any. We can use this to extract parse trees from incomplete code, such as fragments found in git patches.

  #v(1em)

  = Introduction

  Git patches only record the added and removed lines in a codebase, presenting the code as fragments with minimal surrounding context. When studying how code changes across a series of patches, there is a need to understand what the changed code is syntactically: a declaration, a function call, a statement, etc.

  #v(0.5em)
  #block(stroke: 0.5pt + luma(180), radius: 2pt, clip: true, width: 100%)[
    #ctx-line("     int size, rc = 0;")
    #ctx-line(" ")
    #ctx-line("     while (n > 0) {")
    #del-line("-  size = zpci_get_max_write_size((u64 __force) src,")
    #del-line("-  (u64) dst, n,")
    #del-line("-  ZPCI_MAX_READ_SIZE);")
    #add-line("+  size = zpci_get_max_io_size((u64 __force) src,")
    #add-line("+  (u64) dst, n,")
    #add-line("+  ZPCI_MAX_READ_SIZE);")
    #ctx-line("   rc = zpci_read_single(dst, src, size);")
    #ctx-line("         if (rc)")
    #ctx-line("             break;")
  ]
  #align(center)[#text(size: 9pt, style: "italic")[A fragment from a Linux kernel patch.]]

  #v(0.4em)
  #block(stroke: 0.5pt + luma(180), radius: 2pt, clip: true, width: 100%)[
    #ctx-line("     int size, rc = 0;")
    #ctx-line(" ")
    #ctx-line("     while (n > 0) {")
    #add-line("   size = zpci_get_max_io_size((u64 __force) src,")
    #add-line("   (u64) dst, n,")
    #add-line("   ZPCI_MAX_READ_SIZE);")
    #ctx-line("         rc = zpci_read_single(dst, src, size);")
    #ctx-line("         if (rc)")
    #ctx-line("             break;")
  ]
  #align(center)[#text(size: 9pt, style: "italic")[Code to be parsed (highlighted) with surrounding context.]]

  Parsing this input is complicated, since standard parsers assume a well-formed, complete input. When presented with a fragment they fail at the first token that cannot extend a valid parse due to the missing surrounding context. Parsers with error recovery strategies (tree-sitter and similar tools) salvage a single best parse but suppress ambiguity that might exist.

  To resolve these issues, we change the basic assumptions.
  1. We assume that the input string belongs to the language and has a valid derivation
  2. We only need the smallest non terminals that can cover the entire input.

  Given a context-free grammar $G$ and a token sequence $beta$, our algorithm returns the covering set $cal(C)(beta) subset.eq N$ of nonterminals under which $beta$ appears as a substring, together with parse trees rooted at nonterminals in $cal(C)(beta)$ and descriptions of the missing context. This allows us to compare two fragments with the same covering set directly as instances of the same grammatical construct.

  In this paper we describe an adaptation of the h-cover framework of Satta and Stock #cite(<sattastock1994>) to the fragment parsing problem, returning $cal(C)(beta)$ with parse trees and context descriptions for any context-free grammar. We evaluate it on real fragments drawn from Linux kernel patches.

  = Problem

  Let $G = (N, Sigma, P, S)$ be a context-free grammar and $beta in Sigma^+$ a token sequence. A nonterminal $A in N$ _covers_ $beta$ if there exist $alpha, gamma in Sigma^*$ such that

  $ A =>^* alpha beta gamma $

  The _covering set_ is

  $ cal(C)(beta) = {A in N | exists alpha, gamma in Sigma^* : A =>^* alpha beta gamma} $

  The algorithm computes, for each $A in cal(C)(beta)$, a set of _gap parse trees_ rooted at $A$ spanning $beta$. A gap parse tree is a parse tree over $beta$ whose leaves are either tokens from $beta$ or _virtual nodes_ $chevron.l X chevron.r$ ($X in N union Sigma$). Virtual nodes mark constituents present in the derivation of $A$ but absent from $beta$. Those appearing before the first token form the left gap $L$; those after the last token form the right gap $R$.

  *Example.* Let $G_"cl"$ be the grammar #cite(<sattastock1994>):

  $ S &-> "NP VP" quad ("head: VP") \ "VP" &-> "cl v NP" quad ("head: v") \ "NP" &-> "det n" quad ("head: det") $

  For the fragment

  $ beta = "v det" $

  VP derives $"cl" dot beta dot "n"$, placing it in the covering set. S derives $"NP cl" dot beta dot "n"$ similarly, giving $cal(C)(beta) = {"VP", "S"}$.

  The gap parse tree for VP (left gap $chevron.l "cl" chevron.r$, right gap $chevron.l "n" chevron.r$) is:

  #align(center)[
    #canvas(length: 0.75cm, {
      draw.content((2, 3), [VP])
      draw.content((0, 1.5), text(style: "italic")[⟨cl⟩])
      draw.content((2, 1.5), [v])
      draw.content((4, 1.5), [NP])
      draw.content((3.2, 0), [det])
      draw.content((4.8, 0), text(style: "italic")[⟨n⟩])
      draw.line((2, 2.6), (0.3, 1.9))
      draw.line((2, 2.6), (2, 1.9))
      draw.line((2, 2.6), (3.7, 1.9))
      draw.line((4, 1.1), (3.35, 0.4))
      draw.line((4, 1.1), (4.65, 0.4))
    })
  ]

  $chevron.l "cl" chevron.r$ is the missing left sibling and $chevron.l "n" chevron.r$ the missing right terminal, giving $L_"VP" = (chevron.l "cl" chevron.r)$ and $R_"VP" = (chevron.l "n" chevron.r)$. Boundary seeding promotes VP into S, prepending $chevron.l "NP" chevron.r$, so $L_S = (chevron.l "NP" chevron.r, chevron.l "cl" chevron.r)$ and $R_S = (chevron.l "n" chevron.r)$.

  = Terminology
  The *recognition table* $T$ is an $(n+1) times (n+1)$ array for an input of length $n$. Cell $T[i,j]$ holds items representing derivations assembled over the span $w_(i+1) dots w_j$.

  Two kinds of item appear in $T$:

  - A *complete item* $A$ which asserts that nonterminal $A$ derives the span exactly.
  - A *partial item* $(r, s, t)$ that represents partial progress on production $r : D -> Z_1 dots Z_(pi_r)$ with head at position $tau_r$.

  Each production $r : D -> Z_1 dots Z_(pi_r)$ in the grammar designates one symbol as its *head*, at position $tau_r$ for $1 <= tau_r <= pi_r $.

  A partial item starts from the head symbol $Z_(tau_r)$, seeded by *projection*, and grows outward through *left* and *right expansion*. The head always stays within the assembled range ($s < tau_r <= t$); when $s = 0$ and $t = pi_r$ the full right-hand side is covered.

  For example, in the production $"VP" -> "cl" bold(v) "NP"$, we assign $bold(v)$ as the head. Seeing the token "v" in the input projects it to the partial item $(r_"VP", 1, 2)$. Then we search for "cl" and NP to complete it.

  #v(0.3em)
  #block(fill: luma(248), stroke: 0.5pt + luma(200), inset: (x: 8pt, y: 6pt), radius: 3pt, width: 100%)[
    #let on(s) = box(stroke: 0.5pt, fill: luma(212), inset: (x: 5pt, y: 3pt))[#text(size: 8pt)[#s]]
    #let off = box(stroke: (paint: luma(160), dash: "dashed"), inset: (x: 5pt, y: 3pt))[#h(1.4em)]
    #align(center)[#text(size: 8.5pt)[$r$ : VP $arrow.r$ cl *v* NP #h(1em) (head: v, $tau_r = 2$, $pi_r = 3$)]]
    #v(0.4em)
    #grid(
      columns: (3.8em, auto, auto, auto, 1fr),
      column-gutter: 4pt,
      row-gutter: 3pt,
      align: (right + horizon, center + horizon, center + horizon, center + horizon, left + horizon),
      [#text(size: 8pt, fill: luma(120))[input]],  [#text(size: 8pt, fill: luma(120))[cl]], on("v"), [#text(size: 8pt, fill: luma(120))[NP]], [#text(size: 8pt, fill: luma(120))[seen "v"]],
      [],                              [],        [#text(size: 10pt)[$arrow.b$]], [], [],
      [#text(size: 8pt)[*project*]],   off,       on("v"), off,       [#text(size: 8pt)[(r, 1, 2)]],
      [],                              [],        [#text(size: 10pt)[$arrow.b$]], [], [],
      [#text(size: 8pt)[*L-expand*]],  on("cl"),  on("v"), off,       [#text(size: 8pt)[(r, 0, 2)]],
      [],                              [],        [#text(size: 10pt)[$arrow.b$]], [], [],
      [#text(size: 8pt)[*R-expand*]],  on("cl"),  on("v"), on("NP"),  [#text(size: 8pt)[CompleteItem(VP)]],
    )
  ]
  #v(0.3em)

  *Projection* is the step that creates an initial partial item from a recognized head symbol, without consuming additional input. For a unit production ($pi_r = 1$), the head projects directly to a complete item.

  *Expansion* is the step that extends a partial item by combining it with an adjacent item in the table. A *left expansion* consumes the next required symbol to the left while a *right expansion* does the same to the right. For non-unit productions, a complete item is produced only by the final expansion step, not by projection.

  The *h-cover* $cal(H)(G)$ is a set of production rules derived from the grammar. It is essentially an intermediate grammar that preserves the original language. It is computed once and can be reused across all inputs.

  *Virtual nodes* $chevron.l X chevron.r$ represent constituents that participate in a derivation but are absent from the input fragment. They give us possible completions of the fragment.

  *L-Reduce* and *R-Reduce* are passes applied when the full span $T[0,n]$ is empty after the main agenda. L-Reduce processes prefix spans $T[0,k]$ by injecting virtual left siblings for items whose left context is missing from the fragment. R-Reduce does the same for suffix spans $T[k,n]$ when L-Reduce is insufficient.

  = Overview of the algorithm

  Given a CFG $G$ and an input $beta$, each production in $G$ designates one symbol as the _head_ #cite(<sattastock1994>). Using these heads, we precompute an intermediate grammar called the _h-cover_ $cal(H)(G)$. In $cal(H)(G)$, the productions expand outwards from the selected head, and the binary nature of the productions means that every combination step merges exactly two spans. This allows us to use tabular methods to enumerate all valid derivations over every span of $beta$ in cubic time.

  Every token in $beta$ is a potential starting point for a derivation. Initially, each token initiates a chain of upward projections through the grammar, each step applying a head cover production until no further projections apply. From there, analysis expands bidirectionally, combining with constituents to the left and right in any order until no new derivations can be found.

  While this suffices for a complete input, a fragment may be missing its left or right context. The first or last token of $beta$ may need a left or right sibling that is absent from the input. To handle this, we seed the boundary cells $T[0,1]$ and $T[n-1,n]$ with all items reachable by inferring the missing left or right constituent from the grammar, a step we call _boundary seeding_. Each inferred constituent is recorded as a virtual node in the resulting parse tree.

  If $T[0,n]$ is empty after the main agenda, for each prefix span $T[0,k]$, the agenda processes items there with a virtual left sibling, producing new items that can reach $T[0,n]$. If $T[0,n]$ is still empty after this, then we do the same from suffix spans $T[k,n]$. The former is called L-Reduce, and the latter R-Reduce. A final agenda pass then runs on any items newly arrived in $T[0,n]$.

  The items in $T[0,n]$ at the end span the full fragment. Each complete item there identifies a covering nonterminal, and the parse tree reconstructed from it carries the virtual nodes as leaves, directly giving $L_A$ and $R_A$.

  = Algorithm

  == Recognition Table

  Let $beta = w_1 w_2 dots w_n$ be the input fragment. Items are placed in $T[i,j]$ when they cover the span $w_{i+1} dots w_j$. A partial item $(r, s, t)$ projects to a complete item for $D$ once $s = 0$ and $t = pi_r$.

  == H-Cover

  The h-cover $cal(H)(G)$ encodes three families of inference rule derived from the grammar, computed once at preparation time and reused across all inputs.

  For each production $r : D -> Z_1 dots Z_(pi_r)$ with head at position $tau_r$:

  *Projections.* The head symbol $Z_(tau_r)$ seeds an initial partial item $(r, tau_r - 1, tau_r)$ spanning only the head position. For unit productions ($pi_r = 1$), the head projects directly to a complete item for $D$.

  *Left expansions.* A partial item $(r, s, t)$ with $s > 0$ requires $Z_s$ as its immediate left neighbour. If $Z_s$ is assembled over $T[i', i]$, the item combines with it to yield $(r, s-1, t)$ in $T[i', j]$.

  *Right expansions.* Symmetrically, a partial item $(r, s, t)$ with $t < pi_r$ requires $Z_(t+1)$ as its immediate right neighbour. If $Z_(t+1)$ is assembled over $T[j, j']$, it yields $(r, s, t+1)$ in $T[i, j']$.

  Epsilon-nullable nonterminals admit a further class of *epsilon projections*: if an expansion expects a nonterminal $B$ that derives $epsilon$, the partial item may advance without finding $B$ in the table.

  == Agenda

  The table is filled by a worklist agenda. Items are enqueued when first added to a cell; duplicate additions are discarded. Dequeueing item $a$ from $T[i,j]$ triggers four operations.

  + *Project.* If $a$ is ready to project (a complete item, or a partial item with $s = 0$ and $t = pi_r$), add the projected item to $T[i,j]$.
  + *Left-expand.* If $a$ is a partial item $(r, s, t)$ requiring $Z_s$ to its left, probe all cells $T[i', i]$ for the required symbol and add $(r, s-1, t)$ to $T[i', j]$ for each match.
  + *Right-expand.* If $a$ requires $Z_(t+1)$ to its right, probe all cells $T[j, j']$ and add $(r, s, t+1)$ to $T[i, j']$ for each match.
  + *Reverse.* Item $a$ may provide the missing child for a partial item already assembled in some other cell. The table records such blocked items; when $a$ arrives, those waiting for $a$ at boundary $i$ or $j$ are combined and enqueued.

  Because each item is enqueued at most once and the table is finite, the agenda terminates.

  == Boundary Seeding

  The agenda fills $T[0,n]$ only when the fragment has sufficient left context starting at $w_1$. Fragments missing left or right context require additional seeding.

  *Initial seeding.* Before the agenda runs, the edge cells $T[0,1]$ and $T[n-1,n]$ receive items whose derivation requires a missing neighbour. For any partial item derivable from $w_1$ that needs a left sibling absent from $beta$, we inject the item with a virtual node recording the missing constituent. The symmetric injection handles right siblings at $T[n-1,n]$. These virtual nodes become leaves in the reconstructed parse tree.

  *L-Reduce.* If $T[0,n]$ is empty after the main agenda, we process each prefix span $T[0,k]$ for $k = 1, dots, n$. Items at $T[0,k]$ that can be extended leftward with a virtual left sibling are injected and the agenda is re-run. This handles fragments whose left boundary falls in the interior of a derivation.

  *R-Reduce.* If $T[0,n]$ is still empty after L-Reduce, the same process runs on suffix spans $T[k,n]$ for decreasing $k$. A final closure pass runs directly on $T[0,n]$, combining prefix and suffix derivations that meet at the full span.

  == Root Extraction

  Every complete item $A$ in $T[0,n]$ identifies a nonterminal covering $beta$. The covering set $cal(C)(beta)$ is assembled from these items; for each, the parse tree is reconstructed by following derivation pointers stored during recognition.

  A *subtree-dominance filter* removes redundant candidates: if the best parse tree for $A$ appears as a direct child in the best parse tree for $B$, then $A$ is dominated by $B$ and excluded from the output. Surviving candidates are ranked by gap count — the number of virtual nodes in their best parse tree — so that the most complete interpretations appear first.

  = Implementation

  The implementation is in OCaml and separates grammar preparation from recognition, so that the same prepared grammar is reused across an entire corpus of fragments.

  *Grammar pipeline.* Grammars are read from ANTLR4 `.g4` files. The reader strips comments, splits rules, and desugars operator notation: `x+` becomes `x x*`, and `x*` introduces a fresh nonterminal with productions `x* -> x x* | ε`. Uppercase identifiers and single-quoted strings become terminals; lowercase identifiers become nonterminals. The pipeline produces a flat record of nonterminals, terminals, productions, and a designated start symbol.

  *Preparation.* `prepare(G)` computes the h-cover together with two input-independent auxiliary tables. The _nullable set_ identifies nonterminals deriving $epsilon$ and drives epsilon projections. The _min-yield table_ maps each nonterminal to the shortest terminal string it derives; virtual nodes in the output are labelled with this completion rather than an abstract nonterminal name.

  *Recognition.* `recognize(H, beta)` seeds epsilons and boundary items into the empty table, runs the worklist agenda, and applies L-Reduce and R-Reduce as described above. Derivation pointers are stored alongside each item so that parse trees can be reconstructed after recognition completes.

  *Tree reconstruction.* Trees are reconstructed lazily from the stored derivation pointers. Reconstruction is capped at five trees per root to avoid cartesian-product blowup in ambiguous grammars; in practice the first tree suffices to identify the syntactic category and gap description.

  = Evaluation

  We evaluate on three grammars of increasing complexity. Grammar preparation runs once per grammar; recognition and reconstruction run per fragment.

  *GCL grammar.* Three productions, 4 terminals. For the fragment $beta = "v det"$ the system returns one root: VP with 2 gaps ($L = chevron.l "cl" chevron.r$, $R = chevron.l "n" chevron.r$) and a single parse tree. S is inferred but removed by the subtree-dominance filter, since S's best tree contains VP as a direct child — retaining both would be redundant. For the complete input "det n cl v det n" the system returns S with 0 gaps and a single tree.

  *Lisp grammar.* An S-expression grammar read from an ANTLR4 file, with alternation and Kleene operators desugared by the grammar pipeline. Single-atom inputs are covered by `s_expression` with 0 gaps. Dotted pairs such as `(ATOM . ATOM)` are likewise covered with 0 gaps.

  *C grammar.* A full C grammar in ANTLR4 format, desugared to several hundred productions. Grammar preparation completes in under one second and is shared across all fragments. For short fragments of 2–10 tokens, recognition produces tens to hundreds of table items. Multiple root candidates appear naturally: a bare sequence of tokens may be a valid expression, a statement argument, a declarator, or several simultaneously. The subtree-dominance filter reduces the displayed roots to non-redundant candidates. Tree reconstruction is lazy and capped at 5 trees per root to avoid cartesian-product blowup in the derivation forest; this suffices to identify the syntactic category and gap description for each root.

  = Related Work

  *Substring recognition.* Rekers and Koorn #cite(<rekerskoorn1991>) give an O($n^3$) algorithm for deciding whether $beta$ is a substring of some sentence in $L(G)$, and produce parse trees. Their trees are for the complete sentence $alpha beta gamma$ rooted at $S$, not for $beta$ alone rooted at covering nonterminals. The covering set $cal(C)(beta)$ is not computed.

  Osorio and Navarro #cite(<osorio2001>) give the closest prior formulation: using a CYK variant they compute ${A in N | beta in L^"infix"(A)}$ explicitly. No parse trees are produced, no context description is given, and inputs that are not clean infixes of any sentence are not handled.

  *Gap parsing.* Lang #cite(<lang1988>) parses strings with explicit gap markers (? for one unknown word, \* for a sequence). The parser labels gap positions with covering nonterminals. Our setting differs: we have no markers and no knowledge of gap positions — the entire surrounding context is unknown.

  *Bidirectional parsing.* Satta and Stock #cite(<sattastock1994>) develop the h-cover framework for bidirectional tabular recognition of complete input. We adopt the framework but change the goal: instead of recognising membership in $L(G)$, we classify a bare fragment by computing $cal(C)(beta)$ with parse trees and context descriptions. Partial items, intermediate in the original algorithm, become the primary output of ours.

  *Error recovery.* Tree-sitter and similar tools find a single best repair when parsing fails. This is appropriate for editors but not for patch analysis, where multiple grammatical classifications may simultaneously hold for the same fragment.

  = Conclusions

  We have defined the fragment parsing problem and described an algorithm for solving it: given any context-free grammar and a bare token sequence, compute the covering set $cal(C)(beta)$ of nonterminals whose infix language contains $beta$, together with parse trees and context descriptions for each. The algorithm adapts the h-cover framework of Satta and Stock to operate without a complete input or a privileged start symbol. We evaluate it on C fragments from Linux kernel patches.

  *Limitations.* Tree reconstruction is expensive for long fragments against large grammars; lazy reconstruction is future work. The algorithm assumes the fragment has a valid derivation — genuinely malformed inputs are not currently flagged as such.

  *Future work.* Probabilistic ranking of root candidates; application to additional languages via existing ANTLR grammars; a study of syntactic change patterns in Linux kernel patches using $cal(C)(beta)$ as the classification signal.
]

#bibliography("refs.bib")
