
#' SCD Type 1
#'
#' Generate changes for a Slowly changing dimension type 1 (Overwrite values)
#'
#' @param current_dim Current table, if a reference to a table in DWH, will download the entire table into R
#' @param new_data The data you want to insert into the dimension
#' @param surrogate_key The surrogate key you want to use, it has to be an integer column, and it has to be the first column in the table
#' @param natural_keys The natural keys to use for joining the old data with the new data
#'
#' @examples
#'\dontrun{
#'
#' cur_dim = dwh_query('select * from prod.dim_my_dimension')
#' new_data = mutate(cur_dim, bla=1)
#' changes = dwh_update_scd_type1(cur_dim, new_data, dim_key, c('business_key', 'business_key2'))
#'
#'}
#' @importFrom digest digest
#' @import dplyr
#' @importFrom magrittr "%>%"
#' @importFrom rlang "!!" ":=" enquo quo_name sym
#' @export
dwh_update_scd_type1 = function(current_dim, new_data, surrogate_key, natural_keys){
  message(paste0("Natural keys: ", paste(natural_keys, collapse=', ')))
  message(paste0("Surrogate key: ", quo_name(surrogate_key)))
  current_dim = collect(current_dim)

  #Check for duplicates before anything else
  dupeNum = group_by_at(new_data, vars(one_of(natural_keys))) %>%
    filter(n() > 1) %>% ungroup() %>%
    count() %>% collect()

  if(dupeNum>0){
    stop("The natural keys contain ", dupeNum, " duplicates, please check the staging data.")
  }

  staging_hashed <- new_data %>%
    mutate(!! "hash":=apply(new_data, 1, digest))

  old_data = current_dim %>%
    select(-c(surrogate_key))

  cur_hashed <- old_data %>%
    mutate(!! "hash":=apply(old_data, 1, digest))

  addRows = anti_join(staging_hashed, cur_hashed, by='hash') %>% select(-!! "hash")

  if(nrow(addRows) == 0){
    message("Nothing to update")
    return(NA)
  }else{

  # Get last surrogate key
  last_sk_df=select(current_dim, !!sym("key"):=!!surrogate_key) %>%
     summarize(!!sym("last"):=max(!!sym("key")))
  last_sk=last_sk_df$last
  if(is.na(last_sk) | is.infinite(last_sk)){
    last_sk=0
  }
  next_sk=last_sk+1
  message(paste0("Last SK: ", last_sk))


  # Add new rows for updates, with same key as before, because type 1 is overwrite.
  updateNew = inner_join(addRows, select(current_dim, surrogate_key, natural_keys), by=natural_keys) %>%
    select(surrogate_key, everything())

  # Insert new rows without existing keys
  insert = anti_join(addRows, current_dim, by=natural_keys) %>%
    mutate(!!quo_name(surrogate_key) := as.integer(NA)) %>%
    select(surrogate_key, everything())
  # Assign new surrogate keys
  if(nrow(insert) > 0){
    insert = mutate(insert, !!quo_name(surrogate_key) := next_sk:(next_sk+nrow(insert)-1))
  }

  # Combine all changes to upsert
  allChanges = dplyr::union(insert, updateNew)
  return(allChanges)
  }
}


