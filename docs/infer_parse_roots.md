# infer_parse_roots

**File:** `lib/query.ml`

**Input:** `rec_table`
**Output:** `root_candidate list` — each candidate has `root` (NT name), `missing_left`, `missing_right` (grammar symbols)

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | `get_all_items tbl 0 n` | `tbl.entries.(0).(n).items` — direct array lookup, returns `(h_item * derivation list) list` |
| 2 | direct pass over T[0,n] | `CompleteItem nt` → root=nt, nothing missing; `PartialItem (r,s,t)` → root=prod.lhs, missing = symbols before s and after t in RHS |
| 3 | inferred pass | for each `CompleteItem nt` in T[0,n], find productions where nt appears in RHS → report prod.lhs with remaining RHS symbols as missing |
| 4 | `List.sort_uniq compare` | deduplicate candidates |
