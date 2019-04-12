
#' DWH Google sheets connection
#'
#' This function loads a token from Google to connect to Google drive,
#' to read/write spreadsheets with package `googlesheets`
#'
#' @param google_token The token used to connect to google's api, a JSON file has to be indicated in this parameter
#'
#' @examples
#'
#' library(googlesheets)
#' dwh_gsheets()
#' x = gs_key('<YOUR-GSHEET-KEY>')
#'
#' sheets = gs_ws_ls(x)
#' sheet = gs_read(x, ws='mytab')
#'
#' @importFrom jsonlite fromJSON
#' @importFrom googlesheets gs_auth
#' @importFrom httr oauth_service_token oauth_endpoints
#' @export
dwh_gsheets <- function(google_token="~/.dwh_google_token.json"){
  token <- oauth_service_token(
    oauth_endpoints("google"),
    jsonlite::fromJSON(google_token),
    paste(c("https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/drive"),
                                  collapse = " ")
  )
  gs_auth(token=token, cache=F)
}
