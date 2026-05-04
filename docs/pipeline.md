# Top-Level Pipeline

**Entry point:** `bin/main.ml`

**Input:** `grammars/cparser.g4` (grammar file) + `grammars/stdin.c` (C fragment)
**Output:** recognition table + root candidates printed to stdout

| Step | Function | Notes |
|------|----------|-------|
| 1 | `Grammar_reader.extract_grammar` | reads .g4 file (skipped for inline grammars) |
| 2 | `Grammar_converter.convert_grammar` | converts to internal grammar type (skipped for inline) |
| 3 | `Recognize.prepare` | compiles grammar → H-cover |
| 4 | `Recognize.`[recognize_with](recognize_with.md) | runs the parser → rec_table |
| 5 | `Query.count_table_items` | prints item count to stdout |
| 6 | `Htable.show` | prints table + roots (flags: `~roots:true ~cover:true ~table:true`) |
| 7 | `Query.`[infer_parse_roots](infer_parse_roots.md) | infers what the fragment is |
| 8 | `Output.print_results` | reconstruct + print trees |
