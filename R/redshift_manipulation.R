

#' Upsert DWH Table
#'
#' Upsert (Update/Insert) data using data.frame and provided keys. If an existing row matches the key in the data frame sent, it'll be deleted before the insert. Afterwards, the insert will be executed, this is considered an update in this context, this is the fastest way to do upserts with Amazon Redshift.
#'
#' @param df The data.frame with the data to insert, tibbles are also supported.
#' @param table_name The name of the table in Amazon Redshift
#' @param keys Vector with all keys to join by to do the update part of the upsert
#' @param split_num The number of files to split the data.frame into, it should be a multiple of the slices in the DWH, you can check the current number consulting stv_slices https://docs.aws.amazon.com/redshift/latest/dg/r_STV_SLICES.html
#' @param bucket The S3 bucket on which to dump the data before sending to Amazon Redshift
#' @param region The region where the bucket resides
#' @param iam_role_arn The role that is set in Amazon Redshift to access the S3 bucket (You only need this or the access/secret keys)
#' @param pcon Optionally, use an existing connection, if not, will start a temporary connection to use
#'
#' @examples
#'
#' a=data.frame(column_a=c(1,2,3), column_b=c('a','b','c'), column_c=c('x','y','z'))
#' dwh_table_upsert(a, 'test_table', c('column_a','column_b'))
#'
#' @importFrom redshiftTools rs_upsert_table
#' @export
dwh_table_upsert = function(df, table_name, keys, split_num, bucket=Sys.getenv("STAGINGBUCKET_NAME"), region=Sys.getenv("STAGINGBUCKET_REGION"), iam_role_arn=Sys.getenv('REDSHIFT_IAM_ROLE'),  pcon=NULL) {

  #If connection not provided, start a temporary connection
  if(is.null(pcon)){
    con = dwh_connect()
  }else{
    con = pcon
  }

  res = rs_upsert_table(df,
            dbcon=con,
            table_name = table_name,
            bucket=bucket,
            region=region,
            keys=keys,
            iam_role_arn = iam_role_arn,
            split_files=split_num)

  #Close temporary connection
  if(is.null(pcon)){
    dwh_disconnect(con)
  }

  if(res==TRUE){
    res
  }else{
    stop("Error loading data with redshiftTools")
  }
}

#' Replace DWH Table
#'
#' Replace data using data.frame. The existing data in the table will be deleted and the rows will be inserted
#'
#' @param df The data.frame with the data to insert, tibbles are also supported.
#' @param table_name The name of the table in Amazon Redshift
#' @param split_num The number of files to split the data.frame into, it should be a multiple of the slices in the DWH, you can check the current number consulting stv_slices https://docs.aws.amazon.com/redshift/latest/dg/r_STV_SLICES.html
#' @param bucket The S3 bucket on which to dump the data before sending to Amazon Redshift
#' @param region The region where the bucket resides
#' @param iam_role_arn The role that is set in Amazon Redshift to access the S3 bucket (You only need this or the access/secret keys)
#' @param pcon Optionally, use an existing connection, if not, will start a temporary connection to use
#'
#' @examples
#'
#' a=data.frame(column_a=c(1,2,3), column_b=c('a','b','c'), column_c=c('x','y','z'))
#' dwh_table_replace(a, 'test_table')
#'
#' @importFrom redshiftTools rs_replace_table
#' @export
dwh_table_replace = function(df, table_name, split_num, bucket=Sys.getenv("STAGINGBUCKET_NAME"), region=Sys.getenv("STAGINGBUCKET_REGION"), iam_role_arn=Sys.getenv('REDSHIFT_IAM_ROLE'),  pcon=NULL) {
  #If connection not provided, start a temporary connection
  if(is.null(pcon)){
    con = dwh_connect()
  }else{
    con = pcon
  }

  res = rs_replace_table(df,
            dbcon=con,
            table_name = table_name,
            bucket=bucket,
            region=region,
            iam_role_arn = iam_role_arn,
            split_files=split_num)

  #Close temporary connection
  if(is.null(pcon)){
    dwh_disconnect(con)
  }

  if(res==TRUE){
    res
  }else{
    stop("Error loading data with redshiftTools")
  }

}

