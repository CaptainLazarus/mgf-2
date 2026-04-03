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

1. **Pipeline is always a table.** For loops or repeated steps, use `↩ step N` in the Notes column to indicate where control returns. Anonymous functions are not listed as separate steps — fold their logic into the Notes of the enclosing function call.

2. **Always prefix function names with their module** (e.g. `Recognize.recognize_with`, `Query.infer_parse_roots`), unless all functions on the page are from the same module — then the module is stated once at the top and omitted in the table. If unsure which module a function belongs to, check the source before writing.

3. **Only link functions that have been explored.** A function is explored when we know its input and output — it doesn't require reading the code. A function with a known IO gets its own page and a link. Functions whose IO is unknown appear as inline code only: `function_name`. As we walk a pipeline and discover IO, add the page and the link.

4. **Same format everywhere.** Every page has: File, Input, Output, Pipeline table. No exceptions.

5. **No stub pages.** Don't create a page for a function until we've actually explored it.
