# process_agenda

**File:** `lib/recognize.ml`

**Input:** `rec_table` + `agenda : (h_item * int * int) Queue.t`
**Output:** `unit` — fills the recognition table in place

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | `Queue.pop` | dequeue item `(a_h, i, j)` |
| 2 | [find_projections_from_item](find_projections_from_item.md) | project `a_h` → new items at same span `[i,j]` |
| 3 | `find_epsilon_projections` | epsilon-project `a_h` → new items at same span `[i,j]` |
| 4 | `find_left_expansions` | `a_h` is the right child (head); scan `i' = 0..i` for left sibling; combine into `[i',j]` |
| 5 | `find_right_expansions` | `a_h` is the left child (head); scan `j' = j..n` for right sibling; combine into `[i,j']` |
| 6 | `find_right_expansions_by_right` | `a_h` is the right sibling; find matching left head already in table; combine into `[i',j]` |
| 7 | `find_left_expansions_by_left` | `a_h` is the left sibling; find matching right head already in table; combine into `[i,j']` |
| — | `add_item` → `Queue.add` | each new item is added to the table and enqueued if new; ↩ 1 |