#' Replace DWH Table from SQL
#'
#' Replace data using an SQL query. The existing table will be dropped if it exists.
#'
#' @param table_name The name of the table in Amazon Redshift
#' @param query The query to execute to create the table in Amazon Redshift
#' @param group_read The group that will have read access to the table
#' @param group_all The group that will have all access to the table
#' @param slots The number of slots to use
#' @param pcon Optionally, use an existing connection, if not, will start a temporary connection to use
#'
#' @examples
#'
#' dwh_replace_table_from_sql('test_table', 'select 1')
#'
#' @importFrom dbplyr build_sql
#' @export
dwh_replace_table_from_sql = function(table_name, query, group_read='DWH_READ', group_all='DWH', slots=1,  pcon=NULL){
  #If connection not provided, start a temporary connection
  if(is.null(pcon)){
    con = dwh_connect()
  }else{
    con = pcon
  }

  # Use more resources if asked for
  dwh_set_execution_slots(con, slots)

  # Begin stransaction
  dbBegin(con)

  # Create table with random name
  randomTable = randomName()
  print(paste0("Creating table ", randomTable, collapse=""))
  t <- build_sql("CREATE TABLE  ",
   ident(randomTable), " AS ", sql(query), con=con)
  dwh_statement_resolve(con, t)

  # Drop original table
  print(paste0("Dropping original table ", table_name, collapse=""))
  dwh_statement_resolve(con, paste0('drop table if exists ', table_name, collapse=""))

  # Rename temporary table to take place of original table
  print(paste0("Renaming ", randomTable, " to ", table_name, collapse=""))
  dwh_statement_resolve(con, paste0('alter table ', randomTable,' rename to ', table_name,collapse=""))

  # Grant permissions to read/write groups
  print(paste0("Granting permissions", collapse=""))
  if(!is.null(group_read)){
    dwh_statement_resolve(con, paste0('grant select on ', table_name ,' to group ', group_read))
  }
  if(!is.null(group_read)){
    dwh_statement_resolve(con, paste0('grant all on  ', table_name ,' to group ', group_all))
  }


  # Commit
  print(paste0("Table replacement done!", collapse=""))
  dbCommit(con)

  #Close temporary connection
  if(is.null(pcon)){
    dwh_disconnect(con)
  }
}


#' Replace DWH Table from temporary table
#'
#' Replace data using another temporary table. The existing table will be truncated.
#'
#' @param con Connection where to use the temporary table
#' @param table_name The name of the table in Amazon Redshift to copy into
#' @param temp_table The name of the temporary table in Amazon Redshift
#' @param slots The number of slots to use
#' @param transaction Use begin/commit commands, by default yes
#'
#' @examples
#'
#' con = dwh_connect()
#' # [...] generate temp table
#' dwh_replace_table_from_temp_table(con, 'test_table', 'temp_table')
#'
#' @importFrom dbplyr build_sql
#' @export
dwh_replace_table_from_temp_table = function(con, table_name, temp_table, slots=1, transaction=T){
  # Use more resources if asked for
  dwh_set_execution_slots(con, slots)


  # Begin transaction
  if(transaction==T){dbBegin(con)}

  # Delete all original rows
  print(paste0("Deleting rows from original table ", table_name, collapse=""))
  dwh_statement_resolve(con, paste0('delete from ', table_name, collapse=""))

  # Insert rows from temporary table
  print(paste0("Inserting rows from temp table ", temp_table, collapse=""))
  dwh_statement_resolve(con, paste0('insert into ', table_name, ' select * from ', temp_table, collapse=""))

  # Commit
  print(paste0("Rows replacement from temp table done!", collapse=""))
  if(transaction==T){dbCommit(con)}
}

