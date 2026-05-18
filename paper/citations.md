# Citations

Papers gathered during literature search. Organised by cluster.

---

## Foundational: Satta & Stock line (1988–1994)

**Stock, Falcone, Insinnamo. 1988.**
"Island Parsing and Bidirectional Charts."
COLING Budapest 1988 Volume 2, pp. 636–641. ACL Anthology: C88-2132.
*Introduces bidirectional chart parsing from island anchors. Earliest paper combining island-driven + bidirectional ideas in a chart setting.*

**Satta, Giorgio and Stock, Oliviero. 1989.**
"Formal Properties and Implementation of BiDirectional Charts."
IJCAI 1989, Detroit, pp. 1480–1485.
*Formal treatment of bidirectional chart parsing. Completeness proofs.*

**Satta, Giorgio and Stock, Oliviero. 1989.**
"Head-Driven Bidirectional Parsing: A Tabular Method."
IWPT 1989, Pittsburgh, pp. 43–51. ACL Anthology: W89-0205.
*Origin of head-driven bidirectional tabular parsing. Direct ancestor of the H-cover algorithm.*

**Satta, Giorgio and Stock, Oliviero. 1991.**
"A Tabular Method for Island-Driven Context-Free Grammar Parsing."
AAAI 1991, Los Angeles, pp. 143–148.
PDF: https://cdn.aaai.org/AAAI/1991/AAAI91-023.pdf
*Island-driven tabular CFG parsing — parser starts from any position (the island) and expands bidirectionally. Closest existing algorithm to anchor parsing; differs in that the full utterance is known.*

**Satta, Giorgio and Stock, Oliviero. 1994.**
"BiDirectional Context-Free Grammar Parsing for Natural Language Processing."
Artificial Intelligence 69:123–164. DOI: 10.1016/0004-3701(94)90008-6.
*The definitive journal-length treatment of bidirectional tabular parsing. Essential reading.*

---

## Foundational: Anchor word / bidirectional

**Saito, Hiroaki. 1990.**
"Bi-directional LR Parsing from an Anchor Word for Speech Recognition."
COLING 1990 Volume 3. ACL Anthology: C90-3042.
PDF: https://aclanthology.org/C90-3042.pdf
*Runs two LR parsers in opposite directions from a high-confidence speech token. "Anchor" = reliably recognised word in a complete utterance. Goal is a complete parse, not fragment characterisation.*

**Lavelli, Alberto and Satta, Giorgio. 1991.**
"BiDirectional Parsing of Lexicalized Tree Adjoining Grammars."
EACL 1991, Berlin. ACL Anthology: E91-1006.
*Extends bidirectional parsing to Lexicalized TAGs. Shows the anchor/head concept generalises beyond plain CFGs.*

**Devos, Laurent and Gilloux, Michel. 1990.**
"GPSG Parsing, Bidirectional Charts, and Connection Graphs."
COLING 1990 Volume 2. ACL Anthology: C90-2026.
*Applies bidirectional chart parsing to GPSG. Moderate relevance.*

---

## Closest prior work: substring / infix recognition

**Rekers, Jan and Koorn, Wilco. 1991.**
"Substring Parsing for Arbitrary Context-Free Grammars."
IWPT 1991, pp. 218–224. Also: ACM SIGPLAN Notices 26(5):59–66. DOI: 10.1145/122501.122505.
ACL Anthology: 1991.iwpt-1.25.
*Checks whether β ∈ L^{infix}(L(S)) and generates parse trees for full sentences containing β. Start symbol only, no per-nonterminal enumeration, no characterisation of missing context. Fails silently on non-clean infixes.*

**Osorio, Mauricio and Navarro, Juan Antonio. 2001.**
"Decision problem of substrings in Context Free Languages."
CIC 2001 (Mexican Computing Conference).
PDF: https://nokyotsu.com/me/papers/cic01.pdf
*CLOSEST PRIOR WORK on point 1. Explicitly computes {A ∈ N : αβγ ∈ L(A) for some α, γ} using CYK. 3-page note, essentially zero citations, zero follow-up in 24 years. Does NOT characterise α/γ, does NOT handle non-clean infixes.*

**Nederhof, Mark-Jan and Satta, Giorgio. 2011.**
"Computation of Infix Probabilities for Probabilistic Context-Free Grammars."
EMNLP 2011, Edinburgh, pp. 1213–1221. ACL Anthology: D11-1112.
PDF: https://mjn.host.cs.st-andrews.ac.uk/publications/2011a.pdf
*Defines infix probability = Pr(β is a substring of a sentence from G). Uses Bar-Hillel construction. Probabilistic setting; no per-nonterminal enumeration, no context characterisation.*

