
#' @importFrom ini read.ini
dwh_load_credentials = function(credentials_file){
  creds = read.ini(credentials_file)

  creds$dwh
}

#' Connect to DWH
#'
#' Use credentials provided in ini file to connect to DWH, and return the connection pointer
#'
#' @param credentials_file The file where the host, database, user, password and port are
#' @param sslmode Type of SSL requirement to send to PGSQL's client, Auth0's DWH will only accept SSL connections
#' @param bigint The R type that 64-bit integer types should be mapped to, default is numeric (float), which modifies very big numbers, in some scenarios we may need to switch to integer64 to capture it accurately. The possible options are numeric, integer, character and integer64
#'
#' @examples
#'
#' con = dwh_connect()
#' tenants = tbl(con, 'tenants')
#'
#' @import RPostgres
#' @export
dwh_connect = function(credentials_file='~/.dwh_credentials', sslmode='require', bigint='numeric'){
  credentials = dwh_load_credentials(credentials_file)
  con = dbConnect(
    Postgres(),
    dbname=credentials$database,
    host=credentials$host,
    port=credentials$port,
    user=credentials$username,
    password=credentials$password,
    sslmode=sslmode,
    bigint=bigint
  )

  con
}

#' Disconnect from DWH
#'
#' Close a DWH connection
#'
#' @param con The connection to close
#'
#' @examples
#'
#' con = dwh_connect()
#' dwh_disconnect(con)
#'
#' @export
dwh_disconnect = function(con){
  dbDisconnect(con)
}

#' @importFrom DBI dbExecute
dwh_statement_resolve = function(con, q){
  dbExecute(con, q)
}

#' Set execution slots
#'
#' To add processing power to queries, you can add query slots in a specific session, take into account this will slow other queries running in the system so it has to be done very sparingly for critical time-sensitive queries in the critical path. Read more at https://docs.aws.amazon.com/redshift/latest/dg/c_workload_mngmt_classification.html
#'
#' @param con The connection to set slots on
#' @param slots The number of slots to use
#'
#' @examples
#'
#' con = dwh_connect()
#' dwh_set_execution_slots(con, 2)
#'
#' @export
dwh_set_execution_slots = function(con, slots){
    #Use more than one slot
    if(slots>1){
      dwh_statement_resolve(con,paste0("set wlm_query_slot_count to ", slots));
    }
}


#' DWH Query
#'
#' Run specified SQL query in Datawarehouse and return result, allows for specifiying slots and binding values.
#'
#' @param query The query text to execute in Amazon Redshift
#' @param pcon The connection to run the query on, if unspecified, a temporary connection will be created and closed while running the query
#' @param slots The number of slots to run the query on, by default 1
#' @param bindValues List of values to bind to the query
#'
#' @examples
#'
#' a=dwh_query('select 1', slots=2)
#' b=dwh_query('select ?, ?', bindValues=c(1,2))
#'
#' @export
dwh_query = function(query, pcon=NULL, slots=1, bindValues=NULL){

  #Connect
  message("Establishing connection to Redshift...")
  if(is.null(pcon)){
    con <- dwh_connect()
  }else{
    con = pcon
  }


  # Use more resources if asked for
  dwh_set_execution_slots(con, slots)

  #Time it
  ptm <- proc.time()

  #Send query
  message("Running query ", substr(query, 0, 1500), "...", sep='')
  pointer = dbSendQuery(con, query)
  if(!is.null(bindValues)){
    dbBind(pointer, bindValues)
  }
  result = dbFetch(pointer)
  dbClearResult(pointer)

  #Time spent
  message(cat('Elapsed time: ',(proc.time() - ptm)[3], 's', sep=''))

  #Close connection
  if(is.null(pcon)){
    dwh_disconnect(con)
  }

  result
}


#' DWH Statement
#'
#' Run statement in the Datawarehouse, without expecting a result, this is useful for DDL operations (create, update, insert, delete, etc)
#'
#' @param statement The statement text to execute in Amazon Redshift
#' @param pcon The connection to run the query on, if unspecified, a temporary connection will be created and closed while running the query
#' @param slots The number of slots to run the statement on, by default 1
#' @param bindValues List of values to bind to the statement
#'
#' @examples
#'
#' a=dwh_query('create temp table mytable as select 1', slots=2)
#' b=dwh_query('create temp table mytable as select ?, ?', slots=2, bindValues=c(1,2))
#'
#' @export
dwh_statement = function(statement, pcon=NULL, slots=1, bindValues=NULL){

  #Connect
  message("Establishing connection to Redshift...")
  if(is.null(pcon)){
    con <- dwh_connect()
  }else{
    con = pcon
  }

  # Use more resources if asked for
  dwh_set_execution_slots(con, slots)

  #Time it
  ptm <- proc.time()

  #Send query
  message("Running statement ", substr(statement, 0, 1500), "...", sep='')
  if(!is.null(bindValues)){
    result = dbExecute(con, statement, params=bindValues)
  }else{
    result = dbExecute(con, statement)
  }

  #Time spent
  message(cat('Elapsed time: ',(proc.time() - ptm)[3], 's', sep=''))

  #Close connection
  if(is.null(pcon)){
    dwh_disconnect(con)
  }

  result
}
