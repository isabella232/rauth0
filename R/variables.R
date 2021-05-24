#' Login types
#'
#' Types of events which count as active users for usage consumption, as a vector
#'
#' @export
CONST_LOGIN_TYPES=c('s', 'sepft', 'ssa', 'seoobft', 'seotpft', 'sercft', 'sertft', 'seacft', 'scoa', 'sens', 'sede')

#' Login types (string)
#'
#' Types of events which count as active users for usage consumption, as a string
#'
#' @export
CONST_LOGIN_TYPES_STR=paste0("('", paste(CONST_LOGIN_TYPES, collapse="', '"), "')")

#' Social Connections
#'
#' Connections from social sources (Apple, Google, etc)
#'
#' @export
CONST_SOCIAL_CONNECTIONS=c(
  'amazon', 'apple', 'aol', 'baidu', 'bitbucket', 'box', 'dropbox', 'dwolla', 'ebay',
  'exact', 'facebook', 'fitbit', 'github', 'google-openid', 'google-oauth2',
  'instagram', 'linkedin', 'miicard', 'oidc', 'paypal', 'paypal-sandbox',
  'planningcenter', 'renren', 'salesforce', 'salesforce-community',
  'salesforce-sandbox', 'evernote', 'evernote-sandbox', 'shopify', 'soundcloud',
  'thecity', 'thecity-sandbox', 'thirtysevensignals', 'twitter', 'vkontakte',
  'windowslive', 'wordpress', 'yahoo', 'yammer', 'yandex', 'weibo', 'line',
  'oauth2', 'oauth1', 'custom' ## TODO: confirm if this line counts as social
)

#' Social Connections (string)
#'
#' Connections from social sources (Apple, Google, etc), as a string
#'
#' @export
CONST_SOCIAL_CONNECTIONS_STR=paste0("('", paste(CONST_SOCIAL_CONNECTIONS, collapse="', '"), "')")


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
