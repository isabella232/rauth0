#' Login types
#'
#' Types of events which count as active users for usage consumption, as a vector
#'
#' @export
CONST_LOGIN_TYPES=c('s', 'sepft', 'ssa', 'seoobft', 'seotpft', 'sercft', 'sertft', 'seacft', 'scoa')

#' Login types (string)
#'
#' Types of events which count as active users for usage consumption, as a string
#'
#' @export
CONST_LOGIN_TYPES_STR=paste0("('", paste(CONST_LOGIN_TYPES, collapse="', '"), "')")



#' SCD Start date
#'
#' Default time for blank values on SCDs with dates
#'
#' @export
SCD_START_DATE=as.Date('2010-01-01')


#' SCD Future date
#'
#' Default time for future values on SCDs with dates
#'
#' @export
SCD_FUTURE_DATE=as.Date('9999-12-31')
