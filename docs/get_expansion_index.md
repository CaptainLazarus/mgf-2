# get_expansion_index

**File:** `lib/hcover.ml`

**Input:** `h_item`
**Output:** `(int * int * int)` — `(r, s, t)` production index and boundaries

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | pattern match | `PartialItem (r, s, t)` → return `(r, s, t)`; `CompleteItem` → return `(-1, -1, -1)` |

## Notes

`r` = production index, `s` and `t` = left/right boundary positions within the production.
Used by blocking checks in `process_agenda` — `(-1,-1,-1)` for `CompleteItem` means blocking is never triggered on complete items.
