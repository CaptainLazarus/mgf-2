# Notes

Observations and potential improvements noted during exploration.

## process_agenda — rev_right / rev_left may be redundant

`rev_right` and `rev_left` in `process_agenda` fire when the sibling arrives in the agenda, scanning for the head already in the table. But every `add_item` call is followed by `Queue.add`, so the head will always be enqueued and the forward lookups (`find_right_expansions`, `find_left_expansions`) will eventually cover the same combination. Unclear why the reverse lookups are needed — open question.

## process_agenda — projection and epsilon-projection blocks could be combined

Steps 2 and 3 in `process_agenda` are identical in structure — both filter `cover.projections` and call `add_item` at the same span. Could merge into a single `find_all_projections` returning `(h_item * derivation) list`, then one `List.iter`. Derivation tags (`FromProject` vs `FromEpsilon`) would need to be carried in the result tuple.

## Boundary seeding — precompute which rules fire per terminal

Which right/left expansion rules fire at T[0,1] and T[n-1,n] is determined entirely by the grammar, not the input. Could precompute a map from terminal → matching expansion rules at `prepare` time, avoiding a full scan of `right_expansions` and `left_expansions` on every recognition call.

## block_left / block_right — blocked lists stored as list, not set

`blocked_left` and `blocked_right` in `table_entry` are lists with manual duplicate checks in `block_left`/`block_right`. Same issue as `add_item` — could be sets for O(log n) membership instead of O(n) scan.

## add_item — derivations stored as list, not set

`entry.items` stores derivations as a `list`, using `List.mem` to check for duplicates.
Could be a `Set` for O(log n) membership instead of O(n).