#' SCD Type 1 in-database
#'
#' Generate changes for a Slowly changing dimension type 1 (Overwrite values) using an existing DWH table and a tibble database reference
#'
#' @param con Connection to use
#' @param dim_schema Schema of the dimension to update
#' @param dim_name Table name to update
#' @param new_ref The data you want to insert into the dimension, it has to be a tbl reference in the same connection as con
#' @param surrogate_key The surrogate key you want to use, it has to be an integer column, and it has to be the first column in the table
#' @param natural_keys The natural keys to use for joining the old data with the new data
#'
#' @examples
#'\dontrun{
#'
#' con = dwh_connect()
#' cur_dim = tbl(con, in_schema('prod', 'dim_my_dimension'))
#' new_data = mutate(cur_dim, bla=1) %>% compute()
#' dwh_update_scd_type1_in_database(con, 'prod', 'my_dimension',
#' new_data, dim_key, c('business_key', 'business_key2'))
#'
#'}
#'
#' @importFrom dplyr compute
#' @importFrom dbplyr in_schema
#' @export
dwh_update_scd_type1_in_database = function(con, dim_schema, dim_name, new_ref, surrogate_key, natural_keys){
  message(paste0("Natural keys: ", paste(natural_keys, collapse=', ')))
  message(paste0("Surrogate key: ", quo_name(surrogate_key)))

  pre_stg_name = randomName()
  pre_stg = compute(new_ref, name=pre_stg_name)

  #Check for duplicates before anything else
  dupeNum = group_by_at(new_ref, vars(one_of(natural_keys))) %>%
    filter(n() > 1) %>% ungroup() %>%
    count() %>% collect()

  if(dupeNum>0){
    stop("The natural keys contain ", dupeNum, " duplicates, please check the staging data.")
  }

  stg_name = randomName()
  dim_ref = tbl(con, in_schema(dim_schema, dim_name))

  if(dim_schema!=''){
    complete_table_name=paste(dim_schema, dim_name, sep='.')
  }else{
    complete_table_name=dim_name
  }


  # Update existing rows
  existing = inner_join(pre_stg, select(dim_ref, natural_keys, surrogate_key), by=natural_keys) %>%
    select(surrogate_key, everything()) %>%
    compute(name=stg_name)

  existing_rows = count(existing) %>% collect()

  if(existing_rows > 0){
    dbBegin(con)
    message("Replacing existing rows")
    dwh_statement(
      sprintf("delete from %s using %s where %s.%s = %s.%s",
              complete_table_name, stg_name, dim_name, surrogate_key, stg_name, surrogate_key),
                  pcon=con)

    dwh_statement(
      sprintf("insert into %s select * from %s",
              complete_table_name, stg_name),
                  pcon=con)
    dbCommit(con)
  }

  # Get last surrogate key
  last_sk_df=select(dim_ref, !!sym("key"):=!!surrogate_key) %>%
     summarize(!!sym("last"):=max(!!sym("key"), na.rm=T)) %>% collect()
  last_sk=last_sk_df$last
  if(is.na(last_sk) | is.infinite(last_sk)){
    last_sk=0
  }
  next_sk=last_sk+1
  message(paste0("Last SK: ", last_sk))

  message("Obtaining new rows")
  new_rows = anti_join(pre_stg, dim_ref, by=natural_keys) %>% collect(n=Inf)

  if(nrow(new_rows) > 0){
    message("Assigning surrogate keys")
    new_rows = mutate(new_rows, !!surrogate_key := next_sk:(next_sk+nrow(new_rows)-1)) %>%
    select(surrogate_key, everything())

    message("Inserting new rows")
    dwh_table_upsert(new_rows, complete_table_name, c(surrogate_key))
  }
}


