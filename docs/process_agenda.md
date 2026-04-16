# process_agenda

**File:** `lib/recognize.ml`

**Input:** `rec_table` + `agenda : (h_item * int * int) Queue.t`
**Output:** `unit` — fills the recognition table in place

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | `Queue.pop` | dequeue item `(a_h, i, j)` |
| 2 | [find_projections_from_item](find_projections_from_item.md) | project `a_h` → new items at same span `[i,j]`; deriv = `FromProject a_h` |
| 3 | `find_epsilon_projections` | epsilon-project `a_h` → new items at same span `[i,j]`; deriv = `FromEpsilon a_h` |
| 4 | `find_left_expansions` | `a_h` is the head (right child) in rule `B → X · a_h`; scan `i' = 0..i` for `X` in `T[i',i]`; Q-set blocking applies; combine → `B` in `T[i',j]`; deriv = `FromLeftExpand` |
| 5 | `find_right_expansions` | `a_h` is the head (left child) in rule `B → a_h · Y`; scan `j' = j..n` for `Y` in `T[j,j']`; Q-set blocking applies; combine → `B` in `T[i,j']`; deriv = `FromRightExpand` |
| 6 | `find_right_expansions_by_right` | `a_h` arrived as the right sibling in rule `B → leftHead · a_h`; scan `i' = 0..i` for `leftHead` in `T[i',i]`; no blocking; combine → `B` in `T[i',j]`; fires when sibling arrives after head was already processed |
| 7 | `find_left_expansions_by_left` | `a_h` arrived as the left sibling in rule `B → a_h · rightHead`; scan `j' = j..n` for `rightHead` in `T[j,j']`; no blocking; combine → `B` in `T[i,j']`; fires when sibling arrives after head was already processed |
| — | `add_item` → `Queue.add` | each new item is added to the table and enqueued if not already present; ↩ 1 |

## Notes

- Steps 4–7 all scan an entire row or column because the grammar does not constrain the sibling's span width — only the shared boundary is known. Exception: terminal siblings check one exact position, no scan needed.
- Steps 4–5 (head-driven) apply Q-set subsumption blocking. Steps 6–7 (sibling-driven) do not — the blocking decision was already made when the head was originally processed.
- Steps 6–7 exist because the agenda fires items in arbitrary order, not diagonal-by-diagonal. A head can scan for its sibling before the sibling exists; when the sibling arrives later, steps 6–7 catch the missed combination.
- Optional `~debug:true` flag logs each dequeue and every new item added, annotated with which step fired it.
