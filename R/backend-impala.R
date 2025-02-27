#' Backend: Impala
#'
#' @description
#' See `vignette("translation-function")` and `vignette("translation-verb")` for
#' details of overall translation technology. Key differences for this backend
#' are a scattering of custom translations provided by users, mostly focussed
#' on bitwise operations.
#'
#' Use `simulate_impala()` with `lazy_frame()` to see simulated SQL without
#' converting to live access database.
#'
#' @name backend-impala
#' @aliases NULL
#' @examples
#' library(dplyr, warn.conflicts = FALSE)
#'
#' lf <- lazy_frame(a = TRUE, b = 1, c = 2, d = "z", con = simulate_impala())
#' lf %>% transmute(X = bitwNot(bitwOr(b, c)))
NULL

#' @export
#' @rdname simulate_dbi
simulate_impala <- function() simulate_dbi("Impala")

#' @export
dbplyr_edition.Impala <- function(con) {
  2L
}

#' @export
sql_translation.Impala <- function(con) {
  sql_variant(
    scalar = sql_translator(.parent = base_odbc_scalar,
      bitwNot       = sql_prefix("BITNOT", 1),
      bitwAnd       = sql_prefix("BITAND", 2),
      bitwOr        = sql_prefix("BITOR", 2),
      bitwXor       = sql_prefix("BITXOR", 2),
      bitwShiftL    = sql_prefix("SHIFTLEFT", 2),
      bitwShiftR    = sql_prefix("SHIFTRIGHT", 2),

      as.Date       = sql_cast("VARCHAR(10)"),
      ceiling       = sql_prefix("CEIL")
    ) ,
    base_odbc_agg,
    base_odbc_win
  )
}

#' @export
sql_table_analyze.Impala <- function(con, table, ...) {
  # Using COMPUTE STATS instead of ANALYZE as recommended in this article
  # https://www.cloudera.com/documentation/enterprise/5-9-x/topics/impala_compute_stats.html
  build_sql("COMPUTE STATS ", as.sql(table, con = con), con = con)
}
