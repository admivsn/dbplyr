sql_select_clauses <- function(con,
                               select,
                               from,
                               where,
                               group_by,
                               having,
                               order_by,
                               limit = NULL,
                               lvl) {
  out <- list(
    select = select,
    from = from,
    where = where,
    group_by = group_by,
    having = having,
    order_by = order_by,
    limit = limit
  )
  sql_format_clauses(out, lvl, con)
}

sql_clause <- function(kw, parts, sep = ",", parens = FALSE, lvl = 0) {
  clause <- list(
    kw = kw,
    parts = parts,
    sep = sep,
    parens = parens,
    lvl = lvl
  )

  class(clause) <- "sql_clause"
  clause
}

sql_clause_select <- function(con, select, distinct = FALSE, top = NULL, lvl = 0) {
  assert_that(is.character(select))
  if (is_empty(select)) {
    abort("Query contains no columns")
  }

  clause <- build_sql(
    "SELECT",
    if (distinct) sql(" DISTINCT"),
    if (!is.null(top)) build_sql(" TOP ", as.integer(top), con = con),
    con = con
  )

  sql_clause(clause, select)
}

sql_clause_from  <- function(from, lvl = 0) {
  sql_clause("FROM", from, lvl = lvl)
}

sql_clause_where <- function(where, lvl = 0) {
  if (length(where) == 0L) {
    return()
  }

  assert_that(is.character(where))
  where_paren <- sql(paste0("(", where, ")"))
  sql_clause("WHERE", where_paren, sep = " AND", lvl = lvl)
}

sql_clause_group_by <- function(group_by, lvl = 0) {
  sql_clause("GROUP BY", group_by)
}

sql_clause_having <- function(having, lvl = 0) {
  sql_clause("HAVING", having)
}

sql_clause_order_by <- function(order_by, subquery = FALSE, limit = NULL, lvl = 0) {
  if (subquery && length(order_by) > 0 && is.null(limit)) {
    warn_drop_order_by()
    NULL
  } else {
    sql_clause("ORDER BY", order_by)
  }
}

sql_clause_limit <- function(con, limit, lvl = 0){
  if (!is.null(limit) && !identical(limit, Inf)) {
    sql_clause("LIMIT", sql(format(limit, scientific = FALSE)))
  }
}

# helpers -----------------------------------------------------------------

sql_format_clauses <- function(clauses, lvl, con) {
  clauses <- unname(clauses)
  clauses <- purrr::discard(clauses, ~ !is.sql(.x) && is_empty(.x$parts))

  formatted_clauses <- purrr::map(clauses, sql_format_clause, lvl = lvl, con = con)
  clause_level <- purrr::map_dbl(clauses, "lvl", .default = 0)
  out <- indent_lvl(formatted_clauses, lvl + clause_level)

  sql_vector(out, collapse = "\n", parens = FALSE, con = con)
}

sql_format_clause <- function(x, lvl, con, nchar_max = 80) {
  if (is.sql(x)) {
    return(x)
  }

  lvl <- lvl + x$lvl

  # check length without starting a new line
  fields_same_line <- escape(x$parts, collapse = paste0(x$sep, " "), con = con)
  if (x$parens) {
    fields_same_line <- paste0("(", fields_same_line, ")")
  }
  same_line_clause <- paste0(x$kw, " ", fields_same_line)
  nchar_same_line <- nchar(lvl_indent(lvl)) + nchar(same_line_clause)

  if (length(x$parts) == 1 || nchar_same_line <= nchar_max) {
    return(sql(same_line_clause))
  }

  indent <- lvl_indent(lvl + 1)
  collapse <- paste0(x$sep, "\n", indent)

  field_string <- paste0(
    x$kw, if (x$parens) " (", "\n",
    indent, escape(x$parts, collapse = collapse, con = con),
    if (x$parens) paste0("\n", indent_lvl(")", lvl))
  )

  sql(field_string)
}

lvl_indent <- function(times, char = "  ") {
  strrep(char, times)
}

indent_lvl <- function(x, lvl) {
  sql(paste0(lvl_indent(lvl), x))
}
