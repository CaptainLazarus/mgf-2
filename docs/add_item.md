# add_item

**File:** `lib/table.ml`

**Input:** `rec_table` + `i j : int` (cell indices) + `item : h_item` + `deriv : derivation`
**Output:** `bool` — `true` if item was new to `T[i,j]`, `false` if it already existed

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| 1 | `List.find_opt` | check if `item` already exists in `T[i,j]` |
| 2a | `List.mem` | if item exists: check if `deriv` is already recorded |
| 2b | `List.map` | if deriv is new: prepend it to the item's derivation list; return `false` |
| 3 | mutate `entry.items` | if item is new: add `(item, [deriv])`; return `true` |