**Cognetta, Marco; Han, Yo-Sub; Kwon, Soon Chan. 2018.**
"Incremental Computation of Infix Probabilities for Probabilistic Finite Automata."
EMNLP 2018. ACL Anthology: D18-1293.
*Extends Nederhof/Satta 2011 to PFAs, incremental. Lower relevance — finite automata, not CFGs.*

**Cognetta, Marco; Han, Yo-Sub; Kwon, Soon Chan. 2019.**
"Online Infix Probability Computation for Probabilistic Finite Automata."
ACL 2019. ACL Anthology: P19-1528.
*Online/streaming version of [Cognetta 2018]. Same limitations.*

---

## Incomplete / gapped input

**Lang, Bernard. 1988.**
"Parsing Incomplete Sentences."
COLING 1988, vol. 1, pp. 365–371. ACL Anthology: C88-1075.
PDF: https://aclanthology.org/C88-1075.pdf
*Parses strings with explicit gap markers (? = one unknown word, * = unknown sequence). Produces a shared forest; labels gap positions with covering nonterminals. Requires explicit markers — does not infer that the entire surrounding context is unknown. Key limitation for standalone fragment parsing.*

**"Parsing Incomplete Sentences Revisited." 2004.**
CICLing 2004, LNCS 2945, Springer, pp. 102–111.
*Refinement of Lang 1988 with improved DP. Same model — explicit gap markers required.*

**Bertsch, Eberhard and Nederhof, Mark-Jan. 2005.**
"Gap Parsing with LL(1) Grammars."
Grammars 8:1–16.
Semantic Scholar: https://www.semanticscholar.org/paper/Gap-Parsing-with-LL(1)-Grammars-Bertsch-Nederhof/92dbe16799eb4400e2bcbb20946e3caa70384d7d
*Complexity of parsing with explicit gaps: O(n³) for general CFLs, O(n²)/O(n) for LL(1)/XML. Follows Lang 1988 model.*

**Mirzapour, Mehdi. 2017.**
"Finding Missing Categories in Incomplete Utterances."
RECITAL 2017. ACL Anthology: 2017.jeptalnrecital-recital.12.
*Uses categorial grammar + DP to find a single missing grammatical category for a sequence with one known gap. Specific instance of the problem (one gap, one missing NT). Requires knowing gap position.*

---

## Probabilistic island-driven parsing

**Corazza, Anna; De Mori, Renato; Gretter, Roberto; Satta, Giorgio. 1991.**
"Computation of Probabilities for an Island-Driven Parser."
IEEE Transactions on Pattern Analysis and Machine Intelligence 13(9):936–950.
IEEE: https://ieeexplore.ieee.org/document/93811/
*Adds probabilistic weights to island-driven parsing for speech recognition. Implicitly solves the stochastic version of finding which nonterminals generate a fragment. Full sentence length known.*

**Corazza, Anna; Gretter, Roberto; Satta, Giorgio; De Mori, Renato. 1991.**
"Stochastic Context-Free Grammars for Island-Driven Probabilistic Parsing."
IWPT 1991, Cancun, pp. 210–217.
*Conference version of above. Shorter form.*

**Corazza, Anna; De Mori, Renato; Satta, Giorgio. 1992.**
"Computation of Upper-Bounds for Stochastic Context-Free Languages."
AAAI 1992, San Jose, pp. 344–349.
PDF: https://cdn.aaai.org/AAAI/1992/AAAI92-053.pdf
*Upper bounds on string probabilities for stochastic CFGs. Lower relevance.*

---

## Head-driven parsing theory

**Nederhof, Mark-Jan and Satta, Giorgio. 1994.**
"An Extended Theory of Head-Driven Parsing."
ACL 1994, Las Cruces, pp. 210–217. ACL Anthology: P94-1029. arXiv: cmp-lg/9405026.
*Extends the family of head-driven parsing algorithms. Directly relevant to understanding the H-cover algorithm family.*

**Nederhof, Mark-Jan. 1994.**
"An Optimal Tabular Parsing Algorithm."
ACL 1994, Las Cruces, pp. 117–124. ACL Anthology: P94-1017.
*O(n³) optimal tabular parsing algorithm. Establishes complexity of the tabular framework.*

---

## Bidirectional parsing: completeness and extensions

**Ritchie, Graeme. 1999.**
"Completeness Conditions for Mixed Strategy Bidirectional Parsing."
Computational Linguistics 25(4):457–486. ACL Anthology: J99-4001.
*Formal completeness conditions for bidirectional parsers. Theoretical foundation.*

**Ageno, Alicia and Rodríguez, Horacio. 2000.**
"Extending Bidirectional Chart Parsing with a Stochastic Model."
TSD 2000, LNCS 1902, Springer.
*Adds stochastic model to Satta/Stock island-driven parser. Full utterance known.*

