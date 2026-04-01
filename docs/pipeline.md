# Top-Level Pipeline

**Entry point:** `bin/main.ml`

**Input:** `grammars/cparser.g4` (grammar file) + `grammars/stdin.c` (C fragment)
**Output:** recognition table + root candidates printed to stdout

| Step | Function | Notes |
|------|----------|-------|
| 1 | `Grammar_reader.extract_grammar` | reads .g4 file |
| 2 | `Grammar_converter.convert_grammar` | converts to internal grammar type |
| 3 | `Recognize.prepare` | compiles grammar → H-cover |
| 4 | `Io.tokens_from_java` | tokenizes stdin.c via Java CLexer |
| 5 | `Recognize.`[recognize_with](recognize_with.md) | runs the parser → rec_table |
| 6 | `Htable.show` | prints table + roots |
| 7 | `Query.infer_parse_roots` | infers what the fragment is |
| — | ~~`Output.print_results`~~ | reconstruct + print trees (disabled) |
