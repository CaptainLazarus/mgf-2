# find_projections_from_terminal

**File:** `lib/hcover.ml`

**Input:** `h_cover` + `string` (a terminal token)
**Output:** `h_item list` — all H-cover items that project from that terminal

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | `List.filter_map` | keep projections whose rhs is a terminal matching `term`; return their `lhs` |
