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

  In this paper we describe an adaptation of the h-cover framework of #cite(<sattastock1994>) to the fragment parsing problem, returning $cal(C)(beta)$ with parse trees and context descriptions for any context-free grammar. We evaluate it on real fragments drawn from Linux kernel patches.
]

#bibliography("refs.bib")