#' Upsert DWH Table from temporary table
#'
#' Upsert data using another temporary table.
#'
#' @param con Connection where to use the temporary table
#' @param table_name The name of the table in Amazon Redshift to copy into
#' @param temp_table The name of the temporary table in Amazon Redshift
#' @param keys The keys to upsert
#' @param slots The number of slots to use
#'
#' @examples
#'
#' con = dwh_connect()
#' # [...] generate temp table
#' dwh_upsert_table_from_temp_table(con, 'test_table', 'temp_table', c('id', 'id2'))
#'
#' @importFrom dbplyr build_sql
#' @export
dwh_upsert_table_from_temp_table = function(con, table_name, temp_table, keys, slots=1){
  # Use more resources if asked for
  dwh_set_execution_slots(con, slots)


  # Begin transaction
  dbBegin(con)

  keysCond = paste(temp_table,".",keys, "=", table_name,".",keys, sep="")
  keysWhere = sub(" and $", "", paste0(keysCond, collapse="", sep=" and "))

  # Delete all original rows
  print(paste0("Deleting rows from original table ", table_name, collapse=""))
  dwh_statement_resolve(con, sprintf('delete from %s using %s where %s',
          table_name,
          temp_table,
          keysWhere))

  # Insert rows from temporary table
  print(paste0("Inserting rows from temp table ", temp_table, collapse=""))
  dwh_statement_resolve(con, paste0('insert into ', table_name, ' select * from ', temp_table, collapse=""))

  # Commit
  print(paste0("Rows replacement from temp table done!", collapse=""))
  dbCommit(con)
}

#' Replace data in Amazon Redshift table in-place
#'
#' This function replaces a table from an SQL query without dropping/creating the destination table, making it suitable for tables which may be used while the process is running, but does not allow for structure changes without altering the original table.
#'
#' @param table_name The name of the table in Amazon Redshift
#' @param query The query to execute to create the table in Amazon Redshift
#' @param slots The number of slots to use
#'
#' @examples
#'
#' dwh_replace_inplace_from_sql('test_table', 'select 1')
#'
#' @export
dwh_replace_inplace_from_sql = function(table_name, query, slots=1){
  con <- dwh_connect()

  # Use more resources if asked for
  dwh_set_execution_slots(con, slots)
  dbBegin(con)

  # Create temporary table
  randomTable = randomName()
  print(paste0("Creating temporary table ", randomTable, collapse=""))
  t <- build_sql("CREATE temp TABLE  ",
   ident(randomTable), " AS ", sql(query), con=con)
  dwh_statement_resolve(con, t)

  # Replace data
  dwh_replace_table_from_temp_table(con, table_name, randomTable, transaction=F)

  # Drop temp
  print(paste0("Dropping temporary table", collapse=""))
  dwh_statement_resolve(con, paste0('drop table ', randomTable,collapse=""))
  dbCommit(con)

  dwh_disconnect(con)
}


#' Drop view
#'
#' This function drops an existing view in Amazon Redshift
#'
#' @param view_name The name of the view in Amazon Redshift
#'
#' @examples
#'
#' dwh_drop_view('my_view')
#'
#' @export
dwh_drop_view = function(view_name){
  con <- dwh_connect()

  #Drop view
  print(paste0("Dropping view ", view_name, collapse=""))
  dwh_statement_resolve(con, paste0('drop view if exists ', view_name, collapse=""))

  print(paste0("View drop done!", collapse=""))
  dwh_disconnect(con)
}


#' Create view
#'
#' This function creates a view in Amazon Redshift
#'
#' @param orig_table The name of the table to base the view on
#' @param view_name The name of the view in Amazon Redshift
#' @param group_read The group that should have SELECT permissions on the table
#'
#' @examples
#'
#' dwh_drop_view('my_view')
#'
#' @importFrom dbplyr build_sql
#' @export
dwh_create_view = function(orig_table, view_name, group_read='DWH_READ'){
  con <- dwh_connect()

  # Create view
  print(paste0("Creating view from table ", orig_table, " to table ", view_name, collapse=""))
  t <- build_sql("CREATE view  ",
   ident(view_name), " AS SELECT * FROM ", ident(orig_table), con=con)
  dwh_statement_resolve(con, t)

  # Grant select to group
  print(paste0("Granting permissions", collapse=""))
  dwh_statement_resolve(con, paste0('grant select on ', view_name ,' to group ', group_read))

  print(paste0("View creation done!", collapse=""))
  dwh_disconnect(con)
}