#' SCD Type 2
#'
#' Generate changes for a Slowly changing dimension type 2 (Add new rows)
#'
#' @param current_dim Current table, if a reference to a table in DWH, will download the entire table into R
#' @param new_data The data you want to insert into the dimension
#' @param surrogate_key The surrogate key you want to use, it has to be an integer column, and it has to be the first column in the table
#' @param natural_keys The natural keys to use for joining the old data with the new data
#' @param scd_date The date to insert, defaults to the current date
#'
#' @examples
#'\dontrun{
#'
#' cur_dim = dwh_query('select * from prod.dim_my_dimension')
#' new_data = mutate(cur_dim, bla=1)
#' changes = dwh_update_scd_type2(cur_dim, new_data, dim_key, c('business_key', 'business_key2'))
#'
#'}
#' @export
dwh_update_scd_type2 = function(current_dim, new_data, surrogate_key, natural_keys, scd_date=Sys.Date()){
  message(paste0("Natural keys: ", paste(natural_keys, collapse=', ')))
  message(paste0("Surrogate key: ", quo_name(surrogate_key)))
  message(paste0("Marking as processed on date ", scd_date))
  current_dim = filter(current_dim, !!sym("scd_end_date")==SCD_FUTURE_DATE) %>%
    collect()

  #Check for duplicates before anything else
  dupeNum = group_by_at(new_data, vars(one_of(natural_keys))) %>%
    filter(n() > 1) %>% ungroup() %>%
    count() %>% collect()

  if(dupeNum>0){
    stop("The natural keys contain ", dupeNum, " duplicates, please check the staging data.")
  }

  message(paste0("Current dimension has ", count(current_dim), " rows"))
  message(paste0("New staging dimension has ", count(new_data), " rows"))
  staging_hashed <- new_data %>%
    mutate(!! "hash" := apply(new_data, 1, digest))

  old_data = current_dim %>%
    select(-c(surrogate_key,"scd_start_date", "scd_end_date"))

  cur_hashed <- old_data %>%
    mutate(!! "hash":=apply(old_data, 1, digest))

  addRows = anti_join(staging_hashed, cur_hashed, by='hash') %>% select(-!! "hash")

  if(nrow(addRows) == 0){
    message("Nothing to update")
    return(NA)
  }else{
    message(paste0("Identified ", nrow(addRows), " rows to update/insert."))

    # Get last surrogate key
    last_sk_df=select(current_dim, !!sym("key"):=!!surrogate_key) %>%
       summarize(!!sym("last"):=max(!!sym("key")))
    last_sk=last_sk_df$last
    if(is.na(last_sk) | is.infinite(last_sk)){
      last_sk=0
    }
    next_sk=last_sk+1
    message(paste0("Last SK: ", last_sk))


    # Overwrite data from today
    today_dim = filter(current_dim, !!sym("scd_start_date")==scd_date)

    updateToday = inner_join(addRows, select(today_dim, surrogate_key, natural_keys), by=natural_keys) %>%
       mutate(!!sym("scd_start_date"):=scd_date,
             !!sym("scd_end_date"):=SCD_FUTURE_DATE) %>%
      select("scd_start_date", "scd_end_date", surrogate_key, everything())
    if(nrow(updateToday) > 0){
      warning(paste0("Overwriting ", nrow(updateToday), " rows already updated today from this dimension"))
    }

    # Update normally for data before today
    prev_dim = filter(current_dim, !!sym("scd_start_date")<scd_date)

    # Update end date of rows being updated
    updateOld = semi_join(prev_dim, addRows, by=natural_keys) %>%
      mutate(!!sym("scd_end_date"):=scd_date)

    # Add new rows for updates, with different key and start/end date
    updateNew = inner_join(addRows, select(prev_dim, surrogate_key, natural_keys), by=natural_keys) %>%
      mutate(!!sym("scd_start_date"):=scd_date,
             !!sym("scd_end_date"):=SCD_FUTURE_DATE) %>%
      select("scd_start_date", "scd_end_date", surrogate_key, everything())
    # Assign new surrogate keys
    if(nrow(updateNew) > 0){
      updateNew = mutate(updateNew, !!surrogate_key := next_sk:(next_sk+nrow(updateNew)-1))
      next_sk = next_sk+nrow(updateNew)
    }

    # Insert new rows without existing keys
    insert = anti_join(addRows, current_dim, by=natural_keys) %>%
      mutate(!!surrogate_key := as.integer(NA),
             !!sym("scd_start_date"):=scd_date,
             !!sym("scd_end_date"):=SCD_FUTURE_DATE) %>%
      select("scd_start_date", "scd_end_date", surrogate_key, everything())
    # Assign new surrogate keys
    if(nrow(insert) > 0){
      insert = mutate(insert, !!surrogate_key := next_sk:(next_sk+nrow(insert)-1))
    }

    # Combine all changes to upsert
    allChanges = dplyr::union(updateOld, updateNew) %>%  dplyr::union(insert) %>% dplyr::union(updateToday)
    return(allChanges)
  }
}
