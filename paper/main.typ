#set document(title: "Anchor Parsing", author: "captainlazarus")
#set page(paper: "us-letter", margin: (x: 2.5cm, y: 3cm), numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)
#set heading(numbering: "1.1")
#set par(justify: true)

#align(center)[
  #text(size: 18pt, weight: "bold")[Anchor Parsing]
  #v(0.4em)
  #text(size: 11pt, style: "italic")[#datetime.today().display("[month repr:long] [year]")]
]

#v(2em)

#columns(2)[
  *Abstract* #h(0.5em) We present a parser that given a context free grammar $G = (N, Sigma, P, S)$ and a string $beta$ such that $exists x,y in Sigma^*: x beta y in L(G)$, enumerates all possible parse trees that can cover $beta$ with the missing left and right context, if any. We can use this to extract parse trees from incomplete code, such as fragments found in git patches.
]
