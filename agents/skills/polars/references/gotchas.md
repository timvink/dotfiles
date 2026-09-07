# Polars gotchas

Each of these fails silently or with a confusing error. Verified on
Polars 1.x.

- **Strings in `then()`/`otherwise()` are column names, not values.**
  `pl.when(c).then("adult")` reads a column called `adult` (or raises
  `ColumnNotFoundError`). Wrap literals: `.then(pl.lit("adult"))`.
- **Null comparisons drop rows silently.** `filter(pl.col("v") > 2)`
  excludes nulls because `null > 2` is null, which is falsy. If nulls
  should be kept: `(pl.col("v") > 2) | pl.col("v").is_null()`.
- **Use `&`, `|`, `~` with parentheses around each condition.** Python's
  `and`/`or`/`not` raise on expressions, and without parentheses operator
  precedence binds the comparison wrong:
  `(pl.col("a") > 1) & (pl.col("b") < 5)`.
- **A bare aggregation in `with_columns()` broadcasts the global value
  to every row.** `with_columns(pl.col("v").mean())` fills the column
  with the overall mean — it does not error. For the per-group value
  aligned to each row, add `.over("group")`:
  `pl.col("v").mean().over("group")`.
- **Duplicate output names raise `DuplicateError`.** A computed column
  keeps its source name; `select(pl.col("p"), pl.col("p") * 1.1)` fails.
  Always `.alias()` derived columns.
- **Nulls don't match in joins by default.** Rows with null keys silently
  drop out of inner joins. Pass `nulls_equal=True` to `join()` if null
  keys should match each other.
- **pandas names don't transfer.** No index, no `iloc`, no `groupby`.
  Verify uncertain methods against the installed version or official docs instead of
  assuming the pandas spelling exists.

