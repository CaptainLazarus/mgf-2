# recognize_with

**File:** `lib/recognize.ml`

**Input:** `prepared_grammar` (precompiled H-cover) + `string list` (tokens)
**Output:** `rec_table` (filled recognition table)

## Pipeline

| Step | Prereq | Function | Goto | Notes |
|------|--------|----------|------|-------|
| 1 | | `seed_table_with_epsilons` | | epsilon seeds — CompleteItem into every T[i,i] |
| 2 | | `seed_non_terminals_that_produce_terminal_productions` | | terminal seeds into T[i-1,i] |
| 3a | n > 0 | `seed_table_with_left_boundary_items` | | boundary seeds into T[0,1] |
| 3b | n > 0 | `seed_table_with_right_boundary_items` | | boundary seeds into T[n-1,n] |
| 4 | | [process_agenda](process_agenda.md) | | main agenda loop |
| 5 | | `find_right_expansions_by_right` → [add_item](add_item.md) | 4 | L-Reduce: for k = 1 to n |
| 6 | T[0,n] empty | `find_right_expansions` → [add_item](add_item.md) | 4 | R-Reduce: for k = n-1 downto 0 |
| 7 | | `find_right_expansions` → [add_item](add_item.md) | 4 | final R pass on T[0,n] items |
| 8 | | `find_right_expansions_by_right` → [add_item](add_item.md) | 4 | final L pass on T[0,n] items |
