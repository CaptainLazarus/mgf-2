# find_projections_from_item

**File:** `lib/hcover.ml`

**Input:** `h_cover` + `item : h_item`
**Output:** `h_item list` — all H-cover items that `item` can project into

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | `List.filter_map` | keep projections whose rhs is `HItem item`; return their `lhs` |

## Notes

Mirror of [find_projections_from_terminal](find_projections_from_terminal.md) — same logic, but source is an `h_item` instead of a terminal string.
