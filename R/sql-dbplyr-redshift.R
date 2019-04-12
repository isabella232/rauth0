#' SQL Semi join to replace dbplyr's one
#'
#' @param con PGSQL Connection
#' @param x Left table
#' @param y Right table
#' @param anti Anti join?
#' @param by By which variable/s
#' @param ... Other params to pass to underlying methods
#' @export
#' importFrom DBI dbQuoteIdentifier
#' importFrom dbplyr sql sql_vector ident build_sql escape
sql_semi_join.PqConnection <- function(con, x, y, anti = FALSE, by = NULL, ...) {
  # X and Y are subqueries named TBL_LEFT and TBL_RIGHT
  on <- sql_join_tbls(con, by)
  left <- dbplyr::escape(ident("TBL_LEFT"), con = con)
	right <- dbplyr::escape(ident("TBL_RIGHT"), con = con)
	checks <- dbplyr::sql_vector(
    paste0(
      right, ".", sql_escape_ident(con, by$y), if(anti) sql(' IS NULL') else sql(' IS NOT NULL')
    ),
    collapse = " AND ",
    parens = TRUE,
    con = con
  )

	build_sql(
    "SELECT ", left, ".*\n",
    "  FROM ", x, "\n",
    "  LEFT JOIN ", y, "\n",
    build_sql("  ON ", on, "\n"),
		" WHERE ", checks, "\n",
    con = con
  )
}

sql_escape_ident.DBIConnection <- function(con, x) {
  dbQuoteIdentifier(con, x)
}

sql_table_prefix <- function(con, var, table = NULL) {
  var <- sql_escape_ident(con, var)

  if (!is.null(table)) {
    table <- sql_escape_ident(con, table)
    sql(paste0(table, ".", var))
  } else {
    var
  }

}

sql_join_tbls <- function(con, by) {
  on <- NULL
  if (length(by$x) + length(by$y) > 0) {
    on <- dbplyr::sql_vector(
      paste0(
        sql_table_prefix(con, by$x, "TBL_LEFT"),
        " = ",
        sql_table_prefix(con, by$y, "TBL_RIGHT")
      ),
      collapse = " AND ",
      parens = TRUE
    )
  }

  on
}

