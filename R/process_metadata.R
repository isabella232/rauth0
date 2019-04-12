
#' Get metadata value
#'
#' Read metadata value from DWH, will autodetect field type and pull from appropiate table
#'
#' @param metadata_key The key of the metadata value, e.g. "last_processed_fit_score" could be the last processed time of the fit score
#' @param source if `dwh`, it'll use the DWH, if you specify anything else, it'll use it as a filename to use as a config database
#'
#' @examples
#'\dontrun{
#'
#' end_date = get_metadata_value('last_processed_fit_score')
#' print(end_date)
#'
#'}
#' @importFrom dplyr tbl collect filter
#' @importFrom magrittr "%>%"
#' @importFrom utils head
#' @importFrom rlang sym "!!"
#' @export
get_metadata_value = function(metadata_key, source='dwh'){
  if(source=='dwh'){
    con=dwh_connect()

    type_ref=tbl(con, 'stg_process_metadata_type')
    type_row = filter(type_ref, !! sym("key")==metadata_key) %>% collect() %>% head(1)
    if(nrow(type_row) == 1){
      type=type_row$type
      table_name=paste0('stg_process_metadata_', type)

      table_ref=tbl(con, table_name)
      value_row = filter(table_ref, !! sym("key")==metadata_key) %>% collect() %>% head(1)
      if(nrow(value_row)==1){
        val=value_row$value
        if(type=='date'){
          return(as.Date(val))
        }else if (type =='timestamp'){
          return(as.POSIXct(val))
        }else{
          return(val)
        }

      }
    }else{
      warning('Metadata key not found')
      return(NA)
    }
  }else{
    if(file.exists(source)){
      metadata=readRDS(source)
      if(metadata_key %in% names(metadata$values)){
        val = metadata$values[[metadata_key]]
        type = metadata$types[[metadata_key]]
        if(type=='date'){
          return(as.Date(val))
        }else if (type =='timestamp'){
          return(as.POSIXct(val))
        }else{
          return(val)
        }

      }else{
        warning('Metadata key not found')
        return(NA)
      }
    }else{
      warning('Metadata key not found')
      return(NA)
    }
  }

}

#' Clean metadata value
#'
#' Delete any value/types associated with a metadata key, useful for changing a metadata value type.
#'
#' @param metadata_key The key of the metadata value, e.g. "last_processed_fit_score" could be the last processed time of the fit score
#' @param source if `dwh`, it'll use the DWH, if you specify anything else, it'll use it as a filename to use as a config database
#'
#' @examples
#'\dontrun{
#'
#' set_metadata_value('my_cool_value', 'hello')
#' set_metadata_value('my_cool_value', 123) #ERROR!
#' clean_metadata_value('my_cool_value')
#' set_metadata_value('my_cool_value', 123)
#'
#'}
#' @export
clean_metadata_value = function(metadata_key, source='dwh'){
  if(source=='dwh'){
    types = c('string','date','timestamp','integer','decimal')
    dwh_statement("
    delete from stg_process_metadata_type
      where key = $1
    ", bindValues=list(metadata_key))

    for(t in types){
      dwh_statement(sprintf("
      delete from stg_process_metadata_%s
        where key = $1
      ", t), bindValues=list(metadata_key))
    }
  }else{
    if(file.exists(source)){
      metadata=readRDS(source)
      if(metadata_key %in% names(metadata$values)){
        metadata$values[[metadata_key]]=NULL
        metadata$types[[metadata_key]]=NULL
        saveRDS(metadata, file=source)
      }else{
        warning('Metadata key not found')
        return(NA)
      }
    }else{
      warning('Metadata key not found')
      return(NA)
    }
  }
}


#' Set metadata value
#'
#' Set the value of a key to the requested value
#'
#' @param metadata_key The key of the metadata value, e.g. "last_processed_fit_score" could be the last processed time of the fit score
#' @param value The data you want to save under this key
#' @param source if `dwh`, it'll use the DWH, if you specify anything else, it'll use it as a filename to use as a config database
#'
#' @examples
#'\dontrun{
#'
#' set_metadata_value('my_cool_value', 'hello')
#'
#'}
#' @importFrom dplyr tbl
#' @export
set_metadata_value = function(metadata_key, value, source='dwh'){
  if(inherits(value, "POSIXct") | inherits(value, "POSIXlt")){
    type='timestamp'
  }else if(inherits(value, "Date")){
    type='date'
  }else if(inherits(value, "numeric")){
    type='decimal'
  }else if(inherits(value, "integer")){
    type='integer'
  }else if(inherits(value, "character")){
    type='string'
  }else{
    stop('Only supported data types are: character, numeric, integer, POSIXct and Date')
  }

  if(source=='dwh'){

    con=dwh_connect()

    #Get current type
    type_ref=tbl(con, 'stg_process_metadata_type')
    type_row = filter(type_ref, !! sym("key")==metadata_key) %>% collect() %>% head(1)
    if(nrow(type_row) == 1){
      type_db=type_row$type

      if(type_db!=type){
        stop('The provided value has a different type than the one that exists in the database. If the type changed please clean the metadata key with function clean_metadata_value(key)')
      }
    }else{
      # Add new type
        dwh_statement("
          insert into stg_process_metadata_type
          values ($1, $2)
        ", bindValues=list(metadata_key, type))
    }

    #Get current value
    table_name=paste0('stg_process_metadata_', type)
    table_ref=tbl(con, table_name)
    value_row = filter(table_ref, !! sym("key")==metadata_key) %>% collect() %>% head(1)
    if(nrow(value_row)==1){
      #Update existing value
      val=value_row$value
      message(sprintf('For metadata key %s - Old value: %s, setting new value: %s', metadata_key, val, value))
       dwh_statement(sprintf("
        update stg_process_metadata_%s
        set value=$1
          where key = $2
        ", type), bindValues=list(value, metadata_key))
    }else{
      message(sprintf('For metadata key %s - Value not set, setting new value: %s', metadata_key, value))
       dwh_statement(sprintf("
        insert into stg_process_metadata_%s
        values ($1, $2)
        ", type), bindValues=list(metadata_key, value))
    }
  }else{
    if(file.exists(source)){
      metadata=readRDS(source)
    }else{
      metadata=list(values=list(), types=list())
    }
    metadata$values[[metadata_key]]=value
    metadata$types[[metadata_key]]=type
    saveRDS(metadata, file=source)
  }
}
