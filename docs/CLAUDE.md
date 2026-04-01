# Docs conventions

## Format for every page

```
# function_name

**File:** `lib/filename.ml`

**Input:** ...
**Output:** ...

## Pipeline

| Step | Function | Notes |
|------|----------|-------|
| ...  | ...      | ...   |
```

## Rules

1. **Pipeline is always a table.** For loops or repeated steps, use `↩ step N` in the Notes column to indicate where control returns.

2. **Always prefix function names with their module** (e.g. `Recognize.recognize_with`, `Query.infer_parse_roots`), unless all functions on the page are from the same module — then the module is stated once at the top and omitted in the table. If unsure which module a function belongs to, check the source before writing.

3. **Only link functions that have been explored.** A function is explored when it has its own page with input, output, and pipeline filled in. Unexplored functions appear as inline code only: `function_name`.

4. **Same format everywhere.** Every page has: File, Input, Output, Pipeline table. No exceptions.

5. **No stub pages.** Don't create a page for a function until we've actually explored it.
