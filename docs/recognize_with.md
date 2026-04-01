# recognize_with

**File:** `lib/recognize.ml`

**Input:** `prepared_grammar` (precompiled H-cover) + `string list` (tokens)
**Output:** `rec_table` (filled recognition table)

## Pipeline

| Step | Function | Goto | Notes |
|------|----------|------|-------|
| 1 | `add_item` | | epsilon seeds — CompleteItem into every T[i,i] |
| 2 | `find_projections_from_terminal` → `add_item` | | terminal seeds into T[i-1,i] |
| 3 | `add_item` | | boundary seeds into T[0,1] and T[n-1,n] |
| 4 | `process_agenda` | | main agenda loop |
| 5 | `find_right_expansions_by_right` → `add_item` | 4 | L-Reduce: for k = 1 to n |
| 6 | `find_right_expansions` → `add_item` | 4 | R-Reduce: for k = n-1 downto 0, only if T[0,n] empty |
| 7 | `find_right_expansions` → `add_item` | 4 | final R pass on T[0,n] items |
| 8 | `find_right_expansions_by_right` → `add_item` | 4 | final L pass on T[0,n] items |