**Ageno, Alicia. 2003.**
PhD thesis. UPC Barcelona.
PDF (gzip): https://www.cs.upc.edu/~ageno/tesis.pdf.gz
*Comprehensive island-driven parsing system. Full sentence known.*

**Kiefer, Bernd. 2005.**
"Redundancy-free Island Parsing of Word Graphs."
IJCAI 2005.
PDF: https://www.ijcai.org/Proceedings/05/Papers/1037.pdf
*Island parsing on word graphs (ASR lattices). Bounded utterance.*

---

## Robust / error-recovery parsing (programming languages)

**Cormack, Gordon V. 1989.**
"An LR Substring Parser for Noncorrecting Syntax Error Recovery."
PLDI 1989 / ACM SIGPLAN Notices 24(7).
*LR substring parser for near-LR grammars, error recovery context. No per-NT enumeration.*

**Clarke, J. and Barnard, D.T. 1993.**
"Error Handling in a Parallel LR Substring Parser."
Science of Computer Programming 21(2):87–102.
Semantic Scholar: https://www.semanticscholar.org/paper/Error-Handling-in-a-Parallel-LR-Substring-Parser-Clarke-Barnard/2aeabfa58ed0907164df7a7507fbd15504387db3
*Extends Cormack with error-handling heuristics. PL grammars.*

**de Jonge, M.; Nilsson-Nyman, E.; Kats, L.C.L.; Visser, E. 2009/2012.**
"Natural and Flexible Error Recovery for Generated Parsers."
SLE 2009, LNCS 5969. Journal version: ACM TOPLAS 34(4), 2012.
Springer: https://link.springer.com/chapter/10.1007/978-3-642-12107-4_16
*SGLR-based error recovery using substring recognition. PL grammars. No per-NT enumeration.*

**Beckmann, Tom; Rein, Patrick; Mattis, Toni; Hirschfeld, Robert. 2022.**
"Partial Parsing for Structured Editors."
SLE 2022, ACM SIGPLAN.
PDF: https://www.hpi.uni-potsdam.de/hirschfeld/publications/media/BeckmannReinMattisHirschfeld_2022_PartialParsingForStructuredEditors_AcmDL.pdf
ACM DL: https://dl.acm.org/doi/abs/10.1145/3567512.3567522
*Substring recognition for reconciling keyboard input with syntax tree in a structured editor. PL grammars. Most recent application to PL grammars in the literature. Finds one subtree, not a per-NT classification.*

---

## Island grammars (software analysis)

**Moonen, Leon. 2001.**
"Generating Robust Parsers using Island Grammars."
WCRE 2001.
*Island grammars for reverse engineering. Predefined island structures — not dynamic.*

**Afroozeh, Ali et al. 2012.**
"Island Grammar-based Parsing using GLL and Tom."
SLE 2012, LNCS 7745.
Springer: https://link.springer.com/chapter/10.1007/978-3-642-36089-3_13
*GLL + island grammars for embedding Tom language in Java/C. Predefined islands.*

---

## Adjacent / other

**Koji ma, Ryosuke and Sato, Taisuke. 2015.**
"Goal and Plan Recognition via Parse Trees Using Prefix and Infix Probability Computation."
ILP 2014/2015, Springer LNAI 9575.
Springer: https://link.springer.com/chapter/10.1007/978-3-319-23708-4_6
*Uses Nederhof/Satta 2011 infix probabilities inside PRISM to score goal hypotheses. Closest to asking "which NT most likely generates a fragment" — but over a fixed pre-declared set of goals, not all NTs.*

**Pasti, Clemente; Opedal, Andreas et al. 2026.**
"Prefix Parsing is Just Parsing."
arXiv: 2604.21191.
*Reduces prefix-constrained parsing to standard parsing via grammar transformation. Prefix only, not infix.*

**van Noord, Gertjan. 2001.**
"Robust Parsing of Word Graphs."
In: Robustness in Language and Speech Technology, Kluwer 2001, pp. 205–239.
*Extends CFG chart parsing to word graphs. Heuristic coverage maximisation. Not fragment classification.*

---

## Notes on gaps

After this search, the following are confirmed open / unaddressed in the literature:

- **Enumerate all covering NTs + characterise missing context** (missing_left / missing_right): not done anywhere.
- **Handle non-clean infixes gracefully** (produce partial candidates with gap descriptions when β ∉ L^{infix}(L(A)) for any A): not done anywhere.
- **Formalise fragment parsing as a standalone query**: not done. Osorio & Navarro 2001 is the only paper that explicitly states the per-NT enumeration problem, as a 3-page note with essentially no follow-up.
